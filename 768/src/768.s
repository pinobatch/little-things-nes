.p02
.include "nes.inc"

OAM = $0200

.segment "ZEROPAGE"
retraces: .res 3
lastPPUCTRL: .res 1
joy1: .res 1
last_joy1: .res 1
joy1new: .res 1

xferBufName: .res 24
xferBufAttr: .res 6
xferBufDstLo: .res 2
xferBufDstHi = xferBufDstLo + 1
xferBufCol: .res 1
putCol: .res 1
dirtys: .res 1

DIRTY_STATUS = %00000001

cursorX: .res 1
cursorY: .res 1
cursorBrush: .res 1
scrollTile: .res 1
scrollSub: .res 1

scrollTileTarget: .res 1
scrollSubTarget: .res 1

dasKeys: .res 1
dasTime: .res 1
dasDelay = 16
dasPeriod = 2


sprite0_x = 176

.segment "BSS"
.align 256
mapOrigin: .res 3*256

.segment "VECTORS"
reset:
  SEI
  LDX #0
  STX PPUCTRL
  STX PPUMASK
  lda #$40
  sta P2
  CLD
  DEX
  TXS

@mapperwrite1:
  asl a  ; value is now $80, meaning "reset mmc1"
  STA @mapperwrite1+1
  JMP main

  .RES $1a+reset-*
  .addr nmi, reset, irq


.segment "CODE"
nmi:
  inc retraces
irq:
  rti

setMMC1CTRL:
  sta $8000
  lsr a
  sta $8000
  lsr a
  sta $8000
  lsr a
  sta $8000
  lsr a
  sta $8000
  rts

setMMC1CHR0:
  sta $A000
  lsr a
  sta $A000
  lsr a
  sta $A000
  lsr a
  sta $A000
  lsr a
  sta $A000
  rts

setMMC1CHR1:
  sta $C000
  lsr a
  sta $C000
  lsr a
  sta $C000
  lsr a
  sta $C000
  lsr a
  sta $C000
  rts

setMMC1PRG:
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  rts

main:

@warmup1:
  bit PPUSTATUS
  bpl @warmup1

; we have nearly 29000 cycles to init other parts of the NES
; so do it while waiting for the PPU to signal that it's warming up

  ; set sound channels on
  lda #$0F
  sta SNDCHN

  ; set horizontal mirroring, u*rom style banking,
  ; 8 KiB CHR switching
  lda #$0E
  jsr setMMC1CTRL

  ; CHR bank $0000
  lda #0
  jsr setMMC1CHR0

  ; CHR bank for $1000
  lda #0
  jsr setMMC1CHR1

  ; PRG bank for $8000 = 0, enable WRAM
  lda #0
  jsr setMMC1PRG

  lda #0
  tax
@clearZP:
  sta $00,x
  sta mapOrigin,x
  sta mapOrigin+$100,x
  sta mapOrigin+$200,x
  inx
  bne @clearZP

  lda #$F0
@clearShadowOAM:
  sta $200,x
  inx
  bne @clearShadowOAM

; done with tasks; wait for warmup

@warmup2:
  bit PPUSTATUS
  bpl @warmup2

  jsr loadInitialPalette

; clear both nametables
  lda #$20
  sta PPUADDR
  ldx #0
  stx PPUADDR
  txa
:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  inx
  bne :-
  
  ; top border, also used for sprite 0
  lda #$20
  sta PPUADDR
  lda #$70
  sta PPUADDR
  ldx #16
  lda #3
:
  sta PPUDATA
  dex
  bne :-
  
  ; bottom border
  lda #$23
  sta PPUADDR
  lda #$80
  sta PPUADDR
  lda #4
  sta PPUDATA
  ldx #15
  lda #5
  ldy #6
:
  sta PPUDATA
  sty PPUDATA
  dex
  bne :-
  iny
  sty PPUDATA

  ; bottom border, page 2
  lda #$27
  sta PPUADDR
  lda #$80
  sta PPUADDR
  lda #4
  sta PPUDATA
  ldx #15
  lda #5
  ldy #6
:
  sta PPUDATA
  sty PPUDATA
  dex
  bne :-
  iny
  sty PPUDATA

  lda #NT_2000|BG_0000|OBJ_8X16|VBLANK_NMI
  sta PPUCTRL
  sta lastPPUCTRL

  ; load test data
  ldx #127
  lda #$10
:
  sta mapOrigin,x
  dex
  bpl :-
  
  lda #$11
  sta cursorBrush
  
  ; draw test data
  lda #17
  sta xferBufCol
