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

#include "indexedimage.h"
#include "lodepng.h"
#include <stdlib.h>

unsigned IndexedImage_init(IndexedImage *im, unsigned width, unsigned height) {
  unsigned char *pixels = calloc(width, height);
  if (!pixels) return 83;  // Memory exhausted
  im->pixels = pixels;
  im->width = width;
  im->height = height;
  return 0;
}

void IndexedImage_cleanup(IndexedImage *im) {
  free(im->pixels);
  im->pixels = 0;
  free(im->palette);
  im->palette = 0;
}

void IndexedImage_clear(IndexedImage *im, unsigned pixelvalue) {
  memset(im->pixels, pixelvalue, im->width * im->height);
}

void IndexedImage_paste(const IndexedImage *restrict dst,
                        const IndexedImage *restrict src,
                        int x, int y) {
  unsigned char *dstrow = dst->pixels;
  unsigned char *srcrow = src->pixels;
  unsigned int width = dst->width;
  unsigned int height = dst->height;

  // Horizontal clipping
  {
    unsigned int srcw = src->width;
    if (x < 0) {
      // src is partially to the left of dst, but is it
      // entirely off the left side?
      if ((unsigned)-(unsigned)x >= srcw) return;
      // Clip off the left side of src
      srcw += x;
      srcrow -= x;
      x = 0;
    }
    // src is at or to the right of the left of dst, but is it
    // entirely off the right side?
    if ((unsigned)x >= width) return;
    width -= x;
    dstrow += x;
    if (width > srcw) width = srcw;
  }
      
  // Vertical clipping
  {
    unsigned int srch = src->height;
    if (y < 0) {
      // src is partially to the left of dst, but is it
      // entirely off the left side?
      if ((unsigned)-(unsigned)y >= srch) return;
      // Clip off the left side of src
      srch += y;
      srcrow += src->width * (-y);
      y = 0;
    }
    // src is at or to the right of the left of dst, but is it
    // entirely off the right side?
    if ((unsigned)y >= height) return;
    height -= y;
    dstrow += dst->width * y;
    if (height > srch) height = srch;
  }
  
  for (; height > 0;
       --height, srcrow += src->width, dstrow += dst->width) {
    memcpy(dstrow, srcrow, width);
  }
}

/* LodePNG integration *********************************************/

void *memdup(const void *mem, size_t size) { 
   void *out = malloc(size);
   if(out != NULL) memcpy(out, mem, size);
   return out;
}

unsigned IndexedImage_frompng(IndexedImage *im, const char* filename) {
  unsigned error;
  unsigned char *png = 0;
  size_t pngsize;  // file size
  unsigned char *image = 0;
  unsigned width, height;
  LodePNGState state;
  unsigned char *palette = 0;

  // Load the file into memory
  error = lodepng_load_file(&png, &pngsize, filename);
  if (error) {
    free(png);
    return error;
  }

  // Decode the indexed image as is, not converting it
  // to 24-bit RGB or 32-bit RGBA
  lodepng_state_init(&state);
  state.info_raw.colortype = LCT_PALETTE;
  state.info_raw.bitdepth = 8;
  error = lodepng_decode(&image, &width, &height, &state, png, pngsize);
  free(png);

  // At this point:
  // Palette is in state.info_png.color.palette, 4 bytes per color
  // Palette length in colors is in state.info_png.color.palettesize
  // (length in bytes is 4 times this)
  // Make a local copy of the palette
  if (!error) {
    palette = memdup(state.info_png.color.palette,
                     4 * state.info_png.color.palettesize);
    if (state.info_png.color.palettesize > 0 && !palette) {
      error = 83;  // Memory exhausted
    }
  }
  
  if (!error) {
    im->pixels = image;
    im->width = width;
    im->height = height;
    im->palettesize = state.info_png.color.palettesize;
    im->palette = palette;
  }

  lodepng_state_cleanup(&state);
  return error;
}
