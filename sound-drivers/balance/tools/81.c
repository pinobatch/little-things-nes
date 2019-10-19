/* begin readwav.h *************************************************/

#ifndef READWAV_H
#define READWAV_H

#include <stdio.h>
#include <stdlib.h>

/* WAVE READING CODE ***********************************************/

typedef struct WAVE_FMT
{
  unsigned short int format;
  unsigned short int channels;
  unsigned int sample_rate;
  unsigned int bytes_sec;
  unsigned short int frame_size;
  unsigned short int bits_sample;
} WAVE_FMT;


typedef struct WAVE_SRC
{
  WAVE_FMT fmt;
  FILE *fp;
  size_t chunk_left;
  int cur_chn;
} WAVE_SRC;
 
int open_wave_src(WAVE_SRC *wav, const char *filename);
int get_next_wav_sample(WAVE_SRC *wav);
void close_wave_src(WAVE_SRC *wav);

#endif


/* begin readwav.c *************************************************/

/* readwav.c
   RIFF Wave file parser

Copyright 2003 Damian Yerrick

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

*/
//#include "readwav.h"
#include <string.h>


unsigned int fgetu16(FILE *fp)
{
  unsigned char a = fgetc(fp);
  unsigned char b = fgetc(fp);

  return a | (b << 8);
}

unsigned long fgetu32(FILE *fp)
{
  unsigned char a = fgetc(fp);
  unsigned char b = fgetc(fp);
  unsigned char c = fgetc(fp);
  unsigned char d = fgetc(fp);

  return a | (b << 8) | (c << 16) | (d << 24);
}


/* get_fmt() ***************************
   Reads a format chunk from a wav file.
   Returns 0 for success or negative for failure.
*/
int get_fmt(WAVE_FMT *format, FILE *fp)
{
  unsigned int fmt_len = fgetu32(fp);

  if(fmt_len < 16)
    return -3;

  format->format = fgetu16(fp);
  format->channels = fgetu16(fp);
  format->sample_rate = fgetu32(fp);
  format->bytes_sec = fgetu32(fp);
  format->frame_size = fgetu16(fp);
  format->bits_sample = fgetu16(fp);

  fseek(fp, fmt_len - 16, SEEK_CUR);
  return 0;
}


void close_wave_src(WAVE_SRC *wav)
{
  fclose(wav->fp);
  wav->fp = 0;
}

/* open_wave_src() *********************
   Opens a RIFF WAVE (.wav) file for reading through
   get_next_wav_sample().  Returns the following error codes:
     -1  could not open; details are in errno
     -2  bad signature
     -3  bad format metadata or no format metadata before sample data
     -4  no sample data
*/
int open_wave_src(WAVE_SRC *wav, const char *filename)
{
  char buf[256];
  int got_fmt = 0;

  /* open the file */
  wav->fp = fopen(filename, "rb");
  if(!wav->fp)
    return -1;

  /* read the header */
  if(fread(buf, 1, 12, wav->fp) < 12)
  {
    close_wave_src(wav);
    return -2;
  }

  /* check for RIFF/WAVE signature */
  if(memcmp("RIFF", buf, 4) || memcmp("WAVE", buf + 8, 4))
  {
    close_wave_src(wav);
    return -2;
  }

  /* parse chunks */
  while(fread(buf, 4, 1, wav->fp))
  {
    if(!memcmp("fmt ", buf, 4))
    {
      int errc = get_fmt(&(wav->fmt), wav->fp);
      if(errc < 0)
      {
        close_wave_src(wav);
        return -3;
      }
      got_fmt = 1;
    }
    else if(!memcmp("data", buf, 4))
    {
      if(!got_fmt)
      {
        close_wave_src(wav);
        return -3;
      }

      wav->chunk_left = fgetu32(wav->fp);
      if(wav->chunk_left == 0)
      {
        close_wave_src(wav);
        return -4;
      }

      /* at this point, we have success */
      wav->cur_chn = 0;
      return 0;
    }
    else /* skip unrecognized chunk type */
    {
      unsigned long chunk_size = fgetu32(wav->fp);

      fseek(wav->fp, chunk_size, SEEK_CUR);
    }
  }
  /* we've come to the end of all the chunks and found no data */
  close_wave_src(wav);
  return -4;
}


/* get_next_wav_sample() ***************
   Get the next sample from a wav file.
*/
int get_next_wav_sample(WAVE_SRC *wav)
{
  int cur_sample = 0;
  int i;

  if(wav->chunk_left == 0)
    return 0;

  for(i = 0; i < wav->fmt.bits_sample && wav->chunk_left > 0; i += 8)
  {
    int c = fgetc(wav->fp);

    cur_sample >>= 8;
    cur_sample |= (c & 0xff) << 8;
    wav->chunk_left--;
  }

  if(wav->fmt.bits_sample <= 8) /* handle unsigned samples */
    cur_sample -= 32768;
  cur_sample = (signed short)cur_sample; /* sign-extend */

  if(++wav->cur_chn >= wav->fmt.channels)
    wav->cur_chn = 0;

  return cur_sample;
}