:
  jsr col2TransferBuffer
  jsr genAttributes
  jsr copyTransferBuffer
  jsr copyAttributes
  dec xferBufCol
  jsr col2TransferBuffer
  jsr copyTransferBuffer
  dec xferBufCol
  bpl :-

  lda #0
  sta scrollTile
  lda #128
  sta scrollSub

  lda #0
  sta scrollTileTarget
  lda #8
  sta scrollSubTarget
  
  lda #1
  sta cursorX
  sta cursorY
  
  lda #DIRTY_STATUS
  sta dirtys
  
main_loop:
  jsr readPad
  jsr processAutoRepeat
  jsr moveCursorByJoy1
  lda #$FF
  sta xferBufCol
  jsr moveCameraTowardCursor
  jsr moveCameraTowardTarget
  lda xferBufCol
  bpl @doThisColumn
  ldx #$FF
  lda putCol
  stx putCol
  sta xferBufCol
  bmi @noColumn
@doThisColumn:
  lda #BG_ON|OBJ_ON|LIGHTGRAY
  sta PPUMASK
  jsr col2TransferBuffer
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  jsr genAttributes
@noColumn:
  lda #BG_ON|OBJ_ON|LIGHTGRAY
  sta PPUMASK
  
  ; draw sprite 0
  lda #15
  sta OAM + 0
  lda #1
  sta OAM + 1
  lda #0  ; #%00000001  ; behind bg
  sta OAM + 2
  lda #sprite0_x
  sta OAM + 3

  lda #BG_ON|OBJ_ON
  sta PPUMASK

  ; draw cursor
  lda #3
  sta OAM + 5
  sta OAM + 9
  lda retraces
  and #1
  beq :+
  lda #%10000000 
:
  sta OAM + 6
  eor #%11000000
  sta OAM + 10
  lda scrollSub
  lsr a
  lsr a
  lsr a
  lsr a
  sta 1

  lda joy1
  and #$40
  beq @notB

  ; draw cursor around brush
  lda #15
  sta OAM + 4
  sta OAM + 8
  lda #24
  sta OAM + 7
  lda #48
  sta OAM + 11
  bne @endDrawCursor
@notB:
  ; draw cursor in playfield
  lda cursorY
  asl a
  asl a
  asl a
  asl a
  eor #$FF
  adc #208
  sta OAM + 4
  sta OAM + 8
  lda cursorX
  sec
  sbc scrollTile
  asl a
  asl a
  asl a
  asl a
  sec
  sbc 1
  sta OAM + 7
  clc
  adc #8
  sta OAM + 11
@endDrawCursor:

  lda #BG_ON|OBJ_ON|LIGHTGRAY
  sta PPUMASK

  ; draw something else
  lda #64
  sta 8
  lda #16
  sta 9
  lda #224
  sta 10
  lda #0
  sta 11
  ldx #12
  jsr setSpriteXY
  bcc @noDraw1
  lda #$07
  sta OAM + 1,x
  lda #$01
  sta OAM + 2,x
  inx
  inx
  inx
  inx
@noDraw1:

  lda #BG_ON|OBJ_ON
  sta PPUMASK

  lda #$F0
:
  sta OAM,x
  inx
  inx
  inx
  inx
  bne :-

  jsr wait4vbl
  lda PPUSTATUS
  lda #0
  sta OAMADDR
  lda #>OAM
  sta OAM_DMA

  lda xferBufCol
  bmi @noCopyColumn
  jsr copyTransferBuffer
  jsr copyAttributes
  jmp @doneWithVRAM
@noCopyColumn:
  lda dirtys
  and #$01
  beq @doneWithVRAM
  jsr drawStatus

@doneWithVRAM:

  ; set status bar scroll
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda lastPPUCTRL
  sta PPUCTRL
  sta 0
  lda #BG_ON|OBJ_ON|LIGHTGRAY
  sta PPUMASK
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  lda #BG_ON|OBJ_ON|LIGHTGRAY
  sta PPUMASK
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  lda #BG_ON|OBJ_ON|LIGHTGRAY
  sta PPUMASK
  lda #BG_ON|OBJ_ON
  sta PPUMASK

  ; set up scrolling after sprite 0 wait
  lda scrollTile
  asl a
  asl a
  asl a
  asl a
  php
  clc
  adc 1
  plp
  tax
  lda #0
  rol a
  ora lastPPUCTRL
  tay
  txa
  and #$F8
  
  ; right now:
  ; A: X scroll value with 3 low bits set to 0
  ; X: X scroll value with all bits valid
  ; Y: PPUCTRL value, including bit 8 of X scroll value

@sprite0endloop:
  bit PPUSTATUS
  bvs @sprite0endloop

