#!/usr/bin/env python3
"""
symdealias.py - remove aliases for symbols in an ld65 dbg file
By Damian Yerrick

Copyright 2022 Retrotainment Games LLC

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
"""
import sys, os, argparse
from collections import defaultdict, namedtuple

helpText="Strips alias symbols from an ld65 debug symbol file."
helpEnd= ""

def parse_argv(argv):
    p = argparse.ArgumentParser(description=helpText, epilog=helpEnd)
    p.add_argument("dbgfile", help="path of debug symbol file")
    p.add_argument("-o", "--output", default='-',
                   help="path of debug symbol file to write")
    return p.parse_args(argv[1:])

def parse_nvp_line(line):
    line = line.rstrip().split("\t", 1)
    symtype = line[0]
    props = (dict(tuple(item.split("=", 1)) for item in line[1].split(","))
             if len(line) > 1
             else {})
    return symtype, props

SymEntry = namedtuple('SymEntry', [
    'name', 'score', 'orig_line'
])

def main(argv=None):
    args = parse_argv(argv or sys.argv)
    with open(args.dbgfile, "r") as infp:
        lines = list(infp)
    out = []
    symlines = []
    rom_seg_base = {}  # {id: ooffs-start, ...}
    importcount = defaultdict(int)
    for line in lines:
        symtype, props = parse_nvp_line(line)
        if symtype == 'seg' and 'ooffs' in props:
            segid = int(props["id"])
            seg_base = int(props["ooffs"], 0) - int(props["start"], 0)
            rom_seg_base[segid] = seg_base
        if symtype != 'sym':
            out.append(line)
            continue
        if 'scope' not in props:  # @labels and unnamed labels
            continue
        if props["type"] == 'imp':
            importcount[props['name']] += 1
            continue
        symlines.append((props, line))
    print("%d sym lines, %d other lines, %d ROM segments"
          % (len(symlines), len(out), len(rom_seg_base)),
          file=sys.stderr)

    # valtosyms is {address: [entry, ...], ...}
    # entry is (name, score, line)
    # segs is 
    valtosyms = defaultdict(list)
    for props, line in symlines:
        # Drop values outside address space or in the local variable
        # area of zero page
        val = int(props['val'], 0)
        if not 0x0010 <= val <= 0x10000: continue
        # Drop ROM values without a segment
        seg = props.get("seg")
        if val >= 0x8000 and seg is None: continue
        seg = int(seg) if seg is not None else None
        seg_base = rom_seg_base.get(seg) if seg is not None else None
        # Because $6000-$7FFF is not bankable on this cartridge,
        # (seg_base, val) uniquely identifies a ROM address

        name = props["name"]
        is_lab = props['type'] == 'lab'
        has_size = int(props.get('size', '0')) > 0
        score = (1 + (2 if is_lab else 0)
                 + (1 if seg is not None else 0) + (1 if has_size else 0))
        score = score * (1 + importcount[name])
        valtosyms[seg_base, val].append(SymEntry(name, score, line))
    print(len(valtosyms), "symbols", file=sys.stderr)

    for (seg_base, val), syms in valtosyms.items():
        chosen = max(syms, key=lambda x: x.score)
        out.append(chosen.orig_line)

    if args.output == '-':
        sys.stdout.writelines(out)
    else:
        with open(args.output, "w") as outfp:
            outfp.writelines(out)

if __name__=='__main__':
    if 'idlelib' in sys.modules:
        main(["symdealias.py", "../fq-all.dbg", "-o", "../fq.dbg"])
    else:
        main()
