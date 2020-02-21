/*
Indexed image to CHR data conversion

Copyright (c) 2019 Damian Yerrick

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "indexedimage.h"
#include "lodepng.h"
#include "musl_getopt.h"

/* Command line parsing ********************************************/

#define PROGNAME "pngtochr"
const char usageText[] =
"usage: "PROGNAME" [options] [-i] INFILE [-o] OUTFILE\n"
"\n"
"Options:\n"
"  -h, --help        show this help message and exit\n"
"  --version         show version and credits and exit\n"
"  -i INFILE, --image=INFILE\n"
"                    read image from INFILE\n"
"  -o OUTFILE, --output=OUTFILE\n"
"                    write CHR data to OUTFILE\n"
"  -W HEIGHT, --tile-width=HEIGHT\n"
"                    set width of metatiles\n"
"  -H HEIGHT, --tile-height=HEIGHT\n"
"                    set height of metatiles\n"
"  -p PLANES, --planes=PLANES\n"
"                    set the plane map\n"
"  -1                shortcut for -p 0 (that is, 1bpp)\n"
"  --hflip           horizontally flip all tiles (most significant\n"
"                    pixel on right)\n"
"  -c PALFMT, --palette=PALFMT\n"
"                    write a palette in this format instead of tiles\n"
"                    (-p is ignored)\n"
"  --num-colors=NUM  write this many colors instead of PNG PLTE size\n"
"  --little          reverse bytes in each row-plane or palette entry\n"
"  --add=ADDAMT      value to add to each pixel\n"
"  --add0=ADDAMT0    value to add to pixels of color 0 (if different)\n"
"\n"
"In a plane map:\n"
"- Bits of chunky pixels are consecutive.\n"
"- Comma (,) separates row-interleaved planes.\n"
"- Semicolon (;) separates tile-interleaved planes.\n"
"\n"
"Common plane maps:\n"
"  0                 1 bit per pixel\n"
"  0;1               NES (default)\n"
"  0,1               Game Boy, Super NES 2bpp\n"
"  0,1,2,3           Sega Master System, Game Gear\n"
"  0,1;2             Super NES 3bpp (decoded by some games in software)\n"
"  0,1;2,3           Super NES and TurboGrafx-16 (background) 4bpp\n"
"  0,1;2,3;4,5;6,7   Super NES 8bpp for modes 3 and 4\n"
"  3210              Genesis 4bpp\n"
"  76543210          Super NES mode 7 and Game Boy Advance 8bpp\n"
"  10 --hflip --little\n"
"                    Virtual Boy and GBA 2bpp\n"
"  3210 --hflip --little\n"
"                    GBA 4bpp\n"
"\n"
"In a palette format:\n"
"- 0 and 1 are constant bits.\n"
"- R, G, B are color component bits in most to least significant order.\n"
"\n"
"Common palette formats:\n"
"  00BBGGRR                    SMS\n"
"  0000000GGGRRRBBB --little   TG16\n"
"  0000BBBBGGGGRRRR --little   Game Gear\n"
"  0000BBB0GGG0RRR0            Genesis\n"
"  0BBBBBGGGGGRRRRR --little   Super NES, GBC, GBA, DS\n"
;
// EGA (00rgbRGB) and Neo Geo (0rgbRRRRGGGGBBBB) cannot yet be
// represented in this program

const char versionText[] =
  "pngtochr v0.02wip\n"
  "Copyright 2019 Damian Yerrick\n"
  "Comes with ABSOLUTELY NO WARRANTY.  This is free software and may\n"
  "be redistributed pursuant to the conditions in the documentation.\n"
  "Based on LodePNG by Lode Vandevenne and musl by Rich Felker, et al.\n"
;

const char planemap_nes[] = "0;1";
const char planemap_1bpp[] = "0";

typedef struct Args {
  const char *infilename;
  const char *outfilename;
  const char *planemap;
  const char *palettefmt;
  unsigned int mtwidth;
  unsigned int mtheight;
  unsigned int addamt;
  unsigned int addamt0;
  unsigned int num_colors;
  int hflip, little;
} Args;

/**
 * @return 0 for ok, 1 for error
 */
