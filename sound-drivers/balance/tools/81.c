// 81.c: 8-bit wav compression program
// copyright 2000 Damian Yerrick <d_yerrick@hotmail.com>
//
//   This program is free software; you can redistribute it and/or modify
//   it under the terms of the GNU General Public License as published by
//   the Free Software Foundation; either version 2 of the License, or
//   (at your option) any later version.
//
//   This program is distributed in the hope that it will be useful,
//   but WITHOUT ANY WARRANTY; without even the implied warranty of
//   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//   GNU General Public License for more details.
//
//   You should have received a copy of the GNU General Public License
//   along with this program; if not, read the License online at
//   http://www.gnu.org/copyleft/gpl.html
//
// Anyway, this program compresses 8-bit .wav samples into the 1-bit
// delta modulation format that the Famicom and NES use to store
// sampled sound.  While compressing, it scales the volume to a
// more NES-friendly range and oversamples the sound.  Tip: set
// oversampling to 400% for 8 kHz samples or 300% for 11 kHz samples.
// Play them back on the NES at speed $F (33 KHz).  It'll use 4 KB
// per second, but it's worth it for speech, especially when you're
// using a mapper such as MMC3 that can map the $C000 region.
//
// Compile me with DJGPP, MinGW, or GCC(Linux):
//   gcc -Wall -O3 81.c -o 81.exe
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

// amplitude of the input sample (should not exceed 31)
unsigned int maxinamp = 24;

int main(const int argc, const char **argv)
{
  int dmcpos = maxinamp;
  int dmcbits = 0, dmcshift = 8;
  FILE *infile, *outfile;
  int subsample = 0, oversampling = 0;
  long filelen;
  int k = 128;
  unsigned long i = 0, x = 0;

  if(argc < 4)
  {
    puts("syntax:  81 source.wav dest.dmc 300\n"
         "                  oversampling % ^");
    return 1;
  }

  if(argc > 4)
  {
    maxinamp = atoi(argv[4]);
    if(maxinamp < 2)
      maxinamp = 2;
    if(maxinamp > 30)
      maxinamp = 30;
  }

  oversampling = atoi(argv[3]);
  if(oversampling < 1)
  {
    puts("oversampling factor should be at least 1%");
    return 1;
  }

  infile = fopen(argv[1], "rb");
  if(!infile)
  {
    printf("could not open %s for reading\n"
           "because %s\n", argv[1], strerror(errno));
    return 1;
  }
  outfile = fopen(argv[2], "wb");
  if(!outfile)
  {
    printf("could not open %s for writing\n"
           "because %s\n", argv[2], strerror(errno));
    fclose(infile);
    return 1;
  }
  fseek(infile, 0, SEEK_END);
  filelen = ftell(infile) - 64;
  fseek(infile, 64, SEEK_SET); // skip most of the .wav header
  printf("converting %lu KB\n", filelen / 1024);

  do
  {
    dmcbits /= 2;

    if(k > dmcpos)
    {
      dmcpos++;
      if(dmcpos > 63)
        dmcpos = 63;
      dmcbits |= 0x80;
    }
    else
    {
      dmcpos--;
      if(dmcpos < 0)
        dmcpos = 0;
    }

    dmcshift--;
    if(dmcshift == 0)
    {
      dmcshift = 8;
      fputc(dmcbits, outfile);
      dmcbits = 0;
    }
 
    subsample += 100;
    while(subsample > 0)
    {
      k = fgetc(infile) * maxinamp / 128;
      filelen--;
      subsample -= oversampling;
      i++;
      if(i >= 1024)
      {
        i = 0;
        x++;
        printf("%6lu KB done\r", x);
        fflush(stdout);
      }
    }
  } while(filelen > 0);

  fclose(infile);
  fclose(outfile);
  puts("\ndone.");
  return 0;
}
