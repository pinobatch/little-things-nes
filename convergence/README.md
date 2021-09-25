Convergence test
================

Use this ROM to test the convergence of your monitor.

The test is 1.25 KiB, which iNES format rounds up to 16 KiB.
It may run on a minimalist devcart with 8K PRG RAM and no CHR
(mapper 218) but hasn't been tested in that configuration.

Controls

* Left: Switch to grid (or toggle center dot)
* Right: Switch to solid color (or toggle white/red)
* Start: Toggle help

Automatically detects PAL or NTSC, using 7x8 pixel cells on NTSC or
8x11 pixel cells on PAL.

Copyright 2018 Damian Yerrick. Distributed under the zlib License.