unsigned parse_argv(Args *args, int argc, char **argv) {
  static const char short_options[] = "i:o:p:c:W:H:1";
  args->infilename = args->outfilename = args->palettefmt = 0;
  args->planemap = planemap_nes;
  args->mtwidth = args->mtheight = 8;
  args->hflip = args->little = args->addamt = args->addamt0 = 0;

  struct musl_option long_options[] = {
    /* These options set an int to a constant value */
    {"hflip",       musl_no_arg,       &args->hflip, 1},
    {"little",      musl_no_arg,       &args->little, 1},
    /* These options don’t set a flag.
       We distinguish them by their indices. */
    {"image",       musl_required_arg, 0, 'i'},
    {"output",      musl_required_arg, 0, 'o'},
    {"planes",      musl_required_arg, 0, 'p'},
    {"palette",     musl_required_arg, 0, 'p'},
    {"num-colors",  musl_required_arg, 0, '#'},
    {"tile-width",  musl_required_arg, 0, 'W'},
    {"tile-height", musl_required_arg, 0, 'H'},
    {"add",         musl_required_arg, 0, '+'},
    {"add0",        musl_required_arg, 0, '/'},
    {0, 0, 0, 0}
  };

  while (1) {
    unsigned long strtoul_result;
    char *strtoul_end;

    int option_index = 0;
    int c = musl_getopt_long(argc, argv, short_options, long_options,
                             &option_index);
    if (c == -1) break;
    switch (c) {
      case 0:
        // if this option set a flag, we're clear
        if (long_options[option_index].flag != 0) break;

        fprintf(stderr, "%s: warning: option --%s",
                argv[0], long_options[option_index].name);
        if (musl_optarg) {
          fprintf(stderr, " with value '%s'\n", musl_optarg);
        }
        fputc('\n', stdout);
        break;
      case 'i':
        if (args->infilename) {
          fprintf(stderr, "%s: too many input files: '%s' '%s'\n",
                  argv[0], args->infilename, musl_optarg);
          return EXIT_FAILURE;
        }
        args->infilename = musl_optarg;
        break;
      case 'o':
        if (args->outfilename) {
          fprintf(stderr, "%s: too many output files: '%s' '%s'\n",
                  argv[0], args->outfilename, musl_optarg);
          return EXIT_FAILURE;
        }
        args->outfilename = musl_optarg;
        break;
      case 'p':
        args->planemap = musl_optarg;
        break;
      case 'c':
        args->palettefmt = musl_optarg;
        break;
      case 'W':
        strtoul_result = strtoul(musl_optarg, &strtoul_end, 0);
        if (strtoul_end == musl_optarg
            || strtoul_result < 1 || strtoul_result > 16384) {
          fprintf(stderr, "%s: invalid tile width '%s'\n", 
                  argv[0], musl_optarg);
          return EXIT_FAILURE;
        }
        args->mtwidth = strtoul_result;
        break;
      case 'H':
        strtoul_result = strtoul(musl_optarg, &strtoul_end, 0);
        if (strtoul_end == musl_optarg
            || strtoul_result < 1 || strtoul_result > 16384) {
          fprintf(stderr, "%s: invalid tile height '%s'\n", 
                  argv[0], musl_optarg);
          return EXIT_FAILURE;
        }
        args->mtheight = strtoul_result;
        break;
      case '#':
        strtoul_result = strtoul(musl_optarg, &strtoul_end, 0);
        if (strtoul_end == musl_optarg
            || strtoul_result < 1 || strtoul_result > 256) {
          fprintf(stderr, "%s: invalid number of colors '%s' (should be 1 to 256)\n", 
                  argv[0], musl_optarg);
          return EXIT_FAILURE;
        }
        args->num_colors = strtoul_result;
        break;
      case '+':
        strtoul_result = strtoul(musl_optarg, &strtoul_end, 0);
        if (strtoul_end == musl_optarg || strtoul_result > 255) {
          fprintf(stderr, "%s: invalid add amount '%s' (should be 0 to 255)\n", 
                  argv[0], musl_optarg);
          return EXIT_FAILURE;
        }
        args->addamt = strtoul_result;
        break;
      case '/':
        strtoul_result = strtoul(musl_optarg, &strtoul_end, 0);
        if (strtoul_end == musl_optarg || strtoul_result > 255) {
          fprintf(stderr, "%s: invalid add amount '%s' (should be 0 to 255)\n", 
                  argv[0], musl_optarg);
          return EXIT_FAILURE;
        }
        args->addamt0 = strtoul_result;
        break;

      case '?':
        // musl_optopt is the character of the unknown short option,
        // or '\0' for an unknown long option.  An error message was
        // already printed for an unknown short option.
        if (musl_optopt == 0) {
          fprintf(stderr, "%s: unknown long option: %s\n",
                  argv[0], argv[musl_optind-1]);
        }
        return EXIT_FAILURE;

      case ':':
        fprintf(stderr, "%s: option requires an argument: %s\n",
                argv[0], argv[musl_optind - 1]);
        return EXIT_FAILURE;

      default:
        fprintf(stderr, "%s: internal error: getopt returned character %02x\n",
                argv[0], c);
        break;
    }
  }
  
  for (; musl_optind < argc; ++musl_optind) {
    if (!args->infilename) {
      args->infilename = argv[musl_optind];
    } else if (!args->outfilename) {
      args->outfilename = argv[musl_optind];
    } else {
      fprintf(stderr, "%s: too many filenames\n", argv[0]);
      return EXIT_FAILURE;
    }
  }

  if (0) {
    printf("Want to convert %s to %s\n"
           "    using planemap %s or palette format %s\n"
           "    hflip = %d, add = %u, add0 = %u, tile width = %u, height = %u,\n"
           "    numcolors = %u, little = %d\n",
           args->infilename, args->outfilename,
           args->planemap, args->palettefmt,
           args->hflip, args->addamt, args->addamt0, args->mtwidth, args->mtheight,
           args->num_colors, args->little);
  }
  return 0;
}

