MMC1A test
==========

MMC1 is a memory mapping integrated circuit found in about 30 percent
of licensed games for the Nintendo Entertainment System.  It has four
5-bit registers that control what parts of memory it makes available
to the console.  The high bit of the program bank register (D4) is
known to control different behavior on the MMC1A revision compared to
later revisions.  On MMC1B and later, setting D4 to 1 prevents the
MMC1 from asserting the battery RAM's chip select, whereas on MMC1A,
D4 has no effect on the battery RAM's chip select.

Only two games, both exclusive to Japan (where the NES is called
the Family Computer or Famicom), rely on MMC1A's behavior of not
disabling battery RAM.  One is is SOFEL's _The Money Game_, whose
sequel was released elsewhere as _Wall Street Kid_.  The other is
Shinsei's _Tatakae!! Ramen Man: Sakuretsu Choujin 102 Gei_ (whatever
that is).  The preservation community has assigned [iNES mapper 155]
to these games.

A purported datasheet for the MMC1A claims that D4 selects whether to
interpret the next higher bit (D3) as PRG ROM A17 output, selecting
the first or second half of a 256 KiB PRG ROM, or as battery RAM A13
output, selecting the first or second half of a 16 KiB battery RAM.
This resembles the banking mode bit of the [MBC1] mapper on Game Boy,
in which $6000 bit 0 controls whether the secondary bank (set in
$4000) is output as 0 when the CPU is accessing battery RAM or the
ROM's fixed bank.  If MMC1A's PRG ROM A17 output behaves this way,
a program that steps through all possibilities of bank numbers will
select different banks on MMC1A compared to later MMC1 variants.

[iNES mapper 155]: https://wiki.nesdev.org/w/index.php?title=INES_Mapper_155
[MBC1]: https://gbdev.io/pandocs/MBC1.html

The conjectured behavior
------------------------
The claims about the datasheet combined with the known behavior of
MBC1 suggest the following behavior:

Control ($8000): CPPMM

- P=0, P=1: 32K mode (no fixed bank; CPU A14 controls PRG ROM A14)
- P=2: 16K mode, low fixed (CPU A14 low selects bank 0)
- P=3: 16K mode, high fixed (CPU A14 high selects bank 15)
- C and M: Related to the PPU bus, unrelated to this test

PRG bank select ($E000): RPPPP

- P: Select PRG ROM A17-A14 when not in the fixed bank
- R=0: Fixed bank affects PRG A17-A14 output;  
  R=1: Fixed bank affects PRG A16-A14 output, and D3 alone controls
  PRG A17

The test sequence
-----------------

All sixteen banks of PRG ROM, each 16 KiB, contain the same code and
except for one byte, which stores the number of that bank.

1. Reset MMC1
2. Copy font to CHR RAM in case the included CHR ROM is not installed
   (so that the same test works on CHR ROM and CHR RAM boards)
3. Clear the screen and write the title heading at the top
4. Write all combinations of 0, 4, 8, C in $8000 and 00-1F in $E000,
   read which pair of PRG ROM banks is switched in for each case,
   and print the results

Legal
-----
Copyright 2022 Damian Yerrick
License: zlib
