/* bmp2tiles.c
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


#define USE_CONSOLE
#include <stdio.h>
#include "bmp2tiles.h"


int convert_bitmap(FILE *dst_fp, BITMAP *src, const rowplane_t *fmt,
                   unsigned int cel_w, unsigned int cel_h)
{
  unsigned int cel_x, cel_y, tile_x, tile_y, px_x, px_y;
  int tile_len = 8 * compute_bpp(fmt);
  unsigned char dst[64];

  for(cel_y = 0; cel_y < src->h; cel_y += cel_h)
  {
    for(cel_x = 0; cel_x < src->w; cel_x += cel_w)
    {
      for(tile_y = 0; tile_y < cel_h; tile_y += 8)
      {
        unsigned int top = cel_y + tile_y;
        unsigned int bottom = top + 8;
        if(bottom > src->h)
          bottom = src->h;
        if(bottom > cel_y + cel_h)
          bottom = cel_y + cel_h;
        if(bottom < top)
          bottom = top;

        for(tile_x = 0; tile_x < cel_w; tile_x += 8)
        {
          unsigned char tile[64] = {0};

          unsigned int left = cel_x + tile_x;
          unsigned int right = left + 8;
          if(right > src->w)
            right = src->w;
          if(right > cel_x + cel_w)
            right = cel_x + cel_w;
          if(right < left)
            right = left;

          for(px_y = 0; px_y < bottom - top; px_y++)
          {
            for(px_x = 0; px_x < right - left; px_x++)
            {
              tile[px_y * 8 + px_x] =
                  src->line[px_y + top][px_x + left];
            }
          }
          encode_tile(dst, tile, fmt);
          fwrite(dst, tile_len, 1, dst_fp);
        }
      }
    }
  }

  return 0;
}



static const char help_1[] =
"Usage: bmp2tiles [options] infile outfile\n"
"Converts infile (an indexed .bmp or .pcx image) to outfile (a binary file\n"
"in a format for use with a game console).\n"
"Optionally segments image into cels before conversion.\n"
"\n"
"Options:\n"
"  -a            Append tile data to outfile (default: overwrite outfile)\n"
"  -b fmt        Convert image to tile format fmt, where fmt is one of";

static const char help_2[] =
"\n"
"                (default: 1bpp)\n"
/*
"  -c first num  Before tile data, write num colors of the image's palette,\n"
"                starting at first, in format specified by -p (default: 0)\n"
"  -g            Brighten colors for the GBA's dark screen (default: don't)\n"
*/
"  -p fmt        "
/*
                 "If number of colors specified with -c > 0, write palette\n"
"                in format fmt, where fmt is one of"
*/
;

static const char help_3[] =
"\n"
/*
"                (default: snes)\n"
*/
"  -W width      Individual cels are width pixels wide (default: 8)\n"
"  -H height     Individual cels are height pixels tall (default: 8)\n"
"\n"
"Report bugs to gba-tools-bugs@pineight.com\n";

void pr_pal_format_names(void)
{
  fputs("This option is reserved for future use.", stdout);
}

void pr_help(void)
{
  fputs(help_1, stdout);
  pr_format_names();  /* print supported tile formats */
  fputs(help_2, stdout);
  pr_pal_format_names();  /* print supported palette formats */
  fputs(help_3, stdout);
}

static const char version_text[] =
"Pin Eight bmp2tiles 0.01\n"
"Copyright (C) 2004 Damian Yerrick\n"
"bmp2tiles comes with NO WARRANTY,\n"
"to the extent permitted by law.\n"
"You may redistribute copies of bmp2tiles\n"
"under the terms of the GNU General Public License.\n"
"For more information about these matters,\n"
"see the files named COPYING.\n";

void pr_version(void)
{
  fputs(version_text, stdout);
}