/**
 * A planemap is valid if
 * 1. It contains only the characters in "012345678,;"
 * 2. It contains one to eight digits
 * 3. No ',' or ';' is initial, final, or adjacent to another
 *    ',' or ';'
 * @return 0 if valid, or a pointer to a message if not
 */
const char *validate_planemap(const char *planemap) {
  int lastwasdigit = 0, numdigits = 0;

  for (const char *s = planemap; *s; ++s) {
    int c = *s;
    if (c >= '0' && c <= '8') {
      lastwasdigit = 1;
      numdigits += 1;
      if (numdigits > 8) return "more than 8 bits per pixel";
    } else if (c == ';' || c == ',') {
      if (!lastwasdigit) {
        return numdigits ? "initial separator" : "consecutive separators";
      }
      lastwasdigit = 0;
    } else {
      return "unknown character";
    }
  }
  if (!numdigits) return "no digits";
  if (!lastwasdigit) return "final separator";
  return 0;
}

unsigned planemap_bpp(const char *planemap) {
  unsigned numdigits = 0;

  for (const char *s = planemap; *s; ++s) {
    int c = *s;
    if (c >= '0' && c <= '8') {
      numdigits += 1;
    }
  }
  return numdigits;
}

/**
 * A palette format is valid if
 * 1. It contains only characters in "01RGB"
 * 2. At least one of R, G, or B
 * 3. No more than 8 R, 8 G, 8 B, and 32 characters total
 * The bytes per color is (strlen(palettefmt) + 7)/8
 * @return 0 if valid, or a pointer to a message if not
 */
const char *validate_palettefmt(const char *palettefmt) {
  unsigned int numr = 0, numg = 0, numb = 0, numbits = 0;

  for (const char *s = palettefmt; *s; ++s) {
    switch (*s) {
      case 'R':
        numr += 1;
        if (numr > 8) return "more than 8 red (R) bits";
        numbits += 1;
        break;
      case 'G':
        numg += 1;
        if (numg > 8) return "more than 8 green (G) bits";
        numbits += 1;
        break;
      case 'B':
        numb += 1;
        if (numb > 8) return "more than 8 blue (B) bits";
        // fall through
      case '0':
      case '1':
        numbits += 1;
        break;
      default:
        return "unknown character";
    }
    if (numbits > 32) return "more than 32 bits";
  }
  if (numr == 0 && numg == 0 && numb == 0) return "no color bits";
  return 0;
}

/* IndexedImage debugging ******************************************/

void IndexedImage_dump(const IndexedImage *im) {
  printf("%u by %u pixels\n", im->width, im->height);
  {
    const unsigned char *p = im->pixels;
    for (size_t y = 0; y < im->height; ++y) {
      for (size_t x = 0; x < im->width; ++x) {
        printf("%02x", *p++);
      }
      fputc('\n', stdout);
    }
  }

  if (im->palette) {
    printf("%u colors\n", im->palettesize);
    for (size_t i = 0; i < im->palettesize * 4; i += 4) {
      printf("%3u #%02x%02x%02x\n",
             (unsigned int)(i / 4),
             im->palette[i + 0], im->palette[i + 1], im->palette[i + 2]);
    }
  }
}

/* Image conversion ************************************************/

/**
 * @return a pointer to the end of the buffer
 */
