#!/usr/bin/env python3
from PIL import Image
import os
import sys
from pilbmp2chn import dedupe_chr, compress_nt

def get_tiles_in_image(im):
    (w, h) = im.size
    px = im.load()
    tiles = [
        bytes(px[x, y] for y in range(ty, ty+8) for x in range(tx, tx+8))
        for ty in range(0, h, 8)
        for tx in range(0, w, 8)
    ]
    return tiles

def planify_sliver(sliver, num_planes):
    from functools import reduce
    from operator import or_
    sliver = [
        reduce(or_, (
            ((px >> planeno) & 1) << (7 - x)
            for x, px in enumerate(sliver)
        ))
        for planeno in range(num_planes)
    ]
    return sliver

def planify_tile(data, num_planes):
    rows = [planify_sliver(data[i:i + 8], num_planes)
            for i in range(0, len(data), 8)]
    planes = bytes(
        row[planeno]
        for planeno in range(num_planes)
        for row in rows
    )
    return planes

def main(argv=None):
    from sys import stderr as red

    argv = argv or sys.argv

    filename, outpath = argv[1:3]
    im = Image.open(filename)
    try:
        tiles = get_tiles_in_image(im)
    except IndexError as e:
        raise ValueError(
            "failed to load tiles of %s whose size is %s"
            % (filename, im.size)
        )

    tiles = [planify_tile(tile, 4) for tile in tiles]
    uniqs, nt = dedupe_chr(tiles)
    num_tiles = len(tiles)
    num_uniqs = len(uniqs)
    if len(uniqs) > 254:
        raise ValueError("%s has too many tiles (%d of %d unique)"
                         % (filename, num_uniqs, num_tiles))
    greendata = b''.join(tile[:16] for tile in uniqs)
    mgtadata = b''.join(tile[16:] for tile in uniqs)
    num_tiles = len(tiles)
    num_uniqs = len(uniqs)
    del tiles, uniqs

    dimsdata = bytes([
        im.size[0] // 8, im.size[1] // 8,
        num_uniqs & 0xFF, 0
    ])
    cntdata = compress_nt(nt)
    print("%s\n%d unique of %d tiles; reuse map is %d bytes"
          % (filename, num_uniqs, num_tiles, len(cntdata)))

    with open(outpath, 'wb') as outfp:
        outfp.write(dimsdata)
        outfp.write(cntdata)
        outfp.write(greendata)
        outfp.write(mgtadata)

if __name__=='__main__':
    main()
