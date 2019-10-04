The Picture Processing Unit of the Nintendo Entertainment System
contains Object Attribute Memory, which stores a display list of 64
sprites, or positions of individual moving objects.  Internally, OAM
is implemented as DRAM, a form of memory that bleeds out over time
and must be refreshed every few milliseconds.  OAM is organized as 32
rows, each row containing two sprites, and the refresh circuitry
scans a pair of sprites at a time.  Normally, the PPU refreshes OAM
as long as display is enabled.  But at power-on or reset, the refresh
circuit is in an unpredictable state until it has finished displaying
one frame.

Normally, a game updates OAM once per frame by copying a 256-byte
display list from main memory.  But if the program updates OAM once
and then just leaves it there, some sprites will not be displayed
because the refresh circuit will have overwritten them with blank
data.  This program demonstrates this glitch:  it copies the display
list to OAM once after reset and then once again each time the user
presses Select to change the sprite configuration.  Press Reset on
the Control Deck to make two sprites (an even-odd pair) drop out.

The demo can also be used to find defective secondary OAM.
One console was discovered to be broken in such a way as
to allow only seven sprites per line instad of eight.
<https://forums.nesdev.com/viewtopic.php?f=9&t=9628>

Building this demo requires cc65, Python, and Python Imaging Library.
You'll probably also need GNU Make and Coreutils, which Windows users
can find in MSYS and users of Ubuntu and other Debian-based operating
systems can find in the build-essential package.


== Legal ==

The demo is distributed under the following license, based on the
GNU All-Permissive License:

; Copyright 2012 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.

