.include "nes.inc"
.include "global.inc"

LF = $0A
.segment "CODE"
.proc draw_bg
  ; Start by clearing the first nametable
  ldx #$20
  txa
  ldy #$00
  jsr ppu_clear_nt


srclo = $00
srchi = $01
dstlo = $02
dsthi = $03
  ldy #<msg
  lda #>msg
  sta srchi
  lda #0
  sta srclo

  lda #VBLANK_NMI
  sta PPUCTRL
  lda #$20
  sta dsthi
  sta PPUADDR
  lda #$62
  sta dstlo
  sta PPUADDR
  
  txtloop:
    lda (srclo),y
    beq txtdone
    iny
    bne :+
      inc srchi
    :
    cmp #LF
    beq is_newline
    and #$3F
    sta PPUDATA
    jmp txtloop
  is_newline:
    lda #$20
    clc
    adc dstlo
    sta dstlo
    lda dsthi
    adc #0
    sta dsthi
    sta PPUADDR
    lda dstlo
    sta PPUADDR
    jmp txtloop
  txtdone:
  
  rts
.endproc

.rodata
msg:
  .byte "SPECTROGRAM DEMO",LF
  .byte "COPR. 2017 DAMIAN YERRICK",0
