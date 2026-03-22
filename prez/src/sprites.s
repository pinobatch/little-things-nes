.include "nes.inc"
.include "global.inc"

.export clearRestOfSprites, drawMapLocator

.segment "ZEROPAGE"
oam_used: .res 1

.segment "CODE"

.proc clearRestOfSprites
  lda oam_used
  and #$FC
  tax
  lda #$F0
loop:
  sta OAM,x
  inx
  inx
  inx
  inx
  bne loop

  ; plant a sprite 0 dot behind the coin image
  lda #24
  sta OAM
  lda #254
  sta OAM+1
  lda #%00100000  ; using "behind" priority
  sta OAM+2
  lda #96
  sta OAM+3
  lda #4
  sta oam_used
  rts
.endproc

LOCATOR_LEFT = 64
LOCATOR_TOP = 224
.proc drawMapLocator
  ldx oam_used
  ; set y position to below the active playfield
  lda #LOCATOR_TOP - 1
  sta OAM,x
  sta OAM+4,x
  sta OAM+8,x
  ; set tiles to locatorDot and locatorBorder
  lda #251
  sta OAM+1,x
  lda #250
  sta OAM+5,x
  sta OAM+9,x
  ; set attributes
  lda #%00000000
  sta OAM+2,x
  sta OAM+6,x
  lda #%01000000  ; right border is h-flipped
  sta OAM+10,x
  ; set X position of borders
  lda #LOCATOR_LEFT
  sta OAM+7,x
  lda #LOCATOR_LEFT+31*4
  sta OAM+11,x
  ; set x position of locator dot
  lda camX
  sta 0
  lda camPage
  asl 0
  rol a
  asl 0
  rol a
  asl 0
  adc #LOCATOR_LEFT
  sta OAM+3,x

  ; advance sprite pointer
  txa
  clc
  adc #12
  sta oam_used
  rts
.endproc


putSpriteX = 0
putSpriteY = 1
putSpritePage = 2
putSpriteTile = 4
putSpriteAttr = 5
putSpriteW = 6
putSpriteH = 7
.proc putSprite
  xAdd = 15
  visW = 14
  clipSkip = 13
  yAdd = 12
  thisRowX = 11

  ; determine the Y offset depending on the hflip bit
  ldx #8
  bit putSpriteAttr
  bpl :+
    ldx #$F8
  :
  stx yAdd

  ; determine the X offset depending on the hflip bit
  ldx #8
  bit putSpriteAttr
  bvc :+
    ldx #$F8
  :
  stx xAdd
  
  sec
  lda putSpriteX
  sbc camX
  sta putSpriteX
  lda putSpritePage
  sbc camPage
  sta putSpritePage

  bcc clipLeftSide  ; page < 0: left side is off left side of screen
  beq clipRightSide ; page = 0: left side is on screen
knownrts1:
  rts               ; page > 0: left side is off right side of screen

clipRightSide:
  lda #0
  sta clipSkip
  lda putSpriteW
  sta visW
  asl a
  asl a
  asl a
  adc putSpriteX
  bcc clipRightFlipTest
  cmp #8
  bcc clipRightFlipTest
  lsr a
  lsr a
  lsr a
  sta clipSkip
  lda visW
  sec
  sbc clipSkip
  sta visW

clipRightFlipTest:
  ; if sprite is flipped, skip tiles of each row that are offscreen
  bit xAdd
  bpl clipDone
  lda clipSkip
  clc
  adc putSpriteTile
  sta putSpriteTile
  lda visW
  asl a
  asl a
  asl a
  adc putSpriteX
  sec
  sbc #8
  sta putSpriteX
  bne clipDone

clipLeftSide:
  cmp #$FF      ; only draw anything if the left edge is on the
  bne knownrts1 ; screen immediately to the left
  lda putSpriteX
  eor #$FF
  lsr a
  lsr a
  lsr a
  clc
  adc #1
  cmp putSpriteW
  bcs knownrts1
  sta clipSkip
  sec
  lda putSpriteW
  sbc clipSkip
  sta visW

  ; if sprite is NOT flipped, skip tiles of each row that are offscreen
  bit xAdd
  bpl clipLeftNotFlipped
  lda putSpriteW
  asl a
  asl a
  asl a
  sbc #8
  adc putSpriteX
  sta putSpriteX
  jmp clipDone
clipLeftNotFlipped:
  lda clipSkip
  clc
  adc putSpriteTile
  sta putSpriteTile
  lda #$07
  and putSpriteX
  sta putSpriteX

clipDone:

  ldx oam_used
rowLoop:
  lda putSpriteX
  sta thisRowX
  ldy visW
tileLoop:
  lda putSpriteY
  sta OAM,x
  inx
  lda putSpriteTile
  inc putSpriteTile
  sta OAM,x
  inx
  lda putSpriteAttr
  sta OAM,x
  inx
  lda thisRowX
  sta OAM,x
  clc
  adc xAdd
  sta thisRowX
  inx
  dey
  bmi bail
  bne tileLoop

  ; done with this row
  lda clipSkip
  clc
  adc putSpriteTile
  sta putSpriteTile
  lda putSpriteY
  clc
  adc yAdd
  sta putSpriteY
  dec putSpriteH
  bne rowLoop

  ; done with all
  stx oam_used
bail:
  rts
.endproc

.proc putActor
  sta putSpriteAttr
  lda actorPage,x
  sta putSpritePage
  lda actorAniFrame,x
  lda actorXHi,x
  sta putSpriteX
  lda actorYHi,x
  clc
  adc #32
  sta putSpriteY

  ldy actorAniType,x
  lda tileBases,y
  sta putSpriteTile
  lda spriteWidths,y
  sta putSpriteW
  lda spriteHeights,y
  sta putSpriteH
  jmp putSprite
.endproc

.segment "RODATA"
tileBases:
  .byt $00, $04, $10
spriteWidths:
  .byt $02, $03, $02
spriteHeights:
  .byt $02, $03, $02

