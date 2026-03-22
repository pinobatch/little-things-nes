/* bmp2tiles.h
   Convert an indexed Windows bitmap to console system tiles

Copyright 2004 Damian Yerrick

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

#ifndef BMP2TILES_H
#define BMP2TILES_H

#include <allegro.h>

typedef struct rowplane_t
{
  unsigned char ordering;  /* xor'd with pixel order */
  unsigned char direction;
  unsigned char first_bit, n_bits;
} rowplane_t;

typedef struct tile_fmt_name_t
{
  const rowplane_t *format;
  char name[2][8];
  /* We used to store the tile's bit depth here until one of us
     pointed out that the bit depth is the sum of all n_bits in
     the rowplane_t. */
} tile_fmt_name_t;

typedef struct pal_fmt_name_t
{
  const unsigned char *format;  /* as a pascal string */
  char name[2][8];
} pal_fmt_name_t;

void encode_tile(unsigned char *dst,
                 const unsigned char src[],
                 const rowplane_t *fmt);
void encode_color(unsigned char *dst, 
                  const RGB *src,  /* an Allegro format rgb color */
                  const unsigned char *fmt,
                  int do_gamma);
unsigned int compute_bpp(const rowplane_t *fmt);
int find_format(const char *name);

int find_pal_format(const char *name);

const rowplane_t *get_format_from_id(int id);
const unsigned char *get_pal_format_from_id(int id);
void pr_format_names(void);
void pr_formats(void);
int test_find_format(const char *name);
void pr_pal_format_names(void);
void pr_pal_formats(void);
int test_find_pal_format(const char *name);

#endif

