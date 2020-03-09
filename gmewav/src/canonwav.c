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

#include "canonwav.h"

/* This is a template for a Canonical WAVE header.
   Byte values that must be replaced are at offsets
    4(u32): size of wave data + 36
   22 (u8): number of channels
   24(u32): sample rate in Hz
   28(u32): avg bytes per second = sample rate * bytes per frame
   32 (u8): bytes per frame = (bits per sample + 7) / 8 * channels
   34 (u8): bits per sample
   40(u32): number of bytes (must be even)

   8-bit samples are unsigned: 128 center, 0 to 255 range
   16-bit samples are signed and little endian: 0 center,
   -32768 to 32767 range

   Documentation at http://www.lightlink.com/tjweber/StripWav/WAVE.html
 */

#define CANONWAV_SIZE 44

static const unsigned char canonwav_header[CANONWAV_SIZE] = {
  'R','I','F','F',  0,  0,  0,  0,'W','A','V','E','f','m','t',' ',
   16,  0,  0,  0,  1,  0,  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,'d','a','t','a',  0,  0,  0,  0
};

static void pokei32(unsigned char *dest, unsigned long src)
{
  for (int i = 0; i < 4; ++i) {
    *dest++ = src;
    src >>= 8;
  }
}

/**
 * Creates a wave file.
 */
WAVEWRITER *wavewriter_open(const char *filename) {
  WAVEWRITER *self = calloc(sizeof(WAVEWRITER), 1);
  if (!self) return NULL;

  self->fp = fopen(filename, "wb+");
  if (!self->fp) {
    free(self);
    return NULL;
  }

  if (!fwrite(canonwav_header, sizeof(canonwav_header), 1, self->fp)) {
    fclose(self->fp);
    free(self);
    return NULL;
  }

  self->data_size = 0;
  self->sample_rate = 44100;
  self->num_channels = 1;
  self->depth = 16;
  return self;
}

void wavewriter_setrate(WAVEWRITER *self, uint32_t rate) {
  self->sample_rate = rate;
}

void wavewriter_setchannels(WAVEWRITER *self, size_t ch) {
  uint8_t casted_ch = ch;
  if (ch == casted_ch && ch != 0) {
    self->num_channels = casted_ch;
  }
}

void wavewriter_setdepth(WAVEWRITER *self, size_t depth) {
  if (depth == 8 || depth == 16) {
    self->depth = depth;
  }
}

size_t wavewriter_write(const short data[], size_t size, WAVEWRITER *self) {
  size_t num_written = 0;

  if (self->depth == 8) {
    while (num_written < size) {
      unsigned int d = ((unsigned int)data[num_written] & 0xFFFFU) ^ 0x8000U;
      unsigned char c = (d < 0xFF00) ? (d + 0x80) >> 8 : 0xFF;

      if (fputc(c, self->fp) == EOF) break;
      num_written += 1;
    }
    self->data_size += num_written;
  } else {
    while (num_written < size) {
      unsigned int d = (unsigned int)data[num_written] & 0xFFFFU;
      unsigned char c[] = {d & 0xFF, d >> 8};

      if (!fwrite(c, sizeof(c), 1, self->fp)) break;
      num_written += 1;
    }
    self->data_size += num_written * 2;
  }
  return num_written;
}

void wavewriter_close(WAVEWRITER *self) {
  if (!self) return;

  fflush(self->fp);
  rewind(self->fp);
  
  // Fill in the header
  unsigned char header[sizeof(canonwav_header)];
  size_t bytes_per_frame = (self->depth + 7) / 8 * self->num_channels;

  memcpy(header, canonwav_header, sizeof(header));
  pokei32(header + 4, self->data_size + 36);
  header[22] = self->num_channels;
  pokei32(header + 24, self->sample_rate);
  pokei32(header + 28, self->sample_rate * bytes_per_frame);
  header[32] = bytes_per_frame;
  header[34] = self->depth;
  pokei32(header + 40, self->data_size);
  
  fwrite(header, sizeof(header), 1, self->fp);
  fclose(self->fp);
  free(self);
}

