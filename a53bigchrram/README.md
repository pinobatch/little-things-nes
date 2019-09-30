Action 53 CHR bank test
=======================

*Action 53* is an anthology of small video games for NES developed by
the devoted hobbyists in the NESdev community.  The cartridges use a
custom mapper that can simulate common discrete logic mappers, such
as those on Nintendo's NROM, CNROM, UNROM, and AOROM circuit boards.
This mapper has been assigned iNES mapper #28.

The first two volumes of *Action 53* only ever used 8 KiB of CHR RAM,
meaning the CNROM mode went untested in many implementations of the
Action 53 mapper.  In particular, the FCEUX emulator's implementation
was defective in that it delayed writes to the CHR bank register
until the next write to another register (PRG bank, mode, or outer
PRG).  This defect was reported to FCEUX's bug tracker as [bug 779],
and a fix was checked into [FCEUX SVN] in r3339.

[bug 779]: https://sourceforge.net/p/fceultra/bugs/779/
[FCEUX SVN]: https://sourceforge.net/p/fceultra/code/HEAD/tree/fceu/trunk/

Expected result:

> Action 53 CHR bank test  
> © 2017 Damian Yerrick
>
> RAM size: 32K  
> FCEUX bug: No

Setting up the build environment
--------------------------------
You'll need cc65, Python, Pillow, GNU Make, and GNU Coreutils
to build this.  See [nrom-template] for details.

[nrom-template]: https://github.com/pinobatch/nrom-template

Organization of the program
---------------------------

### Include files

* `nes.inc`: Register definitions and useful macros
* `global.inc`: Global variable and function declarations
* `nes2header.inc`: Build an NES 2.0 header (successor to iNES
  header) in a manner familiar to NESASM users

### Source code files

* `a53header.s`: iNES header for Action 53 mapper
* `init.s`: PPU and CPU I/O initialization code
* `main.s`: Main program
* `test.s`: Perform the test
* `bg.s`: Background graphics setup
* `ppuclear.s`: Useful subroutines for interacting with the S-PPU

Greets
------

* [NESdev Wiki] and forum contributors
* [FCEUX] team
* NESHomebrew, Infinite NES Lives, kevtris, and thefox for helping
  make Action 53 a reality

[NESdev Wiki]: http://wiki.nesdev.com/
[FCEUX]: http://fceux.com/

Legal
-----
The demo is distributed under the following license, based on the
GNU All-Permissive License:

> Copyright 2017 Damian Yerrick
> 
> Copying and distribution of this file, with or without
> modification, are permitted in any medium without royalty provided
> the copyright notice and this notice are preserved in all source
> code copies.  This file is offered as-is, without any warranty.

