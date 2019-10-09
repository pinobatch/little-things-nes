/*
Anti-DiskDude header cleaner

Copyright 2007 Damian Yerrick <nes@pineight.com>

This work is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any
damages arising from the use of this work.

Permission is granted to anyone to use this work for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

 1. The origin of this work must not be misrepresented; you
    must not claim that you wrote the original work. If you use
    this work in a product, an acknowledgment in the product
    documentation would be appreciated but is not required.
 2. Altered source versions must be plainly marked as such,
    and must not be misrepresented as being the original work.
 3. This notice may not be removed or altered from any source
    distribution.

"Source" is the preferred form of a work for making changes to it.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

const char iNESMagic[4] = {'N', 'E', 'S', 0x1A};

/* The offset of the 1st byte in the header that must be zero NOW */
#define FIRST_RESERVED_BYTE 12

/* The offset of the 1st byte in the header that must be zero
   in the ORIGINAL format */
#define FIRST_BYTE_TO_CLEAR 7

/**
 * Removes "DiskDude!" crap from an iNES file.
 * @param filename the name of the iNES file
 * @return positive if fixed;
 *   0 if no fix was needed;
 *   negative if failure, in which case errno is set to one of
 *   EINVAL: No file name was provided.
 *   ENOENT: No such file
 *   EACCES: Could not open file for read/write access
 *   EDOM: File is shorter than an iNES header
 *   EILSEQ: Illegal byte sequence (not an iNES file)
 *   
 */
int correctNESFile(const char *filename) {
  char header[16];
  int i;
  FILE *fp;
  int badHeader = 0;

  if (!filename) {
    errno = EINVAL;
    return -1;
  }

  fp = fopen(filename, "rb+");
  if (!fp) {
    return -1;
  }

  /* Read the header */
  if (fread(header, sizeof(header), 1, fp) < 1) {
    fclose(fp);
    errno = EDOM;
    return -1;
  }

  /* Check for the iNES signature */
  for (i = 0; i < sizeof(iNESMagic); ++i) {
    if (header[i] != iNESMagic[i]) {
      fclose(fp);
      errno = EILSEQ;
      return -1;
    }
  }

  /* Assume that any header with the signature of Kevin Horton's
     NES 2.0 is a good header  */
  if ((header[7] & 0x0C) != 0x08) {
  
    /* Check for nonzero header bytes */
    for (i = FIRST_RESERVED_BYTE; i < sizeof(header); ++i) {
      badHeader |= header[i];
    }
  }

  if (badHeader) {
    for (i = FIRST_BYTE_TO_CLEAR; i < sizeof(header); ++i) {
      header[i] = 0;
    }
    rewind(fp);
    if (fwrite(header, sizeof(header), 1, fp) < 1) {
      fclose(fp);
      errno = EDOM;
      return -1;
    }
  }

  fclose(fp);
  return badHeader;
}

const char helpText[] =
"Removes rename-tool garbage (such as \"DiskDude!\") in one or more iNES files.\n"
"Usage: diskdude [options] file...\n"
"Options:\n"
"  --help            display this information\n"
"  -v, --verbose     print each file's name, followed by OK or fixed\n"
"  --version         display version and copyright information\n"
;

const char versionText[] =
"Anti-DiskDude 0.01 (2007-06-17)\n"
"Copyright 2007 Damian Yerrick\n"
"This program is free software; you may redistribute it under the terms of\n"
"the zlib license.  This program has absolutely no warranty.\n"
;

/**
 * Prints an error message like perror, but overrides EDOM and EINVAL.
 */
void iNES_perror(const char *str) {
  const char *errorMsg;

  /* Get an error message */
  switch (errno) {
  case EDOM:
    errorMsg = "File too small";
    break;
  case EILSEQ:
    errorMsg = "File not in the expected format";
    break;
  default:
    errorMsg = strerror(errno);
    break;
  }

  if (str) {
    fputs(str, stderr);
    fputs(": ", stderr);
  }
  fputs(errorMsg, stderr);
  fputc('\n', stderr);
}

int main(const int argc, const char *const *argv) {
  int arg;
  int lastFileArg = 0;
  int verbose = 0;

  for (arg = 1; arg < argc; ++arg) {
    int result;

    if (!strcmp(argv[arg], "--help")) {
      fputs(helpText, stdout);
      return EXIT_SUCCESS;
    }
    if (!strcmp(argv[arg], "--version")) {
      fputs(versionText, stdout);
      return EXIT_SUCCESS;
    }
    if (!strcmp(argv[arg], "-v") || !strcmp(argv[arg], "--verbose")) {
      verbose = 1;
      continue;
    }

    result = correctNESFile(argv[arg]);
    if (result < 0) {
      fputs("diskdude: could not fix ", stderr);
      iNES_perror(argv[arg]);
      return EXIT_FAILURE;
    } else {
      lastFileArg = arg;
      
      if (verbose) {
        fputs(argv[arg], stdout);
        fputs(result > 0 ? " fixed\n" : " OK\n", stdout);
      }
    }
  }

  /* If no file names were specified, print an error message */
  if (lastFileArg == 0) {
    fputs("diskdude: no input files", stderr);
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
