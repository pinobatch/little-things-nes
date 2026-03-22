.include "global.inc"
.export colDecodeReal
.import colDecodeSetupNT, blockBufToAttr

.segment "CODE"

.if 0
;;
; @param colDecodeX the x position of the tile to decode
.proc colDecodeFake
  lda #0
  ldx #11
  :
    sta colDecodeBuf,x
    dex
    bpl :-
  lda colDecodeX
  and #$0F
  tax
  lda fakeMapData,x
  sta colDecodeBuf+8
  bne :+
    lda #$80
    sta colDecodeBuf+9
  :
  lda colDecodeX
  bne :+
    lda colDecodePage
    and #$03
    tax
    lda #$40
    sta colDecodeBuf,x
  :
  jsr colDecodeMLBB
.endproc
.endif
.proc colDecodeFinish
  jsr colDecodeSetupNT
  jsr colDecodeToBlockBuf
  jsr blockBufToAttr
  rts
.endproc

colScanData = 0
colScanPage = 2
colScanX = 3
pageLenLeft = 4
colScanObjX = 5
colScanObjY = 6
colScanOpcode = 7
ysave = 8
xInObj = 9

.proc colDecodeReal
  ; first clear the buffer
  lda #0
  ldx #11
  :
    sta colDecodeBuf,x
    dex
    bpl :-

  lda #<mapDataPage0
  sta colScanData
  lda #>mapDataPage1
  sta colScanData+1
  lda colDecodeX
  and #$0F
  ldx colDecodePage
  bpl pageNotNegative
  rts
pageNotNegative:
  beq :+
    dex
    clc
    adc #16
  :
  sta colScanX
  stx colScanPage
  dex
  bmi skipSeekLoop
seekloop:
  clc
  lda mapDataPageLen,x
  adc colScanData
  sta colScanData
  lda #0
  adc colScanData+1
  sta colScanData+1
  dex
  bpl seekloop
skipSeekLoop:

decodeOnePage:
  ldy #0
  ldx colScanPage
  lda mapDataPageLen,x
  lsr a
  sta pageLenLeft
  beq decodeNoOpcodes
  
decodeOneOpcode:
  lda (colScanData),y
  sta colScanObjY
  lsr a
  lsr a
  lsr a
  lsr a
  sta colScanObjX
  lda colScanObjY
  and #$0F
  sta colScanObjY
  iny
  lda (colScanData),y
  sta colScanOpcode
  iny
  
  lda colScanX
  sec 
  sbc colScanObjX
  bcc notThisColumn
  cmp #16
  bcs notThisColumn
  jsr colDecodeOpcode

notThisColumn:
  dec pageLenLeft
  bne decodeOneOpcode

  ; the page is done so add Y to the position
  clc
  tya
  adc colScanData
  sta colScanData
  lda #0
  adc colScanData+1
  sta colScanData+1

decodeNoOpcodes:
  ; position is advanced to the next y
  inc colScanPage
  lda colScanPage
  cmp #32
  bcs onRightSideOfMap

  lda colScanX
  sbc #15  ; carry is false (borrow is true) coming in
  sta colScanX
  bcs decodeOnePage

onRightSideOfMap:

  ; Only area data is subject to markovs.  The clouds and wall are not.
  jsr colDecodeMLBB
  ; draw clouds, wall, and clouds behind markovs
  lda #1
  and #%00000001
  beq :+
    jsr colDecodeClouds
  :
  lda #0
  and #%00000010
  beq :+
    jsr colDecodeWall
  :
  lda #0
  and #%00000100
  beq :+
    jsr colDecodeClouds
  :

  jmp colDecodeFinish
  rts
.endproc

.proc colDecodeOpcode
  sta xInObj
  lda colScanOpcode
  and #$FC
  lsr a
  tax
  lda decoderProcs+1,x
  pha
  lda decoderProcs,x
  pha
  rts
.endproc

.segment "RODATA"
; Decoder procs MUST preserve the Y register, which holds the position
; within the page.
decoderProcs:
  ; $00-$0F
  .addr straightFloor-1, onePipe-1, slopeUpFloor-1, slopeDownFloor-1
  .addr bricksRow-1, bricksRow-1, bricksRow-1, bricksRow-1
  .addr crate-1, bush-1
widths:
  .byt 1, 2, 4, 8
.segment "CODE"
  
.proc straightFloor
  lda colScanOpcode
  and #$03
  tax
  lda xInObj
  cmp widths,x
  bcs nope
  ldx colScanObjY
  lda #$80
  sta colDecodeBuf,x
nope:
  rts
.endproc

.proc onePipe
  lda xInObj
  cmp #2
  bcs nope
  lda xInObj
  and #$01
  ora #$04
  ldx colScanObjY
  sta colDecodeBuf,x
nope:
  rts
.endproc

.proc slopeUpFloor
  lda colScanOpcode
  and #$03
  tax
  lda xInObj
  lsr a
  cmp widths,x
  bcs nope
  eor #$FF
  sec
  adc colScanObjY
  tax
  lda xInObj
  and #$01
  ora #$82
  sta colDecodeBuf,x
nope:
  rts
.endproc

.proc slopeDownFloor
  lda colScanOpcode
  and #$03
  tax
  lda xInObj
  lsr a
  cmp widths,x
  bcs nope
  adc colScanObjY
  tax
  lda xInObj
  and #$01
  ora #$84
  sta colDecodeBuf,x
nope:
  rts
.endproc

