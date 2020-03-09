gmewav
======

**gmewav** is a program that converts chiptunes and tracker music to
stereo RIFF WAVE (wav) files.  It can read any format supported by
Game_Music_Emu (GME) or Dynamic Universal Music Bibliotheque (DUMB).

Dependencies
------------
Building requires a C compiler, GNU Make, and the header files for
GME and DUMB.  You can install all these on Ubuntu with this command:

    sudo apt install build-essential libdumb1-dev libgme-dev

Installation
------------
From a terminal or Command Prompt:

    make install PREFIX=~/.local

Usage
-----
usage: `gmewav [options] vgmfile wavfile`
    
Options:

* `-h, -?, --help`: show this usage info
* `-t LENGTH`: render `LENGTH` seconds of audio (default: 150.0)
* `-f LENGTH`: fade out the last `LENGTH` seconds (default: 0.0)
* `-m MOVEMENT`: render movement `MOVEMENT` (default: 1)
* `-M VOICES`: mute `VOICES` (e.g. `-M 1,3,6-8`)
* `-S VOICES`: solo: play only `VOICES`

GME supports vgm, gym, spc, sap, nsf, nsfe, ay, gbs, hes, kss.
Not all formats support multiple movements, but nsf does.
If no channels are muted or soloed, and GME detects five seconds of
silence, GME may end the output before the time specified in `-t`.

DUMB supports it, xm, s3m, and mod.  No formats support multiple
movements.

If the output file is `-` (a single hyphen), `gmewav` will instead
write 44100 Hz stereo 16-bit signed native endian audio to standard
output, suitable for piping into a command-line audio output program.
The shell script `scripts/gmeplay.sh` shows an example of how to pipe
into PulseAudio's `paplay`.

Limits
------

* DUMB: Starting from a particular frame in the order table is
  not yet supported.
* DUMB: Changing the interpolation type is not yet supported.
* List of filename extensions routed to GME is hardcoded.  I could
  try loading a file with GME and pass it to other readers, but I
  still need to enumerate extensions for `--help`, and functions
  using `gme_type_t` can list only the console that each format
  represents, not its typical extension.
* List of filename extensions routed to DUMB is hardcoded.  Debian
  and Ubuntu still distribute a version of DUMB from before kode54
  added `dumb_load_any()`.
* Cannot insert tags for title, artist, etc. in output.  Not all
  players can read the same tag chunks, especially those bundled with
  popular operating systems.
* No way to turn off a particular reader at build time.

License
-------

* gmewav: zlib license
* DUMB: zlib license, with several joke clauses that have since been
  revoked
* GME: GNU Lesser General Public License version 2.1 or later
