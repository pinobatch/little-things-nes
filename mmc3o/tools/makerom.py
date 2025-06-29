#!/usr/bin/env python3
"""
MMC3 oversize test ROM builder
Copyright 2025 Damian Yerrick
SPDX-License-Identifier: Zlib
"""
import os, sys, argparse

helpText = """
Builds an MMC3 bank tester ROM of a given size.
""".strip()

helpEndText = """
Procedure: Read the last 8 KiB of PRG ROM from the input file.  Write
an NES 2.0 header followed by the PRG ROM repeated once every 8 KiB,
with the bank number at offset $1FDF in each copy.  If not CHR RAM,
write the first 1 KiB of PRG ROM as the first CHR ROM bank, followed
by blank banks with the bank number at offset $0000 in each bank.
""".strip()

def parse_argv(argv):
    p = argparse.ArgumentParser(description=helpText, epilog=helpEndText)
    p.add_argument("input",
                   help="mmc3bank base ROM")
    p.add_argument("output",
                   help="output ROM")
    p.add_argument("-P", "--prg-size", type=int, default=512,
                   help="size of PRG ROM in 1024-byte units (16 to 2048)")
    p.add_argument("-C", "--chr-size", type=int, default=8,
                   help="size of CHR memory in 1024-byte units (8 to 256)")
    p.add_argument("-R", "--chr-ram", action="store_true",
                   help="use CHR RAM instead of CHR ROM")
    p.add_argument("-v", "--verbose", action="store_true",
                   help="display more troubleshooting information")
    args = p.parse_args(argv[1:])
    if not 16 <= args.prg_size <= 2048:
        p.error("PRG ROM size must be 16 to 2048 KiB, not %d"
                     % args.prg_size)
    if args.prg_size & (args.prg_size - 1):
        p.error("PRG ROM size must be a power of 2, not %d"
                     % args.prg_size)
    if not 8 <= args.chr_size <= 256:
        p.error("CHR memory size must be 8 to 256 KiB, not %d"
                     % args.chr_size)
    if args.chr_size & (args.chr_size - 1):
        p.error("CHR memory size must be a power of 2, not %d"
                     % args.chr_size)
    return args, p.prog

def main(argv=None):
    args, prog = parse_argv(argv or sys.argv)
    try:
        with open(args.input, "rb") as infp:
            header = infp.read(16)
            if args.verbose:
                print("%s: %s: header is %s"
                      % (prog, args.input, header.hex()), file=sys.stderr)
            prgsize = header[4] * 0x4000
            prgskip = prgsize - 0x2000
            if args.verbose:
                print("%s: %s: PRG ROM size is %d KiB; reading at offset 0x%x"
                      % (prog, args.input, prgsize, prgskip + len(header)),
                      file=sys.stderr)
            infp.read(prgskip)
            prgrom = infp.read()
        if len(prgrom) < 0x2000:
            raise ValueError("%s: PRG bank truncated to %d bytes (expected 8192)"
                             % (args.input, len(prgrom)))
        header = bytearray(b"NES\x1A")
        header.append(args.prg_size // 16)
        header.append(0 if args.chr_ram else args.chr_size // 16)
        header.append(0x40)  # MMC3, mapper mirroring, no NVRAM, no trainer
        header.append(0x08)  # MMC3, NES 2.0, for NES/FC hardware
        header.append(0x00)  # MMC3
        header.append(0x00)  # PRG ROM < 4 MiB, CHR ROM < 2 MiB
        header.append(0x00)  # no PRG RAM
        header.append(args.chr_size.bit_length() + 3 if args.chr_ram else 0)
        header.append(0x02)  # all region
        header.append(0x00)  # not Vs. System
        header.append(0x00)  # no expansion ROMs
        header.append(0x00)  # default controller
        assert len(header) == 16
        if args.verbose:
            print("%s: %s: header is %s"
                  % (prog, args.output, header.hex()), file=sys.stderr)

        # Construct ROM contents
        prgbanks = [bytearray(prgrom) for i in range(args.prg_size // 8)]
        for i, bank in enumerate(prgbanks): bank[0x1FDF] = i
        if args.chr_ram:
            chrbanks = []
        else:
            chrbanks = [bytearray(prgrom[:1024])]
            blank_chr_bank = b'\xFF'*1024
            chrbanks.extend(bytearray(blank_chr_bank)
                            for i in range(1, args.chr_size))
            for i, bank in enumerate(chrbanks): bank[0] = i

        if args.verbose:
            print("%s: %s: writing %d bytes"
                  % (prog, args.output,
                     len(header) + sum(len(x) for x in prgbanks)
                     + sum(len(x) for x in chrbanks)), file=sys.stderr)
        with open(args.output, "wb") as outfp:
            outfp.write(header)
            outfp.writelines(prgbanks)
            outfp.writelines(chrbanks)
        
    except Exception as e:
        # it's more polite to less-technical users to elide the
        # traceback without -v
        if args.verbose:
            from traceback import print_exc
            print_exc()
        else:
            print("%s: %s" % (prog, e), file=sys.stdout)

if __name__=='__main__':
    if 'idlelib' in sys.modules:
        main("""
./makeroms.py -v -P1024 -RC32 ../mmc3bankfx.nes ../mmc3bank_1M_CR32.nes
""".split())
        main("""
./makeroms.py -v -P1024 -C128 ../mmc3bankfx.nes ../mmc3bank_1M_C128.nes
""".split())
    else:
        main()
