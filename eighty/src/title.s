;
; Eighty: an NES Four Score test program
; Title screen code
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
;;
; Displays the text file pointed to at (0)
; starting at (2, 4) on nametable $2000.
; In a call-gated environment, the text data must be in the same
; segment as RODATA0.
.proc display_textfile
src = 0
dstLo = 2
dstHi = 3
  lda #$20
  sta dstHi
  lda #$82
  sta dstLo
txt_rowloop:
  ldy dstHi
  sty PPUADDR
  ldy dstLo
  sty PPUADDR
  ldy #0
txt_charloop:
  lda (src),y
  beq txt_done
  cmp #$0A
  beq is_newline
  sta PPUDATA
  iny
  bne txt_charloop
is_newline:

  sec
  tya
  adc src+0
  sta src+0
  lda src+1
  adc #0
  sta src+1
  lda dstLo
  adc #32
  sta dstLo
  lda dstHi
  adc #0
  sta dstHi
  cmp #$23
  bcc txt_rowloop
  lda dstLo
  cmp #$C0
  bcc txt_rowloop

txt_done:
  rts
.endproc

.proc title_screen
  lda #VBLANK_NMI
  sta PPUCTRL
  lda #$00
  sta PPUMASK
  ldx #$20
  tay
  jsr ppu_clear_nt
  
  jsr read_fourscore
  lda 4
  cmp #$10
  bne not_fourscore
  lda 5
  cmp #$20
  beq is_fourscore
not_fourscore:
  lda #<not_fourscore_msg
  sta 0
  lda #>not_fourscore_msg
  sta 1
  jsr display_textfile
  
  lda #VBLANK_NMI
  ldx #0
  ldy #0
  clc
  jsr ppu_screen_on
:
  jmp :-

is_fourscore:
  lda #<title_screen_msg
  sta 0
  lda #>title_screen_msg
  sta 1
  jsr display_textfile

loop:
  lda nmis
:
  cmp nmis
  beq :-
  
  lda #VBLANK_NMI
  ldx #0
  ldy #0
  clc
  jsr ppu_screen_on
  jsr read_fourscore
  lda new_keys+0
  and #KEY_A|KEY_START
  beq loop
  rts
.endproc

.segment "RODATA"
not_fourscore_msg:
  .byt "PLEASE PLUG IN AN",10
  .byt "NES FOUR SCORE ACCESSORY,",10
  .byt "SWITCH IT TO 4 PLAYER MODE,",10
  .byt "AND PRESS THE RESET BUTTON.",0

title_screen_msg:
  .byt "EIGHTY",10,10
  .byt "A TEST PROGRAM FOR THE",10
  .byt "NES FOUR SCORE ACCESSORY",10,10
  .byt "VERSION 0.01",10
  .byt 13," 2012 DAMIAN YERRICK",10
  .byt "DISTRIBUTE FREELY",10,10
  .byt "PRESS START ON CONTROLLER 1",0
