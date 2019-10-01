Big RAM test
============
As of March 2015, NES emulators disagree on how much RAM at $6000 a
game using Sunsoft's FME-7 mapper IC can see.

FME-7 register 8 sets both the bank mapped to $6000 and whether
$6000 is ROM or RAM.  Even if this register is set to RAM, the FME-7
still outputs the bank number on PRG A18-A13.  This was confirmed by
l_oliveira on forums.nesdev.com, who rewired an FME-7 board to use a
larger memory.

Replacing the 6264 (8Kx8 SRAM) on the NES-BTR or JSROM PCB with a
62256 (32Kx8 SRAM) gives the NES program four 8K RAM banks to use.
This would provide ample space for a Z-machine or BASIC interpreter.
    
Run this test on a _Batman: Return of the Joker_ or other FME-7
board with PRG ROM, CHR ROM, and WRAM.  To rewire it to use a 62256,
route signals from the FME-7 to the appropriate pins on the RAM:

* FME-7 pin 36: PRG A13 output
* 62256 pin 26: A13 input (+CE on 6264; you'll need to cut this) 
* FME-7 pin 34: PRG A14 output
* 62256 pin 1: A14 input (not connected on 6264)

Expected results
----------------
With 6264 (by default):

    00: C0 C0 C0 C0 C0 C0 C0 C0
    08: C0 C0 C0 C0 C0 C0 C0 C0

With 62256:

    00: C0 C1 C2 C3 C0 C1 C2 C3
    08: C0 C1 C2 C3 C0 C1 C2 C3

Legal
-----
The test is distributed under the following terms:

    Copyright 2015 Damian Yerrick
    Copying and distribution of this file, with or without
    modification, are permitted in any medium without royalty
    provided the copyright notice and this notice are preserved.
    This file is offered as-is, without any warranty.
