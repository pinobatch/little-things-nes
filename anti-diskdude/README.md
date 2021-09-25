# Anti-DiskDude

Header cleaner for iNES ROMs

## Introduction

ROM images of games for Nintendo Entertainment System are most
commonly stored in a format called "iNES", named after the early NES
emulator developed by Marat Fayzullin that introduced the format.
The iNES format consists of a 16-byte header, followed by program
code ("PRG"), optionally followed by graphics font data ("CHR").
Early versions of iNES used only the first 7 bytes of the header,
leaving the other 9 reserved and set to zero.  Some early conversion
tools designed for use with iNES files stored "signature"
information, such as the author of the tool or the site that provided
a file, in the reserved bytes.  One common signature was "DiskDude!",
after the author of a tool that was popular at the time.  Such files
were invalid, which few people noticed at the time because NESticle
and other emulators of the time simply ignored the reserved bytes.
When later versions of the iNES emulator defined purposes for
some of the reserved bytes, files containing a signature failed
to run on newer emulators that follow the newer specification.

Kevin Horton has described the iNES format as well as an extension
called [NES 2.0](https://wiki.nesdev.org/w/index.php?title=NES_2.0).

Anti-DiskDude looks for nonzero bytes in some of the bytes that are
still reserved.  If nonzero bytes are present, it assumes that these
form part of a signature and overwrites the whole 9-byte original
reserved area with zeroes, forcing the original iNES interpretation
of the header values.

The tool has its limitations:

 1. Anti-DiskDude corrects only the reserved bytes.  It does not
    correct any other part of the header.
 2. It is possible to accidentally trigger NES 2.0 mode if the first
    letter in the signature is H, I, J, K, X, Y, or Z.

## Usage

Anti-DiskDude is a command line program.

    Usage: diskdude [options] file...
    Options:
      --help        Display this information
      -v, --verbose List each file and what happened.
      --version     Display version and copyright information

For example, to remove garbage from the headers of all the iNES
files in the current folder:

    diskdude *.nes

## Glossary

- Emulator: a computer program that allows programs for one
  architecture to run on another architecture
- NES: Nintendo Entertainment System, a video game console of the
  late 1980s
- ROM
    1. (acronym) read-only memory, especially a solid state one
    2. a copy of a work that was first distributed in a solid state
       read-only memory

## Legal

The program and this manual are made available under the
zlib license, which follows:

Copyright 2007 Damian Yerrick <nes@pineight.com>

This work is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any
damages arising from the use of this work.

Permission is granted to anyone to use this work for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

 1. The origin of this work must not be misrepresented; you
    must not claim that you wrote the original work. If you use
    this work in a product, an acknowledgment in the product
    documentation would be appreciated but is not required.
 2. Altered source versions must be plainly marked as such,
    and must not be misrepresented as being the original work.
 3. This notice may not be removed or altered from any source
    distribution.

"Source" is the preferred form of a work for making changes to it.
