/*
Indexed image loading and blitting

Copyright (c) 2019 Damian Yerrick

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
*/

#ifndef INDEXEDIMAGE_H
#define INDEXEDIMAGE_H
#include <sys/types.h>

typedef struct IndexedImage {
  unsigned char *pixels;
  unsigned char *palette;
  unsigned int width, height, palettesize;
} IndexedImage;

/**
 * Creates a blank indexed image.
 * im must not already own pixels.
 * If there is an error, im is not modified.  Otherwise, im takes
 * ownership of the image's pixels.
 * Ownership of a palette is not affected.
 * @return a LodePNG error code (0: success; nonzero: failure)
 */
unsigned IndexedImage_init(IndexedImage *im, unsigned width, unsigned height);

/**
 * Frees the pixels and palette that an indexed image owns.
 * Subsequent cleanups are no-ops.
 */
void IndexedImage_cleanup(IndexedImage *im);

/**
 * Sets all pixels in an image to a constant value.
 */
void IndexedImage_clear(IndexedImage *im, unsigned pixelvalue);

/**
 * Pastes as much of src as will fit on dst.
 * May be used to crop or build.
 * dst cannot be src
 * @param x horizontal position on dst corresponding to left side
 * of src, which may be negative
 * @param y vertical position on dst corresponding to top of src,
 * which may be negative
 */
void IndexedImage_paste(const IndexedImage *restrict dst,
                        const IndexedImage *restrict src,
                        int x, int y);

/**
 * Performs a shallow copy of a data object.
 * The object's structure must permit this.  For example, it must
 * not be owned, and it usually should not own other resources.
 */
void *memdup(const void *mem, size_t size);

/**
 * Loads a PNG image from a path in the file system.
 * If there is an error, im is not modified.  Otherwise, im takes
 * ownership of the image's pixels and palette.
 * @return a LodePNG error code
 */
unsigned IndexedImage_frompng(IndexedImage *im, const char* filename);

#endif
