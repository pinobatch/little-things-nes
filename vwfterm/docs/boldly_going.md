Boldly going where Sunsoft has not gone before
==============================================

This project uses the Sunsoft FME-7 integrated circuit in ways that
no game produced by Sunsoft ever tried.  Existing emulators, which
were tested with Sunsoft's games, may handle these ways incorrectly.
This is in part because far more popular games ran on popular mappers
such as MMC3 than on FME-7.  So the developers have had to blaze new
trails in emulation accuracy.

PRG RAM
-------
A mapper is a circuit in the cartridge that controls the part of
memory that the NES sees.  Most mappers are intended to switch
ROM, and very few allow more than 8 KiB of work RAM on the cart.
The popular MMC3, for example, passes only A14 and A13 to the PRG
bank switching logic.  This means it treats the WRAM bank at $6000
the same as $E000, which is fixed to the last bank of ROM, and
drives PRG ROM address lines A18-A13 high for both $6000 and $E000.

**SXROM** is an MMC1-based board that addresses 32 KiB of work RAM by
repurposing two of the MMC1's CHR ROM address outputs to switch among
four banks of RAM at $6000.  But MMC1's bank switching is fiddly
and slow, and there is no true fixed bank in a ROM larger than 256
KiB because such a ROM is split into halves.

**EWROM** is an MMC5-based board with two dedicated bank bytes.  But
MMC5 was used only in about a dozen games, and the only three EWROM
games are Koei war simulators.  Nor has MMC5 been replicated in
a CPLD as of 2015.

**JSROM**, called **NES-BTR** in North America, uses Sunsoft's FME-7
mapper.  Though the licensed JSROM board contains only 8 KiB of RAM,
it was speculated that FME-7 still outputs a bank number on the PRG
A13-A18 lines when the CPU is reading or writing $6000-$7FFF while
RAM is enabled.  On March 7, 2015, a test ROM was released to help
settle this (see fme7acktest), after which l_oliveira successfully
rewired a board to use 32 KiB and even 128 KiB RAMs.

CHR RAM
-------
The game contains a large amount of text, and drawing it all to a
28-column-wide window quickly becomes awkward.  Text is more
comfortable to read when it uses a smaller, proportional font.
On the NES, a proportional font requires CHR RAM on the cartridge.
Though no licensed FME-7 game uses CHR RAM, FME-7 works when the
cartridge is rewired to use it, and the FME-7 implementations in
the PowerPak and common emulators correctly display the output of
an FME-7 program using CHR RAM.

Raster splits
-------------
The NES is designed to show up to 256 different tiles in one scene.
This is fine for repetitive game scenes.  Arranging the palettes
and attributes to use both bitplanes separately allows up to 512.
A full-screen terminal, by contrast, needs control over each
individual pixel on the screen in order to place individual glyphs
at arbitrary positions.  So the terminal uses raster splits to get
up to 420 different tiles, whose bitplanes separate into 840 tiles.
Covering the center 80 percent of the screen with distinct tiles in
this way produces an "all points addressable" display.

The exact timing of the raster splits differs for three environments:

* Famicom and NTSC NES run at 60 Hz.  The TV usually hides the top
  and bottom of the picture in an "overscan" area.  So we put some
  lines of border above and below the terminal so that the TV cuts
  nothing off.
* Dendy runs at 50 Hz, and 50 Hz TVs have a longer frame with more
  scanlines than 60 Hz TVs.  Instead of an overscan area, the picture
  contains several scanlines of black border, enough that the TV
  displays the entire height of the picture.
* Like Dendy, PAL NES runs at 50 Hz and has border.  Unlike Dendy,
  it has a CPU about 6 percent slower than that of an NTSC NES, and
  it has a  much longer period from the end-of-frame NMI to the start
  of the next frame because the period includes more of the time
  spent outputting border lines.

The NMI handler uploads a line of text to CHR RAM if necessary, sets
the initial scroll position (24 pixels above the status bar for NTSC
and the top of the status bar for PAL), and calculates timer periods
for IRQs that occur at four split points:

1. Below the status bar, the scroll is changed to the scrolling
   text window.  This is 32 pixels from the top on NTSC and 8 pixels
   from the top on PAL.
2. Below the tenth line of text, the CHR ROM banks for the middle
   third of the screen are switched in.
3. Below the twentieth line of text, the CHR ROM banks for the
   bottom third of the screen are switched in.
4. Below the twenty-fourth line of text on NTSC (60 Hz) displays
   only, the scroll is changed to a blank area to cover the bottom
   overscan.
  
The FME-7's interval timer counts CPU cycles, and after counting down
to 0, it wraps around to 65535.  The methods of getting multiple
scroll splits on the FME-7's timer differ from those used with the
more common MMC3, which has a scanline counter with a reload latch.
Naively reloading the entire counter causes cumulative drift of plus
or minus 3 cycles (9 pixels) for each interrupt unless only the high
byte is written.  This has the effect of rounding useful interrupt
periods after the first to a multiple of 256 cycles.  Fortunately,
splits that affect only banks need to hit a window of over 800
cycles, as the new set of banks slightly overlaps the current one.

At one point, the developers had to resolve differences in how
various emulators interpret commands written to the enable port of
the timer.  These differences caused splits to trigger at the correct
time on the PowerPak and FCEUX but trigger over and over in Nestopia,
turning the whole screen into a flickering smear.  In fact, the
PowerPak, FCEUX, and Nestopia all had different behaviors.  A test
ROM was prepared to determine the exact behavior, and it turned out
that an authentic FME-7's behavior differed from all three of them.
Patches to the IRQ logic of these three environments soon followed.

FCEUX still has other timing differences that the acknowledgment
test does not cover.  These differences, which have not yet been
fully characterized, cause some minor display artifacts.
