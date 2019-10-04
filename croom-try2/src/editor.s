.p02
.include "global.inc"

.segment "CODE"
.proc genActualSizeRow

; Compute source address
  tya
  asl a
  asl a
  asl a
  asl a
  tax

; This variable is both an output and a loop counter.  Each time the
; loop executes, each of these is shifted left one bit.  Once the
; loop has run 8 times, a true bit will shift into the carry.
  lda #%00000001
  sta actualSizeData+3

; Convert packed pixel data to planar data
loop:
  lda emblemPixels,x
  lsr a
  rol actualSizeData
  lsr a
  rol actualSizeData+1
  lda emblemPixels+8,x
  inx
  lsr a
  rol actualSizeData+2
  lsr a
  rol actualSizeData+3
  bcc loop

  rts
.endproc

.proc copyRowToVRAM

; Compute actual size destination address
  lda lastPPUCTRL
  ora #VRAM_DOWN
  sta PPUCTRL

  lda #$01  ; $01C0 is the origin
  sta PPUADDR
  tya
  and #$07
  sta 0
  tya
  and #$08
  asl a
  ora 0
  ora #$C0
  sta PPUADDR
  ora #$08
  tax

  ; plane 0
  lda actualSizeData
  sta PPUDATA
  lda actualSizeData+2
  sta PPUDATA

  lda #$01
  sta PPUADDR
  stx PPUADDR  
  lda actualSizeData+1
  sta PPUDATA
  lda actualSizeData+3
  sta PPUDATA

; Compute source address
  tya
  asl a
  asl a
  asl a
  asl a
  tax
  
; Compute magnified destination address
  adc #4*16  ; top at y=4
  sta 0
  lda #0
  rol a

  ; here, A:0 = 16 * (y + 4)
  asl 0
  rol a  
  adc #$20

  ; here, A:0 = $2000 + (32 * (y + 4))
  sta PPUADDR
  lda 0
  ora #$08
  sta PPUADDR
  lda lastPPUCTRL
  sta PPUCTRL
  
; Copy magnified row to nametable
  .repeat 16, I
    lda emblemPixels+I,x
    sta PPUDATA
  .endrepeat

  rts
.endproc

.proc loadSampleIcon
  ldx curEmblemX
  jsr getEmblemMetadata
  ldy #31
loadMetadataLoop:
  lda (0),y
  sta emblemMeta,y
  dey
  bpl loadMetadataLoop

  ldx curEmblemX
  jsr getEmblemData
  ldy #63
loadDataLoop:
  lda (0),y
  sta emblemData,y
  dey
  bpl loadDataLoop

  lda #<emblemData
  sta 0
  lda #>emblemData
  sta 1
  jmp loadEmblemIntoEditor
.endproc



.proc drawCursor

; draw the cursor inside the document area
  lda cursorTool
  asl a
  asl a
  tax
  lda cursorY
  clc
  adc #4
  asl a
  asl a
  asl a
  adc cursorShapes,x
  sta OAM+4
  lda cursorShapes+1,x
  sta OAM+5
  lda #0
  sta OAM+6
  lda cursorX
  clc
  adc #8
  asl a
  asl a
  asl a
  adc cursorShapes+3,x
  sta OAM+7

; draw a pointer to the current color
  lda cursorColor
  asl a
  asl a
  asl a
  asl a
  adc #103
  sta OAM+8
  lda #4
  sta OAM+9
  lda #%00000000
  sta OAM+10
  lda #40
  sta OAM+11
  
  ldx #12
  lda #$F0
  :
    sta OAM,x
    inx
    inx
    inx
    inx
    bne :-
  rts
.endproc

.proc updPalette
  lda #$3F
  sta PPUADDR
  lda #0
  sta PPUADDR
  lda #$30
  sta PPUDATA
  .repeat 3, I
    lda emblemPal+1+I
    sta PPUDATA
  .endrepeat
  lda #$3F
  sta PPUADDR
  lda #$12
  sta PPUADDR
  ldx cursorColor
  beq colorZero
  lda emblemPal,x
  sta PPUDATA
  rts
colorZero:
  lda #$30
  sta PPUDATA
  rts
.endproc

.segment "RODATA"
cursorShapes:
; y, tile, reserved, x
  .byt 3, 4, 0, 4  ; arrow
  .byt <-13, 6, 0, 3  ; pencil
  .byt <-8, 8, 0, 3  ; bucket (not used)
  
