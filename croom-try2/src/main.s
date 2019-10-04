.p02
.include "global.inc"

.segment "INESHDR"
.incbin "snrom.hdr"

.segment "VECTORS"
reset:
  SEI
  LDA #0
  STA PPUCTRL
  STA PPUMASK
  CLD

@mapperwrite1:
  LDA #$80
  STA @mapperwrite1+1
  JMP main

  .RES $1a+reset-*
  .addr nmi, reset, irq

.segment "CODE"
nmi:
  inc retraces
irq:
  rti

.proc main
warmup1:
  bit PPUSTATUS
  bpl warmup1
  
  ldx #0

  ; set mmc1 banking mode
  ldy #1
  stx $8000
  stx $8000
  sty $8000
  sty $8000
  stx $8000
  
  ; enable ram at $6000 and set prg bank 0 into $8000
  stx $E000
  stx $E000
  stx $E000
  stx $E000
  stx $E000
  lda #'N'
  sta $6000
  lda #'A'
  sta $6001
  lda #'Z'
  sta $6002
  lda #'I'
  sta $6003
  lda #13
  sta $6004
  lda #10
  sta $6005
  lda #26
  sta $6006
  
clearRAM:
  lda #$F0
  sta $200,x
  lda #0
  sta 0,x
  sta $100,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  inx
  bne clearRAM

warmup2:
  bit PPUSTATUS
  bpl warmup2

; load palette
  lda #$3F
  sta PPUADDR
  ldx #0
  stx PPUADDR
:
  lda warmupPalette,x
  sta PPUDATA
  inx
  cpx #$20
  bcc :-

; load chr
  jsr loadFont
  ldy #$04
  jsr loadCHR

  lda #VBLANK_NMI|OBJ_8X16
  sta lastPPUCTRL
  sta PPUCTRL
  lda #1
  sta cursorTool

coprLoop:
  lda retraces
  :
    cmp retraces
    beq :-
  jsr screenOn
  lda #%00001010
  sta PPUMASK
  jsr readPad
  lda newKeys
  and #KEY_A|KEY_START
  beq coprLoop

loginScreen:
  jsr doLogin  
  lda #0
  sta curEmblemX
  sta curPage
  lda #2
  sta curBank

dumbloop:
  jsr doSel
  lda newKeys
  and #KEY_B
  beq :+
    lda #0
    sta PPUMASK
    jmp loginScreen
  :
  lda curBank
  sta fromBank
  lda curPage
  sta fromPage
  lda cursorX
  sta fromX
  jsr loadSampleIcon
  jsr emblemEditor
  jsr getEmblemFromEditor

  lda #<keyboardNameTitle
  sta keyboardName
  lda #>keyboardNameTitle
  sta keyboardName+1
  lda #16
  sta keyboardMaxLen
  ldy #0
  lda emblemMeta
  beq dontCopyNameToKB
  copyNameToKB:
    sta keyboardText,y
    iny
    cpy #16
    bcs dontCopyNameToKB
    lda emblemMeta,y
    bne copyNameToKB
  dontCopyNameToKB:

  sty keyboardCurLen
  jsr doKeyboard

  jmp dumbloop
.endproc

warmupPalette:
  .byt $30,$37,$16,$0F, $30,$0F,$0F,$0F, $30,$0F,$0F,$0F, $30,$0F,$0F,$0F
  .byt $30,$38,$16,$0F, $30,$0F,$0F,$0F, $30,$0F,$0F,$0F, $30,$0F,$0F,$0F
  
keyboardNameTitle:
  .asciiz "Title:"



.proc readPad
  lastKeys = 0

  lda keys
  sta lastKeys
  ldx #1
  stx P1
  dex
  stx P1
  lda #1
  sta keys
loop:
  lda P1
  lsr a
  rol keys
  bcc loop

; compute which keys were just pressed
  lda lastKeys
  eor #$FF
  and keys
  sta newKeys
  
; compute delayed auto shift
  beq noNewKeys
  sta dasKeys
  lda #15  ; delay: 250 ms
  sta dasTimer
  rts
  
noNewKeys:
  dec dasTimer
  bne noRepeatThisFrame
  lda #2  ; repeat rate: 30 fps
  sta dasTimer
  lda dasKeys
  and keys
  ora newKeys
  sta newKeys
noRepeatThisFrame:
  rts
.endproc

.proc gotoxy
  vramHi = 4
  vramLo = 5
  lda #0
  sta vramLo
  tya
  lsr a
  ror vramLo
  lsr a
  ror vramLo
  lsr a
  ror vramLo
  ora #$20
  sta vramHi
  txa
  ora vramLo
  sta vramLo
  rts
.endproc

;;
; Draws a frame to the background.
; @param X distance in tiles from left side of bg to frame
; @param Y distance in tiles from top of bg to frame 
; @param 0 width the width in tiles inside the frame
; @param 1 height the height in tiles inside the frame
.proc drawFrame
  width = 0
  height = 1

  ; compute x, y coords (53)
  jsr gotoxy

  ; top of frame (32)
  lda lastPPUCTRL
  sta PPUCTRL
  lda gotoxy::vramHi
  sta PPUADDR
  lda gotoxy::vramLo
  sta PPUADDR
  lda #FRAMETILE::TL
  sta PPUDATA
  lda #FRAMETILE::T
  ldx width
  topLoop:  ; (9*w-1)
    sta PPUDATA
    dex
    bne topLoop

  ; right side (20)
  lda lastPPUCTRL
  ora #VRAM_DOWN
  sta PPUCTRL
  lda #FRAMETILE::TR
  sta  PPUDATA
  lda #FRAMETILE::R
  ldx height
  rightLoop:  ; (9*h-1)
    sta PPUDATA
    dex
    bne rightLoop

  ; left side (32)
  lda lastPPUCTRL
  ora #VRAM_DOWN
  sta PPUCTRL
  lda gotoxy::vramHi
  sta PPUADDR
  lda gotoxy::vramLo
  sta PPUADDR
  bit PPUDATA
  ldx height
  lda #FRAMETILE::L
  leftLoop:  ; (9*h-1)
    sta PPUDATA
    dex
    bne leftLoop

  ; bottom (17)
  lda lastPPUCTRL
  sta PPUCTRL
  lda #FRAMETILE::BL
  sta PPUDATA
  lda #FRAMETILE::B
  ldx width
  bottomLoop:  ; (9*w-1)
    sta PPUDATA
    dex
    bne bottomLoop

  ;bottom right corner (12)
  lda #FRAMETILE::BR
  sta PPUDATA
  rts
.endproc
