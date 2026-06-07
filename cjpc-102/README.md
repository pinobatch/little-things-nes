CJPC-102 test
=============

This ROM tests a Coconuts Japan Pachinko controller (CJPC-102).

Press Left or Right on the Control Pad to make the character scoot
toward one of the walls.  Twist the throttle clockwise to change the
speed of the text and the speed of the character.

Protocol
--------

The pachinko controller appears as Famicom controller 3: a clocked
serial device on bit 1 of $4016.  The first 8 out of 16 bits are the
same as the standard controller: A, B, Select, Start, Up, Down, Left,
and Right.  After this is a 1 bit, then the 7-bit throttle level,
inverted (0 means 1), most significant bit first, then more 1's
until the next strobe.

Throttle levels are usually $03 to $72 (3 to 114).  The four games
using this controller cap the throttle at $63 (99 percent).
If a 1 bit does not follow Right, a pachinko controller probably
isn't plugged in.  Games disregard the throttle value in this case.

Internally, it works by generating a continuous sawtooth wave using a
7-bit counter clocked at roughly 20 kHz and comparing it to a voltage
generated with a potentiometer connected to the throttle.
It completes about 150 polls per second.
