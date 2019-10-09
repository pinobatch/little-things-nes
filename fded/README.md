# fded/cout

Off and on, I have a game concept in my head titled _Fairydust_,
a vaguely _Contra_-style run-and-gun where the various player
characters can fly/float in different ways.  This was made in June
2007, intended as a PC-based level editor for that game (hence the
name `fded`, short for "Fairydust Editor"), which could generate a
compressed output (hence `cout`) for inclusion in a ROM.

(And even that's a pun, as in the Apple II Monitor ROM, the
routine `COUT` for "character output" appears at address $FDED.)

Builds with Allegro 4 and ca65.

Caution: If you edit `tiles.bmp`, make sure to export without
color space information, or Allegro 4 won't be able to load it.
