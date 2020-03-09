/*

Minimalist wave file writer for gmewav

Copyright 2017 Damian Yerrick

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
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
3. This notice may not be removed or altered from any source distribution.

*/

#ifndef P8CANONWAV_H
#define P8CANONWAV_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

typedef struct WAVEWRITER {
  FILE *fp;
  uint32_t data_size;
  uint32_t sample_rate;
  uint8_t num_channels, depth;
} WAVEWRITER;

/**
 * Creates a wave file.
 */
WAVEWRITER *wavewriter_open(const char *filename);

/**
 * Sets the playback rate in samples per second.
 */
void wavewriter_setrate(WAVEWRITER *self, uint32_t rate);

/**
 * Sets the number of channels, usually 1 or 2.
 */
void wavewriter_setchannels(WAVEWRITER *self, size_t ch);

/**
 * Sets the bit depth in bits per sample.
 */
void wavewriter_setdepth(WAVEWRITER *self, size_t depth);


/**
 * Writes samples to the file.
 * @return number of samples written
 */
size_t wavewriter_write(const short data[], size_t size, WAVEWRITER *self);

/**
 * Writes a wave file's header and closes it.
 */
void wavewriter_close(WAVEWRITER *self);

#ifdef __cplusplus
}
#endif

#endif
