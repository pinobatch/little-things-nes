/* encodetile.c
   part of bmp2tiles
   Convert an indexed Windows bitmap to console system tiles

Copyright 2005 Damian Yerrick

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

#include "bmp2tiles.h"
#include <stdio.h>
#include <allegro/unicode.h>

/* Descriptions of format origins

If you don't recognize the console, you may have never used
the initials in speech, or it may have been called something
different in your territory

GB (Game Boy aka DMG aka Game Boy Color)
Genesis (aka Sega Mega Drive)
NES (Nintendo Entertainment System aka Famicom)
NGPC (Neo-Geo Pocket Color)
PC (IBM Personal Computer)
PCE (NEC PC Engine aka TurboGrafx-16)
SMS (Sega Master System aka Mark III aka Game Gear)
SNES (Super Nintendo Entertainment System aka Super Famicom)
VB (Nintendo Virtual Boy aka VUE)

The Wonderswan is able to use Genesis or SMS tiles natively.

Lots of games on lots of platforms use PC style 1bpp tiles for
text glyphs, expanding them to the console's native format at
run time.

Several Super NES games use GB tiles for simpler graphics such
as glyphs, and some GBA games use GB or VB tiles.

These formats are not the primary native format associated with
a console:

8bpp
  used in the rot/scale backgrounds (commonly called "mode 7")
  of Super NES and GBA
SNES3
  a 3-bit-per-pixel tile format used in a few Super NES games
  such as Zelda 3 to save space
NHL
  a 3-bit-per-pixel packed format used in at least some EA ice
  hockey games for Sega Genesis.
SNES8
  an 8-bit-per-pixel tile format using four sequential GB planes
  instead of 2, used for e.g. SUper Mario All-Stars title screen.

*/


/* Explanation of tile format descriptions

A tile consists of one or more passes.
A pass describes how one row of pixels is stored, and it consists
  of one or more rowplanes.
A rowplane consists of the following data:
  byte ordering (left to right or right to left),
  pixel ordering within a byte (left to right or right to left),
  lowest bit place encoded, and
  number of bits encoded.

For example, Game Boy looks like this:

pass:
  rowplane:
    bytes LTR  # doesn't matter; only one byte
    pixels LTR
    bit 0
    1 bit per pixel
  rowplane:
    bytes LTR  # doesn't matter; only one byte
    pixels LTR
    bit 1
    1 bit per pixel
*/

#define END_PASS 0x04
#define END_TILE (0x08 | END_PASS)

static const rowplane_t pc_1bpp_tiles[] =
{
  {0, END_TILE, 0, 1}
};

static const rowplane_t nes_tiles[] =
{
  {0, END_PASS, 0, 1},
  {0, END_TILE, 1, 1}
};

static const rowplane_t gb_tiles[] =
{
  {0, 0       , 0, 1},
  {0, END_TILE, 1, 1}
};

/* vb   is packed, in bit order 33221100 77665544
   ngpc is packed, in bit order 44556677 00112233
   it appears some gba programs may use vb tiles
*/
static const rowplane_t vb_tiles[] =
{
  {3, END_TILE, 0, 2}
};

static const rowplane_t ngpc_tiles[] =
{
  {4, END_TILE, 0, 2}
};

static const rowplane_t snes3_tiles[] =
{
  {0, 0       , 0, 1},
  {0, END_PASS, 1, 1},
  {0, END_TILE, 2, 1}
};

static const rowplane_t nhl_tiles[] =
{
  {0, END_TILE, 0, 3}
};

static const rowplane_t snes_tiles[] =
{
  {0, 0       , 0, 1},
  {0, END_PASS, 1, 1},
  {0, 0       , 2, 1},
  {0, END_TILE, 3, 1}
};

static const rowplane_t sms_tiles[] =
{
  {0, 0       , 0, 1},
  {0, 0       , 1, 1},
  {0, 0       , 2, 1},
  {0, END_TILE, 3, 1}
};

static const rowplane_t genesis_tiles[] =
{
  {0, END_TILE, 0, 4}
};

static const rowplane_t gba_tiles[] =
{
  {1, END_TILE, 0, 4}
};

static const rowplane_t snes8_tiles[] =
{
  {0, 0       , 0, 1},
  {0, END_PASS, 1, 1},
  {0, 0       , 2, 1},
  {0, END_PASS, 3, 1},
  {0, 0       , 4, 1},
  {0, END_PASS, 5, 1},
  {0, 0       , 6, 1},
  {0, END_TILE, 7, 1}
};

static const rowplane_t mode7_tiles[] =
{
  {0, END_TILE, 0, 8}
};