@sprite0loop:
  bit PPUSTATUS
  bmi @nosprite0
  bvc @sprite0loop

  ; We want to change the VRAM temporary address before hblank
  ; so that it can get copied to the VRAM address.  But we don't
  ; want to update the low bits (fine X scroll) at this time.
  sta PPUSCROLL
  sta PPUSCROLL
  sty PPUCTRL
  ; and then wait until we're securely in hblank to update the
  ; fine X scroll.
  bit $fff9 ; burn a few cycles
  bit $fff9
  stx PPUSCROLL
  stx PPUSCROLL
  

@nosprite0:
  jmp main_loop


;;
; Waits for a vertical blank.
.proc wait4vbl
  lda retraces
:
  cmp retraces
  beq :-
  rts
.endproc

.proc drawStatus
  lda lastPPUCTRL
  sta PPUCTRL
  
  ; translate tile
  lda cursorBrush
  and #$0F
  asl a
  asl a
  ora #$80

  ; write top row
  ldx #$20
  stx PPUADDR
  ldy #$44
  sty PPUADDR
  sta PPUDATA
  eor #%00000010
  sta PPUDATA
  eor #%00000011
  
  ; write bottom row
  stx PPUADDR
  ldy #$64
  sty PPUADDR
  sta PPUDATA
  eor #%00000010
  sta PPUDATA
  
  
; dead beef
  stx PPUADDR
  lda #$30
  sta PPUADDR
  lda #'D'
  ldx #'E'
  ldy #'A'
  sta PPUDATA
  stx PPUDATA
  sty PPUDATA
  sta PPUDATA
  iny
  sty PPUDATA
  stx PPUDATA
  stx PPUDATA
  inx
  stx PPUDATA
  
  lda #$23
  sta PPUADDR
  lda #$C1
  sta PPUADDR
  lda cursorBrush
  and #$0F
  tax
  lda mtAttributes,x
  asl a
  asl a
  asl a
  asl a
  sta PPUDATA

  ; mark as done
  lda dirtys
  and #<~DIRTY_STATUS
  sta dirtys

.endproc

.macro copyTransferBufferStep offset
  lda xferBufName+offset
  sta PPUDATA
  ora #$01
  sta PPUDATA
.endmacro

;;
; Copies the transfer buffer to xferBufDstHi:Lo.
;
.proc copyTransferBuffer
  lda lastPPUCTRL  ; set writing direction to DOWN
  ora #VRAM_DOWN
  sta PPUCTRL

; copy left half
  lda xferBufDstHi  ; set vram address
  sta PPUADDR
  lda xferBufDstLo
  sta PPUADDR

  .repeat 12, I
    copyTransferBufferStep 11 - I
  .endrepeat

; copy right half
  lda xferBufDstHi
  sta PPUADDR
  lda xferBufDstLo
  ora #1
  sta PPUADDR

  .repeat 12, I
    copyTransferBufferStep 23 - I
  .endrepeat

  rts
.endproc


.proc col2TransferBuffer
  mapSrc = xferBufDstLo
  mapData = 0
  
  lda xferBufCol
  sta mapSrc
  lda #>mapOrigin
  sta mapSrc+1
  ldx #0
  ldy #0
decodeNibblesLoop:
  ; fetch map byte
  lda (mapSrc),y
  sta mapData

  ; decode into two cells
  lsr a
  lsr a
  lsr a
  lsr a  ; now a = bottomNibble
  sta xferBufName,x
  lda mapData
  and #$0F  ; now a = topNibble
  sta xferBufName+1,x

  ; step to next map byte  
  lda mapSrc
  eor #128
  sta mapSrc
  bmi :+
  inc mapSrc+1
:
  inx
  inx
  cpx #12
  bcc decodeNibblesLoop

  ldx #0
expandTilesLoop:
  lda xferBufName,x
  asl a
  asl a
  ora #$80
  sta xferBufName,x
  ora #2
  sta xferBufName+12,x
  inx
  cpx #12
  bcc expandTilesLoop
  
  ; set the address
  lda xferBufCol
  and #$0F
  asl a
  ora #$80
  sta xferBufDstLo
  lda xferBufCol
  and #$10
  lsr a
  lsr a
  ora #$20
  sta xferBufDstHi
  rts
.endproc

.proc setBlock
  ldy #0  ; 0: destination address
  sty 0
  lda cursorY
  ldy cursorX
  lsr a
  php  ; stacked P: top/bottom row status
  ; calculate row base address
  lsr a
  ror 0
  adc #>mapOrigin
  sta 1
  ; calculate top/bottom row mask
  plp
  lda #$0F
  bcc :+
  lda #$F0