editor_attributeTable:
  .byt $55,$55,$55,$55,$55,$55,$55,$55
  .byt $55,$54,$00,$00,$00,$00,$55,$55
  .byt $55,$55,$00,$00,$00,$00,$55,$55
  .byt $55,$44,$00,$00,$00,$00,$55,$55
  .byt $55,$44,$00,$00,$00,$00,$55,$55
  .byt $55,$55,$55,$55,$55,$55,$55,$55
  .byt $55,$55,$55,$55,$55,$55,$55,$55
  .byt $55,$55,$55,$55,$55,$55,$55,$55

editorHelp_nam:
  .incbin "screens/editorHelp.nam"

.segment "CODE"

.proc drawColumnOfSolids
  lda #$21
  sta PPUADDR
  stx PPUADDR
  ldx #0
  stx PPUDATA
  stx PPUDATA
  inx
  stx PPUDATA
  stx PPUDATA
  inx
  stx PPUDATA
  stx PPUDATA
  inx
  stx PPUDATA
  stx PPUDATA
  rts
.endproc  

;;
; Writes the name of the current emblem to x.
.proc writeName
  lda #$22
  sta PPUADDR
  lda #$A3
  sta PPUADDR
  ldx curBank
  lda bankNames,x
  sta PPUDATA
  lda #'-'
  sta PPUDATA
  lda curPage
  ora #'0'
  sta PPUDATA
  lda curEmblemX
  tax
  ora #'0'
  sta PPUDATA
  lda #' '
  sta PPUDATA
  jsr getEmblemMetadata
  ldy #0
  copyLoop:
    lda (0),y
    beq doneCopy
    sta PPUDATA
    iny
    cpy #16
    bcc copyLoop
  doneCopy:
  rts
.endproc

.proc writeHelp
  lda #$22
  sta PPUADDR
  lda #$E0
  sta PPUADDR
  ldx #0
  jsr writeHelpSub
  
  lda cursorColor
  beq dontWriteSelect
  cmp #3
  beq dontWriteSelect
  jsr writeHelpSub
  
writeHelpSub:
  ldy #8
  @loop:
    .repeat 4
      lda editorHelp_nam,x
      sta PPUDATA
      inx
    .endrepeat
    dey
    bne @loop
  rts
  
dontWriteSelect:
  ldy #8
  lda #' '
  @loop:
    .repeat 4
      sta PPUDATA
    .endrepeat
    dey
    bne @loop
  ldx #64
  jmp writeHelpSub
.endproc

.proc setupVRAMForEditor
  lda #0
  sta PPUMASK
  lda lastPPUCTRL
  sta PPUCTRL

  ; load tools
  ldy #$00
  jsr loadCHR

  lda #$20
  sta PPUADDR
  lda #0
  sta PPUADDR
  ldx #$F0
  ;lda #1  ; DEBUG
clrloop1:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  dex
  bne clrloop1
attrLoop:
  lda editor_attributeTable,x
  sta PPUDATA
  inx
  cpx #$40
  bcc attrLoop

  jsr writeName
  jsr writeHelp
  
  lda #2
  sta 0
  sta 1
  ldx #3
  ldy #3
  jsr drawFrame
  
  lda #2
  sta 0
  lda #8
  sta 1
  ldx #3
  ldy #11
  jsr drawFrame
  
  lda #16
  sta 0
  sta 1
  ldx #7
  ldy #3
  jsr drawFrame
  
  ; draw actual-size preview
  ldx #$20
  stx PPUADDR
  lda #$84
  sta PPUADDR
  lda #$1C
  sta PPUDATA
  lda #$1E
  sta PPUDATA
  stx PPUADDR
  lda #$A4
  sta PPUADDR
  lda #$1D
  sta PPUDATA
  lda #$1F
  sta PPUDATA
  
  lda lastPPUCTRL
  ora #VRAM_DOWN
  sta PPUCTRL
  ldx #$84
  jsr drawColumnOfSolids
  ldx #$85
  jsr drawColumnOfSolids

  lda lastPPUCTRL
  sta PPUCTRL

  ; copy entire loaded emblem to vram
  ldy #16
  sty dirtyRow
  dey
dirtySetup:
  jsr genActualSizeRow
  jsr copyRowToVRAM
  dey
  bpl dirtySetup

  jmp updPalette
.endproc


.proc emblemEditor

  jsr setupVRAMForEditor

mainLoop:
  jsr readPad
  jsr editHandleController
  jsr drawCursor

  ldy dirtyRow
  cpy #16
  bcs notEncodingRow
  jsr genActualSizeRow
