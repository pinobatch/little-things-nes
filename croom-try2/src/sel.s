.include "global.inc"

N_EMBLEMS_PER_PAGE = 10
N_PAGES_PER_DRAWER = 8

PAGESEL_REDRAW_PAGE = 0
PAGESEL_REDRAW_SELECTED = 6

.segment "RODATA"
bankNames: .byt "OBA"
thru: .byt "through"
loadMessage: .asciiz "Open which emblem?"
saveMessage: .asciiz "Replace which emblem?"
selInstruction1:
  .byt 136,137,138,139,": Move",0
selInstruction2:
  .asciiz "B: Cancel   A: Select"


.segment "CODE"

;== Displaying the line of emblems in a page ==
;
;All are three drawers of eight pages of ten emblems.


.proc shiftRightBy4
  lsr4 = emblemPixels + 64

  ldx #31
  rowLoop:
    lda #0
    .repeat 4
      lsr lsr4,x
      ror lsr4+32,x
      ror a
    .endrepeat
    sta lsr4+64,x
    dex
    bpl rowLoop
  rts
.endproc

;;
; Copies 160 bytes from emblemPixels to VRAM in 1422 cycles.
; @param xferBufferDst destination VRAM address
; @param xferBufferLen length of copy in 16-byte units
.proc blastXferBuffer
  ldy xferBufferLen
  beq skip
  lda xferBufferDstHi
  cmp #$40
  bcs blastTileAndPalette
  sta PPUADDR
  lda xferBufferDstLo
  sta PPUADDR
  lda lastPPUCTRL
  sta PPUCTRL

  clc
  ldx #0
  xloop:
    .repeat 16, I
      lda emblemPixels + I,x
      sta PPUDATA
    .endrepeat
    txa
    adc #16
    tax
    dey
    bne xloop
skip:
  sty xferBufferLen
  rts

; $40-$5F: copy 16*n bytes, and then
; copy last bytes 157-159 of to $3F09 in the palette
blastTileAndPalette:
  cmp #$80
  bcs blastZeroes
  sta PPUADDR
  lda xferBufferDstLo
  sta PPUADDR
  lda lastPPUCTRL
  sta PPUCTRL

  clc
  ldx #0
  jsr xloop
  
  lda #$3F
  sta PPUADDR
  lda #$09
  sta PPUADDR
  lda emblemPixels+157
  sta PPUDATA
  lda emblemPixels+158
  sta PPUDATA
  lda emblemPixels+159
  sta PPUDATA
  rts
  
blastZeroes:
  sta PPUADDR
  lda xferBufferDstLo
  sta PPUADDR
  lda lastPPUCTRL
  sta PPUCTRL

  clc
  ldx #0

  zeroesLoop:
    .repeat 16, I
      stx PPUDATA
    .endrepeat
    dey
    bne zeroesLoop
  sty xferBufferLen
  rts
.endproc

.proc pageselPrepareClearWithFrame
  lda #0
  sta emblemPixels
  ldx #159
  clearLoop:
    sta emblemPixels,x
    dex
    bne clearLoop
  lda #FRAMETILE::L
  ldx #FRAMETILE::R
  .repeat 5, I
    sta emblemPixels+32*I+1
    stx emblemPixels+32*I+30
  .endrepeat
  rts
.endproc

.proc pageselPrepareUpdate0

  ; state 0: clear nametable
  lda #$21
  sta xferBufferDstHi
  lda #$E0
  sta xferBufferDstLo
  lda #10
  sta xferBufferLen
  jsr pageselPrepareClearWithFrame
  
  ; write save/load message at top
  ldy #3
  ldx isSaveDialog
  beq headerLoopStart
  ldx #saveMessage-loadMessage
  bne headerLoopStart
headerLoop:
  sta emblemPixels,y
  inx
  iny
headerLoopStart:
  lda loadMessage,x
  bne headerLoop
done:

  ; write "thru" message at top
  ldx curBank
  lda bankNames,x
  sta emblemPixels+64+3
  sta emblemPixels+64+16
  lda #'-'
  sta emblemPixels+64+4
  sta emblemPixels+64+17
  lda #'9'
  sta emblemPixels+64+19
  lda #'0'
  sta emblemPixels+64+6
  ora curPage
  sta emblemPixels+64+5
  sta emblemPixels+64+18
  ldx #6
  thruLoop:
    lda thru,x
    sta emblemPixels+64+8,x
    dex
    bpl thruLoop
  
  inc srb4LoadState
  rts
