#define ALLEGRO_USE_CONSOLE
#include <allegro.h>
#include <stdio.h>

/*

The format of a frame is as follows:

0 source data pointer lo
1 source data pointer hi
2 number of rows
3 
each row:
1 byte for starting x
1 byte for number of tiles

*/

unsigned char tileData[16384] = {0};
unsigned char tableData[4096];
unsigned short tileOffsets[32];
unsigned short tableOffsets[32];
unsigned int tileDataSize = 0, tableDataSize = 0;


int getLeftExtent(BITMAP *cel, unsigned int y, unsigned int h) {

  // clip!
  if (y >= cel->h ) {
    return cel->w;
  }
  if (h > cel->h - y) {
    h = cel->h - y;
  }

  for (int x = 0; x < cel->w; ++x) {
    for (int ysub = y; ysub < y + h; ++ysub) {
      if (getpixel(cel, x, ysub) != 0) {
        return x;
      }
    }
  }
  return cel->w;
}

int getRightExtent(BITMAP *cel, unsigned int y, unsigned int h) {

  // clip!
  if (y >= cel->h ) {
    return 0;
  }
  if (h > cel->h - y) {
    h = cel->h - y;
  }

  for (int x = cel->w - 1; x > 0; --x) {
    for (int ysub = y; ysub < y + h; ++ysub) {
      if (getpixel(cel, x, ysub) != 0) {
        return x;
      }
    }
  }
  return 0;
}

#define STRETCH_X 8
#define STRETCH_Y 7

#if 0
/**
 * Draws boxes around each tile of a cel.
 * @param w width of each tile
 * @param h width of each tile row
 * @return number of tiles
 */
int illustrateExtents2(BITMAP *cel, int w, int h, int baseX, int baseY) {
  int totalTiles = 0;

  acquire_screen();
  stretch_blit(cel, screen,
               0, 0, cel->w, cel->h,
               baseX, baseY, cel->w * STRETCH_X, cel->h * STRETCH_Y);
  if (h == 0) {
    h = 1;
  }
  for (unsigned int y = 0; y < cel->h; y += h) {
    int lExt = getLeftExtent(cel, y, h);
    int rExt = getRightExtent(cel, y, h);
    if (lExt <= rExt) {
      int nTiles = (rExt - lExt + w) / w;
      int center = (lExt + rExt) / 2;
      if (center - nTiles * w / 2 > 0) {
        lExt = center - nTiles * w / 2;
      }
      rExt = lExt + nTiles * w - 1;
      if (rExt > cel->w - 1) {
        lExt = cel->w - nTiles * w;
        rExt = cel->w - 1;
      }
      for (int x = lExt; x < rExt; x += w) {
        rect(screen,
             baseX + x * STRETCH_X, baseY + y * STRETCH_Y,
             baseX + (x + w) * STRETCH_X - 1, baseY + (y + h) * STRETCH_Y - 1,
             16);
      }
      totalTiles += nTiles;
    }
  }
  release_screen();
  return totalTiles;
}
#endif

/**
 * Encodes an 8x16-pixel NES tile.
 */
void encodeTile(BITMAP *cel, int x, int y, unsigned char *dst) {
  
  for (int ypx = 0; ypx < 16; ++ypx) {
    unsigned int bits0 = 0, bits1 = 0;
    
    for (int xpx = 0; xpx < 8; ++xpx) {
      int c = getpixel(cel, x + xpx, y + ypx);
      bits0 = (bits0 << 1) | (c & 0x01);
      bits1 = (bits1 << 1) | ((c & 0x02) >> 1);
    }
    dst[0] = bits0;
    dst[8] = bits1;
    ++dst;
    if ((ypx & 7) == 7) {
      dst += 8;
    }
  }
}