:
  sta 2  ; 2: mask
  
  ; make the change
  lda (0),y
  eor cursorBrush
  and 2
  eor cursorBrush
  sta (0),y
  rts
.endproc

.proc readPad
  ldx #1
  stx P1
  dex
  stx P1
  stx joy1
  ldx #8
  lda #$03
  clc
padLoop:
  bit P1
  beq :+
  sec
:
  rol joy1
  dex
  bne padLoop
  rts
.endproc

.proc processAutoRepeat
  lda last_joy1
  eor #$FF
  and joy1
  sta joy1new
  beq noResetDAS
  sta dasKeys
  lda #dasDelay
  sta dasTime
noResetDAS:
  dec dasTime
  bne noRepeatEvent
  lda #dasPeriod
  sta dasTime
  lda dasKeys
  and joy1
  sta dasKeys
  ora joy1new
  sta joy1new
noRepeatEvent:  
  lda joy1
  sta last_joy1
  rts
.endproc

.proc moveCursorByJoy1
  lda #$08
  and joy1new
  beq notUp
  lda cursorY
  cmp #11
  bcs notUp
  inc cursorY
  jsr moveSound
notUp:

  lda #$04
  and joy1new
  beq notDown
  lda cursorY
  beq notDown
  dec cursorY
  jsr moveSound
notDown:

  lda #$02
  and joy1new
  beq notLeft
  
  ;if B is held, change the brush
  lda #$40
  and joy1
  beq @notB
  clc
  lda cursorBrush
  adc #15
  jsr setBrush
  jsr moveSound
  jmp notLeft
@notB:
  lda cursorX
  beq notLeft
  dec cursorX
  jsr moveSound
notLeft:

  lda #$01
  and joy1new
  beq notRight

  ;if B is held, change the brush
  lda #$40
  and joy1
  beq @notB
  clc
  lda cursorBrush
  adc #1
  jsr setBrush
  jsr moveSound
  jmp notRight
@notB:
  lda cursorX
  cmp #127
  bcs notRight
  inc cursorX
  jsr moveSound
notRight:

  lda #$80
  and joy1new
  beq notPut
  jsr setBlock
  lda cursorX
  sta putCol
  jsr putSound
notPut:

  rts
.endproc


.proc setBrush
  and #$0F
  sta cursorBrush
  asl a
  asl a
  asl a
  asl a
  ora cursorBrush
  sta cursorBrush
  lda dirtys
  ora #DIRTY_STATUS
  sta dirtys
  rts
.endproc

.proc moveSound
  lda #$40
  sta P2
  lda #$98
  sta $4000
  lda #8
  sta $4001
  lda #126
  sta $4002
  lda #$18
  sta $4003
  rts
.endproc

.proc putSound
  lda #$40
  sta P2
  lda #$98
  sta $4000
  lda #$08
  sta $4001
  lda #253
  sta $4002
  lda #$28
  sta $4003
  rts
.endproc

.proc moveCameraTowardCursor
  lda cursorX
  sec
  sbc scrollTileTarget
  bcc wayLeft
  cmp #7
  bcs notLeft
wayLeft:
  lda scrollTileTarget
  beq :+
  dec scrollTileTarget
:
  rts
notLeft:
  cmp #9
  bcc notRight
  lda scrollTileTarget
  cmp #112
  beq :+
  inc scrollTileTarget
:
notRight:
  rts
.endproc

.proc moveCameraTowardTarget
  ; clear transfer buffer
  lda #$FF
  sta xferBufCol
  
  lda scrollSubTarget
  sec
  sbc scrollSub
  sta 0
  lda scrollTileTarget
  sbc scrollTile
  bcs handlePositive
  
  ; handle negative movement
  lsr a
  ror 0
  lsr a
  ror 0
  ora #$C0
  cmp #255
  bcs negNotTooFar
  lda #0
  sta 0
negNotTooFar:
  ; by now we know that we are adding (-256) + r0 pixels to scrollSub
  lda 0
  clc
  adc scrollSub
  sta scrollSub
  bcs negNoPrevious

  ;rts
  ; scrolling actual tile to left: schedule a transfer
  dec scrollTile
  lda scrollTile
  sta xferBufCol
negNoPrevious:
  rts

handlePositive:
  ; bias rounding up
  tax
  lda 0
  clc
  adc #3
  sta 0
  txa
  adc #0

  lsr a
  ror 0
  lsr a
  ror 0
  cmp #0
  beq posNotTooFar
  lda #$FF
  sta 0
