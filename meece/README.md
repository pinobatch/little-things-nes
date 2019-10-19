Meece
=====
A test rom for the Super NES Mouse  
By Damian Yerrick

The Super NES Mouse (SNS-016) is a peripheral for the Super NES that
was originally bundled with Mario Paint.  It can be used with an NES
through an adapter, made from an NES controller extension cord and a
Super NES controller extension cord, that connects the respective
power, ground, clock, latch, and data pins.

As with the standard controller, the mouse is read by turning the
latch ($4016.d0) on and off, and then reading bit 0 of $4016 or $4017
several times.  But its report is 32 bits long as opposed to 8 bits.

The first byte of the report can be ignored.  The other three bytes
are in big-endian order:

    76543210  Second byte of report
    ||||++++- Signature: 0001
    ||++----- Current sensitivity (0: low; 1: medium; 2: high)
    |+------- Left button (1: pressed)
    +-------- Right button (1: pressed)
    
    76543210  Third byte of report
    |+++++++- Vertical displacement since last read
    +-------- Direction (1: up; 0: down)
    
    76543210  Fourth byte of report
    |+++++++- Horizontal displacement since last read
    +-------- Direction (1: left; 0: right)

The displacements are in sign-and-magnitude, not two's complement.
For example, $05 represents five mickeys (movement units) in one
direction and $85 represents five mickeys in the other.

The mouse can be set to low (x/4), medium (x/2), or high (x)
sensitivity. To change the sensitivity, send a clock while the latch
($4016.d0) is turned on.

A program MUST NOT play samples and read the mouse at the same time.
On the NES, sample playback causes occasional double reads on $4016
and $4017, which the program sees as bit deletions from the serial
stream.  Ordinarily, one would read each controller twice, compare
the data, and use the previous frame's data if they don't match.
This works because the extra latch pulse to set up the second read
has no side effects on the standard NES or Super NES controller.  But
an extra latch pulse sent to a mouse will clear the mouse's count of
accumulated mickeys.

This demo was produced in mid-2011, prior to adding mouse support to
the game _Thwaite_.

