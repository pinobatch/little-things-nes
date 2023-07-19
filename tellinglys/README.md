Telling LYs?
============

Tests whether a Nintendo Entertainment System emulator produces
realistic timing for button presses.

The NES CPU can read the system's controller ports more often than
once per video frame, which is 50 or 60.1 Hz.  The state of the
controller ports can change at any time in the frame: top, middle,
bottom, or in the vertical blanking between frames.  A program can
see exactly when the interrupt fired by polling the controller
repeatedly during a frame and counting how many times it was polled
since the start of the frame.  For instance, a game  could wait for
a press at the title screen and then seed a random number generator
from the time it took.

Simple emulators always change button states at the same time each
frame, such as the start or end of vertical blanking.  In a sense,
such emulators are "lying" to the game about when the button is
pressed.  The lack of variance in timing is telling about whether
an emulator was used; hence the name.

How to use
----------
Starting at the title screen, press all four directions on the
Control Pad and all four buttons (A, B, Select, and Start) of
controller 1, one after another in any order.  The arrow at the
right side tells exactly when, relative to the PPU frame, the last
button changed from not pressed to pressed.  As you press buttons,
the lyrics of "[Johny, Johny]" appear on the screen.  Once you have
pressed all eight keys, a screen for passing or failing appears.

[Johny, Johny]: https://youtu.be/FLd_n4p-S2M

Test results
------------
A front-loading NTSC NES with a PowerPak passes.  FCEUX as of June
2019 and Mesen 2 (2023) reach the "Incorrect behavior"
screen, with the arrow remaining in roughly the same position
throughout the test.

Legal
-----
Copyright 2018, 2019 Damian Yerrick

Permission is granted to use this program under the terms of the
zlib License.
