#!/usr/bin/env python3
import os, sys
from PIL import Image, ImageStat, ImageChops

commonpath = os.path.normpath(os.path.join(
    os.path.dirname(__file__), "..", "..", "common", "tools"
))
sys.path.append(commonpath)

from pilbmp2nes import pilbmp2chr, formatTilePlanar

def realwidth(im, borderimg):
    diff = ImageChops.difference(im, borderimg).getbbox()
    bbox = diff.getbbox()
    return bbox[2] if bbox else 0

def load_glyph_tiles_from(filename, cellw, cellh, fmt):
    """Load tiles from glyphs in filename.

im -- PIL image object in indexed color or filename to load
cellw -- width of each glyph box, multiple of 8
cellh -- height of glyph box, multiple of 8
fmt -- a pilbmp2nes planemap string, such as "0,1" for GB or "0;1" for NES

The glyphs in `im` are left-aligned in their boxes, using color 0
for transparent and the highest color value for space between glyphs.

Return a list of lists of tiles in column-major order.

"""
    if isinstance(filename, str):
        im = Image.open(filename)
    else:
        im, filename = filename, '<image>'
    if im.mode != 'P':
        raise ValueError("%s: not indexed color" % filename)
    st = ImageStat.Stat(im)
    bordercolor = st.extrema[0][1]
    
    # Crop each glyph out of the image
    portions = (im.crop((x, y, x + cellw, y + cellh))
                for y in range(0, im.size[1], cellh)
                for x in range(0, im.size[0], cellw))

    # Crop out the internal border to right of each glyph
    # ImageChops.difference(im, flat).getbbox(): thanks Eugene Nagorny
    # http://stackoverflow.com/q/10615901/2738262
    flatborder = Image.new(im.mode, (cellw, cellh), bordercolor)
    bboxes = ((portion, ImageChops.difference(portion, flatborder).getbbox())
              for portion in portions)

    portionsC = (portion.crop(bb) if bb is not None else None
                 for portion, bb in bboxes)

    # Now break each glyph down into tiles
    fmtTile = lambda im: formatTilePlanar(im, fmt)
    portionsT = [pilbmp2chr(portion, 8, 32, fmtTile)
                 if portion is not None
                 else []
                 for portion in portionsC]
    return portionsT

# zero elimination compression

def zeroelim(s):
    out = bytearray()
    outbits = 1
    outbitptr = None

    for c in s:
        if outbits == 1:
            outbitptr = len(out)
            out.append(0)
        outbits = (outbits << 1) | (1 if c == 0 else 0)
        if c != 0:
            out.append(c)
        if outbits >= 0x100:
            out[outbitptr] = outbits & 0xFF
            outbits = 1

    while outbits > 1:
        outbits = outbits << 1
        if outbits >= 0x100:
            out[outbitptr] = 0
            outbits = 1
    return out

# similar tiles

def bitweight(s):
    wt = 0
    while s > 0:
        s = s & s - 1
        wt += 1
    return wt

def tilediffweight(ti, tj):
    """Count different pixels between tiles.

The tiles are byteslike, with 8 bytes per plane and however
many planes per row.

Return the number of pixels that differ between the tiles.

"""

    from operator import or_ as bitor
    tixortj = [a ^ b for a, b in zip(ti, tj)]
    diffpixels = [reduce(bitor, tixortj[i::8]) for i in range(8)]
    weight = sum(bitweight(b) for b in diffpixels)
##    print("tile %02x: %s\n vs. %02x: %s\n"
##          "    xor: %s\n diffpx: %s\n"
##          "weight: %d pixels"
##          % (ni, ''.join('%02x' % b for b in ti),
##             nj, ''.join('%02x' % b for b in tj),
##             ''.join('%02x' % b for b in tixortj),
##             ''.join('%02x' % b for b in diffpixels),
##             weight))
    return weight

def similartiles(tiles):
    from collections import defaultdict
    difftiles = defaultdict(lambda: [])
    for ni, ti in enumerate(tiles):
        ti = bytearray(ti)
        for nj in range(ni + 1, len(tiles)):
            tj = bytearray(tiles[nj])
            weight = tilediffweight(ti, tj)
            if weight > 4:
                continue
            difftiles[weight].append((ni, nj))
    return difftiles

def similar_report(outtiles, portionsT, num_tilerows):
    from collections import defaultdict
    wheretileused = defaultdict(lambda: [])
    for c, tiles in enumerate(portionsT):
        c = chr(c + 32)
        for i, tile in enumerate(tiles):
            x, y = i // num_tilerows, i % num_tilerows  # column major
            wheretileused[tile].append((c, x * 8, y * 8))
    blanktile = '\x00' * len(outtiles[0])
    # if I wanted to print (character, tile left, tile top) tuples
    # for all blank tiles, I'd do this:
    # print(wheretileused[blanktile])

    sim = similartiles(outtiles)
    for (ndiff, pairs) in sorted(sim.items()):
        for (a, b) in pairs:
            wtua = wheretileused[outtiles[a]]
            wtub = wheretileused[outtiles[b]]
            print("\na tile used %s\n%s\n"
                  "differs in %d pixels from a tile used %s\n%s"
                  % ("once" if len(wtua) < 2 else "%d times" % len(wtua),
                     "[blank tile]" if outtiles[a] == blanktile else wtua,
                     ndiff,
                     "once" if len(wtub) < 2 else "%d times" % len(wtub),
                     "[blank tile]" if outtiles[b] == blanktile else wtub))

