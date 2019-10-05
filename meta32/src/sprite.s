.include "nes.inc"

.export objType, objState1, objState2, objXTile, objXSub, objXVel, objYTile, objYSub, objYVel
.export objOrderToTable, objTableToOrder
.export finalizeOAM, nextOAM
.export N_OBJS
.importzp camXSub, camXCol

N_OBJS = 32

.segment "ZEROPAGE"
curOAMIdx:
  .res 1

.segment "BSS"
.align 32
objType:   ; type of obj (0: none)
  .res N_OBJS
objState1: ; 8-bit state
  .res N_OBJS
objState2: ; 8-bit state
  .res N_OBJS
objXTile:  ; x position of obj (in tiles)
  .res N_OBJS
objXSub:   ; x position of obj (in 1/32 pixels)
  .res N_OBJS
objXVel:   ; x velocity of obj (possibly in 1/32 pixels, signed)
  .res N_OBJS
objYTile:  ; y position of obj (in tiles)
  .res N_OBJS
objYSub:   ; y position of obj (in 1/32 pixels)
  .res N_OBJS
objYVel:   ; y velocity of obj (possibly in 1/32 pixels, signed)
  .res N_OBJS

objOrderToTable:  ; indexes of objs in left-to-right order
  .res N_OBJS
objTableToOrder:  ; indexes of objs in left-to-right order
  .res N_OBJS     ; objs nearest this in collision searches


.segment "CODE"

;
; Gets the (x, y) position of an object.
; In:   
; Out:  carry set if invisible due to offscreen
;       1 = x position
;       0 = y position
;
getXY:
  sec
  lda objXSub,x
  sbc camXSub
  sta 0
  lda objXTile
  sbc camXCol  ; A:0 = screen position of obj times 32
  cmp #32
  bcs @offscreen
  asl 0
  rol a
  asl 0
  rol a
  asl 0
  rol a            ; A:0 = screen position of obj times 256
  bcs @offscreen
  sta 1           ; 1 = screen x position of obj

  sec
  lda objXSub,x
  sbc camXSub
  sta 0
  lda objXTile
  sbc camXCol  ; A:0 = screen position of obj times 32
  cmp #32
  bcs @offscreen
  asl 0
  rol a
  asl 0
  rol a
  asl 0
  rol a
  sta 0            ; 0 = screen x position of obj
@offscreen:
  rts


;
; Added to each sprite. Must be of form n*8+4.
; 
FLICKER_VAL = 68

;
; Gets 
; In:   curOAMFirstIdx = OAM index start/end point
; Upd8: curOAMIdx = OAM index of next sprite
; Out:  Z flag set if no space is available for sprites
;       Y = OAM index
nextOAM:
  lda curOAMIdx
  beq @noSpaceLeft
  clc
  adc #FLICKER_VAL
  beq :+  ; skip sprite 0
  adc #FLICKER_VAL
:
  sta curOAMIdx
  tay
@noSpaceLeft:
  rts


finalizeOAM:
  ldy curOAMIdx
  jmp @start
@loop:
  tay
  lda #$EF
  sta OAM,y
@start:
  tya
  clc
  adc #FLICKER_VAL
  bne @loop
  lda #FLICKER_VAL
  sta curOAMIdx
  rts

