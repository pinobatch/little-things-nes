#include <stdio.h>
#include <stdlib.h>
#include <math.h>



#define NTSC_NES

#if   defined( NTSC_NES )
#define COLORCLOCK_RATE 3579545.4545
#define APU_CLOCK_RATE (COLORCLOCK_RATE/2)
#define BASIC_WAVELENGTH (APU_CLOCK_RATE/16)
#define FREQTABLE_XOR 0x0000

#elif defined( GAME_BOY )
#define COLORCLOCK_RATE 4194304.0
#define APU_CLOCK_RATE (COLORCLOCK_RATE/2)
#define BASIC_WAVELENGTH (APU_CLOCK_RATE/16)
#define FREQTABLE_XOR 0x07ff

#endif

#define LOWEST_NOTE     33  /* 33 = midi note for A-2 */
#define FREQTABLE_STEPS 80
#define TUNING_NOTE     69  /* MIDI A-5, A above middle C */
#define TUNING_FREQ    440  /* Hz value for TUNING_NOTE */

unsigned short freqtable[FREQTABLE_STEPS];


int main(void)
{
  unsigned int i;

  for(i = 0; i < FREQTABLE_STEPS; i++)
  {
    signed int rel_note = (i + LOWEST_NOTE) - TUNING_NOTE;
    double freq = pow(2.0, rel_note / 12.0) * TUNING_FREQ;
    double wavelength = BASIC_WAVELENGTH / freq;
/*
    printf("w[%u] = %7.2f Hz = %7.2f period\n", i, freq, wavelength);
*/
    freqtable[i] = (unsigned int)(floor(wavelength - 0.5)) ^ FREQTABLE_XOR;
  }
  
  fputs(".segment \"RODATA\"\n"
        ".global notefreqs_lo, notefreqs_hi\n"
        "notefreqs_lo:", stdout);
  for(i = 0; i < FREQTABLE_STEPS; i++)
  {
    if((i & 15) == 0)
      fputs("\n.byt ", stdout);
    else
      fputs(",", stdout);

    printf("%3d", freqtable[i] & 0xff);
  }
  fputs("\n\nnotefreqs_hi:", stdout);
  for(i = 0; i < FREQTABLE_STEPS; i++)
  {
    if((i & 15) == 0)
      fputs("\n.byt ", stdout);
    else
      fputs(",", stdout);

    printf("%3d", freqtable[i] >> 8);
  }
  fputs("\n\n", stdout);

  return 0;
}