/* begin 81.c ******************************************************/


/* 81.c
   encode DPCM

Copyright 2003 Damian Yerrick

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

*/

/* Explanation

This program compresses 8-bit .wav samples into the 1-bit
delta modulation format that the Famicom and NES use to store
sampled sound.  While compressing, it scales the volume to a
more NES-friendly range and oversamples the sound.  Tip: set
oversampling to 414% for 8 kHz samples or 300% for 11 kHz samples.
Play them back on the NES at speed $F (33 KHz).  It'll use 4 KB
per second, but it's worth it for speech, especially when you're
using a mapper such as MMC3 that can map the $C000 region.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
//#include "readwav.h"


/* WAV OUTPUT STUFF ************************************************/

typedef struct WAVOUT_SPECS
{
  unsigned long len;  /* in samples per channel */
  unsigned long sample_rate;  /* in Hz */
  unsigned char sample_width;  /* in bytes per sample, usually 1 or 2 */
  unsigned char channels;
} WAVOUT_SPECS;

const unsigned char canonical_wav_header[44] =
{
  'R','I','F','F',  0,  0,  0,  0,'W','A','V','E','f','m','t',' ',
   16,  0,  0,  0,  1,  0,  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,'d','a','t','a',  0,  0,  0,  0
};

void fill_32(unsigned char *dest, unsigned long src)
{
  int i;

  for(i = 0; i < 4; i++)
    {
      *dest++ = src;
      src >>= 8;
    }
}

void wavout_make_header(unsigned char *header, const WAVOUT_SPECS *data)
{
  memcpy(header, canonical_wav_header, 44);

  header[22] = data->channels;
  header[32] = data->sample_width * header[22];
  fill_32(header + 24, data->sample_rate);
  fill_32(header + 28, header[32] * data->sample_rate);
  header[34] = 8 * data->sample_width;
  fill_32(header + 4, data->len * header[32] + 36);
  fill_32(header + 40, data->len * header[32]);
}


/* NOISE SHAPED DITHERING *************************/



int main(int argc, char **argv)
{
  WAVE_SRC wav;
  FILE *outfp, *codefp;
  int maxinamp = 24;
  int subsample = 99, oversampling = 100;
  long filelen;
  int y = 0, x = 0;


  if(argc < 3)
  {
    fputs("81 by Damian Yerrick: compresses pcm wav file to 8ad\n"
          "usage: 81 infile outfile [upsample_pct [amplitude]]\n"
          "example: 81 song.wav song.dmc 100 24\n", stderr);
    return EXIT_FAILURE;
  }

  if(argc > 3)
  {
    oversampling = atoi(argv[3]);
    if(oversampling < 100)
      oversampling = 100;
    if(oversampling > 1000)
      oversampling = 1000;
  }

  if(argc > 4)
  {
    maxinamp = atoi(argv[4]);
    if(maxinamp < 2)
      maxinamp = 2;
    if(maxinamp > 40)
      maxinamp = 40;
  }

  printf("oversample: %d; amplitude: %d\n", oversampling, maxinamp);


  if(open_wave_src(&wav, argv[1]) < 0)
  {
    fputs("couldn't open wave file\n", stderr);
    return EXIT_FAILURE;
  }

  if(wav.fmt.channels != 1)
  {
    fputs("wave file isn't mono\n", stderr);
    close_wave_src(&wav);
    return EXIT_FAILURE;
  }

  codefp = fopen(argv[2], "wb");
  if(!codefp)
  {
    fputs("couldn't write to dmc file\n", stderr);
    perror(argv[2]);
    close_wave_src(&wav);
    return EXIT_FAILURE;
  }

  outfp = fopen("decomp.wav", "wb");
  if(!outfp)
  {
    fputs("couldn't write to output wave file\n", stderr);
    close_wave_src(&wav);
    fclose(codefp);
    return EXIT_FAILURE;
  }

  {
    WAVOUT_SPECS specs;
    unsigned char header[44];

    specs.len = wav.chunk_left / wav.fmt.frame_size * oversampling / 100;
    specs.sample_rate = wav.fmt.sample_rate * oversampling / 100;
    specs.sample_width = 1;
    specs.channels = 1;

    wavout_make_header(header, &specs);
    fwrite(header, 1, sizeof(header), outfp);
  }

  while(wav.chunk_left > 0)
  {
    int i;
    unsigned char code = 0;

    for(i = 0; i < 8; i++)
    {
      /* read sample */
      while(subsample < 100)
      {
        x = (get_next_wav_sample(&wav) * maxinamp + 16384) >> 15;
        filelen--;
        subsample += oversampling;
      }
      subsample -= 100;

      if(x >= y)
      {
        y++;
        if(y > 31)
          y = 31;
        code |= 1 << i;
      }
      else
      {
        y--;
        if(y < -32)
          y = -32;
      }

      fputc(y * 4 + 128, outfp);
    }
    fputc(code, codefp);
  }
  fclose(outfp);
  fclose(codefp);
  close_wave_src(&wav);

  return 0;
}
