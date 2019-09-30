#include <limits.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

extern char eight_bit_chars[CHAR_BIT == 8 ? 1 : -1];

void encodePassword(unsigned char *restrict pw, 
                    const unsigned char *restrict data) {
  unsigned char a = data[0], b = data[1], c = data[2], d = data[3], e = 42;
  unsigned int i;
//  printf("Initial, %02x %02x %02x %02x %02x\n",
//         a, b, c, d, e);
  for (i = 16; i > 0; --i) {
    a ^= (b << 2) - (c >> 3) + 40;
    b += (c << 2) ^ (d >> 3) ^ 80;
    c ^= (d << 2) - (e >> 3) + 150;
    d += (e << 2) ^ (a >> 3) ^ 160;
    e ^= (a << 2) - (b >> 3) + 230;
//    printf("After round %d, %02x %02x %02x %02x %02x\n",
//           17 - i, a, b, c, d, e);
  }
  for (i = 0; i < 8; ++i) {
    unsigned int byte = a & 1;
    a >>= 1;
    byte = (byte << 1) | (b & 1);
    b >>= 1;
    byte = (byte << 1) | (c & 1);
    c >>= 1;
    byte = (byte << 1) | (d & 1);
    d >>= 1;
    byte = (byte << 1) | (e & 1);
    e >>= 1;
    pw[i] = byte;
  }
}

bool decodePassword(unsigned char *restrict data,
                    const unsigned char *restrict pw) {
  unsigned char a = 0, b = 0, c = 0, d = 0, e = 0;
  unsigned int i;
  for (i = 7; i < 8; --i) {  // this is C's equivalent of a bpl loop
    unsigned int byte = pw[i];
    e = (e << 1) | ((byte >> 0) & 1);
    d = (d << 1) | ((byte >> 1) & 1);
    c = (c << 1) | ((byte >> 2) & 1);
    b = (b << 1) | ((byte >> 3) & 1);
    a = (a << 1) | ((byte >> 4) & 1);
  }
  for (i = 16; i > 0; --i) {
//    printf("Before round %d, %02x %02x %02x %02x %02x\n",
//           i, a, b, c, d, e);
    e ^= (a << 2) - (b >> 3) + 230;
    d -= (e << 2) ^ (a >> 3) ^ 160;
    c ^= (d << 2) - (e >> 3) + 150;
    b -= (c << 2) ^ (d >> 3) ^ 80;
    a ^= (b << 2) - (c >> 3) + 40;
  }
//  printf("Final, %02x %02x %02x %02x %02x\n",
//         a, b, c, d, e);
  if (e != 42) return false;
  data[0] = a;
  data[1] = b;
  data[2] = c;
  data[3] = d;
  return true;
}

void testPasswordRoundTrip(void) {
  unsigned char data[4], pw[8];
  uint32_t ss = 0;
  unsigned int printsLeft = 256;
  do {
    data[0] = ss;
    data[1] = ss >> 8;
    data[2] = ss >> 16;
    data[3] = ss >> 24;
    encodePassword(pw, data);
    data[0] = 0;
    data[1] = 0;
    data[2] = 0;
    data[3] = 0;
    if (!decodePassword(data, pw)
        || data[0] != (ss & 0xFF)
        || data[1] != ((ss >> 8) & 0xFF)
        || data[2] != ((ss >> 16) & 0xFF)
        || data[3] != ((ss >> 24) & 0xFF)) {
      printf("Failure at 0x%8lx", (unsigned long int)ss);
      break;
    }

    ss = ss * 1103515245 + 12345;
    if ((ss & 0xFFFFFF) == 0) {
      printf("%02x\n", --printsLeft);
      fflush(stdout);
    }
  } while (ss != 0);
}

void asciiArmorPassword(unsigned char *password) {
  static const char pwChars[33] =
  "123BCDFG"
  "456HJKLM"
  "789NPQRT"
  "*0#VWXYZ";
  for (int i = 0; i < 8; ++i) {
    unsigned int c = password[i];
    password[i] = (c < 32) ? pwChars[c] : '_';
  }
}

int main(void) {
  //testPasswordRoundTrip();
  srand(time(0));
  for (int i = 0; i < 16; ++i) {
    unsigned char data[4], pw[9] = {0}, outdata[5];
    data[0] = rand() >> 7;
    data[1] = rand() >> 7;
    data[2] = rand() >> 7;
    data[3] = rand() >> 7;
    encodePassword(pw, data);
    if (!decodePassword(outdata, pw)
        || memcmp(outdata, data, 4)) {
      printf("Failure: %02x%02x%02x%02x %02x != %02x%02x%02x%02x 2A\n",
             outdata[0], outdata[1], outdata[2], outdata[3], outdata[4],
             data[0], data[1], data[2], data[3]);
      return EXIT_FAILURE;
    }
    asciiArmorPassword(pw);
    printf("%02x %02x %02x %02x = %s\n",
           data[0], data[1], data[2], data[3], pw);
  }
  return 0;
}

