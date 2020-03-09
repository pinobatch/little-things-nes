/*

Wave renderer for Game_Music_Emu and Dynamic Universal Music Bibliotheque
Use this before lame or oggenc

Build instructions:

sudo apt install build-essential libdumb1-dev libgme-dev
gcc -std=c99 -Wall -Wextra -O -o gmewav gmewav.c gmesrcs.c canonwav.c -lgme -ldumb

Copyright 2017 Damian Yerrick

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
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
3. This notice may not be removed or altered from any source distribution.

*/

#include "canonwav.h"  // stdio, stdlib, string live here
#include "gmesrcs.h"
#include <limits.h>
#include <stdbool.h>

#define WAVEBUFSIZE 1024  // Must be even

void handle_error( const char* str);

const char usageMsg[] =
"usage: gmewav [options] vgmfile wavfile\n"
"\n"
"options:\n"
"  -h, -?, --help        show this usage info\n"
"  -t LENGTH             render LENGTH seconds of audio (default: 150.0)\n"
"  -f LENGTH             fade out the last LENGTH seconds (default: 0.0)\n"
"  -m MOVEMENT           render movement MOVEMENT (default: 1)\n"
"  -M VOICES             mute VOICES (e.g. -M 1,3,6-8)\n"
"  -S VOICES             solo: play only VOICES\n"
"\n"
"Supported game music formats (Game_Music_Emu):\n"
"vgm, gym, spc, sap, nsf, nsfe, ay, gbs, hes, kss\n"
"Supported module formats (Dynamic Universal Music Bibliotheque):\n"
"it, xm, s3m, mod\n"
"\n"
"wavfile can be - (a hyphen) to write native-endian raw data to stdout:\n"
"  gmewav some.nsf - | paplay --raw --rate=44100 --format=s16ne --channels=2\n"
;

