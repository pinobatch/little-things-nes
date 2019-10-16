# x816 things

These were originally built using x816, an assembler for MS-DOS whose
Pascal source code has since disappeared.  In little things, they are
built with the assembler ASM6, whose syntax is similar.  Greets to
Johnathan Roatch for proving the concept of assembling x816 code
using ASM6.

## Compatibility Benchmarks 2001

I made this in September 2001.  I intended it to be a big dunk on
NESticle, showing a bunch of things that it got wrong and other
emulators of the time got right, but Game Boy Advance homebrew
sucked me in before I could finish it.

## GNOME vs. KDE

`bingo` is GNOME vs KDE: Battle of the Desktops (June 2000).

To account for modern NES emulators' increased accuracy compared to
what we had at the time (NESticle and LoopyNES), two changes have
been made to the program:  Waiting for vertical blank uses the more
reliable method of busy-waiting for a change in retrace count,
and the OAM update has been moved to vertical blank.

## Insane Game

`insane` is a very incomplete attempt to clone SameGame in January
and May 2000, inspired by the TI-83 port by Martin Hock and Bill
Nagel.

## Nibbles

`nibbles` is a port of a QBasic game, the origin of the "Damian
Yeppick" misnomer from a misreading of the font in one version, and
the first time I felt tension between ROM organizing tools and the
"release early and often" mentality of the free software community.
I've even seen it pop up on NOAC famiclones' built-in pirate
multicarts despite everything that's broken about its code from
having been tested exclusively on emulators of the time.

Most files were modified around February 2001, but the CHR was a year
newer (March 2002) to make the font more legible.  The title screen
was modified on 2003-11-01, presumably to remove confusing references
to an unfinished 2-player mode, and there also appears to be a PIF
(shortcut to a DOS program) for x816 from 2003-10-26.  Difficulties
in getting MS-DOS programs to cooperate with NT-based Windows XP
may have contributed to my switch to ca65 during that month, with
`sound-drivers/5` being the first nontrivial project on the new
toolchain.  The date of `hello-world-ca65` agrees with this.

One change has been made:  Waiting for vertical blank uses the more
reliable method of busy-waiting for a change in retrace count.

## Raw PCM Hello

Demonstrates sound quality difference between hardware DPCM playback
and raw 4-bit PCM.  The pulse width test is broken due to limits of
available emulators in January 2001.

## Sprite 0 test

An interactive test to verify that the sprite 0 hit flag gets set
only when an opaque pixel of sprite 0 overlaps an opaque background
pixel.  Many emulators circa June 2000 (NESticle, REW, NESten) got
this wrong, setting the flag on any opaque pixel of sprite 0
regardless of the background; LoopyNES got it right.

One change has been made:  Waiting for vertical blank uses the more
reliable method of busy-waiting for a change in retrace count.
