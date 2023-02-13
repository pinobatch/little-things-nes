#!/usr/bin/env python3
"""
Copyright 2014 Damian Yerrick
license: zlib

This program creates a lookup table for horizontally scaling a tile.
bitfield, based on an algorithm suggested by psycopathicteen.
https://forums.nesdev.org/viewtopic.php?p=134277#p134277
"""
import sys

def scale_8to7(x):
    # XXX.XXXX
    return ((x & 0xE0) >> 1) | ((x & 0x0F) >> 0)

def scale_8to6(x):
    # XX.XXX.X
    return ((x & 0xC0) >> 2) | ((x & 0x1C) >> 1) | ((x & 0x01) >> 0)

def scale_8to5(x):
    # X.X.XX.X
    return (((x & 0x80) >> 3) | ((x & 0x20) >> 2)
            | ((x & 0x0C) >> 1) | ((x & 0x01) >> 0))

def scale_8to4(x):
    # .X.X.X.X
    return (((x & 0x40) >> 3) | ((x & 0x10) >> 2)
            | ((x & 0x04) >> 1) | ((x & 0x01) >> 0))

scalers = [
    ('scaletab8to8', lambda x: x),
    ('scaletab8to7', scale_8to7),
    ('scaletab8to6', scale_8to6),
    ('scaletab8to5', scale_8to5),
    ('scaletab8to4', scale_8to4)
]

sys.stdout.write("""; Bit plane scaling table
.segment "RODATA"
.align 256
""")
for name, f in scalers:
    sys.stdout.writelines([".global ", name, "\n", name, ':\n'])
    sys.stdout.writelines("  .byte %s\n"
                          % ','.join('$%02x' % f(b) for b in range(i, i + 16))
                          for i in range(0, 256, 16))

