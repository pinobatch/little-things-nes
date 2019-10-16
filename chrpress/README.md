# CHR compression through pixel RLE

This tile codec from February 2010 operated by applying run length
encoding (RLE) to horizontal runs of pixels within 32x8-pixel or
16x16-pixel units.  It was vaguely inspired by the image codec that
Codemasters used in Bee 52 and other NES games.  It was used for the
menu of the limited-run Midwest Gaming Classic multicart menu and
prototypes of the 2011 NESdev compo menu from before the switch to
Action 53.

It was dropped as of _Who's Cuter_ in favor of PB8 for the same
reason that Genesis games switched from Nemesis compression to
Kosinski and ProPack:  bit-level operation is slow.
