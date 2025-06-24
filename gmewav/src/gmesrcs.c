/*

Audio source abstraction for gmewav

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

#include "gmesrcs.h"
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

static char dumb_inited = 0;

// Game_Music_Emu adapter ///////////////////////////////////////////

static void Reader_gme_destroy(Reader *self) {
  gme_delete(self->src.gme_src);
  self->destroy = NULL;
}

/**
 * Starting a track in GME renders the first few milliseconds into a
 * buffer private to GME. Muting or unmuting doesn't take effect
 * until the end of this buffer. So if rendering after having both
 * restarted and changed a mute setting, restart the track and
 * play it without silence detection.
 */
enum {
  GME_QUIRK_RESTARTED = 1,
  GME_QUIRK_MUTE_CHANGED = 2
};

static const char *Reader_gme_start(Reader *self, int track) {
  self->_state1 = GME_QUIRK_RESTARTED;
  self->cur_track = track;
  return gme_start_track(self->src.gme_src, track);
}

static int Reader_gme_ended(Reader *self) {
  return gme_track_ended(self->src.gme_src);
}

static const char *Reader_gme_render(Reader *self, size_t length, short samples[]) {
  if ((self->_state1 & (GME_QUIRK_RESTARTED | GME_QUIRK_MUTE_CHANGED))
      == (GME_QUIRK_RESTARTED | GME_QUIRK_MUTE_CHANGED)) {
    gme_ignore_silence(self->src.gme_src, 1);
    gme_start_track(self->src.gme_src, self->cur_track);
  }
  self->_state1 = 0;
  return gme_play(self->src.gme_src, length, samples);
}

static size_t Reader_gme_count_voices(Reader *self) {
  int count = gme_voice_count(self->src.gme_src);
  return count > 0 ? count : 0;
}

static void Reader_gme_set_muted(Reader *self, size_t voice, _Bool mute_state) {
  self->_state1 |= GME_QUIRK_MUTE_CHANGED;
  gme_mute_voice(self->src.gme_src, voice, mute_state);
}

const char *Reader_gme(Reader *self,
                       const char *filename, unsigned long sample_rate) {
  Music_Emu *gme_src;
  const char *err = gme_open_file(filename, &gme_src, sample_rate);
  if (err) return err;
  self->destroy = Reader_gme_destroy;
  self->start = Reader_gme_start;
  self->ended = Reader_gme_ended;
  self->render = Reader_gme_render;
  self->count_voices = Reader_gme_count_voices;
  self->set_muted = Reader_gme_set_muted;
  self->src.gme_src = gme_src;
  return err;
}

// DUMB adapter /////////////////////////////////////////////////////
// dynamic universal music bibliotheque by Ben Davis, dumb.sf.net
// (new projects should probably use libopenmpt instead)

static void Reader_dumb_destroy(Reader *self) {
  if (self->sig.dumb_sig) {
    duh_end_sigrenderer(self->sig.dumb_sig);
    self->sig.dumb_sig = NULL;
  }
  unload_duh(self->src.dumb_src);
  self->src.dumb_src = NULL;
  self->destroy = NULL;
}

static int Reader_return_false(Reader *self) {
  (void)self;
  return 0;
}

static int Reader_return_true(Reader *self) {
  (void)self;
  return 1;
}

static const char *Reader_dumb_start(Reader *self, int track) {
  if (self->sig.dumb_sig) {
    duh_end_sigrenderer(self->sig.dumb_sig);
    self->sig.dumb_sig = NULL;
  }

  unsigned int channels = 2;
  DUH_SIGRENDERER *dumb_sig =
    duh_start_sigrenderer(self->src.dumb_src, 0, channels, 0);
  if (!dumb_sig) return "no dumb_sig";
  self->sig.dumb_sig = dumb_sig;
  self->ended = Reader_return_false;
  (void)track;  // TODO: seek to a position
  return NULL;
}

