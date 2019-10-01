#!/usr/bin/env python3
#
# Bitmap to NES CHR converter using Python Imaging Library
# Copyright 2010 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offesys.stderr as-is, without any warranty.
#
from __future__ import with_statement
import sys
from time import sleep
from PIL import Image
from pilbmp2nes import formatTilePlanar, pilbmp2chr
from bitbuilder import BitBuilder, Biterator, log2

def histo(it):
    """Count occurrences of each distinct element in an iterable."""
    out = {}
    for el in it:
        out.setdefault(el, 0)
        out[el] += 1
    return out

def parse_argv(argv):
    from optparse import OptionParser
    parser = OptionParser(usage="usage: %prog [options] [-i] INFILE [-o] OUTFILE")
    parser.add_option("-i", "--image", dest="infilename",
                      help="read image from INFILE", metavar="INFILE")
    parser.add_option("-o", "--output", dest="outfilename",
                      help="write CHR data to OUTFILE", metavar="OUTFILE")
    parser.add_option("--packbits", dest="packbits",
                      help="use PackBits RLE compression for CHR",
                      action="store_true", default=False)
    parser.add_option("--pb8", dest="pb8",
                      help="use pb8 RLE compression for CHR",
                      action="store_true", default=False)
    parser.add_option("--index-rle", dest="indexrle",
                      help="use delta-RLE compression for tile indices",
                      action="store_true", default=False)
    parser.add_option("--max-tiles", dest="maxTiles",
                      help="error if more than this many 8x8 tiles are used",
                      metavar="NUM",
                      type="int", default=256)
    parser.add_option("--dims", dest="dims",
                      help="write 4-byte header with width, height, and number of distinct tiles",
                      action="store_true", default=False)
    parser.add_option('-v', "--verbose", dest="stats",
                      help="write lies, damn lies, and image statistics",
                      action="store_true", default=False)
    (options, args) = parser.parse_args(argv[1:])

    # Fill unfilled roles with positional arguments
    maxTiles = int(options.maxTiles)
    if maxTiles < 1:
        raise ValueError("number of tiles must be 1 or more")
    if maxTiles > 256:
        raise ValueError("number of tiles must be 256 or fewer")

    argsreader = iter(args)
    try:
        infilename = options.infilename
        if infilename is None:
            infilename = argsreader.next()
    except StopIteration:
        raise ValueError("not enough filenames")

    outfilename = options.outfilename
    if outfilename is None:
        try:
            outfilename = next(argsreader)
        except StopIteration:
            outfilename = '-'
    if outfilename == '-':
        import sys
        if sys.stdout.isatty():
            raise ValueError("cannot write CHR to terminal")

    if options.packbits:
        codec = 'packbits'
    elif options.pb8:
        codec = 'pb8'
    else:
        codec = ''
    return (infilename, outfilename, maxTiles,
            options.dims, codec, options.indexrle, options.stats)

def dedupe_chr(chrdata):
    seen_chrdata = {}
    nt = []
    for tile in chrdata:
        seen_chrdata.setdefault(tile, len(seen_chrdata))
        nt.append(seen_chrdata[tile])
    seen_chrdata = sorted(seen_chrdata.items(), key=lambda x: x[1])
    seen_chrdata = [row[0] for row in seen_chrdata]
    return (seen_chrdata, nt)

def compress_nt(ntdata):
    from bitbuilder import gammalen

    runcounts = {}  # used for determining backref
    base = 0
    runs = []
    greatest = -1
    while base < len(ntdata):

        # measure the run of new tiles (greatest+i+1)
        # starting at t
        i = 0
        imax = min(128, len(ntdata) - base)
        while (i < imax
               and (greatest + i + 1) % 256 == ntdata[base + i]):
            i += 1
        if i > 0:
            greatest += i
            base += i
            runs.append((-1, i))
            continue

        # measure the +0 run starting at t
        i = 1
        imax = min(128, len(ntdata) - base)
        while (i < imax
               and ntdata[base] == ntdata[base + i]):
            i += 1

        # we use the same number of bits for a backreference
        # that are in greatest
        runs.append((ntdata[base], i, log2(greatest) + 1))
        runcounts.setdefault(ntdata[base], 0)
        runcounts[ntdata[base]] += 1
        base += i
    runcounts = sorted(runcounts.items(), key=lambda x: -x[1])
    most_common_backref = runcounts[0][0] if len(runcounts) else 0
