/*

FdEd can generate COUT compression, a parallel version of PCX compression.


COUT compression is a run-length encoding designed to be decoded with 12 rows in parallel.

Start with rleCount[0..ht) = all 0
and rleValue[0..ht) = don't care
For each column x in [0..wid):
  For each row y in [0..ht):
    If rleCount[y] == 0:
      inputData = *input++
      If inputData < 193:
        rleValue[y] = inputData
        rleCount[y] = 1
      Else:
        rleCount[y] = inputData - 192
        rleValue[y] = *input++
    Copy rleValue[y] to tile at (x, y)
    --rleCount[y]

*/

#include <allegro.h>
#include <stdio.h>
#include <string.h>


#define MAP_W 256
#define MAP_H 12
#define MT_W 16
#define MT_H 16
#define WND_W 640
#define WND_H 320

unsigned char map[MAP_W][MAP_H];
BITMAP *tiles;

int fgColor, scrollbarPageColor, scrollbarThumbColor;

volatile int wantClose = 0;

void setWantClose(void) {
  wantClose = 1;
}
END_OF_FUNCTION(setWantClose)

void decompressMap(const unsigned char *input) {
  unsigned char rleCount[MAP_H] = {0};
  unsigned char rleValue[MAP_H] = {0};
  for (int x = 0; x < MAP_W; ++x) {
    for (int y = 0; y < MAP_H; ++y) {

      // If we're not in the middle of a run,
      // grab a code from the data stream.
      if (rleCount[y] == 0) {
        unsigned int inputData = *input++;

        if (inputData < 193) {

          // 0-192: Literal single value
          rleValue[y] = inputData;
          rleCount[y] = 1;
        } else {

          // 193-255: Run length followed by run value
          rleCount[y] = inputData - 192;
          rleValue[y] = *input++;
        }
      }

      map[x][y] = rleValue[y];
      --rleCount[y];
    }
  }
}



unsigned int findRunLength(int x, int y) {
  unsigned int val = map[x++][y];
  unsigned int runLength = 1;
  while (x < MAP_W && map[x][y] == val) {
    ++x;
    ++runLength;
  }
  return runLength;
}

size_t compressMap(unsigned char *output) {
  unsigned char *start = output;
  unsigned char rleCount[MAP_H] = {0};

  for (int x = 0; x < MAP_W; ++x) {
    for (int y = 0; y < MAP_H; ++y) {
      if (rleCount[y] == 0) {
        int val = map[x][y];
        unsigned int runLength = findRunLength(x, y);

        if (runLength > 63) {
          runLength = 63;
        }
        if (runLength > 1 || val >= 193) {
          *output++ = runLength + 192;
        }
        rleCount[y] = runLength;
        *output++ = val;
      }
      
      --rleCount[y];
    }
  }
  return output - start;
}


void setInitialMap(void) {
  for (int x = 0; x < MAP_W; ++x) {
    map[x][0] = 11;
    map[x][1] = 11;
    map[x][2] = 11;
    map[x][3] = 11;
    map[x][4] = 11;
    map[x][5] = 11;
    map[x][6] = 1;
    map[x][7] = 1;
    map[x][8] = 1;
    map[x][9] = 1;
    map[x][10] = 2;
    map[x][11] = 6;
  }
}



int loadMap(const char *filename) {
  unsigned char *packData = calloc(MAP_W * MAP_H * 2, 1);
  if (!packData) {
    return -1;
  }
  FILE *fp = fopen(filename, "rb");
  if (!fp) {
    return -1;
  }
  fread(packData, 1, MAP_W * MAP_H * 2, fp);
  fclose(fp);
  decompressMap(packData);
  free(packData);
  return 0;
}


int saveMap(const char *filename) {
  unsigned char *packData = calloc(MAP_W * MAP_H * 2, 1);
  if (!packData) {
    return -1;
  }
  FILE *fp = fopen(filename, "wb");
  if (!fp) {
    return -1;
  }
  size_t sz = compressMap(packData);
  fwrite(packData, sz, 1, fp);
  fclose(fp);
  free(packData);
  return sz;
}



/**
 * Draws columns x to x + width - 1 of the map,
 * shifted to the left by scroll columns.
 */