int wrExtents2(BITMAP *cel, int w, int h) {
  int totalTiles = 0;

  if (h == 0) {
    h = 1;
  }
  for (unsigned int y = 0; y < cel->h; y += h) {
    int lExt = getLeftExtent(cel, y, h);
    int rExt = getRightExtent(cel, y, h);
    if (lExt <= rExt) {
      int nTiles = (rExt - lExt + w) / w;
      int center = (lExt + rExt) / 2;
      if (center - nTiles * w / 2 > 0) {
        lExt = center - nTiles * w / 2;
      }
      rExt = lExt + nTiles * w - 1;
      if (rExt > cel->w - 1) {
        lExt = cel->w - nTiles * w;
        rExt = cel->w - 1;
      }
      for (int x = lExt; x < rExt; x += w) {
        encodeTile(cel, x, y, tileData + tileDataSize);
        tileDataSize += 32;
      }
      tableData[tableDataSize++] = lExt;
      tableData[tableDataSize++] = nTiles;
      totalTiles += nTiles;
    }
  }
  return totalTiles;
}


int main(void) {
  PALETTE pal;
  BITMAP *celData;
  BITMAP *thisCel;

  allegro_init();
  install_timer();
  if (set_gfx_mode(GFX_AUTODETECT_WINDOWED, 480, 480, 0, 0) < 0) {
    allegro_message("no video");
  }
  install_keyboard();
  
  celData = load_bitmap("celData.bmp", pal);
  if (!celData) {
    set_gfx_mode(GFX_TEXT, 0, 0, 0, 0);
    allegro_message("Could not load celData.bmp\n");
  }
  pal[16] = (RGB){63, 0, 0};
  set_palette(pal);
  
  thisCel = create_bitmap(32, 48);
  if (!thisCel) {
    destroy_bitmap(celData);
    set_gfx_mode(GFX_TEXT, 0, 0, 0, 0);
    allegro_message("Could not allocate RAM for new bitmap\n");
  }

  int nCels = 0;
  for (int y = 0; y < celData->h; y += thisCel->h) {
    for (int x = 0; x < celData->w; x += thisCel->w) {
      tileOffsets[nCels] = tileDataSize;
      tableOffsets[nCels] = tableDataSize;
      blit(celData, thisCel, x, y, 0, 0, thisCel->w, thisCel->h);
      wrExtents2(thisCel, 8, 16);
      ++nCels;
    }
  }
  FILE *fp = fopen("sprcelsOut.chr", "wb");
  if (fp) {
    for (int i = 0; i < nCels; ++i) {
      int n = nCels * 4 + tableOffsets[i];
      fputc(n, fp);
      fputc(n >> 8, fp);
    }
    for (int i = 0; i < nCels; ++i) {
      int n = nCels * 4 + tableDataSize + tileOffsets[i];
      fputc(n, fp);
      fputc(n >> 8, fp);
    }
    fwrite(tableData, tableDataSize, 1, fp);
    fwrite(tileData, tileDataSize, 1, fp);
    fclose(fp);
  }

#if 0
  while (!keypressed()) {
    int totalTiles = 0;
    int t = 0;
    for (int y = 0; y < celData->h; y += thisCel->h) {
      for (int x = 0; x < celData->w; x += thisCel->w) {
        vsync();
        blit(celData, thisCel, x, y, 0, 0, thisCel->w, thisCel->h);
        int nTiles = illustrateExtents2(thisCel, 8, 16, 40, 40);
        totalTiles += nTiles;
        textprintf_ex(screen, font, 8, 8, 16, 0,
                      "tiles in this frame: %2d", nTiles);

        ++t;
        {
          int treadmillY = 40 + thisCel->h * STRETCH_Y;
          for (int treadmillX = -t * 40 * STRETCH_X / 12;
               treadmillX < SCREEN_W;
               treadmillX += 40 * STRETCH_X) {
            rectfill(screen,
                     treadmillX, treadmillY,
                     treadmillX + 20 * STRETCH_X - 1, treadmillY + 7,
                     16);
            rectfill(screen,
                     treadmillX + 20 * STRETCH_X, treadmillY,
                     treadmillX + 40 * STRETCH_X - 1, treadmillY + 7,
                     1);
          }
        }
        rest(90);
      }
    }
    textprintf_ex(screen, font, 8, 24, 16, 0,
                  "total tiles: %3d", totalTiles);
  }
  readkey();
#endif
  
  destroy_bitmap(thisCel);
  destroy_bitmap(celData);

  return 0;
} END_OF_MAIN();
