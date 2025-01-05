IRE tiny
========

![A rectangle at level 10 on a backdrop of level 2d](docs/iretiny-screenshot)

This is a very simple brightness tester, intended for measuring
the IRE levels of the NES composite video output.

It uses only 1 KiB of PRG ROM, and it doesn't need CHR RAM because
it can use the mapper 218 configuration where nametable memory in the
Control Deck acts as CHR RAM (VRAM enable = GND, VRAM A10 = PA13).

* Left, Right: Change the brightness of the outside
* Up, Down: Change the brightness of the center rectangle
* A: Toggle gray emphasis

The brightness levels, from darkest to brightest, are
`0d` (below black), `1d` (normal black), `2d` (dark gray),
`00` (dark gray), `10` (light gray), `3d` (light gray), and
`30` (white).

    Copyright 2011-2015 Damian Yerrick
    Copying and distribution of this file, with or without
    modification, are permitted in any medium without royalty
    provided the copyright notice and this notice are preserved.
    This file is offered as-is, without any warranty.