##    runHisto = sorted(histo(row[1] for row in runs).items())
##    print >>sys.stderr, "Run length distribution:"
##    print >>sys.stderr, "\n".join("%3d x%3d" % row for row in runHisto)
##    print >>sys.stderr, "mcbr is", most_common_backref

    out = BitBuilder()
    out.append(most_common_backref, 8)
##    print "\n".join(repr(row) for row in runs)
    for row in runs:
        idx, runlength = row[:2]
        out.appendGamma(runlength - 1)
        if idx < 0:
            out.append(2, 2)
        elif idx == most_common_backref:
            out.append(3, 2)
        else:
            nbits = row[2]
            if idx >= 1 << nbits:
                print("index FAIL! %d can't fit in %d bits" % (idx, nbits),
                      file=sys.stderr)
            out.append(idx, nbits + 1)
    return bytes(out)

argvTestingMode = True
printStats = True

def main(argv=None):
    global printStats
    import sys

    if argv is None:
        argv = sys.argv
        if (argvTestingMode and len(argv) < 2
            and sys.stdin.isatty() and sys.stdout.isatty()):
            argv.extend(raw_input('args:').split())
    try:
        (infilename, outfilename, maxTiles, useDims,
         chrCodec, useIndexRLE, printStats) = parse_argv(argv)
    except Exception as e:
        sys.stderr.write("%s: %s\n" % (argv[0], str(e)))
        sys.exit(1)

    if printStats:
        print("filename: %s" % infilename, file=sys.stderr)
    im = Image.open(infilename)
    (w, h) = im.size
    if printStats:
        print >>sys.stderr, "size: %dx%d" % im.size
    if w % 8 != 0:
        raise ValueError("image width %d is not a multiple of 8" % w)
    if h % 8 != 0:
        raise ValueError("image height %d is not a multiple of 8" % h)

    ochrdata = pilbmp2chr(im, 8, 8,
                          lambda im: formatTilePlanar(im, 2))
    del im
    (chrdata, ntdata) = dedupe_chr(ochrdata)
    numTiles = len(chrdata)

    if numTiles > maxTiles:
        raise ValueError("%d distinct tiles exceed maximum %d" % (numTiles, maxTiles))

    ochrdata = ''.join(ochrdata)
    chrdata = ''.join(chrdata)
    if printStats:
        print("CHR size before dedupe: %d" % len(ochrdata), file=sys.stderr)
        print("distinct tiles: %d of %d" % (numTiles, len(ntdata)), file=sys.stderr)
        print("unpacked CHR size: %d" % len(chrdata), file=sys.stderr)
    if useIndexRLE:
        cntdata = compress_nt(ntdata)
        if printStats:
            print("compressed nametable size: %s" % len(cntdata), file=sys.stderr)
        ntdata = cntdata
    else:
        ntdata = ''.join(chr(x) for x in ntdata)
    if chrCodec == 'packbits':
        from packbits import PackBits
        sz = len(chrdata) % 0x10000
        pchrdata = PackBits(chrdata).flush().tostring()
        pchrdata = bytes([chr(sz >> 8), chr(sz & 0xFF)]) + pchrdata
        if printStats:
            print("packed CHR size: %d" % len(pchrdata), file=sys.stderr)
        chrdata = pchrdata
    elif chrCodec == 'pb8':
        from pb8 import pb8
        sz = len(chrdata) // 16
        pchrdata = pb8(chrdata)
        pchrdata = bytes([sz & 0xFF]) + pchrdata
        if printStats:
            print("packed CHR size: %d" % len(pchrdata), file=sys.stderr)
        chrdata = pchrdata

    if useDims:
        dimsdata = bytes([w // 8, h // 8, numTiles & 0xFF, 0])
    else:
        dimsdata = ''
    outdata = b''.join([dimsdata, ntdata, chrdata])

    # Write output file
    outfp = None
    try:
        if outfilename != '-':
            outfp = open(outfilename, 'wb')
        else:
            outfp = sys.stdout
        outfp.write(outdata)
    finally:
        if outfp and outfilename != '-':
            outfp.close()

if __name__=='__main__':
    try:
        main()
##        main(['pilbmp2nes.py', '-v', '--dims', '--packbits',
##              '--index-rle', '../tilesets/nesdev/abadidea.png', 'test.chn'])
    except Exception as e:
        from traceback import print_exc
        import sys
        print_exc(None if printStats else 0)
        sys.exit(1)
