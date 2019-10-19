/**************************************\
* packbits.c                           *
* Compress a nametable or other file   *
* using a codec compatible with        *
* Apple's PackBits RLE codec           *
*                                      ******************************\
* Copyright 2000 Damian Yerrick                                      *
*                                                                    *
* This program is free software; you can redistribute it and/or      *
* modify it under the terms of the GNU General Public License        *
* as published by the Free Software Foundation; either version 2     *
* of the License, or (at your option) any later version.             *
*                                                                    *
* This program is distributed in the hope that it will be useful,    *
* but WITHOUT ANY WARRANTY; without even the implied warranty of     *
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the      *
* GNU General Public License for more details.                       *
*                                                                    *
* You should have received a copy of the GNU General Public License  *
* along with this program; if not, write to                          *
*   Free Software Foundation, Inc., 59 Temple Place - Suite 330,     *
*   Boston, MA  02111-1307, USA.                                     *
* GNU licenses can be viewed online at http://www.gnu.org/copyleft/  *
*                                                                    *
* Visit http://www.pineight.com/ for more information.               *
*                                                                    *
\********************************************************************/

#include <stdio.h>
#include <stdlib.h>

/* fpack() *****************************
   Write PackBits() encoded data to a file.
   buffer, file: as fwrite()
   size: size of source (unpacked) buffer
   returns: number of packed bytes written

   Yes, I have checked this for conformance; I've successfully used
   it to pack the graphics in a MacPaint document.
 */
size_t fpack(const unsigned char *buf, size_t size, FILE *fp)
{
  char b[127];
  unsigned int bdex = 0, i = 0, j = 0, t = 0;

  do {
    /* zero the line index */
    i = 0;

    /* check for a run of at least three bytes */
    while((buf[t + i] == buf[t + i + 1]) &&
          (buf[t + i] == buf[t + i + 2]) &&
          (t + i + 3 < size) && (i < 126))
      i++;

    /* if there's a run... */
    if((i > 0 && bdex > 0) || (bdex >= 127))
    {
      /* if there's a literal string... */
      fputc(bdex - 1, fp);
      j++;
      /* write it to the file. */
      j += fwrite(b, 1, bdex, fp);
      bdex = 0;
    }
    if(i > 0)
    {
      /* and then write the run. */
      i += 2;
      fputc(257 - i, fp);
      fputc(buf[t], fp);
      t += i;
      j += 2;
    }
    else
    {
      b[bdex++] = buf[t++];
    }
  } while(t < size);
  if(bdex)
  {
    /* if there's a literal string... */
    fputc(bdex - 1, fp);
    j++;
    /* write it to the file. */
    j += fwrite(b, 1, bdex, fp);
    bdex = 0;
  }

  return j;
}

int main(int argc, char **argv)
{
  FILE *infile, *outfile;
  unsigned char *buf;
  size_t filelen;

  if(argc < 2)
  {
    fputs("syntax: packbits infile.nam outfile.pkb\n", stderr);
    return 1;
  }

  infile = fopen(argv[1], "rb");
  if(infile == 0)
  {
    fprintf(stderr, "packbits could not open %s for reading\n", argv[1]);
    return 1;
  }
  outfile = fopen(argv[2], "wb");
  if(outfile == 0)
  {
    fprintf(stderr, "packbits could not open %s for writing\n", argv[2]);
    fclose(infile);
    return 1;
  }

//fprintf(stderr, "compressing %s into %s\n", argv[1], argv[2]);

  // get the size of the file
  fseek(infile, 0, SEEK_END);
  filelen = ftell(infile);
  fseek(infile, 0, SEEK_SET);
  printf("reading %lu bytes\n", (unsigned long)filelen);

  buf = malloc(filelen);
  if(buf == 0)
  {
    fprintf(stderr, "packbits could not allocate %lu bytes to hold the file",
            (unsigned long)filelen);
    fclose(infile);
    fclose(outfile);
    return 1;
  }

  fread(buf, 1, filelen, infile);
  fclose(infile);
  /* write length, network byte order */
  fputc((unsigned char)(filelen >>  8), outfile);
  fputc((unsigned char)(filelen      ), outfile);
  /* write file */
  printf("compressed to %lu bytes.\n", (unsigned long)fpack(buf, filelen, outfile));
  free(buf);
  fclose(outfile);
  return 0;
}