static const char *Reader_dumb_render(Reader *self, size_t length, short samples[]) {
  float volume = 1.0;
  float sample_period = 65536.0 / self->r8;
  long actual_frames = duh_render(
    self->sig.dumb_sig, 16, 0, volume, sample_period, length / 2, samples
  );
  size_t actual_samples = actual_frames * 2;
  
  if (actual_samples < length) {
    self->ended = Reader_return_true;
    for (; actual_samples < length; ++actual_samples) {
      samples[actual_samples] = 0;
    }
  }
  return NULL;
}

static size_t Reader_dumb_count_voices(Reader *self) {
  (void)self;
  return DUMB_IT_N_CHANNELS;
}

static void Reader_dumb_set_muted(Reader *self, size_t voice, _Bool mute_state) {
  DUMB_IT_SIGRENDERER *itsr = duh_get_it_sigrenderer(self->sig.dumb_sig);
  if (!itsr) {
    fputs("no itsr\n", stderr);
    return;
  }
  dumb_it_sr_set_channel_muted(itsr, voice, mute_state);
}

typedef DUH *(*DUHLOADER)(const char *);

const char *Reader_dumb(Reader *self, DUHLOADER dumb_load,
                        const char *filename, unsigned long sample_rate) {
  if (!dumb_inited) {
    atexit(&dumb_exit);
    dumb_register_stdfiles();
    dumb_inited = 1;
  }

  DUH *dumb_src = dumb_load(filename);
  if (!dumb_src) return "failed to load s3m";
  self->destroy = Reader_dumb_destroy;
  self->start = Reader_dumb_start;
  self->ended = Reader_return_true;
  self->render = Reader_dumb_render;
  self->src.dumb_src = dumb_src;
  self->sig.dumb_sig = NULL;
  self->count_voices = Reader_dumb_count_voices;
  self->set_muted = Reader_dumb_set_muted;
  self->r8 = sample_rate;
  return NULL;
}

const char *Reader_dumb_it(Reader *self,
                            const char *filename, unsigned long sample_rate) {
  return Reader_dumb(self, dumb_load_it_quick, filename, sample_rate);
}

const char *Reader_dumb_xm(Reader *self,
                            const char *filename, unsigned long sample_rate) {
  return Reader_dumb(self, dumb_load_xm_quick, filename, sample_rate);
}

const char *Reader_dumb_s3m(Reader *self,
                            const char *filename, unsigned long sample_rate) {
  return Reader_dumb(self, dumb_load_s3m_quick, filename, sample_rate);
}

// As of June 2025, Debian and Ubuntu ship DUMB 0.9.3, the last
// version by original maintainer Ben Davis.  sylvie (aka zlago)
// reports that Arch Linux ships DUMB fork version 2.0.3 by kode54,
// which adds a way to restrict misdetection of 31-sample MOD files.
// This is a breaking API change.
// https://github.com/kode54/dumb/commit/4e1db2adb05e53c50fe38102676889c22a4f2e66
static DUH *dumb_load_mod_quick_norestrict(const char *filename) {
  #if DUMB_MAJOR_VERSION > 0
    return dumb_load_mod_quick(filename, 0);
  #else
    return dumb_load_mod_quick(filename);
  #endif
}

const char *Reader_dumb_mod(Reader *self,
                            const char *filename, unsigned long sample_rate) {
  return Reader_dumb(self, dumb_load_mod_quick_norestrict,
                     filename, sample_rate);
}

// File extension detection /////////////////////////////////////////

/**
 * Lowercase strncpy, transforming 'A' through 'Z' into 'a' through
 * 'z' and stopping after length bytes or after the first zero byte,
 * whatever comes first.
 *
 * As with strncpy, if length bytes are seen without a zero byte,
 * the string is not terminated.  Set dst[length - 1] to zero before
 * calling and test it to see if it's terminated.
 * @param dst where to store
 * @param src where to get the characters
 * @param length number of characters
 * @return dst
 */
char *strnlwr(char *dst, const char *src, size_t length) {
  char *return_value = dst;

  for (; length > 0; --length) {
    *dst++ = tolower((unsigned char)*src);
    if (!*src) return return_value;
    ++src;
  }
  return return_value;
}

