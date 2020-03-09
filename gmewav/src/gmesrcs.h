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

#ifndef P8GMESRCS_H
#define P8GMESRCS_H

#include <stdint.h>
#include "gme/gme.h"
#include "dumb.h"

typedef uint64_t VoiceSet;

typedef struct Reader {
  union {
    DUH *dumb_src;
    Music_Emu *gme_src;
  } src;
  union {
    DUH_SIGRENDERER *dumb_sig;
  } sig;
  
  /**
   * Frees resources owned by a Reader.  Calling twice without an
   * intervening Reader_init() has undefined behavior.
   */
  void (*destroy)(struct Reader *self);
  
  /**
   * Starts playing a particular track/movement of a loaded file.
   */
  const char *(*start)(struct Reader *self, int track);
  
  /**
   * Returns nonzero iff the movement has detectably ended.
   */
  int (*ended)(struct Reader *self);
  
  /**
   * Fills a buffer with rendered samples.
   * @param length the number of half frames (individual samples) to generate
   * @param samples the length of the array
   */
  const char *(*render)(struct Reader *self, size_t length, short samples[]);

  /**
   * Counts the voices that the engine is able to mute, if applicable.
   */
  size_t (*count_voices)(struct Reader *self);

  /**
   * Mutes or unmutes a voice.
   * @param voice an index from 0 to count_voices()-1
   * @param mute_state true to mute, false to unmute
   */
  void (*set_muted)(struct Reader *self, size_t voice, _Bool mute_state);

  unsigned long r8;
  size_t cur_track;
  unsigned int _state1;
} Reader;

/**
 * Detects the extension of a filename and loads it into a Reader.
 * 
 * Caller is responsible for calling the destroy method when done.
 * @param self pointer to the Reader
 * @param filename pointer to a filename
 * @param 
 * @return NULL for success or an error string for failure
 */
const char *Reader_init(struct Reader *self,
                        const char *filename, unsigned long sample_rate);

/**
 * Parses a string consisting of inclusive ranges of integers 1-64
 * into a bitmask. For example, "1,3,6-8" becomes 0xE5.
 * @param str 
 * @param out if not null and successful, the output is written here
 * @return NULL for success or a string
 */
const char *VoiceSet_fromstring(const char *restrict str, VoiceSet *restrict out);

/**
 * Mutes one or more channels of a Reader.
 */
void Reader_mutemany(Reader *self, VoiceSet v, _Bool mute_state);

#endif
