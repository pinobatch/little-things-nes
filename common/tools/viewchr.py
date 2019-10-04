#!/usr/bin/env python3
import sys
import os
import argparse
from PIL import Image

def sliver_to_texels(lo, hi):
    return [((lo >> i) & 1) | (((hi >> i) & 1) << 1)
            for i in range(7, -1, -1)]

def tile_to_texels(chrdata):
    _stt = sliver_to_texels
    return [_stt(a, b) for (a, b) in zip(chrdata[0:8], chrdata[8:16])]

def chrbank_to_texels(chrdata):
    _ttt = tile_to_texels
    return [_ttt(chrdata[i:i + 16]) for i in range(0, len(chrdata), 16)]

def texels_to_pil(texels, tile_width=16):
    tilerows = [texels[i:i + tile_width]
              for i in range(0, len(texels), tile_width)]
    texels = [bytes(c for tile in row for c in tile[y])
              for row in tilerows for y in range(8)]
    im = Image.frombytes('P', (8 * tile_width, len(texels)), b''.join(texels))
    im.putpalette(b'\x00\x00\x00\x66\x66\x66\xb2\xb2\xb2\xff\xff\xff')
    return im

def render_usage(tilewidth=32):
    tiles = texels_to_pil(chrbank_to_texels(chrdata, tilewidth))
    return tiles

def parse_skip_arg(s):
    s = s.lower()
    if s == 'prg': return s
    if s.startswith("0x"): return int(s[2:], 16)
    if s.startswith("$"): return int(s[1:], 15)
    return int(s)

def parse_argv(argv):
    p = argparse.ArgumentParser()
    p.add_argument("romfile",
                   help="path to .nes or .chr file")
    p.add_argument("outfile", nargs="?",
                   help="path to .bmp, .png, or .gif output file")
    p.add_argument("--skip", type=parse_skip_arg,
                   help="bytes to skip (e.g. 4096, $1000, 0x1000), "
                        "or prg to skip entire .nes PRG ROM "
                        "(default: 16 for .nes or 0 for other extensions")
    p.add_argument("--width", type=int, default=16,
                   help="number of tiles per row (default: 16)")
    return p.parse_args(argv[1:])

def main(argv=None):
    args = parse_argv(argv or sys.argv)
    infilename, outfilename = args.romfile, args.outfile
    skip = args.skip
    skip_prg = False
    if skip is None:
        ext = os.path.splitext(infilename)[-1].lower()
        skip = 16 if ext == '.nes' else 0
    elif skip == 'prg':
        skip = 16
        skip_prg = True
    with open(infilename, "rb") as infp:
        header = infp.read(skip)
        if skip_prg:
            prgromsize = header[4] << 14
            if (header[7] & 0x0C) == 0x08:  # NES 2.0 large PRG ROM extension
                prgromsize += (header[9] & 0x0F) << 22
            infp.read(prgromsize)
        romdata = infp.read()
    tiles = texels_to_pil(chrbank_to_texels(romdata), args.width)
    if outfilename:
        tiles.save(outfilename, bits=2)
    else:
        tiles.show()

if __name__=='__main__':
    in_IDLE = 'idlelib.__main__' in sys.modules or 'idlelib.run' in sys.modules
    if in_IDLE:
        main(['./viewchr.py', '../../768/768.nes', "--skip=prg"])
    else:
        main()
