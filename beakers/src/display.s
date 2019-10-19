.p02
.export textBuf
.export calcPalette, xfer, drawTitle, convertText, setTextXferRow
.export curTruthTable, curTruthX, curTruthAlias
.include "nes.inc"

.segment "BSS"
xferBuf: .res 160
xferPal = xferBuf + 128
textBuf: .res 64
xferDstHi: .res 5
xferDstLo: .res 5

curTruthTable: .res 1
curTruthX: .res 1
curTruthAlias: .res 1


COLOR_O = $02
COLOR_A = $16
COLOR_B = $28
COLOR_AB = $14

.segment "CODE"
.proc calcPalette

  ; lay down grayscale palette
  ldx #15
:
  lda basePal,x
  sta xferPal,x
  sta xferPal+16,x
  dex
  bpl :-

  ; load 'O' color
  lda #$01
  and curTruthTable
  beq @noO
  lda #COLOR_O
  sta xferPal+7
  sta xferPal+11
@noO:

  ; load 'B' color
  lda #$02
  and curTruthTable
  beq @noB
  lda #COLOR_B
  sta xferPal+10
@noB:

  ; load 'A' color
  lda #$04
  and curTruthTable
  beq @noA
  lda #COLOR_A
  sta xferPal+6
@noA:

  ; load 'AB' color
  lda #$08
  and curTruthTable
  beq @noAB
  lda #COLOR_AB
  sta xferPal+5
  sta xferPal+9
@noAB:

  lda #$3F
  sta xferDstHi+4
  lda #$00
  sta xferDstLo+4
  rts
.endproc

.proc drawTitle

  ; copy the top half of bgopt.nam
  lda #$20
  sta PPUADDR
  lda #$A0
  sta PPUADDR
  ldx #0
copyTopHalf:
  lda bgopt_nam,x
  sta PPUDATA
  inx
  bne copyTopHalf
copyBottomHalf:
  lda bgopt_nam+256,x
  sta PPUDATA
  inx
  bne copyBottomHalf

  lda #$23
  sta PPUADDR
  lda #$C8
  sta PPUADDR
copyAttrs:
  lda titleAttrs,x
  sta PPUDATA
  inx
  cpx #40
  bcc copyAttrs

  ; Prepare an xfer with the title on rows 0 and 2,
  ; the top and bottom borders on rows 1 and 3,
  ; and the palette on row 4.
  ldx #31
@copyText:
  lda titlebarText,x
  sta textBuf,x
  lda topBottomBorder,x
  sta xferBuf+32,x
  sta xferBuf+96,x
  dex
  bpl @copyText
  ldx #32
  jsr convertText

  lda #$20
  sta xferDstHi+0
  sta xferDstHi+2
  sta xferDstHi+1
  lda #$22
  sta xferDstHi+3
  lda #$40
  sta xferDstLo+0
  lda #$60
  sta xferDstLo+2
  lda #$80
  sta xferDstLo+1
  lda #$A0
  sta xferDstLo+3

  rts
.endproc


;;
; The 160-byte transfer buffer is organized into five "rows" of 32 bytes.
; If xferDstHi for a row is nonzero, this row is copied;
; otherwise, it is ignored.
; 
;
.proc xfer
  ldx #4
eachRow:
  lda xferDstHi,x
  bne :+
  jmp notThisRow 
:
  sta PPUADDR
  lda xferDstLo,x
  sta PPUADDR
  ldy times32,x
  .repeat 32, I
    lda xferBuf+I,y
    sta PPUDATA
  .endrepeat
  lda #0
  sta xferDstHi,x
notThisRow:
  dex
  bmi :+
  jmp eachRow
:
  rts
.endproc

;;
; Converts the first x characters of the text buffer
; to the transfer buffer.
; Leaves the first line in rows 0 and 2 and
; (if x > 32) the second line in rows 1 and 3.
; @param x number of characters to convert (1-64)
.proc convertText
  dex
loop:
  lda textBuf,x
  asl a
  clc
  adc #32
  sta xferBuf,x
  ora #1
  sta xferBuf+64,x
  dex
  bpl loop
  rts
.endproc

;;
; Sets the destination address for a line of text.
; @param Y high byte of address
; @param A low byte of address
; @param X line (0 or 1)
.proc setTextXferRow
  sta xferDstLo,x
  clc
  adc #32
  sta xferDstLo+2,x

  tya
  sta xferDstHi,x
  adc #0
  sta xferDstHi+2,x
  rts
.endproc

.segment "RODATA"
bgopt_nam:
  .incbin "data/bgopt.nam"
basePal:
  .byt $30, $10, $00, $0F
  .byt $30, $10, $10, $10
  .byt $30, $10, $10, $10
  .byt $30, $10, $00, $0F

titlebarText:
  .byt "         Bhhijkl Bjkmjno        "
topBottomBorder:
  .byt 0,0,1,1,1,1,1,1, 1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1, 1,1,1,1,1,1,0,0
titleAttrs:
  .byt $55,$55,$55,$55,$AA,$AA,$AA,$AA
  .byt $55,$55,$55,$55,$AA,$AA,$AA,$AA
  .byt $55,$55,$55,$55,$AA,$AA,$AA,$AA
  .byt $55,$55,$55,$55,$AA,$AA,$AA,$AA
  .byt $05,$05,$05,$05,$0A,$0A,$0A,$0A

times32:
  .byt 0, 32, 64, 96, 128, 160, 192, 224

.segment "CHR"
.incbin "data/bgopt.chr"
.incbin "data/8x16.chr"