int perform_conversion(const char *src_name, 
                       const char *dst_name, 
                       const char *dst_mode,
                       int tile_fmt, int cel_w, int cel_h,
                       int pal_fmt, int pal_begin, int pal_n, int gamma)
{
  BITMAP *src;
  FILE *fp;
  PALETTE pal;

  src = load_bitmap(src_name, pal);
  if(!src)
  {
    fprintf(stderr, "bmp2tiles: could not read %s\n", src_name);
    return EXIT_FAILURE;
  }

  fp = fopen(dst_name, dst_mode);
  if(!fp)
  {
    destroy_bitmap(src);
    fprintf(stderr, "bmp2tiles: could not open %s for writing: ", dst_name);
    perror(NULL);
    return EXIT_FAILURE;
  }

  convert_bitmap(fp, src, get_format_from_id(tile_fmt), cel_w, cel_h);
  fclose(fp);
  destroy_bitmap(src);

  return EXIT_SUCCESS;
}


static int testing(void)
{
  fputs("=== --version ===\n", stdout);
  pr_version();
  fputs("=== --help ===\n", stdout);
  pr_help();
  fputs("=== supported tile formats ===\n", stdout);
  pr_formats();
  fputs("=== finding a format ===\n", stdout);
  test_find_format("pce");
  test_find_format("GENESiS");
  test_find_format("butt");
  test_find_format("");

  return perform_conversion("hello.bmp", "hello.chr", "wb", 
                            find_format("snes"),
                            128, 8,
                            0, 0, 0, 0 /* palette unused */);
}


int main(const int argc, const char **argv)
{
  int tile_fmt_id = 0;
  int append = 0;
  int cel_w = 8, cel_h = 8;
  int infile_arg = -1, outfile_arg = -1;
  unsigned int arg;
  int pal_fmt_id = 0;
  int pal_begin = 0;
  int pal_n = 0;
  int do_gamma = 0;

  install_allegro(SYSTEM_NONE, &errno, atexit);

  for(arg = 1; arg < argc; arg++)
  {
    if(argv[arg][0] == '-')
    {
      switch(argv[arg][1])
      {
      case '-':
        if(!ustrcmp(argv[arg] + 2, "help"))
        {
          pr_help();
          return EXIT_SUCCESS;
        }
        else if(!ustrcmp(argv[arg] + 2, "version"))
        {
          pr_version();
          return EXIT_SUCCESS;
        }
        else if(!ustrcmp(argv[arg] + 2, "test"))
        {
          return testing();
        }
        break;
      case 'a':
        append = 1;
        break;
      case 'b':
        ++arg;
        if(arg == argc)
        {
          fputs("bmp2tiles: -W not followed by width\n", stderr);
          return EXIT_FAILURE;
        }
        tile_fmt_id = find_format(argv[arg]);
        if(tile_fmt_id < 0)
        {
          fprintf(stderr, "bmp2tiles: unknown tile format %s\n", argv[arg]);
          return EXIT_FAILURE;
        }
        break;
      case 'W':
        ++arg;
        if(arg == argc)
        {
          fputs("bmp2tiles: -W not followed by width\n", stderr);
          return EXIT_FAILURE;
        }
        cel_w = ustrtol(argv[arg], 0, 0);
        if(cel_w < 1)
        {
          fprintf(stderr, "bmp2tiles: invalid cel width %s\n", argv[arg]);
          return EXIT_FAILURE;
        }
        break;
      case 'H':
        ++arg;
        if(arg == argc)
        {
          fputs("bmp2tiles: -H not followed by height\n", stderr);
          return EXIT_FAILURE;
        }
        cel_h = ustrtol(argv[arg], 0, 0);
        if(cel_h < 1)
        {
          fprintf(stderr, "bmp2tiles: invalid cel height %s\n", argv[arg]);
          return EXIT_FAILURE;
        }
        break;
      }
    }
    else if(infile_arg < 0)
      infile_arg = arg;
    else if(outfile_arg < 0)
      outfile_arg = arg;
    else
    {
      fputs("bmp2tiles: too many file names specified\n", stderr);
      return EXIT_FAILURE;
    }
  }

  if(outfile_arg < 0)
  {
    fputs("bmp2tiles: too few file names specified; try bmp2tiles --help\n", stderr);
    return EXIT_FAILURE;
  }

  return perform_conversion(argv[infile_arg], 
                            argv[outfile_arg],
                            append ? "ab" : "wb",
                            tile_fmt_id, cel_w, cel_h,
                            pal_fmt_id, pal_begin, pal_n, 0);
} END_OF_MAIN();
