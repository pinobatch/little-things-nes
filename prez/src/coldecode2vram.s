.include "nes.inc"
.include "global.inc"
.export colDecodeSetupNT, blockBufToAttr, blastCol

.segment "CODE"
;;
; Decodes a column of metatiles to the nametable copy buffer.
;
.proc colDecodeSetupNT

  ; decode metatile numbers to hwtile numbers for nametables
  ldx #COL_HEIGHT-1
  loop:
    lda #0
    sta 0
    lda colDecodeBuf,x
    asl a
    rol 0
    asl a
    rol 0
    tay
    stx 2
    ldx 0
    lda mtTablesLo,x
    sta 0
    lda mtTablesHi,x
    sta 1
    ldx 2
    lda (0),y
    sta ntCopyBufTL,x
    iny
    lda (0),y
    sta ntCopyBufBL,x
    iny
    lda (0),y
    sta ntCopyBufTR,x
    iny
    lda (0),y
    sta ntCopyBufBR,x
    dex
    bpl loop

  ; compute nametable address
  lda colDecodePage
  and #$01
  asl a
  asl a
  ora #$20
  sta ntCopyDstHi
  lda colDecodeX
  and #$0F
  asl a
  ora #$80
  sta ntCopyDstLo

  ;compute attribute table address
  lda colDecodeX
  and #$0E
  lsr a
  ora #$C8
  sta attrCopyDstLo
  rts
.endproc

;;
; Swizzles the high bits of a pair of columns to form
; values for the attribute table.
.proc blockBufToAttr
  lda colDecodeX
  and #$0E
  sta 0
  lda colDecodePage
  and #$01
  ora #>blockBuf0
  sta 1
  ldx #0
  loop:
    ldy #17
    lda (0),y
    asl a
    rol 2
    asl a
    rol 2
    
    dey
    lda (0),y
    asl a
    rol 2
    asl a
    rol 2

    ldy #1
    lda (0),y
    asl a
    rol 2
    asl a
    rol 2

    dey
    lda (0),y
    asl a
    rol 2
    asl a
    rol 2

    lda 2
    sta attrCopyBuf,x

    lda 0
    clc
    adc #32
    sta 0
    inx
    cpx #COL_HEIGHT/2
    bcc loop
  rts
.endproc

.proc blastCol

  ; start to copy nametable tiles: 12 cycles
  lda #VBLANK_NMI|VRAM_DOWN
  sta PPUCTRL
  ldx #0
  ldy ntCopyDstLo
  blastEachCol:
    ; seek: 14 cycles
    lda ntCopyDstHi
    sta PPUADDR
    sty PPUADDR
    iny
    ; copy each column of nametable tiles: 192 cycles
    ; but lots of bytes so keep it banked out most of the time
    .repeat 12, i
      lda ntCopyBufTL+i,x
      sta PPUDATA
      lda ntCopyBufBL+i,x
      sta PPUDATA
    .endrepeat
    ; loop: 11 cycles
    txa
    eor #COL_HEIGHT
    tax
    beq :+
    jmp blastEachCol
  :
  ; add 1 for taken branch, totaling xxx cycles so far

  ; set up attribute table copy: 10 cycles
  lda ntCopyDstHi
  ora #$03  ; attribute table for to $2000-$23BF is $23C0
  tay
  clc
  
  blastEachAttr:
    ; seek: 18 cycles
    sty PPUADDR
    lda attrCopyDstLo
    sta PPUADDR
    adc #8
    sta attrCopyDstLo
    ; copy: 8 cycles
    lda attrCopyBuf,x
    sta PPUDATA
    ; loop: 7 cycles
    inx
    cpx #COL_HEIGHT/2
    bne blastEachAttr
  
  ; subtract 1 for untaken branch, totaling xxx cycles
  rts
.endproc


.segment "RODATA"
mtTablesLo:
  .byt <mtTable0, <mtTable1, <mtTable2, <mtTable3
mtTablesHi:
  .byt >mtTable0, >mtTable1, >mtTable2, >mtTable3
mtTable0:
  .byt $00,$00,$00,$00
  .byt $11,$01,$01,$01
  .byt $12,$02,$02,$02
  .byt $13,$03,$03,$03
  .byt $29,$2B,$02,$2C ; pipe top 1
  .byt $02,$2C,$2A,$2D ; pipe top 2
  .byt $2E,$2E,$02,$02
  .byt $02,$02,$2F,$2F
  .byt $00,$00,$00,$D2 ;cloud left
  .byt $D0,$03,$D1,$03 ;cloud center
  .byt $00,$D3,$00,$00 ;cloud right
  .byt $00,$00,$D4,$00 ;cloud bottom 1
  .byt $D5,$00,$D6,$00 ;cloud bottom 2
  .byt $D7,$00,$00,$00 ;cloud bottom 3
mtTable1:
  .byt $20,$22,$21,$23 ;? crate
mtTable2:
  .byt $04,$01,$04,$01
  .byt $01,$01,$01,$01
  .byt $00,$08,$00,$09
  .byt $08,$0A,$09,$0B
  .byt $0E,$0C,$0F,$0D
  .byt $00,$0E,$00,$0F
  .byt $0A,$01,$0B,$01
  .byt $0C,$01,$0D,$01
  .byt $00,$00,$00,$D2 ;cloud left
  .byt $D0,$03,$D1,$03 ;cloud center
  .byt $00,$D3,$00,$00 ;cloud right
mtTable3:
  .byt $28,$28,$28,$28 ;bricks


