Russian Roulette: a Zapper tech demo by Damian Yerrick
======================================================

One of a revolver's six chambers holds a paint capsule.  Each player
in turn spins the cylinder and pulls the trigger.  (No Zapper? Press
A on controller 1.)  If it doesn't fire, pass it to the next player.
Get splattered and you're out!

This game is a luck-based mission for 2 to 6 players alternating.
Each player has a 1 in 6 chance of being eliminated on each turn.
The winner is the last player who hasn't been eliminated.

Building
--------

To compile the source code, you need to install these:

* GNU [Make]
* ca65 and ld65 from the [cc65] project
* [Python] 2.6, 2.7, or 3.x
* Python Imaging Library (or its fork [Pillow])

Rationale
---------

Russian Roulette began in July 2010 as a one-day project to make the
simplest useful demo for the Zapper, a light gun controller for the
Nintendo Entertainment System.  It uses only the trigger, not the
light sensor, as the trigger is the only part that works with LCD TVs.

Legal
-----

Copyright 2014 Damian Yerrick

Copying and distribution of this file, with or without
modification, are permitted in any medium without royalty
provided the copyright notice and this notice are preserved.
This file is offered as-is, without any warranty.

[make]:   https://www.gnu.org/software/make/
[cc65]:   https://cc65.github.io/cc65/
[python]: https://www.python.org/downloads/
[pillow]: https://pillow.readthedocs.org/