.endproc

.proc pageselPrepareUpdate1_5

  ; compute source address
  ; A = 5 * curPage (five pairs of emblems per page)
  ldx srb4LoadState
  dex
  txa
  asl a
  tax
  jsr getEmblemData
  
  ldy #127
  copyLoop:
    lda (0),y
    sta emblemPixels,y
    dey
    bpl copyLoop

  ; compute destination address
  lda #0
  sta xferBufferDstLo
  ldx srb4LoadState
  dex
  txa
  sta xferBufferDstHi
  asl a
  asl a
  adc xferBufferDstHi

  ; as of now: A = pairNo * 10
  ; we want address = $0900 + pairNo * 320
  .repeat 3
    lsr a
    ror xferBufferDstLo
  .endrepeat
  adc #$09
  sta xferBufferDstHi
  lda #10
  sta xferBufferLen

  ; finish up
  inc srb4LoadState
  jmp shiftRightBy4
.endproc

.proc pageselPrepareUpdate6
  jsr pageselPrepareClearWithFrame

  lda #$22
  sta xferBufferDstHi
  lda #$40
  sta xferBufferDstLo
  lda #10
  sta xferBufferLen
  lda #$C1  ; tiles are $90 to $C1
  ldx #24
  sec
  ntloop:
    sta emblemPixels+35,x
    sbc #1
    sta emblemPixels+3,x
    sbc #1
    dex
    bpl ntloop

  ldx curEmblemX
  jsr getEmblemMetadata
  ldy #0
copyNameLoop:
  lda (0),y
  beq copyNameEnd
  sta emblemPixels+96+11,y
  iny
  cpy #16
  bcc copyNameLoop
copyNameEnd:

  ldx curBank
  lda bankNames,x
  sta emblemPixels+96+6
  lda #'-'
  sta emblemPixels+96+7
  lda curPage
  ora #'0'
  sta emblemPixels+96+8
  lda curEmblemX
  ora #'0'
  sta emblemPixels+96+9
  lda #'b'
  sta emblemPixels+96+32+8
  lda #'y'
  sta emblemPixels+96+32+9

  ldy #16
copyAuthorLoop:
  lda (0),y
  beq copyAuthorEnd
  sta emblemPixels+96+16+11,y
  iny
  cpy #24
  bcc copyAuthorLoop
copyAuthorEnd:

  ldx #$18  ; preview of selected tile is in tile $18
  stx emblemPixels+96+3
  inx
  stx emblemPixels+128+3
  inx
  stx emblemPixels+96+4
  inx
  stx emblemPixels+128+4

  inc srb4LoadState
  rts
.endproc

.proc pageselPrepareUpdate7
  ldx curEmblemX
  jsr getEmblemMetadata
  ldy #25

  lda (0),y
  sta emblemPixels+157
  iny
  lda (0),y
  sta emblemPixels+158
  iny
  lda (0),y
  sta emblemPixels+159

  ; copy the preview
  ldx curEmblemX
  jsr getEmblemData
  ldy #63
  copyCurLoop:  
    lda (0),y
    sta emblemPixels,y
    dey
    bpl copyCurLoop

  ; write destination address for preview
  ; $4180: preview is in tile $18, plus $4000 for
  ; also copying a palette
  lda #$41  
  sta xferBufferDstHi
  lda #$80
  sta xferBufferDstLo
  lda #4
  sta xferBufferLen
  inc srb4LoadState
  rts
.endproc

.proc pageselPrepareUpdate8
  lda #$23
  sta xferBufferDstHi
  lda #$00
  sta xferBufferDstLo
  lda #4
  sta xferBufferLen
  jsr pageselPrepareClearWithFrame

  ldx #0
  lda selInstruction1

  copyI1Loop:
    sta xferBuffer+3,x
    inx
    lda selInstruction1,x
    bne copyI1Loop

  tax
  lda selInstruction2
  copyI2Loop:
    sta xferBuffer+32+3,x
    inx
    lda selInstruction2,x
    bne copyI2Loop

  inc srb4LoadState
  rts
