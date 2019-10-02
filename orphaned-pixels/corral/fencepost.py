#!/usr/bin/env python3
import sys
from PIL import Image
from collections import defaultdict

def getmaskP(im):
    """Return a mask image for nonzero pixels in a mode P Pillow image."""
    im = im.copy()
    im.putpalette(b"\x00\x00\x00" + b"\xFF" * 765)
    return im.convert('1')

"""
Each map cell has bits for whether its south and west walls are solid.

Each tile potentially contains pixels from these wall bits:

* This cell's S wall
* S wall of cell to the west OR this cell's W wall
* S wall of cell to south
* S wall of cell to southwest OR W wall of cell 1 to south
* W wall of cell 2 to south

"""
wall_offsets = {
    'S': [(0, -8), (4, -8), (8, -8)],
    'W': [(0, -16), (0, -12), (0, -8)]
}
wall_pvs = [
    ('S', 0, 0),
    ('S', -8, 0),
#    ('W', 0, 0),
    ('S', 0, 8),
    ('S', -8, 8),
#    ('W', 0, 8),
    ('W', 0, 16)
]

def make_fencepost_tiles():
    hwall = Image.open("hwall.png")
    hwallmask = getmaskP(hwall)
    vwall = Image.open("vwall.png")
    vwallmask = getmaskP(vwall)

    walltypes = {
        'S': (hwall, hwallmask),
        'W': (vwall, vwallmask)
    }

    def wallsortkey(row):
        side, sx, sy = row
        return sy + (1 if side == 'S' else 0), sx

    pixelstotileno, wallstotileno = {}, []
    blanktile = Image.new("P", (8, 8), 0)
    blanktile.putpalette(hwall.getpalette())
    alltiles = Image.new("P", (128, 64), 0)
    alltiles.putpalette(hwall.getpalette())
    for walls in range(1 << len(wall_pvs)):
        coords = [
            (side, sx, sy)
            for i, (side, sx, sy) in enumerate(wall_pvs)
            if walls & (1 << i)
        ]
        coords.sort(key=wallsortkey)

        tile = blanktile.copy()
        for side, sx, sy in coords:
            im, mask = walltypes[side]
            topleft = (sx, sy + 8 - im.size[1])
            tile.paste(im, topleft, mask)

        tilebytes = tile.tobytes()
        if tilebytes not in pixelstotileno:
            pixelstotileno[tilebytes] = tilenum = len(pixelstotileno)
            tilenumtl = (tilenum % 16 * 8, tilenum // 16 * 8)
            alltiles.paste(tile, tilenumtl)
        tilenum = pixelstotileno[tilebytes]
        wallstotileno.append(tilenum)
        
    print("; Estimate II:", len(pixelstotileno), "tiles")
    num_tile_rows = -(-len(pixelstotileno) // 16)
    alltiles = alltiles.crop((0, 0, 128, 8 * num_tile_rows))

##    out = Image.new("P", (64, 64))
##    out.putpalette(hwall.getpalette())
##    out.paste(hwall, (16, 16), hwallmask)
##    out.paste(vwall, (24, 24), vwallmask)
##    out.resize((out.size[0] * 4, out.size[1] * 4)).show()
##    raise NotImplementedError

    return alltiles, wallstotileno

def look_for_irrelevant(seq):
    """Look for cases where bits can be dropped before passing them in.

Return an iterator over i where i has one bit set, and for all x,
seq[x] == seq[x | i]

O(n log n)
"""
    i = 1
    while i < len(seq):
        if all(seq[x] == seq[x | i] for x in range(len(seq))):
            yield i
        i = i << 1

def look_for_or(seq):
    """Look for cases where bits can be OR'd before passing them in.

Return an iterator over i, j where i and j have one bit set, i < j,
and for all x, seq[x | i] == seq[x | j] == seq[x | i | j]

O(n log^2 n)
"""
    
    i = 1
    while i << 1 < len(seq):
        j = i << 1
        while j < len(seq):
            if all(seq[x | i] == seq[x | j] == seq[x | i | j]
                   for x in range(len(seq))):
                yield (i, j)
            j = j << 1
        i = i << 1

def look_for_masked_bit(seq):
    """Look for cases where one bit always covers up another.

Return an iterator over i, j where i and j have one bit set, i != j,
and for all x, seq[x | i] == seq[x | i | j].  Thus j is a don't care
whenever i is true.

O(n log^2 n)
"""
    i = 1
    while i < len(seq):
        j = 1
        while j < len(seq):
            if i != j:
                if all(seq[x | i] == seq[x | i | j] for x in range(len(seq))):
                    yield (i, j)
            j = j << 1
        i = i << 1

def analyze_relevance(wallstotileno):
    print("\n".join(
        "{:08b}: ${:02x}".format(i, tileno)
        for i, tileno in enumerate(wallstotileno)
    ))
    for i in look_for_irrelevant(wallstotileno):
        print("{:08b} can be ignored".format(i, j))
    for i, j in look_for_or(wallstotileno):
        print("{:08b} and {:08b} can be combined".format(i, j))
    for i, j in look_for_masked_bit(wallstotileno):
        print("{:08b} occludes {:08b}".format(i, j))

def ibatch(it, size):
    out = []
    for el in it:
        out.append(el)
        if len(out) >= size:
            yield out
            out = []
    if out:
        yield out

def bytes_to_ca65(bytedata, size=16, usehex=False, prefix=".byte "):
    fmt = "$%02x" if usehex else "%3d"
    for line in ibatch(bytedata, size):
        yield "".join((prefix, ",".join(fmt % i for i in line), "\n"))

SWALL = 0x40
WWALL = 0x80

def random_fenceposts():
    import random
    
    wwalltypes = [0x00, 0x00, 0x00, WWALL]
    swalltypes = [0x00, 0x00, 0x00, SWALL]
    rowtemplate = bytes([
        0, 0, WWALL, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, WWALL, 0
    ])
    num_rows = 24
    rows = []
    while len(rows) < num_rows:
        row = bytearray(rowtemplate)
        for i in range(2, 30):
            row[i] |= random.choice(swalltypes) | random.choice(wwalltypes)
        rows.append(row)
    for i in range(2, 30):
        row[i] |= SWALL
    return rows

def render_ascii_fenceposts(fp):
    for row in fp:
        line = []
        for c in row:
            line.append('|' if c & WWALL else '.')
            line.append('_' if c & SWALL else ' ')
        line.append('\n')
        yield ''.join(line)

def render_tiled_fenceposts(fp, alltiles, wallstotileno):
    field_h = len(fp)
    outsize = (256, (field_h + 2) * 8)
    out = Image.new("P", outsize, 0)
    out.putpalette(alltiles.getpalette())
    empty_row = [0] * 32
    nwall_row = [0] * 2 + [SWALL] * 28 + [0]
    r_s, r_ss = empty_row, nwall_row
    for y in range(field_h + 2):
        r_here, r_s = r_s, r_ss
        r_ss = fp[y] if y < field_h else empty_row
        for x in range(2, 31):
            
            # This cell's S wall
            # S wall of cell to the west OR this cell's W wall
            # S wall of cell to south
            # S wall of cell to southwest OR W wall of cell 1 to south
            # W wall of cell 2 to south

            s_here = r_here[x] & SWALL
            w_here = r_here[x] & WWALL
            s_w = r_here[x - 1] & SWALL
            s_s = r_s[x] & SWALL
            w_s = r_s[x] & WWALL
            s_sw = r_s[x - 1] & SWALL
            w_ss = r_ss[x] & WWALL

            idx = ((0x01 if s_here else 0)
                   | (0x02 if w_here or s_w else 0)
                   | (0x04 if s_s else 0)
                   | (0x08 if w_s or s_sw else 0)
                   | (0x10 if w_ss else 0))
            tileno = wallstotileno[idx]
            tilex = (tileno % 16) * 8
            tiley = (tileno // 16) * 8
            tilesrc = alltiles.crop((tilex, tiley, tilex + 8, tiley + 8))
            out.paste(tilesrc, (x * 8, y * 8))

    return out


alltiles, wallstotileno = make_fencepost_tiles()
alltiles.resize((alltiles.size[0] * 4, alltiles.size[1] * 4)).show()
print("".join(bytes_to_ca65(wallstotileno, usehex=True)))
##analyze_relevance(wallstotileno)
fp = random_fenceposts()
print("".join(render_ascii_fenceposts(fp)))
im = render_tiled_fenceposts(fp, alltiles, wallstotileno)
im.resize((im.size[0] * 2, im.size[1] * 2)).show()