.proc bricksRow
  objH = 10

  lda colScanOpcode
  and #$03
  tax
  lda xInObj
  cmp widths,x
  bcs nope
  lda #1
  lda colScanOpcode
  lsr a
  lsr a
  and #$03
  sta objH
  ldx colScanObjY
  loop:
    lda #$C0
    sta colDecodeBuf,x
    inx
    cpx #12
    bcs nope
    dec objH
    bpl loop    
  nope:

  rts
.endproc

.proc crate
  lda xInObj
  bne nope
  lda #$40
  ldx colScanObjY
  sta colDecodeBuf,x
nope:
  rts
.endproc

.proc bush
  objW = $10
  lda colScanOpcode
  and #$03
  clc
  adc #1
  sta objW
  lda xInObj
  beq doLeftPart
  cmp objW
  beq doRightPart
  bcs nope

  lda #$89
finishPart:
  ldx colScanObjY
  sta colDecodeBuf,x
nope:
  rts
doRightPart:
  lda #$8A
  bne finishPart
doLeftPart:
  lda #$88
  bne finishPart
.endproc

.segment "RODATA"
mapDataPageLen:
  .byt $0E,$08,$06,$00,$00,$00,$00,$00
  .byt $00,$00,$00,$00,$00,$00,$00,$00
  .byt $00,$00,$00,$00,$00,$00,$00,$00
  .byt $00,$00,$00,$00,$00,$00,$00,$00

mapDataPage0:
  .byt $09,$0A
  .byt $F3,$12
  .byt $86,$02
  .byt $C6,$0C
  .byt $E7,$03
  .byt $85,$24
  .byt $E6,$26
mapDataPage1:
  .byt $03,$20
  .byt $47,$0D
  .byt $97,$04
  .byt $D9,$03
mapDataPage2:
  .byt $49,$03
  .byt $C9,$03
  .byt $58,$20
  .byt $68,$20



.segment "CODE"
;;
; Fills spaces by replacing blocks of value 0 with the most likely
; block below it.
.proc colDecodeMLBB
  ldx #0
  loop:
    lda colDecodeBuf+1,x
    bne notSky
      ; find which table to look in
      lda #0
      sta 0
      lda colDecodeBuf,x
      asl a
      rol 0
      asl a
      rol 0
      ; get address of this table
      stx 2
      ldx 0
      lda mlbBelowLo,x
      sta 0
      lda mlbBelowHi,x
      sta 1
      ldx 2
      ; look up the tile in the table
      lda #$3F
      and colDecodeBuf,x
      tay
      lda (0),y
      sta colDecodeBuf+1,x
    notSky:
    
    inx
    cpx #COL_HEIGHT-1
    bcc loop
  rts
.endproc

.segment "RODATA"
; Each block has a most likely block below it.  For example, the most
; likely block below a solid grass tile is the solid dirt tile, and
; the most likely block below the top of a pipe is the body of a
; pipe.  So if a decoded metatile is 0, it is replaced with the most
; likely block below the block above it.
mlbBelowLo:
  .byt <mlbBelow0, <mlbBelow1, <mlbBelow2, <mlbBelow3
mlbBelowHi:
  .byt >mlbBelow0, >mlbBelow1, >mlbBelow2, >mlbBelow3
mlbBelow0:
  .byt $00,$00,$00,$00,$06,$07,$06,$07
  .byt $00,$0B,$00,$00
mlbBelow1:
  .byt $00,$00
mlbBelow2:
  .byt $81,$81,$86,$81,$81,$87,$81,$81
  .byt $00,$00,$00
mlbBelow3:
  .byt $00

.segment "CODE"

.proc colDecodeClouds
  lda colDecodeX
  and #$0F
  tax
  lda cloudTable1,x
  cmp #$C0
  bcs nope
  lsr a
  lsr a
  lsr a
  lsr a
  tay

  ; compute height of cloud column = max(12 - y, 3)
  eor #$FF
  sec
  adc #12
  cmp #3
  bcc :+
    lda #3
  :
  sta 1
  
  ; find cloud table column
  lda cloudTable1,x
  and #$0F
  sta 0
  asl a
  adc 0
  tax
  loop:
    lda colDecodeBuf,y
    bne notEmpty
      lda cloudMTs,x
      sta colDecodeBuf,y
    notEmpty:
    iny
    cpy #12
    bcs nope
    inx
    dec 1
    bne loop
  nope:

  rts
.endproc

.segment "RODATA"

cloudMTs:
  .byt $08,$0B,$00
  .byt $09,$0C,$00
  .byt $0A,$0D,$00
cloudTable1:
  .byt $FF,$00,$01,$02,$FF,$FF,$FF,$FF, $10,$11,$11,$12,$FF,$FF,$FF,$FF

.segment "CODE"
.proc colDecodeWall
  rts
.endproc

;;
; Copies a column of decoded tiles to the block buffer.
.proc colDecodeToBlockBuf
  lda colDecodeX
  and #$0F
  tay
  ldx #0
  stx 0
  lda colDecodePage
  and #$01
  ora #>blockBuf0
  sta 1
  clc
  loop:
    lda colDecodeBuf,x
    sta (0),y
    tya
    adc #16
    tay
    inx
    cpx #COL_HEIGHT
    bcc loop
  rts
.endproc

.segment "RODATA"
fakeMapData:
  .byt $82,$83,$80,$80,$80,$84,$85,$00
  .byt $00,$00,$82,$83,$80,$84,$85,$00


