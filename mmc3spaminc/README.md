Spam Inc
========

- **spam:** repeatedly and rapidly perform an action
- **inc:** a CPU instruction that increments a value in memory

The Nintendo Entertainment System contains a clone of the MOS 6502
CPU.  Like the authentic 6502, the NES's CPU has several instructions
that perform a read-modify-write (RMW) sequence on the value in a
memory address.  This sequence consists of three cycles: read old
value, write back old value, and write new value.  The six officially
documented RMW instructions shift a value's bits by one position or
add or subtract 1.  `inc`, short for increment, adds 1.

Most mappers, or circuits to switch pages in NES memory, treat
reads from addresses $8000 through $FFFF as reads from ROM and
writes to the same addresses as commands to the mapper.  Different
mappers respond differently to an RMW.  MMC1, for example, honors the
first write with the old value and disregards the second with the new
value.  The startup code in a few games relies on this, doing `inc`
on a ROM address containing value $FF (which would normally write
back $FF then $00) and expecting only the $FF write to take effect.

MMC3 is believed to honor the second write.  Whether it honors the
first write is uncertain.  Testing this behavior is tricky, as a
program running on the CPU has no way to see the intermediate result
by itself.  So instead, the program uses side effects from the PPU.
The tilemap is filled with a tile index where one bank has a
character with opaque pixels and another transparent pixels, and
sprite 0 is drawn opaque.  Then it rapidly executes RMW instructions
on a ROM address with the bank number for opaque pixels to make the
MMC3 switch to opaque pixels for one CPU cycle and transparent pixels
the next cycle.

If the MMC3 honors both writes, I expect it to keep the bank switched
just long enough for the CHR ROM to sometimes return opaque pixels
for the background.  These pixels overlapping sprite 0 then cause the
PPU to set the sprite 0 overlap flag in its status register.

\* Exact ratio varies in PAL NES

Caveat
------
Only the title screen exists as of this writing.

Future directions
-----------------
The method can be extended to other mappers used in NES games,
be they licensed or well-known unlicensed:

- Tengen MIMIC-1 and RAMBO-1 can use tests similar to those for MMC3.
- FME-7 could be tested via CHR bank or via nametable mirroring.
  Address $A000 behaves like MMC3 $8001.
- ANROM and AOROM can be tested, as they lack bus conflicts and have
  nametable select.
- The variant of the Camerica mapper used in Fire Hawk likewise
  has a nametable select at $9000.
- Action 53 emulates ANROM and CNROM and lacks bus conflicts.

The method is not expected to apply as directly to these mappers:

- CNROM, CPROM, GNROM, and Color Dreams cannot be tested in this way.
  These mappers leave ROM enabled during writes and thus have a bus
  conflict when the new value differs from the old.
- UNROM and BNROM have bus conflicts and can't switch CHR anyway.
- The common variant of the Camerica mapper can't switch CHR.
- MMC5 does not overlap ROM and registers, as it allows switching
  RAM into $8000-$DFFF.

Copyright 2021 Damian Yerrick  
(Insert zlib license here)

Not to be confused with any canned pork product made by Hormel.