unsigned char *convert_tile(unsigned char *dst,
                            const unsigned char *src,
                            const char *planemap,
                            unsigned hflip, unsigned little) {
  const char *rowmap, *pxmap;

  hflip = hflip ? 7 : 0;
  little = little ? 7 : 0;
  while (1) {
    // Convert each outer plane
    for (unsigned rowstart = 0; rowstart < 64; rowstart += 8) {
      // Convert each row, from the start of the outer plane
      const unsigned char *srcrow = src + rowstart;
      rowmap = planemap;

      while (1) {
        // Convert each inner plane of this row
        unsigned char outbits[8] = {0};
        unsigned out_i = 0, out_bitsleft = 8;

        for (unsigned int x = 0; x < 8; ++x) {
          // Each pixel loops through the bits in the current
          // inner plane
          unsigned pixel = srcrow[x ^ hflip];
          pxmap = rowmap;
          for (;
               *pxmap && *pxmap != ',' && *pxmap != ';';
               ++pxmap) {
            // Read the appropriate bit of this pixel
            unsigned shiftamt = (unsigned)*pxmap - '0';
            if (shiftamt > 8) continue;
            unsigned bit = (pixel >> shiftamt) & 0x01;

            // And write it to the output
            --out_bitsleft;
            outbits[out_i] |= bit << out_bitsleft;
            if (out_bitsleft == 0) {
              out_bitsleft = 8;
              ++out_i;
            }
          }
        }

        // Write out this plane of this row to dst
        if (little) {
          while (out_i > 0) {
            *dst++ = outbits[--out_i];
          }
        } else {
          memcpy(dst, outbits, out_i);
          dst += out_i;
        }

        // At the end of this inner plane.  Are there more?
        if (*pxmap == ',') {
          rowmap = pxmap + 1;
        } else {
          break;
        }
      }
    }
    // After the last inner plane of the last row of the outer plane.
    // If this is the last outer plane, stop.
    if (!*pxmap) return dst;
    planemap = pxmap + 1;
  }
}

/**
 * Adds a constant value to all pixels in an image.
 * @param addamt the amount to add to nonzero pixels
 * @param addamt0 the amount to add to zero pixels
 */
void IndexedImage_addconst(IndexedImage *im,
                           unsigned int addamt, unsigned int addamt0) {
  size_t sz = im->width * im->height;
  for (unsigned char *c = im->pixels; sz > 0; ++c, --sz) {
    unsigned int amt = *c ? addamt : addamt0;
    *c += amt;
  }
}

/* Palette conversion **********************************************/

/**
 * Writes out a palette.
 * @param dst a byte array of at least
 * (strlen(planemap)+7)/8*ncolors bytes
 * @param src a 4*ncolors-byte array with entries in order
 * red, green, blue, unused
 * @return a pointer to the end of the buffer
 */
unsigned char *convert_palette(unsigned char *dst,
                               const unsigned char *src,
                               const char *palettefmt,
                               unsigned ncolors, unsigned little) {

  for (; ncolors > 0; src += 4, ncolors -= 1) {
    uint32_t bits = 0;
    unsigned numr = 0, numg = 0, numb = 0, numbits = 0;

    // Collect bits per the palette format string
    for (const char *s = palettefmt; *s; ++s) {
      bits <<= 1;
      numbits += 1;
      switch (*s) {
        case '1':
          bits |= 1;
          break;
        case 'R':  // Pull one red bit
          if (numr < 8) bits |= (src[0] >> (7 - numr)) & 1;
          numr += 1;
          break;
        case 'G':  // Pull one red bit
          if (numg < 8) bits |= (src[1] >> (7 - numg)) & 1;
          numg += 1;
          break;
        case 'B':  // Pull one red bit
          if (numb < 8) bits |= (src[2] >> (7 - numb)) & 1;
          numb += 1;
          break;
        default:  // treat others as 0
          break;
      }
    }

    // Write the bits to the buffer
    if (little) {
      for (unsigned int b = 0; b < numbits; b += 8) {
        *dst++ = bits >> b;
      }
    } else {
      numbits = (numbits + 7) / 8 * 8;
      for (unsigned int b = (numbits + 7) / 8 * 8; b > 0; b -= 8) {
        *dst++ = bits >> (b - 8);
      }
    }
  }
  return dst;
}


