/*
http://www.newwaveinstruments.com/resources/articles/m_sequence_linear_feedback_shift_register_lfsr.htm
*/

#include <stdio.h>

unsigned long int seed = 1;
unsigned long int mask;

unsigned long int clockLFRSR(void) {
  unsigned long int carry = seed & 1;
  seed >>= 1;
  if (carry) {
    seed ^= mask;
  }
  return seed;
}

unsigned long int clockLFLSR(void) {
  unsigned long int carry = seed & 0x80000000UL;
  seed <<= 1;
  if (carry) {
    seed ^= mask;
  }
  return seed;
}

unsigned long int period(unsigned long int in_mask) {
  unsigned long int iters = 0;
  seed = 0x80000000;
  mask = in_mask;
  do {
    ++iters;
    if (!(iters & 0xFFFFFF)) {
      fputc('.', stdout);
      fflush(stdout);
    }
  } while (clockLFLSR() != 0x80000000);
  return iters;
}

int main(void) {
  unsigned long int p;
  
  p = period(0x60000000);
  printf("\nperiod [3,2]: %lu\n", p);
  p = period(0x30000000);
  printf("\nperiod [4,3]: %lu\n", p);
  p = period(0x000000C5);
  printf("\nperiod [32,30,26,25] using rshift: %lu\n", p);

  return 0;
}

