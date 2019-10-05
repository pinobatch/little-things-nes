#!/usr/bin/env python3
#
# Implementation of Apple PackBits data compression
# Copyright 2010, 2019 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#
import sys

class PackBits():
    def __init__(self, toWrite=''):
        self.data = bytearray()
        self.closed = False
        self.mode = 'wb'
        self.name = '<PackBits>'
        self.newlines = None
        if toWrite:
            self.write(toWrite)

    def close(self):
        self.data = None
        self.closed = True

    def write(self, s):
        """Add a bytes-like object to the buffer."""
        if not self.closed:
            self.data.extend(s)

    def tell(self):
        return len(self.data)

    def truncate(self, length):
        if not self.closed:
            del self[length:]

    def writelines(self, seq):
        """Add an iterable of bytes-like objects to the buffer."""
        for s in seq:
            self.write(s)

    def flush(self):
        """Compress the data to a file."""
        base = 0
        out = bytearray()
        while base < len(self.data):

            # measure the run starting at t
            i = 1
            imax = min(128, len(self.data) - base)
            basebyte = self.data[base]
            while (i < imax
                   and basebyte == self.data[base + i]):
                i += 1
            # if the run is either length 3 or to the end of the file,
            # write it
            if i > 2 or base + i == len(self.data):
                out.append(257 - i)
                out.append(self.data[base])
                base += i
                continue

            # measure the nonrun starting at t
            i = 1
            imax = min(128, len(self.data) - base)
            while (i < imax
                   and (base + i + 2 >= len(self.data)
                        or self.data[base + i] != self.data[base + i + 1]
                        or self.data[base + i] != self.data[base + i + 2])):
                i += 1
            out.append(i - 1)
            out.extend(self.data[base:base + i])
            base += i
        return out

    @staticmethod
    def test():
        pb = PackBits(b'stopping stoppping stopppppi')
        data = pb.flush()
        print(data.hex())

def parse_argv(argv):
    from optparse import OptionParser
    parser = OptionParser(usage="usage: %prog [options] [[-i] INFILE [[-o] OUTFILE]]")
    parser.add_option("-d", "--unpack", dest="unpacking",
                      help="unpack instead of packing",
                      action="store_true", default=False)
    parser.add_option("--raw", dest="withHeader",
                      help="don't write 2-byte length header",
                      action="store_false", default=True)
    parser.add_option("-i", "--input", dest="infilename",
                      help="read input from INFILE", metavar="INFILE")
    parser.add_option("-o", "--output", dest="outfilename",
                      help="write output to OUTFILE", metavar="OUTFILE")
    (options, args) = parser.parse_args(argv[1:])

    # Fill unfilled roles with positional arguments
    argsreader = iter(args)
    infilename = options.infilename
    if infilename is None:
        try:
            infilename = next(argsreader)
        except StopIteration:
            infilename = '-'
    if infilename == '-' and options.unpacking:
        import sys
        if sys.stdin.isatty():
            raise ValueError('cannot decompress from terminal')

    outfilename = options.outfilename
    if outfilename is None:
        try:
            outfilename = next(argsreader)
        except StopIteration:
            outfilename = '-'
    if outfilename == '-' and not options.unpacking:
        import sys
        if sys.stdout.isatty():
            raise ValueError('cannot compress to terminal')

    return (infilename, outfilename, options.unpacking, options.withHeader)

class UnPackBits(PackBits):
    def flush(self):
        out = bytearray()
        base = 0
        while base < len(self.bytes):
            c = self.bytes[base]
            if c > 0 and c <= 127:
                b = self.bytes[base + 1]
                out.extend(self.bytes[base + 1:base + c + 2])
                base += 2 + c
            elif c >= -127:
                b = self.bytes[base + 1]
                out.fromlist([b] * (1 - c))
                base += 2
        return out

    @staticmethod
    def test():
        start = b'stopping stoppping stopppppi'
        packed = PackBits(start).flush()
        print("Packed is", repr(packed))
        unpacked = UnPackBits(packed).flush()
        print("Unpacked is", repr(unpacked))
        print("pass" if start == unpacked else "fail")

argvTestingMode = True

def main(argv=None):
    import sys
    if argv is None:
        argv = sys.argv
        if (argvTestingMode and len(argv) < 2
            and sys.stdin.isatty() and sys.stdout.isatty()):
            argv.extend(raw_input('args:').split())
    try:
        (infilename, outfilename, unpacking, withHeader) = parse_argv(argv)
    except Exception as e:
        print("%s: %s" % (argv[0], e), file=sys.stderr)
        sys.exit(1)

    # Read input file
    infp = None
    try:
        if infilename != '-':
            infp = open(infilename, 'rb')
        else:
            infp = sys.stdin
        data = infp.read()
    finally:
        if infp and infilename != '-':
            infp.close()
        del infilename, infp

    if unpacking:

        # Decompress input file
        if withHeader:
            maxlength = data[0] * 256 + data[1]
            startOffset = 2
        else:
            maxlength = None
            startOffset = 0
        outdata = UnPackBits(data[startOffset:]).flush()
        if maxlength is not None:
            if len(outdata) < maxlength:
                raise IndexError('incomplete PackBits chunk')
            if len(outdata) > maxlength:
                outdata = outdata[:maxlength]
    else:

        # Compress input file
        outdata = PackBits(data).flush()
        if withHeader:

            # The .pkb header is the unpacked length in bytes,
            # 16-bit big endian
            sz = len(data) % 0x10000
            outdata = bytes([sz >> 8, sz & 0xFF]) + outdata
    
    # Read input file
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
    main()

