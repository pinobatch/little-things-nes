.include "global.inc"

.segment "CODE"
;The format of a cel is as follows:
;
;each row:
;1 byte for starting x
;1 byte for number of tiles
; @param oamAddress destination OAM address; will be updated
; @param 12 y position of sprite
; @param 13 base tile no
; @param 14 oam attribute 2 (%vhp000cc)
; @param 15 x position of sprite
; @param A number of cel to draw
.proc drawSpriteCel
  src = 0
  nRows = 2
  celNo = 3
  yOffset = 4
  xXor = 5
  nTilesThisRow = 6
  thisRowX = 7
  
  yCoord = 12
  tileNoBase = 13
  flipBits = 14
  xBase = 15

  asl a
  tax
  lda celMapTable,x
  sta src
  lda celMapTable+1,x
  clc
  adc #>sprCelsBase
  sta src+1
  lda #3
  sta nRows
  stx celNo

  ldy #$10
  lda flipBits
  and #%10000000
  beq notFlippedY
  ldy #$F0
notFlippedY:
  sty yOffset

  lda flipBits
  and #%01000000
  beq notFlippedX
  lda #$FF
notFlippedX:
  sta xXor
  ldy #0
  ldx oamAddress

  rowLoop:
    lda (src),y
    iny
    sta thisRowX
    lda (src),y
    beq skipEmptyRow
    sta nTilesThisRow  
    tileLoop:

      ; draw sprite
      lda yCoord
      sta OAM,x
      lda tileNoBase
      sta OAM+1,x
      clc
      adc #2
      sta tileNoBase
      lda flipBits
      sta OAM+2,x
      lda xXor
      eor thisRowX
      adc xBase
      sta OAM+3,x

      ; advance to next x position
      lda thisRowX
      clc
      adc #8
      sta thisRowX

      ; advance to next oam entry
      txa
      clc
      adc #4
      tax
      dec nTilesThisRow
      bne tileLoop
skipEmptyRow:
    lda yCoord
    clc
    adc yOffset
    sta yCoord
    iny
    dec nRows
    bne rowLoop
  stx oamAddress
  rts
.endproc

;@param A number of cel
;@return 0: 16-bit pointer to cel's tile data
.proc getSpriteCelTileData
  asl a
  tax
  lda celTileDataTable,x
  sta 0
  lda celTileDataTable+1,x
  clc
  adc #>sprCelsBase
  sta 1
  rts
.endproc

.segment "SPRCELS"
sprCelsBase = *
celMapTable = *
celTileDataTable = * + 24
.incbin "tools/sprcelsOut.chr"