typedef struct ReaderEntry {
  const char *extension;
  const char *(*loader)(Reader *self,
                        const char *filename, unsigned long sample_rate);
} ReaderEntry;

const ReaderEntry Reader_formats[] = {
  {"vgm", Reader_gme},
  {"gym", Reader_gme},
  {"spc", Reader_gme},
  {"sap", Reader_gme},
  {"nsf", Reader_gme},
  {"nsfe", Reader_gme},
  {"ay", Reader_gme},
  {"gbs", Reader_gme},
  {"hes", Reader_gme},
  {"kss", Reader_gme},
  {"it", Reader_dumb_it},
  {"xm", Reader_dumb_xm},
  {"s3m", Reader_dumb_s3m},
  {"mod", Reader_dumb_mod},
};

/**
 * Detects the extension of a filename and calls the appropriate
 * loader for that extension.
 */
const char *Reader_init(Reader *self,
                        const char *filename, unsigned long sample_rate) {
  const char *dotext = strrchr(filename, '.');
  char ext[8] = {0};
  if (!dotext) return "no extension";
  if (strlen(dotext) > 8) return "extension too long";
  strnlwr(ext, dotext+1, sizeof(ext) - 1);

  for (size_t i = 0;
       i < sizeof(Reader_formats) / sizeof(Reader_formats[0]);
       ++i) {
    if (!strcmp(Reader_formats[i].extension, ext)) {
      return Reader_formats[i].loader(self, filename, sample_rate);
    }
  }
  return "unknown extension";
}


// Mute and solo ////////////////////////////////////////////////////

/**
 * Advances a pointer past space characters.
 */
static const char *ltrim_const(const char *str) {
  while(*str && isspace(*str)) {
    ++str;
  }
  return str;
}

/**
 * Parses a string consisting of inclusive ranges of integers 1-64
 * into a bitmask. For example, "1,3,6-8" becomes 0xE5.
 * @param str 
 * @param out if not null and successful, the output is written here
 * @return NULL for success or a string
 */
const char *VoiceSet_fromstring(const char *restrict str, VoiceSet *restrict out) {
  int range_start = -1;
  VoiceSet voices = 0;
  
  while (*str) {
    char *str_end = NULL;

    // strtoul() applies negation with unsigned integer wraparound
    // if the number begins with a minus sign.  Disallow because
    // it'd confuse users.
    str = ltrim_const(str);
    if (!isdigit(*str)) {
      return "range start/end must be digit";
    }
    unsigned long range_end = strtoul(str, &str_end, 10);
    str = ltrim_const(str_end);
    
    // Channel numbers are 1-based
    if (range_end < 1 || range_end > 64) {
      return "voice numbers must be 1-64";
    }
    range_end -= 1;
    
    // The character after an integer can be a hyphen, comma, or
    // nul-terminator.  A hyphen is disallowed if already in a range.
    if (*str == '-') {
      if (range_start >= 0) {
        return "range may contain only one hyphen";
      }
      range_start = range_end;
      ++str;
      continue;
    }

    // This is the end of a range
    if (*str != ',' && *str != 0) {
      return "character other than comma after range";
    }
    if (*str) ++str;

    // Set the bits in this range
    if (range_start < 0 || (unsigned long)range_start == range_end) {
      voices |= 1ULL << range_end;
      
    } else {
      unsigned long range_start_u = range_start;
      if (range_start_u > range_end) {
        range_start_u = range_end;
        range_end = range_start;
      }
      VoiceSet mask_start = 1ULL << range_start_u;
      VoiceSet mask_end = (range_end == 63) ? 0 : 2ULL << range_end;
      voices |= mask_end - mask_start;
    }
  }
  if (out) *out = voices;
  return NULL;
}

void Reader_mutemany(Reader *self, VoiceSet voices, _Bool mute_state) {
  size_t num_voices = self->count_voices(self);

  for (size_t voice = 0; 
       voices != 0 && voice < num_voices;
       ++voice) {
    if ((1 & voices) != 0) {
      self->set_muted(self, voice, mute_state);
    }
    voices >>= 1;
  }
}
