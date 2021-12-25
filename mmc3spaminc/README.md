Spam Inc
========

- **spam:** repeatedly and rapidly perform an action
- **inc:** a CPU instruction that increments a value in memory

The Nintendo Entertainment System contains a clone of the MOS 6502
CPU.  Like the authentic 6502, the NES's CPU has several instructions
that perform a read-modify-write (RMW) sequence on the value in a
memory address.  This sequence consists of three cycles: read old
value, write back old value, and write new value.  The officially
documented RMW instructions perform bit shifting by one position or
adding or subtracting 1.  `inc`, short for increment, adds 1.

Most mappers, or integrated circuits to switch pages in NES memory,
treat reads from addresses $8000 through $FFFF as reads from ROM and
writes to the same addresses as commands to the mapper.  Different
mappers respond differently to an RMW.  MMC1, for example, honors the
first write with the old value and disregards the second with the new
value.  The startup code in a few games relies on this, doing `inc`
on a ROM address containing value $FF (which would normally write
back $FF then $00) and expecting only the $FF write to take effect.

MMC3 is believed to honor the second write.  Whether it honors the
first write is uncertain.  To test the MMC3's behavior, this program
runs repeated `inc` instructions on a register that selects a page of
characters that the PPU uses to draw the background.  One page has
transparent pixels, and the other has opaque pixels.  The PPU detects
whether any opaque pixels of the background overlap sprite 0 and sets
a status flag.  Thus even though the RMW is too fast for the program
to see, it can read the side effects through the PPU.

Caveat
------
Only the title screen exists as of this writing.

Copyright 2021 Damian Yerrick  
(Insert zlib license here)

Not to be confused with any canned pork product made by Hormel.
