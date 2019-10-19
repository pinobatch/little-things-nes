/*
copyright 2004 damian yerrick
*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define NTSC_NES_CLOCK_FREQ (21477270.0 / 12 / 16)
#define PAL_NES_CLOCK_FREQ (21477270.0 / 12 / 16)
#define GB_CLOCK_FREQ (4194304.0 / 2 / 16)
#define MIDI_C0 8.1757989156437

#define CLOCK_FREQ NTSC_NES_CLOCK_FREQ
#define BASE_FREQ (MIDI_C0 * 8)

#define TWELFTH_ROOT_TWO 1.0594630943593

#define N_FREQS 80

int main(void)
{
  double cur_clock = CLOCK_FREQ / BASE_FREQ;
  int freqs[N_FREQS];
  int i;

  for(i = 0; i < N_FREQS; i++)
  {
    freqs[i] = floor(cur_clock - 0.5);
    cur_clock /= TWELFTH_ROOT_TWO;
  }

  fputs(".export tone_freqs_hi, tone_freqs_lo \n\n"
        "tone_freqs_lo:", stdout);
  for (i = 0; i < N_FREQS; i++)
  {
    if (i & 0x07) {
      fputc(',', stdout);
    } else {
      fputs("\n  .byt", stdout);
    }
    fprintf(stdout, " %3d", freqs[i] & 0xff);
  }
  fputs("\n\n"
        "tone_freqs_hi:", stdout);
  for(i = 0; i < N_FREQS; i++)
  {
    if (i & 0x07) {
      fputc(',', stdout);
    } else {
      fputs("\n  .byt", stdout);
    }
    fprintf(stdout, " %3d", (freqs[i] >> 8) & 0xff);
  }
  fputc('\n', stdout);

  return EXIT_SUCCESS;
}

