# Sprite 0 Test

The Nintendo Entertainment System's PPU has a so-called "sprite 0
hit" detection feature at CPU address $2002, bit %01000000.
On the NES, it is set when the first pixel of sprite #0 is drawn
overlapping the background.  This feature is used most often in
scrolling games, to detect when to switch from scrolling the
playfield to scrolling a status bar (in _Gradius_) or vice versa
(in _Super Mario Bros._).  However, many NES emulators circa 2000
(NESticle, REW, NESten) had a flawed implementation of sprite 0 hit
that triggered when the first pixel of sprite 0 is drawn, whether
or not it overlaps the background.  It worked for existing games
but destroys these emulators' ability to be a testbed for homemade
scrolling code.  LoopyNES was among the first to get this right.

This program tests an emulator's compatibility with the NES with
respect to sprite 0 hit.  When sprite 0 is hit, the background
momentarily turns off, creating a black bar under sprite 0.  On a
correct emulator, the black bar should _disappear_ if sprite 0 is
between background tiles or otherwise not overlapping background
pixels.  This takes into account only opacity (0 vs. nonzero), not
the exact color value of each pixel (1-3) or palette values.
In addition, it does not trigger on the far right (X=255).

Use ASM6 (from the maker of LoopyNES) to assemble.

## Controls

- Control Pad: Move sprite 0
- A: Increase size of sprite 0
- B: Decrease size of sprite 0
- Select: Change color of background (%01 or %10)

## Legal

Copyright 2000, 2019 Damian Yerrick

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met: 

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in
   the documentation and/or other materials provided with the
   distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
