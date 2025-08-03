Two-bit clones
==============

This program lets you quickly test whether a famiclone swaps two of
its pulse duty cycles.  It does this by playing a recorded waveform
through the pulse channels in a way that is audible on an authentic
Nintendo Entertainment System (NES) and nearly silent on a famiclone
that swaps duty cycles or vice versa.

Background
----------

Family Computer (FC), called NES outside Japan, is a video game
console made by Nintendo in the 1980s.  It contains an audio circuit
that generates pulse waves, periodic tones that alternate between a
high level for some fraction of the cycle and a low level for the
rest of the cycle.  The "duty cycle" is the fraction of a pulse
wave's cycle during which the waveform is high.  Typically, the duty
cycle controls the timbre (tonal quality) of pulse waves.

A famiclone is an independently produced video game console designed
for compatibility with software made for the NES.  Several brands of
famiclone have a design flaw that swaps the sense of control flags
that set the pulse channels' duty cycle.

A [post by Creepy Kingdom] on the Bluesky social network service
on May 2, 2025, states:

> Unboxing Haunted Halloween ’86 from #SpiritHalloween Retro game
> drops this fall! 🕹️🎃👻

The post shows a video of unboxing a RetroN famiclone bundled with
the game *Haunted: Halloween '86* by Retrotainment Games.  As the
lead programmer of *HH86*, I'm interested in players hearing what our
composer Thomas Cipollone intended.  In the video, the timbres of the
pulse channels sound swapped compared to an authentic NES: the 25%
pulse wave sounds like a 50% and vice versa.  This error is common in
some famiclone chipsets.  So I sought to build a simple test to let
a novice user, neither highly technical nor musically trained, tell
whether a console's duty cycles are swapped.

I wrote a routine to play a pulse code modulation (PCM) waveform with
2 bits per sample by setting the pulse channels to a high frequency
(12429 Hz) and translating sample values to volume and duty cycle
values on the pulse channels every 144 cycles.  This routine can be
set to play a wave in such a way as to make changes to volume either
reinforce or cancel out changes to duty cycle, depending on whether
the chipset swaps duty cycles or not.

[post by Creepy Kingdom]: https://bsky.app/profile/creepykingdom.bsky.social/post/3lo64o42jhs2d

Using the test
--------------

Load the ROM onto your rewritable cartridge and run it.  Listen for
one of two phrases:

- "This console sounds ... authentic!"
- "This console sounds like a swapped clone."