posNotTooFar:
  ; by now we know that we are adding r0 pixels to scrollSub
  clc
  lda 0
  adc scrollSub
  sta scrollSub
  bcc posNoNext

  ; scrolling actual tile to right: schedule a transfer
  inc scrollTile
  lda scrollTile
  clc
  adc #16
  cmp #128
  bcs posNoNext
  sta xferBufCol
  
posNoNext:
  rts
.endproc

.proc loadInitialPalette
  ldx #$00
  stx PPUMASK
  stx PPUCTRL
  lda #$3F
  sta PPUADDR
  stx PPUADDR
loop:
  lda initialPalette,x
  sta PPUDATA
  inx
  cpx #$20
  bcc loop
  rts
.segment "RODATA"
initialPalette:
  .byt $0f,$00,$10,$30,$0f,$06,$16,$26,$0f,$0A,$1A,$2A,$0f,$02,$12,$22
  .byt $0f,$00,$10,$30,$0f,$37,$28,$07,$0f,$0A,$1A,$2A,$0f,$02,$12,$22
.segment "CODE"
.endproc

.export copyAttributes
.proc copyAttributes
  lda lastPPUCTRL
  ora #VRAM_DOWN
  sta PPUCTRL

  ; compute destination address
  lda xferBufDstHi
  ora #$23
  tay

  lda xferBufCol
  lsr a
  and #$CF
  ora #$C8
  tax
  clc

  sty PPUADDR
  stx PPUADDR
  txa
  adc #$08
  tax
  lda xferBufAttr+5
  sta PPUDATA
  lda xferBufAttr+1
  sta PPUDATA

  sty PPUADDR
  stx PPUADDR
  txa
  adc #$08
  tax
  lda xferBufAttr+4
  sta PPUDATA
  lda xferBufAttr+0
  sta PPUDATA
  
  sty PPUADDR
  stx PPUADDR
  txa
  adc #$08
  tax
  lda xferBufAttr+3
  sta PPUDATA

  sty PPUADDR
  stx PPUADDR
  lda xferBufAttr+2
  sta PPUDATA

  rts
.endproc


;
; 2 | y
; --+--
; 4 | x

.proc genAttributes
.segment "CODE"
  lda #>mapOrigin
  sta 1
  lda xferBufCol
  and #%11111110
  sta 0
  ldx #0
loop:
  stx 5
  ; get tile numbers for left half
  ldy #0
  lda (0),y
  sta 4
  and #$0F
  sta 2
  lda 4
  lsr a
  lsr a
  lsr a
  lsr a
  sta 4
  
  ; get tile numbers for right half
  iny
  lda (0),y
  sta 3
  and #$0F
  tay
  lda 3
  lsr a
  lsr a
  lsr a
  lsr a
  tax
  
  ; compose attribute column
  lda mtAttributes,x
  asl a
  asl a
  ldx 4
  ora mtAttributes,x
  asl a
  asl a

  ora mtAttributes,y
  asl a
  asl a
  ldx 2
  ora mtAttributes,x
  
  ; queue up byte
  
  ldx 5
  sta xferBufAttr,x
  
  ; advance to next map element
  lda 0
  eor #$80
  sta 0
  bmi :+
  inc 1
:
  inx
  cpx #6
  bcc loop
  
  rts
.endproc

.segment "RODATA"
mtAttributes:
  .byt 3, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.segment "CODE"
  
;;
; Sets the X and Y of a sprite and reports whether it was clipped.
; @param r8 x subtile (1/16 pixel) offset
; @param r9 x tile offset
; @param r10 y height in subtiles (1/16 pixel)
; @param r11 y height in tiles
; @param X offset in shadow OAM to store X and Y
; @return C flag set iff the X and Y were set
.proc setSpriteXY

  ; calculate X
  sec
  lda 8
  sbc scrollSub
  sta 8
  lda 9
  sbc scrollTile

  ; clip to left and right bounds of screen
  bcc dontDraw
  cmp #16
  bcs dontDraw

  ; convert X to pixels
  lsr a
  ror 8
  lsr a
  ror 8
  lsr a
  ror 8
  lsr a
  ror 8

  ; calculate Y
  sec
  lda #0
  sbc 10
  sta 10
  lda #13
  sbc 11

  ; convert Y to pixels
  lsr a
  ror 10
  lsr a
  ror 10
  lsr a
  ror 10
  lsr a
  ror 10

  ; fill in X and Y of sprite

  lda 10
  sta OAM,x
  lda 8
  sta OAM+3,x

  sec
  rts

dontDraw:
  clc
  rts
.endproc


.segment "INESHDR"
.incbin "src/768.hdr"
.segment "CHR"
.incbin "tilesets/768.chr"
