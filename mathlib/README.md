This is a library of mathematical subroutines for use in video games running on an NES or other device with a 6502 CPU.

Multiplication and division
-------------
`mul8` computes `A * Y` using long multiplication.  It is expected to
finish in about 150 or so cycles.

`getSlope1` computes `floor(256 * A / Y)`.  As the name indicates, it was developed for rise over run calculations in _Thwaite_, where the result can be interpreted as 0.8 fixed point (that is, the numerator of a fraction with a denominator of 256).

Square root
----------
What do you call the part of a _Minecraft_ tree that's in the ground?  
A square root.  
What do you call the number that you multiply by itself to get a
given number?  
That's also a square root.

Integers that are not perfect squares do not have square roots in the
integers (or even the rationals).  For any positive integer, this
routine finds the greatest integer not greater than the square root,
as well as the remainder.

Given integer n where 0 <= n <= 65535, solve for r and m, where n = r*r + m, 0 <= r, and 0 <= m <= 2r.

A subroutine to do this in under 520 cycles was taken
from <http://6502org.wikidot.com/software-math-sqrt>.

Trigonometry
----------
`getAngle` finds the angle of a vector from (X1, Y1) to (X2, Y2) in
units of 1/32 turn, rounded to the nearest unit.  Using this angle,
you can project the displacement back onto the unit vector
corresponding to that angle to approximate the length of the vector
without needing a square root.  It finishes within about 380 cycles,
and the maximum error found in the fixed tests was 0.506 units, or
5.7 degrees, or 0.099 radian.  (Errors up to 0.5 are unavoidable when
angles are rounded; the rest is tangent search.)

Number formatting
----------
Because the 2A03 CPU in the NES has no binary-coded decimal (BCD) mode for ADC and SBC, base 10 arithmetic has to be done in software.  One way to do this is by doing all arithmetic in binary and then converting to decimal at display time.

bcd.s (Binary Conversions to Decimal) has an unrolled subroutine to convert an 8-bit number to three decimal digits and a looping subroutine to convert a 16-bit number to five decimal digits.  It works sort of like a binary long division routine, except it subtracts the place values of each individual bit in the BCD output.  For example, the 8-bit routine trial-subtracts 200, 100, 80, 40, 20, and 10 to form the high digits and the remainder is the low digit. The 8-bit routine uses no more than 80 cycles, the 16-bit routine up to 652.

A game that gives an accuracy score, such as Galaga or In the Groove, often has to display a fraction with a 16-bit numerator and denominator as a percentage (e.g. 131/225 = 58.2%).  A series of multiplications by 10 is used.  For each output digit, the numerator is multiplied by 1.25, by 2, by 2, and by 2 again, adding a bit to the output each time the result is greater than the denominator.  This takes about 230 cycles per digit.

Simulator
---------
The subroutines in this library have been tested with a simple 6502 simulator written in Python.  The simulator, in turn, has been tested with nestest, a 15 KiB test suite covering official and some unofficial instructions.

To do
-----
1. Test getAngle random subsets
2. Test pctage exhaustively up to denominator 256
3. Randomized tests for pctage (can't do exhaustive due to 2 billion)
4. Generalize getAngle to 32, 64, 128, or 256 steps
5. Retest getAngle with all four resolutions

Legal
-----
The license below applies to the library, documentation,
the library's test suite, and the simulator:

Copyright 2012 Damian Yerrick

Copying and distribution of this file, with or without
modification, are permitted in any medium without royalty provided
the copyright notice and this notice are preserved in all source
code copies.  This file is offered as-is, without any warranty.