int main(const int argc, const char **argv) {
  const char *filename = NULL;
  const char *outfilename = NULL;
  bool to_stdout = false;
  size_t track = 0;  // Track to convert
  unsigned long sample_rate = 44100;
  double length = 150.0;
  double fade_time = 0.0;
  VoiceSet to_mute = 0, to_solo = 0;

  for (int i = 1; i < argc; ++i) {
    if (argv[i][0] == '-' && argv[i][1] != 0) {
      if (!strcmp(argv[i], "--help")) {
        fputs(usageMsg, stdout);
        return 0;
      }

      // -t1 or -t 1
      int argtype = argv[i][1];
      switch (argtype) {
        case 'h':
        case '?':
          fputs(usageMsg, stdout);
          return 0;

        case 't': {
          const char *argvalue = argv[i][2] ? argv[i] + 2 : argv[++i];
          const char *endptr = NULL;

          double tvalue = strtod(argvalue, (char **)&endptr);
          if (endptr == argvalue || tvalue <= 0) {
            fprintf(stderr, "bad time %s\n", argvalue);
            return EXIT_FAILURE;
          }
          length = tvalue;
        } break;

        case 'f': {
          const char *argvalue = argv[i][2] ? argv[i] + 2 : argv[++i];
          const char *endptr = NULL;

          double tvalue = strtod(argvalue, (char **)&endptr);
          if (endptr == argvalue || tvalue <= 0) {
            fprintf(stderr, "bad fade length %s\n", argvalue);
            return EXIT_FAILURE;
          }
          fade_time = tvalue;
        } break;

        case 'm': {
          const char *argvalue = argv[i][2] ? argv[i] + 2 : argv[++i];
          const char *endptr = NULL;

          unsigned long tvalue = strtoul(argvalue, (char **)&endptr, 10);
          if (endptr == argvalue || tvalue <= 0) {
            fprintf(stderr, "bad movement %s\n", argvalue);
            return EXIT_FAILURE;
          }
          track = tvalue - 1;
        } break;

        case 'M': {
          const char *argvalue = argv[i][2] ? argv[i] + 2 : argv[++i];
          VoiceSet parsed = 0;
          const char *err = VoiceSet_fromstring(argvalue, &parsed);
          if (err) {
            fprintf(stderr, "malformed mute set %s: %s\n", argvalue, err);
            return EXIT_FAILURE;
          }
          to_mute |= parsed;
        } break;

        case 'S': {
          const char *argvalue = argv[i][2] ? argv[i] + 2 : argv[++i];
          VoiceSet parsed = 0;
          const char *err = VoiceSet_fromstring(argvalue, &parsed);
          if (err) {
            fprintf(stderr, "malformed solo set %s: %s\n", argvalue, err);
            return EXIT_FAILURE;
          }
          to_solo |= parsed;
        } break;

        default:
          fprintf(stderr, "gmewav: unknown option -%c\n", argtype);
      }
    } else if (!filename) {
      filename = argv[i];
    } else if (!outfilename) {
      outfilename = argv[i];
      if (strcmp(outfilename, "-") == 0) {
        to_stdout = true;
      }
    } else {
      fprintf(stderr, "gmewav: unknown positional argument %s\n", argv[i]);
      return EXIT_FAILURE;
    }
  }
  
  if (!filename) {
    fputs("gmewav: no input filename; try gmewav --help\n", stderr);
    return EXIT_FAILURE;
  }
  
  if (!outfilename && !to_stdout) {
    fputs("gmewav: no output filename; try gmewav --help\n", stderr);
    return EXIT_FAILURE;
  }
  
  if (fade_time > length) {
    fprintf(stderr, "gmewav: fade time %.2f s exceeds length %.2f s\n",
            fade_time, length);
    return EXIT_FAILURE;
  }

  /* Open audio source */
  Reader src = {0};
  handle_error(Reader_init(&src, filename, sample_rate));

  /* Start track */
  handle_error(src.start(&src, track));

  if (to_solo) to_mute |= ~to_solo;
  Reader_mutemany(&src, to_mute, 1);

  /* Begin writing to wave file or standard output */
  WAVEWRITER *out = NULL;
  if (!to_stdout) {
    out = wavewriter_open(outfilename);
    if (!out) {
      src.destroy(&src);
      handle_error("could not open file for output");
    }
    wavewriter_setrate(out, sample_rate);
    wavewriter_setchannels(out, 2);
    wavewriter_setdepth(out, 16);
  }

  unsigned int nch = 2;
  unsigned long total_samples =
    (unsigned long)(length * sample_rate) * nch;
  unsigned long fade_start_samples =
    (unsigned long)((length - fade_time) * sample_rate) * nch;
  double fade_slope = fade_time ? -1.0 / (fade_time * sample_rate) : 1.0;

  /* Record 10 seconds of track */
  for (unsigned long t = 0;
       t < total_samples && !src.ended(&src);
       ) {

    /* Fill sample buffer */
    short buf[WAVEBUFSIZE];
    size_t buf_size = total_samples - t;
    if (buf_size > WAVEBUFSIZE) buf_size = WAVEBUFSIZE;
    handle_error(src.render(&src, buf_size, buf));

    // Handle fade amount
    if (t + buf_size >= fade_start_samples) {
      unsigned long i = 0;
      double fade_pos = 1.0;
      if (t < fade_start_samples) {
        i = fade_start_samples - t;
        fade_pos = 1.0 - ((fade_start_samples - t) / nch * fade_slope);
      } else {
        fade_pos = 1.0 + ((t - fade_start_samples) / nch * fade_slope);
      }

      for (; i < buf_size; i += 2U) {
        double amt = fade_pos + (i / nch) * fade_slope;
        amt = amt * amt;  // Quadratic fadeout
        for (unsigned long j = i; j < i + nch; ++j) {
          buf[j] *= amt;
        }
      }
    }
    
    /* Write samples to destination */
    if (to_stdout) {
      fwrite(buf, sizeof(buf[0]), buf_size, stdout);
    } else {
      wavewriter_write(buf, buf_size, out);
    }
    t += buf_size;
  }
  
  /* Cleanup */
  if (!to_stdout) {
    wavewriter_close(out);
  }
  src.destroy(&src);
  
  return 0;
}

void handle_error(const char *str) {
  if (str) {
    fprintf(stderr, "Error: %s\n", str);
    exit(EXIT_FAILURE);
  }
}

