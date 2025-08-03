Two-bit clones
==============

This program plays a 2-bit PCM sample through the pulse channels of
the Nintendo Entertainment System's audio circuit in a way that is
audible on an authentic NES and nearly inaudible on a famiclone that
swaps two of the duty cycles.

Background
----------

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
some famiclone chipsets.  So I wanted to build a simple test to let a
nontechnical user tell whether a console's timbres are swapped.

I wrote a routine to play a pulse code modulation (PCM) waveform with
2 bits per sample by setting the pulse channels to a high frequency
(12429 Hz) and translating sample values to volume and timbre values
on the pulse channels every 144 cycles.  This routine can be set to
play a wave in such a way as to make changes to volume either
reinforce or cancel out changes to timbre, depending on whether the
chipset is swapping the timbres or not.

[post by Creepy Kingdom]: https://bsky.app/profile/creepykingdom.bsky.social/post/3lo64o42jhs2d

Using the test
--------------

Load the ROM onto your rewritable cartridge and run it.

