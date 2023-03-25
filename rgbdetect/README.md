RGB PPU detection
=================

This program attempts to detect whether NESRGB or Hi-Def NES is
installed.

The Picture Processing Unit (PPU) of the Nintendo Entertainment
System (NES) normally outputs composite video, with luma (brightness)
and chroma (color) squeezed onto one pair of wires.  It has a special
mode called "EXT output mode", where instead of outputting composite
video, the PPU outputs indices into a color palette.  Games leave EXT
output mode off because the NES mainboard is not wired to support it.

In the 2010s, as the mainstream market upgraded to high definition,
TVs that adequately decode NES composite video became harder to find.
This led to modifications to the NES called NESRGB and Hi-Def NES.
These mods insert an interposer between the PPU and the rest of the
system that turns on EXT output mode.  Then the interposer intercepts
and stores values that the game writes to the PPU's palette and
outputs color signals, either on analog red, green, and blue pins
(NESRGB) or as HDMI (Hi-Def NES).

In the NESdev Discord server on 2023-03-25, user Fiskbit reported
that the game *Arkista's Ring* was malfunctioning on NESRGB and
Hi-Def NES.  The user investigated further and found that the game
was reading from write-only registers of the PPU.  Normally, reading
a write-only register produces "PPU open bus" behavior, returning the
last value read or written to any PPU register.  The interposers
enable EXT output mode by changing values written to register $2000.
If the game reads back PPU open bus immediately after a write,
it can detect this change.

This version of the program should show `80` on an unmodified NES
and `C0` on NESRGB or Hi-Def NES.

An older RGB mod uses a 2C03 or 2C05 PPU pulled from a PlayChoice-10
arcade system, which outputs an RGB signal.  This version does not
detect 2C03 or 2C05 because they do not support EXT output mode.

Building
--------

To build the program from source, install cc65, Python 3, Pillow,
GNU Make, and Coreutils (see [nrom-template]), and then run `make`.

[nrom-template]: https://github.com/pinobatch/nrom-template/

Legal
-----
Copyright 2023 Damian Yerrick.
The demo is free software distributed under the zlib License.
