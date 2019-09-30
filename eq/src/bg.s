;
; Background for EQ test
;
; Copyright 2017 Damian Yerrick
; 
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;

.include "nes.inc"
.include "global.inc"
.segment "CODE"
.proc draw_bg
  lda #>introtext
  ldy #<introtext
.endproc

;;
; Clears the screen and write the zero-terminated string at (AAYY),
; which must not exceed 12 lines.
.proc cls_puts_multiline
  pha
  tya
  pha

  lda #VBLANK_NMI
  sta PPUCTRL
  asl a
  sta PPUMASK

  ; Start by clearing the first nametable
  ldx #$20
  lda #$40
  ldy #$00
  jsr ppu_clear_nt

  lda #$20
  sta $03
  lda #$62
  sta $02
  pla
  tay
  pla
  ; fall through to puts_multiline_16
.endproc

;;
; Writes the string at (AAYY) to lines starting at 2 and 3.
; At finish, 0 and 1 points to start of last line, and Y is the
; length of the last line.
.proc puts_multiline_16
srclo = 0
srchi = 1
dstlo = 2
dsthi = 3
  sta srchi
  sty srclo
lineloop:
  lda dsthi
  ldx dstlo
  jsr puts_16
  lda dstlo
  clc
  adc #64
  sta dstlo
  bcc :+
  inc dsthi
:
  lda (srclo),y
  beq done
  tya
  sec
  adc srclo
  sta srclo
  bcc lineloop
  inc srchi
  bcs lineloop
done:
  rts
.endproc

;;
; Writes the string at (0) to the nametable at AAXX.
; Does not write to memory.
.proc puts_16
  sta PPUADDR
  stx PPUADDR
  pha
  txa
  pha
  ldy #0
copyloop1:
  lda (0),y
  cmp #' '
  bcc after_copyloop1
  asl a
  sta PPUDATA
  iny
  bne copyloop1
after_copyloop1:
  
  pla
  clc
  adc #32
  tax
  pla
  adc #0
  sta PPUADDR
  stx PPUADDR
  ldy #0
copyloop2:
  lda (0),y
  cmp #' '
  bcc after_copyloop2
  rol a
  sta PPUDATA
  iny
  bne copyloop2
after_copyloop2:
  rts
.endproc

.rodata

LF=10
COPR=127
introtext:
  .byte "Audio equalization test",LF
  .byte COPR," 2017 Damian Yerrick",LF
  .byte LF
  .byte "left: pink (1/f) noise using",LF
  .byte "  Voss-McCartney algorithm",LF
  .byte "  (hold B to exit)",LF
  .byte "right: sine sweep",LF
  .byte "  (nonlinearity compensated)",0