notEncodingRow:
  lda retraces
:
  cmp retraces
  beq :-
  bit PPUSTATUS
  ldy dirtyRow
  cpy #16
  bcs notBlittingRow
  jsr copyRowToVRAM
  lda #16
  sta dirtyRow
notBlittingRow:
  jsr updPalette
  lda #>OAM
  sta OAM_DMA
  jsr screenOn

  lda newKeys
  and #KEY_START
  bne exitLoop
  jmp mainLoop
exitLoop:
  rts

.endproc

.proc editHandleController
  moved = 0
  
  lda #0
  sta moved

  lda newKeys
  and #KEY_B
  beq notB
  inc cursorColor
  lda cursorColor
  and #$03
  sta cursorColor
  
  ; rewrite the help now that the actions have changed
  lda retraces
  :
  cmp retraces
    beq :-
  jsr writeHelp
  jsr screenOn
notB:

  lda newKeys
  and #KEY_UP
  beq notUp
  lda #$FF
  sta moved
  dec cursorY
notUp:

  lda newKeys
  and #KEY_DOWN
  beq notDown
  lda #$FF
  sta moved
  inc cursorY
notDown:

  lda newKeys
  and #KEY_LEFT
  beq notLeft
  lda #$FF
  sta moved
  dec cursorX
notLeft:

  lda newKeys
  and #KEY_RIGHT
  beq notRight
  lda #$FF
  sta moved
  inc cursorX
notRight:

  ; wrap cursor inside rectangle
  lda cursorY
  and #$0F
  sta cursorY
  lda cursorX
  and #$0F
  sta cursorX

  lda keys
  and moved
  ora newKeys
  and #KEY_A
  beq notA

  lda cursorY
  cmp dirtyRow
  bcs :+
  sta dirtyRow
:
  asl a
  asl a
  asl a
  asl a
  ora cursorX
  tax
  lda cursorColor
  sta emblemPixels,x
notA:

  lda newKeys
  and #KEY_SELECT
  beq notSelect
  ldx cursorColor
  beq notSelect
  cpx #3
  beq notSelect
  lda emblemPal,x
  jsr colorPicker
  ldx cursorColor
  sta emblemPal,x

  ; rewrite the help that the dialog box covered
  lda retraces
  :
  cmp retraces
    beq :-
  jsr writeHelp
  jsr screenOn
notSelect:

  rts
.endproc

;;
; Converts an emblem from packed to planar format for editing.
; @param src emblem data in NES planar format
.proc loadEmblemIntoEditor
  src = 0
  convY = 3
  leftp0 = 4
  leftp1 = 5
  rightp0 = 6
  rightp1 = 7

  ldx #0
  stx convY

  ; X = the offset into emblemPixels
rowLoop:

  ; seek to row
  lda convY
  and #$08
  asl a
  sta leftp0
  lda convY
  and #$07
  ora leftp0

  ; load image sliver
  tay
  lda (src),y
  sta leftp0
  tya
  eor #$08
  tay
  lda (src),y
  sta leftp1
  tya
  eor #$20
  tay
  lda (src),y
  sta rightp1
  tya
  eor #$08
  tay
  lda (src),y
  sta rightp0

  ; decode
  ldy #8
pixelLoop:
  lda #0
  asl leftp1
  rol a
  asl leftp0
  rol a
  sta emblemPixels,x
  lda #0
  asl rightp1
  rol a
  asl rightp0
  rol a
  sta emblemPixels+8,x
  inx
  dey
  bne pixelLoop

  inc convY
  txa
  adc #8
  tax
  bcc rowLoop

  rts
.endproc

;;
; Converts the packed-pixel emblem into a planar emblem in the
; current data
.proc getEmblemFromEditor
  ldy #0
  yloop1:
    jsr genActualSizeRow
    lda actualSizeData
    sta emblemData,y
    lda actualSizeData+1
    sta emblemData+8,y
    lda actualSizeData+2
    sta emblemData+32,y
    lda actualSizeData+3
    sta emblemData+40,y
    iny
    cpy #8
    bcc yloop1
  yloop2:
    jsr genActualSizeRow
    lda actualSizeData
    sta emblemData+8,y
    lda actualSizeData+1
    sta emblemData+16,y
    lda actualSizeData+2
    sta emblemData+40,y
    lda actualSizeData+3
    sta emblemData+48,y
    iny
    cpy #8
    bcc yloop1
  rts
.endproc
