.include "nes.inc"
.include "global.inc"

LF = $0A

.segment "CODE"
.proc draw_bg
  ; Start by clearing the first nametable
  ldx #$20
  txa
  ldy #0
  jsr ppu_clear_nt
  lda #$80
  sta PPUCTRL

dst_lo = $00
dst_hi = $01

  lda #<bgmessage
  sta src_lo
  lda #>bgmessage
  sta src_hi
  lda #$21
  sta dst_hi
  sta PPUADDR
  lda #$03
  sta dst_lo
  sta PPUADDR
  ldy #0
  text_loop:
    lda (src_lo),y
    beq text_done
    iny
    bne :+
      inc src_hi
    :
    cmp #LF
    beq linefeed
    sta PPUDATA
    bne text_loop
  linefeed:
    lda #32
    clc
    adc dst_lo
    sta dst_lo
    lda #0
    adc dst_hi
    sta PPUADDR
    sta dst_hi
    lda dst_lo
    sta PPUADDR
    jmp text_loop
  text_done:
  rts
.endproc

.rodata
bgmessage:
  .byte "TWO-BIT CLONES",LF
  .byte "COPR.2025 D.YERRICK",LF
  .byte LF
  .byte "LISTEN TO THE VOICE TO",LF
  .byte "TELL IF YOUR CONSOLE'S",LF
  .byte "DUTY CYCLES ARE SWAPPED:",LF
  .byte LF
  .byte "  THIS CONSOLE SOUNDS",LF
  .byte "  LIKE A SWAPPED CLONE.",LF
  .byte "        [OR]",LF
  .byte "  THIS CONSOLE SOUNDS",LF
  .byte "  AUTHENTIC.",LF
  .byte LF
  .byte "PRESS A BUTTON TO REPLAY",0
