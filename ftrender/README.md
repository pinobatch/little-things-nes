ftrender
========
An attempt to render a FamiTracker module's text export as video.
It was created in April 2018, when the Discord chat platform played
video when uploaded as an attachment to a channel and treated an
audio-only file as a download.  It shows the channels roughly as they
would appear in the tracker and renders the result through FFmpeg.

Installation
------------
Because Debian does not package Pygame for Python 3, it must be
installed through pip.

    sudo apt install python3-pip ffmpeg
    sudo -H pip3 install pygame

Choice of library
-----------------
Pygame uses SDL 1.2, not SDL 2.  As of April 2018, there are two
different SDL 2 wrappers for Python: [PySDL2], whose API mirrors that
of SDL 2, and the Ren'Py project's [pygame_sdl2], which attempts to
mirror that of Pygame.  Neither of them can export a surface as a
byte array (`pygame.image.tostring()`), which is needed for feeding
frames to FFmpeg when encoding a run as a video.

[PySDL2 for Pygamers] acknowledges the lack of any counterpart to
`pygame.image.tostring()`.  In addition, its sole official tutorial,
to make a [Pong clone in PySDL2], is built around a strict
component-oriented programming (COP) model that forbids an object
to own more than one object of a given type, as the name of the
field is literally the lowercased type name. This is
[Systems Hungarian] taken to its illogical conclusion.

The `readme.rst` file for pygame_sdl2 also acknowledges the lack
of "APIs that expose pygame data as buffers or arrays."  Just as
worryingly, it omits blitting from indexed images whose palette has
changed at runtime.  The developers of pygame_sdl2 consider surfaces
with fewer than 32 bits per pixel to be "legacy formats" unworthy of
first-class support other than as a source for load-time conversion.
Yet indexed images are needed for rendering text in a bitmap font in
multiple colors without having to duplicate the entire font in memory
once for each color, or for rendering sprites with different colored
uniforms per team or skin color that depends on a character's health.
The developer of the present project would appreciate a different
compatible method to achieve the same effect as palette swapping
using 32-bit textures, especially for environments that cannot use
GLSL pixel shaders, without generating a separate 32bpp texture for
each entry in the indexed image's palette.

[PySDL2]: https://pysdl2.readthedocs.io/en/rel_0_9_6/index.html
[pygame_sdl2]: https://github.com/renpy/pygame_sdl2
[PySDL2 for Pygamers]: https://pysdl2.readthedocs.io/en/rel_0_9_6/tutorial/pygamers.html
[Pong clone in PySDL2]: https://pysdl2.readthedocs.io/en/latest/tutorial/pong.html
[Systems Hungarian]: https://blogs.msdn.microsoft.com/larryosterman/2004/06/22/hugarian-notation-its-my-turn-now/