void drawCols(int x, int width, int scroll) {
  acquire_screen();
  
  // clip to right side of map
  if (width > MAP_W - x) {
    width = MAP_W - x;
  }

  // clip to right side of screen
  if (width > WND_W / MT_W - (x - scroll)) {
    width = WND_W / MT_W - (x - scroll);
  }

  for (;
       width > 0;
       --width, ++x) {
    for (int y = 0; y < MAP_H; ++y) {
      int dstX = (x - scroll) * MT_W;
      int dstY = y * MT_H;
      if (tiles) {
        int c = map[x][y];
        int srcX = (c & 0x0F) * MT_W;
        int srcY = ((c & 0xF0) >> 4) * MT_H;
        blit(tiles, screen, srcX, srcY, dstX, dstY, MT_W, MT_H);
      } else {
        rectfill(screen,
                 dstX, dstY,
                 dstX + (MT_W - 1), dstY + (MT_H - 1),
                 map[x][y]);
      }
    }
  }
  release_screen();
}

void drawScrollbar(int scroll) {
  int rightTile = scroll + WND_W / MT_W;
  int left = scroll * WND_W / MAP_W;
  int right = rightTile * WND_W / MAP_W;
  int top = MAP_H * MT_H;
  int bottom = top + 7;
  
  acquire_screen();

  // draw top border
  hline(screen, 0, top, WND_W - 1, fgColor);
  
  // draw left page area
  if (left > 0) {
    rectfill(screen, 0, top + 1, left - 1, bottom - 1, scrollbarPageColor);
  }
  
  // draw thumb
  rectfill(screen, left, top + 1, right - 1, bottom - 1, scrollbarThumbColor);

  // draw right page area
  if (right < WND_W) {
    rectfill(screen, right, top + 1, WND_W - 1, bottom - 1, scrollbarPageColor);
  }
  
  // draw bottom border
  hline(screen, 0, bottom, WND_W - 1, fgColor);

  // draw 16-tile markers
  for (int x = ((-scroll) & 0x0F) * MT_W;
        x < WND_W;
        x += MT_W * 16) {
    vline(screen, x, top, bottom, fgColor);
  }

  release_screen();
}

void drawHelpText(void) {
  textout_ex(screen, font, "use the mouse to draw blocks in top area", 0, 290, fgColor, -1);
  textout_ex(screen, font, "Home, Left, Right, End: scroll    C: change color", 0, 300, fgColor, -1);
  textout_ex(screen, font, "L: load    S: save    Esc: exit", 0, 310, fgColor, -1);

}


int tilePicker(void) {
  scare_mouse();
  acquire_screen();
  rectfill(screen,
           WND_W - MT_W * 18, 0,
           WND_W - 1, 18 * MT_H - 1,
           fgColor);
  blit(tiles, screen,
       0, 0,
       WND_W - MT_W * 17, MT_H,
       16 * MT_W, 16 * MT_H);
  release_screen();
  unscare_mouse();
  
  int last_mouse_b = ~0;
  int picked = -1;

  while(picked == -1) {
    int m_b = mouse_b;
    int new_mouse_b = m_b & ~last_mouse_b;
    last_mouse_b = m_b;

    if (new_mouse_b & 1) {
      int m_x = mouse_x - (WND_W - MT_W * 17);
      int m_y = mouse_y - MT_H;
      
      if (m_x >= 0 && m_x < MT_W * 16
          && m_y >= 0 && m_y <= MT_H * 16) {
        m_x /= MT_W;
        m_y /= MT_H;
        picked = 16 * m_y + m_x;
      }
    }
    if (keypressed()) {
      readkey();
      picked = -2;
    }    
  }
  
  rectfill(screen,
           WND_W - MT_W * 18, 0,
           WND_W - 1, 18 * MT_H - 1,
           0);
  return picked;
}

void makeColors(void) {
  fgColor = makecol(255, 255, 255);
  scrollbarPageColor = makecol(128, 128, 128);
  scrollbarThumbColor = makecol(128, 191, 255);
}

char openFilePath[512] = "drawing.cout";