.endproc


; srb4 loading states:
; 0: load dialog title ("Open..." or "Replace...") and clear
;    nametable rows corresponding to row of emblems
; 1-5: load emblems 0-1, 2-3, 4-5, 6-7, 8-9
; 6: load row of emblems and selected emblem's name
; 7: load selected emblem's data and palette
;
.proc pageselPrepareUpdate
  lda srb4LoadState
  cmp #1
  bcs :+
  jmp pageselPrepareUpdate0
:
  cmp #PAGESEL_REDRAW_SELECTED
  bcs :+
  jmp pageselPrepareUpdate1_5
:
  cmp #7
  bcs :+
  jmp pageselPrepareUpdate6
:
  cmp #8
  bcs :+
  jmp pageselPrepareUpdate7
:
  cmp #9
  bcs :+
  jmp pageselPrepareUpdate8
:
  lda #$FF
  sta srb4LoadState
  
  rts
  
.endproc

.proc pageselHandlePad

  ; Right: Go to next emblem on this page
  lda newKeys
  and #KEY_RIGHT
  beq notRight
    ldx curEmblemX
    inx
    cpx #N_EMBLEMS_PER_PAGE
    bcc @notWrap
      ldx #0
    @notWrap:
    stx curEmblemX

    ; schedule redraw of this emblem's info
    lda #PAGESEL_REDRAW_SELECTED
    cmp srb4LoadState
    bcs notRight
      sta srb4LoadState
  notRight:

  ; Right: Go to previous emblem on this page
  lda newKeys
  and #KEY_LEFT
  beq notLeft
    ldx curEmblemX
    dex
    bpl @notWrap
      ldx #N_EMBLEMS_PER_PAGE - 1
    @notWrap:
    stx curEmblemX

    ; schedule redraw of this emblem's info
    lda #PAGESEL_REDRAW_SELECTED
    cmp srb4LoadState
    bcs notLeft
      sta srb4LoadState
  notLeft:

  ; Down: Go to next page
  lda newKeys
  and #KEY_DOWN
  beq notDown
    ldx curPage
    inx
    cpx #N_PAGES_PER_DRAWER
    bcc @notWrap
      ldx #0
    @notWrap:
    stx curPage

    ; schedule redraw of entire page
    lda #PAGESEL_REDRAW_PAGE
    sta srb4LoadState
  notDown:

  ; Right: Go to previous page
  lda newKeys
  and #KEY_UP
  beq notUp
    ldx curPage
    dex
    bpl @notWrap
      ldx #N_PAGES_PER_DRAWER - 1
    @notWrap:
    stx curPage

    ; schedule redraw of entire page
    lda #PAGESEL_REDRAW_PAGE
    sta srb4LoadState
  notUp:

  rts
.endproc

.proc pageselUpdateOAM
  lda #160
  sta OAM+4
  lda #$D6
  sta OAM+5
  lda #%00000000
  sta OAM+6
  lda curEmblemX
  asl a
  asl a
  adc curEmblemX
  asl a
  asl a
  adc #28
  sta OAM+7
  lda #$F0
  sta OAM+8
  sta OAM+12
  rts
.endproc

.proc doSel
  jsr loadStudio

  ldx #1
  ldy #13
  lda #28
  sta 0
  lda #13
  sta 1
  jsr drawFrame

  lda #0
  sta srb4LoadState

pressA:

  lda #8
  sta oamAddress
  ;jsr updateWeebleAnim
  jsr pageselUpdateOAM
  lda oamAddress
  cmp #12
  bcc :+
  jsr clearRestOfOAM
:
  jsr pageselPrepareUpdate
  ; wait for vblank and blast everything in
  lda retraces
:
  cmp retraces
  beq :-
  lda #>OAM
  sta OAM_DMA
  jsr blastXferBuffer
  jsr screenOn

  jsr readPad
  jsr pageselHandlePad
  lda newKeys
  and #%11010000
  beq pressA
  rts
.endproc

.proc clearRestOfOAM
  ldx oamAddress
  lda #$F0
clroamloop:
  sta OAM,x
  inx
  inx
  inx
  inx
  bpl clroamloop
  ldx #4
  stx oamAddress
  rts
.endproc