const tile_fmt_name_t format_names[] =
{
  {pc_1bpp_tiles, {"1bpp",    "pc"     }},
  {nes_tiles,     {"nes",     ""       }},
  {gb_tiles,      {"gb",      ""       }},
  {vb_tiles,      {"vb",      ""       }},
  {ngpc_tiles,    {"ngpc",    ""       }},
  {snes3_tiles,   {"snes3",   ""       }},
  {nhl_tiles,     {"nhl",     ""       }},
  {snes_tiles,    {"snes",    "pce"    }},
  {sms_tiles,     {"sms",     ""       }},
  {genesis_tiles, {"genesis", ""       }},
  {gba_tiles,     {"gba",     ""       }},
  {snes8_tiles,   {"snes8",   "",      }},
  {mode7_tiles,   {"8bpp",    "mode7"  }},
  {NULL}
};


void encode_rowplane(unsigned char *dst,  /* bit data */
                     const unsigned char src[],  /* packed pixel data */
                     const rowplane_t *fmt)
{
  unsigned int dst_x;
  unsigned int cur_bits = 0;
  unsigned int n_bits = 0;

  for(dst_x = 0; dst_x < 8; dst_x++)
  {
    int src_pixel = src[dst_x ^ fmt->ordering] >> fmt->first_bit;
    src_pixel &= (1 << fmt->n_bits) - 1;
    cur_bits = (cur_bits << fmt->n_bits) | src_pixel;

    n_bits += fmt->n_bits;
    if(n_bits >= 8)
    {
      int next_byte = 0xff & (cur_bits >> (n_bits - 8));
      *dst++ = next_byte;
      n_bits -= 8;
    }
  }
}


void encode_tile(unsigned char *dst,
                 const unsigned char src[],
                 const rowplane_t *fmt)
{
  char tile_done = 0;
  unsigned int y;

  while(!tile_done)
  {
    /* for each pass */
    for(y = 0; y < 8; y++)
    {
      const rowplane_t *row_fmt = fmt;
      char row_done = 0;

      while(!row_done)
      {
        if((row_fmt->direction & END_TILE) == END_TILE)
          tile_done = 1;
        if(row_fmt->direction & END_PASS)
          row_done = 1;
        encode_rowplane(dst, src + 8 * y, row_fmt);
        dst += row_fmt->n_bits;
        row_fmt++;
      }
      if(y == 7)
        fmt = row_fmt;
    }
  }
}


#if 0  /* this turned out to not be used at all */

/* compute_n_pixels() **************
   Computes the number of pixels in a bitmap after rounding width
   and height to an integral multiple of the size of a cel.
*/
unsigned int compute_n_pixels(unsigned int w, unsigned int h,
                              unsigned int cel_w, unsigned int cel_h)
{
  /* guarantee no divide by 0 */
  if(cel_w < 1)
    cel_w = 8;
  if(cel_h < 1)
    cel_h = 8;

  /* round w and h up to a multiple of the cel size */
  if(cel_w > 1)
    w = (w + cel_w - 1) / cel_w * cel_w;
  if(cel_h > 1)
    h = (h + cel_h - 1) / cel_h * cel_h;

  return w * h;
}
#endif


/* compute_bpp() **************
   Computes the number of bits per pixel in a tile of a given format.
*/
unsigned int compute_bpp(const rowplane_t *fmt)
{
  char done = 0;
  int len = 0;

  while(!done)
  {
    if((fmt->direction & END_TILE) == END_TILE)
      done = 1;
    len += fmt->n_bits;
    fmt++;
  }
  return len;
}


const rowplane_t *get_format_from_id(int id)
{
  return (id >= 0) ? format_names[id].format : NULL;
}


int find_format(const char *name)
{
  int fmt_n;

  /* empty string is not found */
  if(name[0] == 0)
    return -1;

  for(fmt_n = 0; format_names[fmt_n].format; fmt_n++)
  {
    if(!ustricmp(name, format_names[fmt_n].name[0]))
      return fmt_n;
    if(!ustricmp(name, format_names[fmt_n].name[1]))
      return fmt_n;
  }
  return -1;
}


void pr_format_names(void)
{
  const tile_fmt_name_t *cur_fmt;
  int need_comma = 0;
  unsigned int till_format_brk = 0;

  for(cur_fmt = format_names; cur_fmt->format; cur_fmt++)
  {
    if(need_comma)
      fputs(", ", stdout);
    else
      need_comma = 1;
    if(till_format_brk == 0)
    {
      fputs("\n                ", stdout);
      till_format_brk = 6;
    }
    till_format_brk--;
    fputs(cur_fmt->name[0], stdout);
  }
}


void pr_formats(void)
{
  const tile_fmt_name_t *cur_fmt;

  for(cur_fmt = format_names; cur_fmt->format; cur_fmt++)
  {
    printf("%s: %u bpp\n",
           cur_fmt->name[0], compute_bpp(cur_fmt->format));
  }
}


int test_find_format(const char *name)
{
  int fmt_n = find_format(name);
  if(fmt_n < 0)
    printf("%s is not found\n", name);
  else
    printf("%s is format %d (%s)\n",
           name, fmt_n, format_names[fmt_n].name[0]);
  return fmt_n;
}

