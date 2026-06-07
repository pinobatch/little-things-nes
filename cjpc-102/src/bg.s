.include "nes.inc"
.include "global.inc"
.segment "CODE"
.proc draw_bg
  ; clear both nametables
  lda #$00
  ldy #$FF
  ldx #$20
  jsr ppu_clear_nt
  ldx #$24
  jsr ppu_clear_nt

  ; Draw a floor
  lda #$22
  sta PPUADDR
  lda #$80
  sta PPUADDR
  lda #$0B
  ldx #32
floorloop1:
  sta PPUDATA
  dex
  bne floorloop1
  
  ; Draw areas buried under the floor as solid color
  ; (I learned this style from "Pinobee" for GBA.  We drink Ritalin.)
  lda #$01
  ldx #3*16
floorloop2:
  sta PPUDATA
  sta PPUDATA
  dex
  bne floorloop2

  lda #$20
  sta PPUADDR
  lda #$C7
  sta PPUADDR
  ldx #0
  :
    lda throttle_label,x
    beq label_done
    sta PPUDATA
    inx
    bne :-
  label_done:

  ; set attributes of ground
  lda #$23
  sta PPUADDR
  lda #$E8
  sta PPUADDR
  lda #$AA
  ldx #8
  :
    sta PPUDATA
    dex
    bne :-

  ; Draw blocks on the sides, in vertical columns
  lda #VBLANK_NMI|VRAM_DOWN
  sta PPUCTRL
 
  ; At position (2, 20) (VRAM $2282) and (28, 20) (VRAM $229C),
  ; draw two columns of two blocks each, each block being 4 tiles:
  ; 0C 0D
  ; 0E 0F
  ldx #2

colloop:
  lda #$22
  sta PPUADDR
  txa
  sta PPUADDR

  ; Draw $0C $0E $0C $0E or $0D $0F $0D $0F depending on column
  and #$01
  ora #$0C
  ldy #4
tileloop:
  sta PPUDATA
  eor #$02
  dey
  bne tileloop

  ; Columns 2, 3, 28, and 29 only  
  inx
  cpx #4  ; Skip columns 4 through 27
  bne not4
  ldx #28
not4:
  cpx #30
  bcc colloop

  ; The attribute table elements corresponding to these stacks are
  ; (0, 4) (VRAM $23E0) and (7, 4) (VRAM $23E7).  Set them to 0.
  ldx #$23
  lda #$E0
  ldy #$00
  stx PPUADDR
  sta PPUADDR
  sty PPUDATA
  lda #$E7
  stx PPUADDR
  sta PPUADDR
  sty PPUDATA

  rts
.endproc

;;
; Converts throttle value to decimal
.proc format_throttle
  lda cur_throttle
  jsr bcd8bit
  ora #'0'
  sta throttle_digits+2
  lda #' '
  sta throttle_digits+1
  sta throttle_digits+0
highdigits = $00
  lda highdigits
  beq no_tens
    cmp #10
    bcc no_hundreds
      lsr a
      lsr a
      lsr a
      lsr a
      ora #'0'
      sta throttle_digits+0
      lda highdigits
      and #$0F
    no_hundreds:
    ora #'0'
    sta throttle_digits+1
  no_tens:
  rts
.endproc

.proc draw_throttle
  lda #$20
  sta PPUADDR
  lda #$D0
  sta PPUADDR
  lda #VBLANK_NMI
  sta PPUCTRL
  lda throttle_digits+0
  sta PPUDATA
  lda throttle_digits+1
  sta PPUDATA
  lda throttle_digits+2
  sta PPUDATA
  rts
.endproc

throttle_label:
  .byte "THROTTLE:   %", 0
