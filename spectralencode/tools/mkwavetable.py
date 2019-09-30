#!/usr/bin/env python3
from math import sin, cos, pi as HALFTAU
import sys
import argparse

tablelen = 238
num_waves = 7
lowest_freq = 61
freqstep = 4
amplitude = 18

def ca65_formatbytes(data, linelen=16, hex=True):
    formatstring = "$%02x" if hex else "%3d"
    return [
        "  .byte "+",".join(formatstring % c for c in data[j:j + linelen])
        for j in range(0, len(data), linelen)
    ]

def parse_args(args):
    parser = argparse.ArgumentParser()
    parser.add_argument("-o", metavar="OUTFILE",
                        help="write output to a file instead of standard output")
    return parser.parse_args(args[1:])

def main(argv=None):
    args = parse_args(argv or sys.argv)

    sinscale = HALFTAU / tablelen / 2
    
    freqs = [
        (lowest_freq + i * freqstep, -1 if i & 1 else 1)
        for i in range(num_waves)
    ]
    sinusfreqs = [
        [int(round(amplitude * (1 - (
             sin(i * sinscale * freqfac) * sgn
         ))))
         for i in range(tablelen)]
        for freqfac, sgn in freqs
    ]
    wavenames = [
        ("wave%d" % i, data) for i, data in enumerate(sinusfreqs)
    ]
    wavenames.append(('wavesilence', bytes([amplitude]) * tablelen))

    lines = [
        ".exportzp WAVELEN = %d" % tablelen,
        ".rodata"
    ]
    for wavename, data in wavenames:
        lines.append(".align 256")
        lines.append(".export %s" % wavename)
        lines.append("%s:" % wavename)
        lines.extend(ca65_formatbytes(data))
    lines.append("")

    outfilename = args.o
    outfp = open(outfilename, 'w') if outfilename else sys.stdout
    with outfp:
        outfp.write("\n".join(lines))

if __name__=='__main__':
    main()
