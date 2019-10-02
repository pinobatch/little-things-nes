Four Score and Famicom port test
================================

This reads a Four Score, D4-D1 of $4016-$4017, and D2-D0 of
test register $4018.  It also allows adding an extra clock pulse
to $4016 or $4017 and controlling the state of $4016 D2-D0 while
the controllers aren't being read.  It's intended for testing
assembly of a famiclone with both four NES controller ports and
a Famicom DA15 port.

In addition to displaying the button status on screen, it recognizes
five buttons on controller 1 to toggle outputs:

* Left: Toggle $4016 D2
* Up: Toggle $4016 D1
* Right: Toggle $4016 D0
* B: Extra read on $4017
* A: Extra read on $4016

Differences from Eighty:

1. Ability to toggle the three outputs for use with LEDs
2. Ability to toggle read count parity on both ports for use with
   toggle flip-flops driving LEDs
3. Does not require Four Score
4. Reads D4-D1 of both controller ports (try with Zapper)
5. Reads D2-D0 of $4018 (which would be provided by the clone
   console's internal testing facility)
