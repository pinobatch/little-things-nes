;
; Boot screen pattern loader for Pretendo
; Copyright 2013 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;
; Nintendo and Game Boy are trademarks of Nintendo.  This is a parody
; of the Game Boy boot screen, and NintenDON'T sponsor or endorse it.
;
.include "nes.inc"
.include "global.inc"

; I'll admit the code isn't quite as tight as the GB BIOS, but the
; GB BIOS has the advantage of a constant, fixed-size 48x8 pixel
; bitmap as opposed to assembling it from individual letters.

.segment "RODATA"
; Actually spell "[NIN]Ni'tendo PruWs/"
; This covers all these phrases:
; No entiendo: Spanish for "I don't get it"
; Pretendo: Fictional console in Muppet Babies animated series
; Innuendo: Subtle implication, often negative
; Nintendon't: What Genesis does
; Nesticle: Early NES emulator
; Wintendo: A Mac or Linux user's secondary PC for Windows gaming
; [NIN]tendo: Nine Inch Nails
; Mildendo: Capital of Lilliput

glyphbitmaps:
glyph_nineinchnails:
  .byt $FF,$81,$BD,$89,$91,$BD,$81,$BD,$81,$BD,$91,$89,$BD,$81
glyph_capn:
  .byt $FF,$FF,$06,$18,$60
glyph_capi:
  .byt $FF,$FF,$00
glyph_i:
  .byt $FB,$FB,$00
glyph_apos:
  .byt $05,$03
glyph_t:
  .byt $04,$FE,$FE,$04
glyph_e:
  .byt $70,$F8,$A8,$A8,$B8,$B0,$00
glyph_n:
  .byt $F8,$F8,$10,$08,$F8,$F0,$00
glyph_d:
  .byt $70,$F8,$88,$88,$FF,$FF,$00
glyph_o:
  .byt $70,$F8,$88,$88,$F8,$70,$00,$00,$00
glyph_capp:
  .byt $FF,$FF,$11,$11,$11,$1F,$0E,$00
glyph_r:
  .byt $F8,$F8,$10,$08,$08
glyph_u:
  .byt $78,$F8,$80,$40,$F8,$F8,$00
glyph_capw:
  .byt $1F,$FF,$F0,$3C,$3C,$F0,$FF,$1F
glyph_s:
  .byt $90,$B8,$A8,$A8,$E8,$48
glyph_mslant:
  .byt $1E,$78,$78,$1E
glyph_end:

.macro glyphline aa, bb
  .byt aa-glyphbitmaps, bb-glyphbitmaps
.endmacro

pattern_data:
pattern_test:
  glyphline glyphbitmaps, glyph_end
pattern_nintendo:
  glyphline glyph_capn, glyph_apos  ; Ni
  glyphline glyph_n, glyph_d-1      ; n
  glyphline glyph_t, glyph_o+6      ; tendo
pattern_nintendont:
  glyphline glyph_capn, glyph_apos  ; Ni
  glyphline glyph_n, glyph_d-1      ; n
  glyphline glyph_t, glyph_o+7      ; tendo
  glyphline glyph_n, glyph_d-1      ; n
  glyphline glyph_apos, glyph_e     ; 't
pattern_mildendo:
  glyphline glyph_capn, glyph_capn+2 ; M
  glyphline glyph_mslant, glyph_end ; M
  glyphline glyph_capi, glyph_apos  ; Mi
  glyphline glyph_capi, glyph_i     ; l
  glyphline glyph_d, glyph_o        ; d
  glyphline glyph_e, glyph_o+6      ; endo
pattern_pretendo:
  glyphline glyph_capp, glyph_u     ; Pr
  glyphline glyph_e, glyph_e+6      ; e
  glyphline glyph_t, glyph_o+6      ; tendo
pattern_dontunderstand:
  glyphline glyph_capn, glyph_i     ; N
  glyphline glyph_o, glyph_capp     ; o_
  glyphline glyph_e, glyph_d-1      ; en
  glyphline glyph_t, glyph_e        ; t
  glyphline glyph_i, glyph_apos     ; i
  glyphline glyph_e, glyph_o+6      ; endo
pattern_innuendo:
  glyphline glyph_capi, glyph_i     ; I
  glyphline glyph_n, glyph_d        ; n
  glyphline glyph_n, glyph_d        ; n
  glyphline glyph_u, glyph_capw     ; u
  glyphline glyph_e, glyph_o+6      ; endo
