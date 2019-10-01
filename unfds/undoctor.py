#!/usr/bin/env python3
import sys
import os
import glob

force_glob = False  # used for testing Windows behavior on UNIX

def platform_needs_manual_glob():
    return os.name == 'nt'

def doctor_image_to_ines(data, mapper=0, mirroring=0,
                         verbose=False, filename=None):
    # First split the files on a 15-byte boundary string, as in MIME
    boundary = data[0x5C:0x6B]
    files = [(file[:6], file[6:]) for file in data[0x6B:-2].split(boundary)]
    if verbose:
        print(len(files))
        print("%s: header is" % filename)
        header = data[:0x5C]
        for i in range(0, len(header), 16):
            headerline = header[i:i + 16]
            print("  %04x:" % i, " ".join("%02x" % b for b in headerline))
        print("%s: boundary is %s"
              % (filename, boundary.hex()))
        for i, (prefix, payload) in enumerate(files):
            print("%s#%d: prefix is %s and payload is %d bytes"
                  % (filename, i, prefix.hex(), len(payload)))

    # Keep the PRG ROM and CHR ROM
    files = [file[1] for file in files]
    files = [file for file in files if len(file) >= 8192]
    prgrom = files[0]
    chrrom = files[1] if len(files) > 1 else b''

    # VA10=PA11 = V pad = vertical arrangement = horizontal mirroring
    # (Lode Runner, Bomberman, Super Mario Bros.)
    # VA10=PA10 = H pad = horizontal arrangement = vertical mirroring
    # (Ice Climber)
    # B00daW thought header byte 3 being 0x83 or 0x84 correlated with
    # mirroring, but both Lode and IC have 0x84 there.  Need to look
    # for another byte that differs.

    # Correct NROM-128 dumped as NROM-256
    if prgrom[:16384] == prgrom[16384:]:
        prgrom = prgrom[:16384]

    header = bytearray(b"NES\x1A")
    header.extend([
        len(prgrom) // 16384, len(chrrom) // 8192,
        mirroring | ((mapper & 0x0F) << 4),
        mapper & 0xF0
    ])
    header.extend(bytes(16 - len(header)))
    parts = [header, prgrom, chrrom]
    return b''.join(parts)


def main(argv=None):
    argv = argv or sys.argv
    inputfiles = argv[1:]
    if not inputfiles:
        print("undoctor.py: no input files", file=sys.stderr)
        sys.exit(1)
    if sys.argv[1] in ['--help', '-h', '-?', '/?']:
        print("usage: undoctor.py FC1234.A FC2345.A ...")
        sys.exit(0)

    # check & remove verbose flag from list of input files
    verbose = ('-v' in inputfiles) or ('--verbose' in inputfiles)
    inputfiles = [f for f in inputfiles if f not in ('-v', '--verbose')]

    # Unlike UNIX shells, Windows Command Prompt and Windows
    # PowerShell do not expand shell glob patterns before passing
    # them to a program.
    if force_glob or platform_needs_manual_glob():
        inputfiles = [
            filename
            for globpattern in inputfiles
            for filename in glob.glob(globpattern)
        ]

    for filename in inputfiles:
        with open(filename, "rb") as infp:
            data = infp.read()
        ines = doctor_image_to_ines(data, verbose=verbose, filename=filename)
        with open("%s.nes" % filename, "wb") as outfp:
            outfp.write(ines)

if __name__=='__main__':
    main()
