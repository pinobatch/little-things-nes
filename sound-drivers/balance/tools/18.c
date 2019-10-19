/* 18.c
   rip sounds from an NES ROM

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

This program decompresses the samples from an NES ROM.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


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


int main(int argc, char **argv)
{
  FILE *outfp, *codefp;
  int y = 0;
  size_t romsz;


  if(argc != 3)
  {
    fputs("18 by Damian Yerrick: rips samples from an NES game\n"
          "usage: 18 infile outfile\n"
          "example: 18 klax.nes klax_samples.wav\n", stderr);
    return EXIT_FAILURE;
  }

  codefp = fopen(argv[1], "rb");
  if(!codefp)
  {
    fputs("couldn't read dmc file\n", stderr);
    perror(argv[2]);
    return EXIT_FAILURE;
  }

  fseek(codefp, 0, SEEK_END);
  romsz = ftell(codefp);
  rewind(codefp);

  outfp = fopen(argv[2], "wb");
  if(!outfp)
  {
    fputs("couldn't write to output wave file\n", stderr);
    fclose(codefp);
    return EXIT_FAILURE;
  }

  {
    WAVOUT_SPECS specs;
    unsigned char header[44];

    specs.len = romsz * 8;
    specs.sample_rate = 16800;
    specs.sample_width = 1;
    specs.channels = 1;

    wavout_make_header(header, &specs);
    fwrite(header, 1, sizeof(header), outfp);
  }

  while(romsz > 0)
  {
    int i;
    unsigned char code = fgetc(codefp);

    for(i = 0; i < 8; i++)
    {
      if(code & (1 << i))
      {
        y++;
        if(y > 31)
          y = 31;
      }
      else
      {
        y--;
        if(y < -32)
          y = -32;
      }

      fputc(y * 4 + 128, outfp);
    }
    romsz--;
  }
  fclose(outfp);
  fclose(codefp);

  return 0;
}
