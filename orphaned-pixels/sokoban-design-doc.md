# Wrecking Ball Boy design doc

I have recovered a design document from 2001 for what became
_Wrecking Ball Boy_.

## Concept brainstorming

My game's hero cannot jump, fly, or move and shoot at the same time.
But he's still begging to be put in my side-scroller.

thulcander says:

> Solve puzzles, shoot things, navigate flotation pads, throw
> switches to make other things work, collect text clues, little
> rocket powered disks, anti-gravity wells,

kalandir says:

> Power it with a storyline and mission based levels.

## Moves

_Sokoban_, that game where you push boxes onto the dots from an
overhead-ish view, was released as _Boxxle_ in some territories.

But what if it were side view?  I thought about that in mid-2001 and
came up with this move set:

    8 = you
    N = crate
    * = crate or solid

I. Move sideways with head clearance

    ..     ..
    8.     .8
    ** <-> **

II. Gravity acts automatically

    8         .
    . auto -> 8

    N         .
    . auto -> N

III. Push or pull crate
     ..      ..
    8N. <-> .8N

IV. Climb

     .      .
    ..     .8
    8* <-> .*

V. Lift crate

    ...    ..N
    8N* -> .8*

VI. Lower crate

      .      .
    ..N    ...
    .8* -> 8N*

VII. Lift crate from below

     ..      ..
    .8.     .N8
    N** <-> .**

_Wrecking Ball Boy_ ended up implementing I-IV but not V-VII,
which I had forgotten.  However, the way it implemented III ended up
behaving almost as an eighth move:

III. Pull crate across gap

    ...     ...
    8N. <-> 8.N