int main(int argc, char **argv) {
  IndexedImage im = {0}, curmetatile = {0}, curtile = {0};
  Args args = {0};
  unsigned int error;
  unsigned char convertedtile[64];
  unsigned int outbpp = 0;
  FILE *outfp = 0;

  // Argument parsing
  if (argc >= 2) {
    if (!strcmp(argv[1], "-h") || !strcmp(argv[1], "-?")
        || !strcmp(argv[1], "--help")) {
      fputs(usageText, stdout);
      return 0;
    }
    if (parse_argv(&args, argc, argv)) {
      return EXIT_FAILURE;
    }
  }
  if (!args.infilename) {
    fprintf(stderr, "%s: no input filename; try %s --help\n",
            argv[0], argv[0]);
    return EXIT_FAILURE;
  }
  if (!args.outfilename) {
    fprintf(stderr, "%s: no output filename; for standard output use -o -\n",
            argv[0]);
    return EXIT_FAILURE;
  }

  if (args.palettefmt) {
    const char *problem = validate_palettefmt(args.palettefmt);
    if (problem) {
      fprintf(stderr, "%s: invalid palette format %s: %s\n",
              argv[0], args.palettefmt, problem);
      return EXIT_FAILURE;
    }
  } else {
    const char *problem = validate_planemap(args.planemap);
    if (problem) {
      fprintf(stderr, "%s: invalid planemap %s: %s\n",
              argv[0], args.planemap, problem);
      return EXIT_FAILURE;
    }
    outbpp = planemap_bpp(args.planemap);
    if (outbpp > 8) {
      fprintf(stderr, "%s: internal error: %s is %u bits per pixel\n",
              argv[0], args.planemap, outbpp);
      return EXIT_FAILURE;
    }
  }

  // Grab memory and files
  error = IndexedImage_frompng(&im, args.infilename);
  if (!error) error = IndexedImage_init(&curmetatile, args.mtwidth, args.mtheight);
  if (!error) error = IndexedImage_init(&curtile, 8, 8);
  if (!error) {
    outfp = (strcmp(args.outfilename, "-")
             ? fopen(args.outfilename, "wb")
             : stdout);
    if (!outfp) error = 79;
  }
  if (error) {
    IndexedImage_cleanup(&curtile);
    IndexedImage_cleanup(&curmetatile);
    IndexedImage_cleanup(&im);
    fprintf(stderr, "%s: LodePNG error %u: %s\n", 
            args.infilename, error, lodepng_error_text(error));
    return EXIT_FAILURE;
  }

  // With all inputs checked and appearing to be consistent, we can
  // solve the problem
  if (args.palettefmt) {
    unsigned int sizeof_entry = (strlen(args.palettefmt) + 7) / 8;
    unsigned int in_ncolors = im.palettesize;
    unsigned int out_ncolors = args.num_colors;
    if (out_ncolors == 0) out_ncolors = in_ncolors;
    unsigned char *outbuf = calloc(out_ncolors, sizeof_entry);
    if (!outbuf) {
      error = 83;
      goto abort_conversion;
    }

    // Don't extract more colors than there are; leave the rest
    // black-filled
    if (in_ncolors > out_ncolors) in_ncolors = out_ncolors;

    // Extract the palette
    convert_palette(outbuf, im.palette, args.palettefmt,
                    in_ncolors, args.little);
    if (!fwrite(outbuf, out_ncolors * sizeof_entry, 1, outfp)) {
      error = 79;
    }
    free(outbuf);
  } else {
    // Extract the pixels
    IndexedImage_addconst(&im, args.addamt, args.addamt0);
    for (unsigned mty = 0; mty < im.height; mty += args.mtheight) {
      for (unsigned mtx = 0; mtx < im.width; mtx += args.mtwidth) {
        IndexedImage_clear(&curmetatile, 0);
        IndexedImage_paste(&curmetatile, &im, -mtx, -mty);

        for (unsigned ty = 0; ty < args.mtheight; ty += 8) {
          for (unsigned tx = 0; tx < args.mtwidth; tx += 8) {
            IndexedImage_clear(&curtile, 0);
            IndexedImage_paste(&curtile, &curmetatile, -tx, -ty);
          
            unsigned char *tileend = convert_tile(
              convertedtile, curtile.pixels,
              args.planemap, args.hflip, args.little
            );
            if (tileend - convertedtile != 8 * outbpp) {
              fprintf(stderr, "internal error: conversion produced %d bytes but %u were expected\n",
                     (int)(tileend - convertedtile), 8 * outbpp);
              error = 255;
              goto abort_conversion;
            }
            if (!fwrite(convertedtile, tileend - convertedtile, 1, outfp)) {
              fprintf(stderr, "%s: fwrite failed\n", args.outfilename);
              error = 79;
              goto abort_conversion;
            }
          }
        }
      }
    }
  }
  if (fflush(outfp)) {
    fprintf(stderr, "%s: fflush failed\n", args.outfilename);
    error = 79;
  }

abort_conversion:
  if (outfp && outfp != stdout) fclose(outfp);
  IndexedImage_cleanup(&curtile);
  IndexedImage_cleanup(&curmetatile);
  IndexedImage_cleanup(&im);
  return error;
}
