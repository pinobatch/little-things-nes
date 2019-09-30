;
; Eighty: an NES Four Score test program
; Copyright 2012 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.global OAM, copybuf
.global ppu_clear_nt, ppu_clear_oam, ppu_screen_on
.global read_fourscore
.globalzp cur_keys, new_keys, nmis
.global draw_droid, play_droid
.globalzp oam_used
.global title_screen
