pngtochr
========

This is a program to convert indexed PNG images to the character
(CHR) data that 8- and 16-bit video game consoles use.  It describes
each data format using a string called a "plane map," which allows
one program to cover multiple consoles.

This is a rewrite of `pilbmp2nes.py`, one of the tools included in
my NES and Super NES project templates, in the C language.  It has
some advantages over the Python version:

- Faster on large images
- Does not need the Python 3 interpreter installed
- Smaller, especially on platforms where Python is uncommon

Disadvantages:

- Cannot read non-PNG images
- Cannot be imported as a library
- Not tested as much

Usage
-----
usage: `pngtochr [options] [-i] INFILE [-o] OUTFILE`

Options:
- `-h, --help`  
  show this help message and exit
- `--version`  
  show version and credits and exit
- `-i INFILE, --image=INFILE`  
  read image from `INFILE`
- `-o OUTFILE, --output=OUTFILE`
  write CHR data to `OUTFILE`  
- `-W HEIGHT`, `--tile-width=HEIGHT`  
  set width of metatiles
- `-H HEIGHT, --tile-height=HEIGHT`  
  set height of metatiles
- `-p PLANES`, `--planes=PLANES`  
  set the plane map
- `-1`  
  shortcut for `-p 0` (that is, 1bpp)
- `--hflip`  
  horizontally flip all tiles (most significant pixel on right)
- `-c PALFMT`, `--palette=PALFMT`
  write a palette in this format instead of tiles (`-p` is ignored)
- `--num-colors=NUM`  
  write this many colors instead of PNG PLTE size
- `--little`
  reverse bytes in each row-plane or palette entry
- `--add=ADDAMT`  
  value to add to each pixel
- `--add0=ADDAMT0`  
  value to add to pixels of color 0 (if different)

In a plane map:
- Bits of chunky pixels are consecutive.
- Comma (`,`) separates row-interleaved planes.
- Semicolon (`;`) separates tile-interleaved planes.

Common plane maps:
- `0`  
  1 bit per pixel
- `0;1`  
  NES (default)
- `0,1`  
  Game Boy, Super NES 2bpp
- `0,1,2,3`  
  Sega Master System, Game Gear
- `0,1;2`  
  Super NES 3bpp (decoded by some games in software)
- `0,1;2,3`  
  Super NES and TurboGrafx-16 (background) 4bpp
- `0,1;2,3;4,5;6,7`  
  Super NES 8bpp for modes 3 and 4
- `3210`  
  Genesis 4bpp
- `76543210`  
  Super NES mode 7 and Game Boy Advance 8bpp
- `10 --hflip --little`  
  Virtual Boy and GBA 2bpp
- `3210 --hflip --little`  
  GBA 4bpp

Less common plane maps:
- `0;1;2;3`  
  VT03 4bpp
- `0,2;1,3`  
  VT16 4bpp on 16-bit data bus

In a palette format:
- `0` and `1` are constant bits.
- `R`, `G`, `B` are color component bits in most to least significant order.

Common palette formats:

- `00BBGGRR`  
  SMS
- `0000000GGGRRRBBB --little`  
  TG16
- `0000BBBBGGGGRRRR --little`  
  Game Gear
- `0000BBB0GGG0RRR0`  
  Genesis
- `0BBBBBGGGGGRRRRR --little`  
  Super NES, GBC, GBA, DS


Legal
-----
Copyright 2019 Damian Yerrick

The main program and the LodePNG library are under the zlib License
as set forth in `lodepng.cpp`.  The option parser from the musl library
is under the MIT (Expat) License as set forth in `musl_getopt.c`.
