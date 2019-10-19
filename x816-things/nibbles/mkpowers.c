/*

mkpowers.c
Make data tables for Nibbles for NES

*/

/*

Copyright 2001 Damian Yerrick

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

#include <stdio.h>

#define NES_SOUND_CONSTANT 111830
#define NOTE_C1 65.4064

int main(void)
{
  int freqs[64];
  double period = NES_SOUND_CONSTANT / NOTE_C1;
  int i;
  FILE *fp;

  fp = fopen("nibb_tab.bin", "wb");
  if(!fp)
  {
    fputs("error: could not write to nibb_tab.bin\n", stderr);
    return 1;
  }
  for(i = 0; i < 63; i++)
  {
    freqs[i] = period;
    period /= 1.0594630943593; /* 2^(1/12) */
  }

  /* offset 0: low bytes of note periods */
  for(i = 0; i < 64; i++)
    fputc(freqs[i] & 0xff, fp);

  /* offset 64: high bytes of note periods */
  for(i = 0; i < 64; i++)
    fputc((freqs[i] >> 8) & 0xff, fp);

  /* offset 128: end of file */
  fclose(fp);

  return 0;
  
}
