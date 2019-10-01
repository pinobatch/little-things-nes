#!/usr/bin/env python3
import sys
import os
import glob

force_glob = False  # used for testing Windows behavior on UNIX

def platform_needs_manual_glob():
    return os.name == 'nt'

fds_file_types = {
    1: (55, '.mbr'),
    2: (1, '.count'),
    3: (15, '.meta'),
}

fds_file_suffixes = ['.prg', '.chr', '.nam']

def unpack_fds(data, has_crcs=False, num_files=3):
    """Extract data from a Quick Disk image formatted for FDS."""
    sync_pattern = b'\x01*NINTENDO-HVC*'
    i = data.index(sync_pattern)
    filesleft, next_filesize, next_suffix = 3, 0, "error"
    out = []

    files_written = 0
    while i < len(data) and filesleft > 0:
        filetype = data[i]
        i += 1
        if filetype == 0 or filetype > 4:
            continue
        if filetype == 4:
            size, suffix = [next_filesize, next_suffix]
        else:
            size, suffix = fds_file_types[filetype]
        filedata = data[i:i + size]
        if filetype >= 3:
            suffix = "-%02x%s" % (files_written, suffix)
            if filetype == 3:
                next_filesize = filedata[12] + 256 * filedata[13]
                next_suffix = fds_file_suffixes[filedata[14]]
            else:
                files_written += 1
        yield suffix, filedata
        i += size
        if has_crcs:
            i += 2

def form_ines(prgrom, chrrom, mapper, mirroring):
    # VA10=PA11 = V pad = vertical arrangement = horizontal mirroring
    # (Lode Runner, Bomberman, Super Mario Bros.)
    # VA10=PA10 = H pad = horizontal arrangement = vertical mirroring
    # (Ice Climber)

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
        print("""usage: undoctor.py [options] FC1234.A FC2345.A ...
Unpacks a Quick Disk image in Famicom Disk System format.

options:
  --no-crc            assume image lacks CRCs, for fwNES .fds images""")
        sys.exit(0)

    # check & remove flags from list of input files
    inputfiles = []
    has_crc = True
    for arg in argv[1:]:
        if arg in ('--no-crc',):
            has_crc = False
        else:
            inputfiles.append(arg)

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
        for suffix, data in unpack_fds(data, has_crcs=True):
            with open(filename + suffix, "wb") as outfp:
                outfp.write(data)

if __name__=='__main__':
    main()