int fileOpen(void) {
  int result = file_select_ex("Map to open:",
                              openFilePath,
                              "cout",
                              sizeof(openFilePath),
                              WND_W - 64, WND_H - 32);
  if (result == 0) {
    return -1;
  }
  return loadMap(openFilePath);
}

int fileSave(void) {
  int result = file_select_ex("Save this map as:",
                              openFilePath,
                              "cout",
                              sizeof(openFilePath),
                              WND_W - 64, WND_H - 32);
  if (result == 0) {
    return -1;
  }
  return saveMap(openFilePath);
}

int main(void) {
  if (allegro_init() < 0) {
    return -1;
  }
  install_timer();

  set_color_depth(desktop_color_depth());
  if (set_gfx_mode(GFX_AUTODETECT_WINDOWED, WND_W, WND_H, 0, 0) < 0) {
    allegro_message("could not open the window.\n");
  }
  install_keyboard();
  install_mouse();

  set_color_conversion(COLORCONV_TOTAL);
  tiles = load_bitmap("tiles.bmp", NULL);
  if (!tiles) {
    alert("Could not load \"tiles.bmp\"",
          "Please make a 256 by 16-256 pixel bitmap",
          "containing 16x16 pixel tiles.",
          "OK", 0, 13, 0);
  }

  int penColor = 2;
  int scrolled = 1;
  int scroll = 0;
  show_mouse(screen);
  int done = 0;
  setInitialMap();
  makeColors(); 
  drawHelpText();

  LOCK_FUNCTION(setWantClose);
  set_close_button_callback(setWantClose);

  while (!done) {
    int m_b = mouse_b;
    int m_x = mouse_x;
    int m_y = mouse_y;
    vsync();
    if (scrolled) {
      scare_mouse();
      drawCols(scroll, WND_W / MT_W, scroll);
      drawScrollbar(scroll);
      unscare_mouse();
      scrolled = 0;
    }
    if (keypressed()) {
      int scancode;
      int c = ureadkey(&scancode);
      
      if (c == 'C' || c == 'c') {
        int c = tilePicker();
        if (c >= 0) {
          penColor = c;
        }
        drawHelpText();
        scrolled = 1;
        while (mouse_b & 1) {
          rest(30);
        }
      } else if (c >= '0' && c <= '9') {
        penColor = c - '0';
      } else if (c >= 'A' && c <= 'F') {
        penColor = c - 'A' + 10;
      } else if (c >= 'a' && c <= 'f') {
        penColor = c - 'a' + 10;
      }
      else if (scancode == KEY_ESC) {
        done = 1;
      } else if (scancode == KEY_LEFT) {
        if (scroll > 0) {
          --scroll;
          scrolled = 1;
        }
      } else if (scancode == KEY_RIGHT) {
        if (scroll < MAP_W - WND_W / MT_W) {
          ++scroll;
          scrolled = 1;
        }
      } else if (scancode == KEY_HOME) {
        if (scroll > 0) {
          scroll = 0;
          scrolled = 1;
        }
      } else if (scancode == KEY_END) {
        if (scroll < MAP_W - WND_W / MT_W) {
          scroll = MAP_W - WND_W / MT_W;
          scrolled = 1;
        }
      } else if (c == 'L' || c == 'l') {
        if (fileOpen() >= 0) {
          scroll = 0;
          scrolled = 1;
        } else {
          alert("couldn't load", "", strerror(errno), "OK", 0, 13, 0);
        }
      } else if (c == 'S' || c == 's') {
        int sz = fileSave();
        if (sz >= 0) {
          char line[80];
  
          usprintf(line, "compressed to %d bytes and saved.", sz);
          alert(line, "", "", "OK", 0, 13, 0);
        } else {
          alert("couldn't save", "", strerror(errno), "OK", 0, 13, 0);
        }
      }
    }
    if ((m_b & 1) && (m_y < MAP_H * MT_H)) {
      int x = m_x / MT_W + scroll;
      int y = m_y / MT_H;
      
      if (x < MAP_W) {
        map[x][y] = penColor;
      }
      scare_mouse();
      drawCols(x, 1, scroll);
      unscare_mouse();
    }
    if (wantClose) {
      done = 1;
    }
    rest(5);
  }
  
  destroy_bitmap(tiles);
  return EXIT_SUCCESS;
} END_OF_MAIN();
