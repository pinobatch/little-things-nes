Tall Pixel demo

PocketNES is an emulator that runs NES games on Game Boy Advance.
<http://www.pocketnes.org>
It shrinks the screen to match that of the GBA by skipping lines
of the picture.  But it changes which lines it skips every frame
so that lines don't appear to "drop out" of the image.

On December 9, 2009, I had the idea to reverse this process in order
to fit larger photos into the 8 KiB of CHR RAM in UNROM or SNROM.
Instead of skipping different lines, it repeats different lines to
make the picture bigger.  Every 3 lines, it uses mixed $2006/$2005
writes to set the scroll down by 2 lines from the last write,
resulting in a repeat.

The effect works on my NTSC NES + PowerPak, and it should also
work on Dendy-style PAL famiclones that use a clock divider of 15.
But the official PAL NES uses a clock divider of 16, resulting in
319.6875 CPU cycles for each 3 lines instead of 341, and the code
would need to be modified.  The part that waits for a partial cycle
should look like the following, but I have no PAL NES to test it on:

  lda tmp176
  adc #176
  sta tmp176
  bcs here
here:

The image tilesets/ac16.png contains an 8x16 pixel monospace font
based on the style of type used for the titles of the DS games
Animal Crossing: Wild World, Puppy Palace, and Big Brain Academy.

== Legal ==

Copyright (c) 2009 Damian Yerrick <http://www.pineight.com/>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

