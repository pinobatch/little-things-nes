;
; Eighty: an NES Four Score test program
; Robot graphic and voice code
; Copyright 2012 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.include "nes.inc"
.include "global.inc"

.segment "CODE"
.proc play_droid
  lda #$0F
  sta $4015
  sta $4010
  lda #$00 ;<(droid_dmc >> 6)
  sta $4012
  lda #$FF
  sta $4013
  lda #$1F
  sta $4015
  rts
.endproc

.proc draw_droid
ycoord = 0
xcoord = 1
sprites_this_row = 2
  ldx oam_used
  ldy #103
  sty ycoord
  ldy #0
rowloop:
  lda droid_map,y
  beq done
  iny
  sta sprites_this_row
  eor #$07
  asl a
  asl a
  adc #100
  sta xcoord
tileloop:
  lda ycoord
  sta OAM,x
  inx
  lda droid_map,y
  and #$3F
  sta OAM,x
  inx
  lda droid_map,y
  iny
  and #$C1
  ora #$01
  sta OAM,x
  inx
  lda xcoord
  sta OAM,x
  inx
  beq done
  clc
  adc #8
  sta xcoord
  dec sprites_this_row
  bne tileloop
  clc
  lda ycoord
  adc #8
  sta ycoord
  jmp rowloop
done:
  stx oam_used
  rts
.endproc

.segment "RODATA"
droid_map:
  .byt 3, $10,$11,$50
  .byt 4, $12,$13,$53,$52
  .byt 5, $14,$15,$16,$55,$54
  .byt 5, $17,$18,$19,$58,$57
  .byt 5, $1A,$1B,$1C,$5B,$5A
  .byt 2, $1D,$5D
  .byt 0


.segment "DMC"
.align 64
droid_dmc: .incbin "obj/nes/droid.dmc"
