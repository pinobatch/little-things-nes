#!/usr/bin/env python3
from __future__ import with_statement, division

def pb8(chrdata):
    import sys
    outdata = bytearray()
    tiles = (chrdata[i:i + 8] for i in range(0, len(chrdata), 8))
    for tile in tiles:
        ctile = []
        lastc = 0
        flag = 0
        for c in tile:
            flag = flag << 1
            if c == lastc:
                flag = flag | 1
            else:
                ctile.append(c)
                lastc = c
        outdata.append(flag)
        outdata.extend(ctile)
    return bytes(outdata)
