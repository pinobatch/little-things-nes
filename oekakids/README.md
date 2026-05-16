Oeka Kids tablet test
=====================

Bandai released the Oeka Kids (おえかキッズ) tablet, a graphics tablet
for Nintendo's Family Computer, in October 1990.  Two games support
it, both based on Takashi Yanase's Anpanman characters.

It has been proposed to give PC and mobile ports of NES games a
touch-driven menu interface.  For the sake of authenticity, these
games could use the same protocol as this tablet.  This means we'll
need to test how the tablet reacts to both the player's input and
request signals sent by the game.

I've identified these research objectives:

1. Get a feel for pen-down and the space-bar-shaped button at the
   bottom of the tablet, to inform how emulators on PC should
   translate mouse input to touch
2. Measure roughly how much of the surface the pen can reach with a
   coordinate display, moving sprite, and drawing canvas
3. Measure how long it takes for the tablet to acknowledge
   each clock edge on $4016
4. Measure whether the tablet samples the pen position on the
   falling or rising edge of strobe

This version of the test is suitable for objectives 1 through 3.

The test
--------

The top 1/8 of the tablet is a toolbar with seven holes to represent
buttons for particular tools or color selections.  The rest is a
big rectangular drawing surface.

At the title screen, press the Start Button on controller 1 to
show a canvas.

Above the canvas are three groups of numbers: the chosen advance mode,
the horizontal (X) and vertical (Y) coordinates of the pen position,
and the two bits sent after the coordinates.  The first status bit
becomes 1 while the pen is on the tablet, and the second reflects the
space bar.

Below the canvas are two rows of digits indicating how long the
driver spent waiting for the tablet to acknowledge each half-bit,
in 11-cycle units.  These are hexadecimal $0 to $16, then space
meaning $17, then various canvas border tiles meaning $18 to $1F.

At the top of the screen is a gray bar.  Its height is proportional
to how long the program took to read the position from the tablet.
A ruler at top left helps measure how tall the gray bar is.

A reticle appears while the pen is on the tablet.  Moving the pen
within the drawing surface draws gray pixels into the canvas.  Moving
the pen while holding the space bar draws white pixels.  Tapping
toolbar buttons moves the reticle but does not draw into the canvas.

Protocol
--------

The tablet samples the pen position when $4016 bit 0 (strobe) is 0.
It's unknown whether this is when it becomes 0 (falling edge) or
continuously while it remains 0 (in effect the rising edge).
It can be read while strobe is 0 and outputs a bit each time
$4016 bit 1 (advance) becomes 1.

    7654 3210  Tablet request ($4016 write)
           |+- Strobe (0: sample; 1: readable)
           +-- Advance to next bit

    7654 3210  Tablet data ($4017 read)
         || +- Controller 2 data (A Button if strobe is 1)
         |+--- 1 if strobe is 0 or advance is 1, 0 otherwise
         +---- 0 if strobe is 0, inverted report bit otherwise

The microcontroller in the tablet is slow.  The program must wait for
the tablet to acknowledge each clock edge on $4016 by reading $4017:
write $01, wait for $00, write $03, wait for $04, read report bit.

The report read from $4017 bit 3 is 18 bits long.  All fields of the
report are MSB first, and all bits are inverted such that $08 means 0
and $00 means 1.

1. 8 bits X position (increasing to right)
2. 8 bits Y position (increasing downward; toolbar lies above $20)
3. 1 bit for stylus touching tablet (XY unspecified if not)
4. 1 bit for whether the space bar is held

Timing results
--------------

This controller is slow to read.  It takes about 67 scanlines' worth
of CPU time, starting at prerender line and ending at the bottom of
the "8" mark on the ruler, averaging about 423 cycles per bit.
However, the individual bit times are anything but even.

The first digit in the top row, time to acknowledge a transition from
1 to 3, is usually $B through $10, occasionally $13.  Other digits in
the top row are mostly $7 and $8 with about two randomly placed $D
and $E.  The bottom row, time to acknowledge a transition from 3 to
1, is mostly $14 and $15 with about five $1A (lower left dot) and $1B
(right line).

A developer might consider interleaving reading the tablet with
other game logic or clocking each half-bit in a DMC IRQ handler.

It is unknown how long the strobe has to be 0 before it turns 1.
We assume it's no longer than how long it takes to read a pair of
standard controllers.

Legal
-----

Short tech demo, no copyleft restrictions needed:

    Copyright 2026 Damian Yerrick
    
    Copying and distribution of this file, with or without modification,
    are permitted in any medium without royalty provided the copyright
    notice and this notice are preserved.  This file is offered as-is,
    without any warranty.
