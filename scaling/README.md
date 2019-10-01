This NES program illustrates scaling a sprite down in real time.
It can shrink 8 tiles every vertical blank, allowing 15 fps
for (say) a 32x64 pixel character if nothing else is being scaled.
Horizontal shrinking is performed  by putting each bit plane of
each row of pixels in a tile through a lookup table, and vertical
shrinking just skips rows that aren't used using a DDA algorithm.

Press Left or Right on the Control Pad to move the character.
Press Up or Down to change the size of the scaled preview in the
center.

Building
========

Building requires Python 2, Pillow, ca65, and ld65.

These Python programs are in the `tools` folder:

* `pilbmp2nes.py` is a program to convert bitmap images in PNG or
  BMP format into tile data usable by several classic video game
  consoles.  It has several options to control the data format; use
  `pilbmp2nes.py --help` from the command prompt to see them all.
* `mkscaletable.py` generates lookup tables from an 8x1 pixel sliver
  to the same sliver scaled to 8x1, 7x1, 6x1, 5x1, and 4x1 pixels.

Legal
=====

The demo is distributed under the following license, based on the
GNU All-Permissive License:

> Copyright 2014 Damian Yerrick
> 
> Copying and distribution of this file, with or without
> modification, are permitted in any medium without royalty provided
> the copyright notice and this notice are preserved in all source
> code copies.  This file is offered as-is, without any warranty.