def ca65_bytearray(s):
    """Convert a byteslike into ca65 constant byte statements"""
    s = ['  .byt ' + ','.join("%3d" % ch for ch in s[i:i + 16])
         for i in range(0, len(s), 16)]
    return '\n'.join(s)

def chrtonam(c):
    """Find unique elements in an iterable and in what order they appear.

Return a 3-tuple (uniqelements, eltoindex, map):
uniqelements -- elements in order of first appearance
eltoindex -- map from elements to their indices in uniqelements;
    equivalent to dict((el, i) for (i, el) in uniqelements)
map -- indices of uniqelements in the order in which they appeared,
    such that c[i] = uniqelements[map[i]]

"""
    d = {}
    nam = []
    for tile in c:
        d.setdefault(tile, len(d))
        nam.append(d[tile])
    chrdata = [None] * len(d)
    for (tile, tn) in d.items():
        chrdata[tn] = tile
    return chrdata, d, nam

def cvt_font(filename, cellw, cellh, fmt, title):

    # First load each glyph into an image
    portionsT = load_glyph_tiles_from(filename, cellw, cellh, fmt)
    num_tilerows = (cellh + 7) // 8

    # Get the glyph widths
    startoffsets = bytearray([0])
    for glyph in portionsT:
        startoffsets.append(startoffsets[-1] + len(glyph) // num_tilerows)

    # Reorder the font back to row major order for uniquing
    uniqtiles = {b'\x00'*16: 0}
    tilenums = [[] for i in range(num_tilerows)]
    for c in portionsT:
        for i, tile in enumerate(c):
            uniqtiles.setdefault(tile, len(uniqtiles))
            tilenums[i % num_tilerows].append(uniqtiles[tile])

    if len(uniqtiles) > 256:
        print("cvtfont: %s: %d unique tiles is %d too many"
              % (filename, len(uniqtiles), len(uniqtiles) - 256),
              file=sys.stderr)
        sys.exit(1)

    outtiles = [b'\xFF'*16]*len(uniqtiles)
    for tile, tileno in uniqtiles.items():
        outtiles[tileno] = tile

##    similar_report(outtiles, portionsT, num_tilerows)
    outtiles = b''.join(outtiles)
    uniqtiles = len(uniqtiles)
    portionsT = len(portionsT)
    couttiles = zeroelim(outtiles)
    out = [
        "; font converted with cvtfont.py",
        ".export %s_startoffsets, %s_tilerowlen, %s_numglyphs"
        % (title, title, title),
        "",
        "; tile data, %d unique tiles" % uniqtiles,
        '.segment "CHR10"',
        ca65_bytearray(outtiles),
        '.segment "RODATA"',
        "; starting offset of each glyph in tilerow; a[x+1]-a[x] is width",
        "%s_numglyphs = %d" % (title, portionsT),
        "%s_startoffsets:" % title,
        ca65_bytearray(startoffsets),
        "; tile numbers making up each glyph, like a %d byte wide nametable"
        % len(tilenums[0]),
        "%s_tilerowlen = %d" % (title, len(tilenums[0])),
        "; in negative-leading mode, the bottom row of each line of text",
        "; overlaps the top row of the previous line",
    ]
    for rownum, row in enumerate(tilenums):
        out.append(".export %s_tilerow%d" % (title, rownum))
        out.append("%s_tilerow%d:" % (title, rownum))
        out.append(ca65_bytearray(row))
    return '\n'.join(out)

def main(argv=None):
    argv = argv or sys.argv
    op = argv[1]
    filename = argv[2]
    if op == 'font':
        w = int(argv[3])
        h = int(argv[4])
        title = argv[5]
        print(cvt_font(filename, 24, 32, '0;1', title))
        return
    if op == 'img':
        starttile = int(argv[3])
        title = argv[4]
        im = Image.open(filename)
        c = pilbmp2chr(im, 8, 8, lambda k: formatTilePlanar(k, '0;1'))
        tiles, itiles, nam = chrtonam(c)
        nam = bytearray(starttile + c for c in nam)
        tiles = b''.join(tiles)
        ctiles = zeroelim(tiles)
        out = [
            "; image converted with cvtfont.py",
            ".export %s_zet, %s_chr_size, %s_nam"
            % (title, title, title),
            ".exportzp %s_w, %s_h" % (title, title),
            '.segment "RODATA"',
            "%s_w = %d" % (title, (im.size[0] + 7) // 8),
            "%s_h = %d" % (title, (im.size[1] + 7) // 8),
            "%s_chr_size = %d" % (title, len(tiles)),
            "%s_zet:" % title,
            ca65_bytearray(ctiles),
            "%s_nam:" % title,
            ca65_bytearray(nam)
        ]
        print('\n'.join(out))
        return

if __name__=='__main__':
    if 'idlelib' in sys.modules:
        main(['cvtfont.py', 'font', "../tilesets/fizzter.png", '24', '32', 'fizzter'])
    else:
        main()
##    main(['cvtfont.py', 'img', "../tilesets/titletiles.png", '200', 'title'])
