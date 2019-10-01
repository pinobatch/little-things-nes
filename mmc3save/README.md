# MMC3 save viewer

I made this while I was trying to help track down a bug in the
PowerPak's MMC3 mapper that was causing screen corruption in
_Crystalis_ and _M.C. Kids_.  Something was overwriting the
cartridge RAM at $6000-$7FFF.

It turned out to be a timing issue in decoding $E000-$FFFF writes
(to turn IRQ on and off), as the address bus momentarily switches
to $E000-$FFFF for about 30 ns before switching to $6000-$7FFF, as
[discovered by loopy](https://forums.nesdev.com/viewtopic.php?p=70513#p70513).

But I did end up with a hex viewer and wiper for .sav files.
