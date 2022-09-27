.include "nes.inc"
.include "global.inc"
.segment "CODE"
.proc draw_bg
  ; Start by clearing the first nametable
  lda #VBLANK_NMI
  sta PPUCTRL
  lda #$00
  tay
  ldx #$20
  jsr ppu_clear_nt
  ldx #$24
  jsr ppu_clear_nt
  
  lda #$23
  sta PPUADDR
  lda #$D0
  sta PPUADDR
  ldy #3
  lda #%11110000
  mid_attr_loop:
    sta PPUDATA
    sta PPUDATA
    and #%01010101
    ldx #6
    :
      sta PPUDATA
      dex
      bne :-
    lda #%11111111
    dey
    bne mid_attr_loop

  ; AC8 decompression
ac8srclo = $00
ac8srchi = $01
ac8dstlo = $02
ac8dsthi = $03
ac8bits = $04
ac8common = $05
ac8prev = $06
ac8rowsleft = $07
ac8colsleft_row = $08
ac8colsleft_half = $09

ac8_unpack:
  lda #>grid_ac8
  sta ac8srchi
  lda #<grid_ac8
  sta ac8srclo
  lda #18
  sta ac8rowsleft
  lda #$80
  sta ac8bits
  asl a
  sta ac8dstlo
  sta ac8common
  sta ac8prev
  lda #$20
  sta ac8dsthi
  rowloop:
    lda ac8dsthi
    sta PPUADDR
    lda ac8dstlo
    sta PPUADDR
    lda #32
    sta ac8colsleft_half
    lda #36
    sta ac8colsleft_row
    ldy #0
    byteloop:
      asl ac8bits
      bne nonewpacket
        lda (ac8srclo),y
        iny
        rol a
        sta ac8bits
      nonewpacket:
      lda ac8common
      bcs is_common
        lda (ac8srclo),y
        iny
      is_common:
      sta PPUDATA
      cmp ac8prev
      bne nomatchprev
        sta ac8common
      nomatchprev:
      sta ac8prev
      dec ac8colsleft_half
      bne :+
        lda ac8dsthi
        ora #$04
        sta PPUADDR
        lda ac8dstlo
        sta PPUADDR
      :
      dec ac8colsleft_row
      bne byteloop
    tya
    clc
    adc ac8srclo
    sta ac8srclo
    bcc :+
      inc ac8srchi
      clc
    :
    lda #32
    adc ac8dstlo
    sta ac8dstlo
    bcc :+
      inc ac8dsthi
    :
    dec ac8rowsleft
    bne rowloop
  rts

ac8getbyte:
  lda (ac8srclo),y
  iny
  bne :+
    inc ac8srchi
  :
  rts

.out .sprintf("ac8_unpack is %d bytes; is it worth it?", * - ac8_unpack)
.endproc

.rodata
grid_ac8: .incbin "obj/nes/grid.nam.ac8"
