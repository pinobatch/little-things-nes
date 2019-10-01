# RGB121

This demo poops rainbows.

The NES can display 2 bits per pixel in a background tile.  This
means only four colors can appear in the same part of the screen.
RGB121 uses persistence of vision to fool the viewer into seeing
up to 16 colors.

1. 1bpp red, 2bpp green, and 1bpp blue
2. Split the image into green and red/blue images
3. Alternate the two images by scanline

Copyright 2012, 2019 Damian Yerrick  
License: zlib
