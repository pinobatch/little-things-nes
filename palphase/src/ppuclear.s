;
; NES PPU common functions
; Copyright 2011 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;
.include "nes.inc"
.export ppu_clear_oam, ppu_screen_on
.import OAM

;;
; Moves all sprites starting at address X (e.g, $04, $08, ..., $FC)
; below the visible area.
; X is 0 at the end.
.proc ppu_clear_oam

  ; First round the address down to a multiple of 4 so that it won't
  ; freeze should the address get corrupted.
  txa
  and #%11111100
  tax
  lda #$FF  ; Any Y value from $EF through $FF will work
loop:
  sta OAM,x
  inx
  inx
  inx
  inx
  bne loop
  rts
.endproc

;;
; Sets the scroll position and turns PPU rendering on.
; @param A value for PPUCTRL ($2000) including scroll position
; MSBs; see nes.h
; @param X horizontal scroll position (0-255)
; @param Y vertical scroll position (0-239)
; @param C if true, sprites will be visible
.proc ppu_screen_on
  stx PPUSCROLL
  sty PPUSCROLL
  sta PPUCTRL
  lda #BG_ON
  bcc :+
  lda #BG_ON|OBJ_ON
:
  sta PPUMASK
  rts
.endproc

