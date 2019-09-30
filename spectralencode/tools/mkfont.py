#!/usr/bin/env python3
import argparse
import sys
from operator import or_ as bitor
from functools import reduce
from PIL import Image

def process_glyph(pixels):
    if len(pixels) != 64:
        raise ValueError("length must be 64, not %d" % len(pixels))
    out = bytearray()
    for x in range(8):
        col = [0x80 >> y if px else 0 for y, px in  enumerate(pixels[x::8])]
        out.append(reduce(bitor, col))
    return out

def ca65_formatbytes(data, linelen=16, hex=True):
    formatstring = "$%02x" if hex else "%3d"
    return [
        "  .byte "+",".join(formatstring % c for c in data[j:j + linelen])
        for j in range(0, len(data), linelen)
    ]

def parse_args(args):
    parser = argparse.ArgumentParser()
    parser.add_argument("INFILE",
                        help="indexed image with 8x8 glyphs as nonzero indices")
    parser.add_argument("-o", metavar="OUTFILE",
                        help="write output to a file instead of standard output")
    return parser.parse_args(args[1:])

def main(argv=None):
    args = parse_args(argv or sys.argv)
    im = Image.open(args.INFILE)
    if im.mode != 'P':
        raise ValueError("%s must be indexed color" % filename)
    glyphs = []
    for tile_y in range(0, im.size[1], 8):
        for tile_x in range(0, im.size[0], 8):
            cropped = im.crop((tile_x, tile_y, tile_x + 8, tile_y + 8))
            glyphs.append(process_glyph(cropped.tobytes()))
    lines = [".rodata", ".export alphabetdata", "alphabetdata:"]
    lines.extend(line for glyph in glyphs for line in ca65_formatbytes(glyph))
    lines.append("")
    outfilename = args.o
    outfp = open(outfilename, 'w') if outfilename else sys.stdout
    with outfp:
        outfp.write("\n".join(lines))
            

if __name__=='__main__':
    main()
##    main(['mkfont.py', "../tilesets/alphabet.png"])