pattern_wintendo:
  glyphline glyph_capw, glyph_s   ; W
  glyphline glyph_i-1, glyph_apos   ; i
  glyphline glyph_n, glyph_d-1      ; n
  glyphline glyph_t, glyph_o+6      ; tendo
pattern_nailstendo:
  glyphline glyph_nineinchnails, glyph_capn+1
  glyphline glyph_t, glyph_o+6      ; tendo
pattern_nesticle:
  glyphline glyph_capn, glyph_i     ; N
  glyphline glyph_e, glyph_n        ; e
  glyphline glyph_s, glyph_mslant   ; s
  glyphline glyph_t, glyph_e        ; t
  glyphline glyph_i, glyph_apos     ; i
  glyphline glyph_o, glyph_o+4      ; c (1/3)
  glyphline glyph_o+2, glyph_o+4    ; c (2/3)
  glyphline glyph_o+6, glyph_o+7    ; c (3/3)
  glyphline glyph_capi, glyph_i     ; l
  glyphline glyph_e, glyph_n-1      ; e
pattern_end:

; Each pattern is stored as a list of extents in the glyph data.
patterns:
  .byt pattern_test-pattern_data
  .byt pattern_nintendo-pattern_data
  .byt pattern_nintendont-pattern_data
  .byt pattern_mildendo-pattern_data
  .byt pattern_pretendo-pattern_data
  .byt pattern_dontunderstand-pattern_data
  .byt pattern_innuendo-pattern_data
  .byt pattern_wintendo-pattern_data
  .byt pattern_nailstendo-pattern_data
  .byt pattern_nesticle-pattern_data
NUM_PATTERNS = <(* - patterns)
  .byt pattern_end-pattern_data


.segment "CODE"
.proc get_pattern_x
glyph_end = 0
pat_end = 1

  ldy #0
  lda patterns+1,x
  sta pat_end
  lda patterns,x
newglyph:
  pha  ; stash pattern position on stack
  tax
  lda pattern_data+1,x
  sta glyph_end
  lda pattern_data,x
  tax
patbyte:
  ; X = current position
  ; Y = current position in output
  lda glyphbitmaps,x
  sta assembled_pattern,y
  iny
  cpy #MAX_PAT_COLS
  bcs bail
  inx
  cpx glyph_end
  bcc patbyte
  pla
  adc #1  ; carry is set coming in
  cmp pat_end
  bcc newglyph
  rts
bail:
  pla
  rts
.endproc

.proc center_pattern
width = 0
leftside = 1
  sty width
  lda #MAX_PAT_COLS
  sec
  sbc width
  beq do_nothing
  lsr a
  sta leftside
  beq no_shift_right
  clc
  adc width
  tax
  dex  ; X = rightmost byte of dst
  dey  ; Y = rightmost byte of src
shiftloop:
  lda assembled_pattern,y
  sta assembled_pattern,x
  dex
  dey
  bpl shiftloop
  lda #0
clrleftloop:
  sta assembled_pattern,x
  dex
  bpl clrleftloop
no_shift_right:
  lda leftside
  clc
  adc width
  tay
  lda #0
clrrightloop:
  sta assembled_pattern,y
  iny
  cpy #MAX_PAT_COLS
  bcc clrrightloop
do_nothing:
  rts
.endproc

.proc rotate_pattern
rotated_chr = 8

  lda #>(PATTERN_FIRST_TILENO << 4)
  sta PPUADDR
  lda #<(PATTERN_FIRST_TILENO << 4)
  sta PPUADDR
  ldy #0
pat4loop:
  lda #1
  sta rotated_chr+0
colloop:
  lda assembled_pattern,y
  ldx #7
rowloop:
  asl a
  rol rotated_chr,x
  asl rotated_chr,x
  dex
  bpl rowloop
  iny
  ; After rotated_chr+0 is shifted left 8 times, C becomes 1
  bcc colloop

  inx
copytophalf:
  jsr do_one_rotated_byte
  cpx #4
  bcc copytophalf
  jsr do_8_blank_bytes
  ldx #4
copybottomhalf:
  jsr do_one_rotated_byte
  cpx #8
  bcc copybottomhalf
  jsr do_8_blank_bytes
  cpy #MAX_PAT_COLS
  bcc pat4loop
  rts

do_one_rotated_byte:
  lda rotated_chr,x
  lsr a
  ora rotated_chr,x
  sta PPUDATA
  sta PPUDATA
  inx
  rts
do_8_blank_bytes:
  ldx #8
  lda #0
loop_blank:
  sta PPUDATA
  dex
  bne loop_blank
  rts
.endproc

; End of pattern code ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

