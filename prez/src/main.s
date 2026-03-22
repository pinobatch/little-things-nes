.include "nes.inc"
.include "global.inc"

.import demo_tileset
.import blastCol
.import limitScrollingTo16, updateColDecodeX
.import read_pads
.import colDecodeReal
.import clearRestOfSprites, drawMapLocator


.segment "ZEROPAGE"
colDecodeBuf: .res COL_HEIGHT
colDecodeX: .res 1
colDecodePage: .res 1
slidingWindowBaseX: .res 1
slidingWindowBasePage: .res 1
camX: .res 1
camPage: .res 1
lastCamX: .res 1
lastCamPage: .res 1
debugHex1: .res 1
cur_keys: .res 2
new_keys: .res 2

.segment "CODE"

.proc main
  ldy #0
  sty main+1
  lda #<demo_tileset
  sta 0
  lda #>demo_tileset
  sta 1
  lda #$20
  sta 2
  sty PPUADDR
  sty PPUADDR
@copyloop:
  lda (0),y
  sta PPUDATA
  iny
  bne @copyloop
  inc 1
  dec 2
  bne @copyloop
  
  lda #$23
  sta PPUADDR
  ldx #$C0
  stx PPUADDR
  ldx #0
@copystatusattrloop:
  lda statusBarAttrs,x
  sta PPUDATA
  inx
  cpx #8
  bcc @copystatusattrloop

  jsr setupStatusBar
  lda PPUSTATUS
  jsr blitStatusBar
  
  lda #0
  sta slidingWindowBasePage
  lda #0
  sta slidingWindowBaseX
  lda #0
  sta camPage
  lda #0
  sta camX
  
preloadLevel:
  lda slidingWindowBasePage
  clc
  adc #2
  sta colDecodePage
  lda slidingWindowBaseX
  sta colDecodeX
@preloadLoop:
  dec colDecodeX
  bpl :+
    lda #15
    sta colDecodeX
    dec colDecodePage
  :
  jsr colDecodeReal
  jsr blastCol
  lda slidingWindowBaseX
  cmp colDecodeX
  lda slidingWindowBasePage
  sbc colDecodePage
  bcc @preloadLoop

; preload actors
  lda #0
  sta actorPage+0
  lda #$60
  sta actorXHi+0
  lda #$70
  sta actorYHi+0
  lda #0
  sta actorAniFrame

  lda #VBLANK_NMI
  sta PPUCTRL
  lda #$FF
  sta nmis
  lda PPUSTATUS
mainloop:
  ;; FIRST HALF OF MAIN LOOP: starts during draw time

  ; move camera
  lda cur_keys
  and #KEY_RIGHT
  beq :+
  lda #$00
  sta actorFaceDir+0
  clc
  lda actorXHi+0
  adc #2
  sta actorXHi+0
  lda actorPage+0
  adc #0
  sta actorPage+0
:

  ; move an object
  lda cur_keys
  and #KEY_LEFT
  beq :+
  lda #$40
  sta actorFaceDir+0
  sec
  lda actorXHi+0
  sbc #2
  sta actorXHi+0
  lda actorPage+0
  sbc #0
  sta actorPage+0
  bcs :+
    lda #0
    sta actorXHi+0
    sta actorPage+0
:

  jsr moveCameraTowardActor0
  jsr limitScrollingTo16
  jsr updateColDecodeX
  jsr colDecodeReal
  jsr drawMapLocator

  ldx #0
  lda actorFaceDir,x
  jsr putActor

  lda #$F0
  sta putSpriteX
  lda #$8F
  sta putSpriteY
  lda #3
  sta putSpriteW
  lda #4
  sta putSpriteH
  lda #$04  ; DPCF
  sta putSpriteTile
  lda cur_keys
  and #$C0
  ora #$02
  sta putSpriteAttr
  lda #1
  sta putSpritePage
  jsr putSprite

  lda #$98
  sta putSpriteX
  lda #$70
  sta putSpriteY
  lda #2
  sta putSpriteW
  lda #4
  sta putSpriteH
  lda #$10
  sta putSpriteTile
  lda cur_keys
  and #$02
  beq :+
    lda #$40
  :
  ora #$03
  sta putSpriteAttr
  lda #1
  sta putSpritePage
  jsr putSprite

  jsr clearRestOfSprites
  
  lda #223
  sta OAM+248
  sta OAM+252
  lda debugHex1
  lsr a
  lsr a
  lsr a
  lsr a
  jsr hexdig
  sta OAM+249
  lda #%00000000  ; palette 0
  sta OAM+250
  sta OAM+254
  lda #16
  sta OAM+251
  lda debugHex1
  and #$0F
  jsr hexdig
  sta OAM+253
  lda #24
  sta OAM+255

  ;; SECOND HALF OF MAIN LOOP: the part that starts at vertical blank

  ; wait for vblank
  lda nmis
:
  cmp nmis
  beq :-
  lda PPUSTATUS

  lda colDecodePage
  bmi :+
    jsr blastCol  ; copy column
  :
  lda #0        ; copy sprites
  sta OAMADDR
  lda #>OAM
  sta OAM_DMA

  lda #8        ; turn on screen
  sta PPUSCROLL
  lda #0
  sta PPUSCROLL
  lda #VBLANK_NMI|OBJ_1000|NT_2000|BG_0000
  sta PPUCTRL
  lda #%00011110
  sta PPUMASK

  ; end of vblank code.  We have about 30 lines before sprite 0 hit;
  ; use that for some code that will take a predictable amount of time.
  jsr read_pads

  ; now we wait for sprite 0
@wait4endvbl:
  bit PPUSTATUS
  bvs @wait4endvbl
@wait4s0:
  bit PPUSTATUS
  bmi @s0giveup
  bvc @wait4s0
  ldy #26
:
  dey
  bne :-
  lda camPage
  and #1
  ora #VBLANK_NMI|OBJ_1000|BG_0000
  sta PPUCTRL
  
  lda camX
.if 0
  lda #$1F
  sta PPUMASK
  sta PPUMASK
  lda $FFFF
  lda #$1E
  sta PPUMASK
  sta PPUMASK  
.else
  and #$F8  ; the low 3 bits take effect immediately; the upper bits take effect at the end of the scanline
  sta PPUSCROLL
  sta PPUSCROLL
  lda $FFFF  ; dummy read to space out the writes
  lda camX
  sta PPUSCROLL
  sta PPUSCROLL
.endif

@s0giveup:
  jmp mainloop
.endproc

.if COL_HEIGHT<>12
.error "die"
.endif

statusBarCopyBuf = copyBuf2
NUMBERS_TILE_BASE = $10
LIVES_TILE = $1B
CASH_TILE = $1C
CLOCK_TILE = $1D
CLOCK_SEP_TILE = $1A
EMPTY_HEALTH_TILE = $1E
FULL_HEALTH_TILE = $1F
;
;01234567890123456789012345678901
;  x 3 **--  $124  T3:56  18790
.proc setupStatusBar
  lda #0
  ldx #31
clear_out:
  lda statusBarData,x
  sta statusBarCopyBuf,x
  dex
  bpl clear_out
  rts
.endproc

.proc blitStatusBar
  lda #$20
  sta PPUADDR
  lda #$60
  sta PPUADDR
  lda #VBLANK_NMI
  sta PPUCTRL
  ldx #statusBarCopyBuf-copyBuf0
  .repeat 32,I
    lda copyBuf0+I,x
    sta PPUDATA
  .endrepeat
  rts
.endproc

.proc hexdig
  cmp #10
  bcc :+
    adc #214
    rts
  :
  adc #240
  rts
.endproc

.segment "RODATA"

statusBarData:
  .byt $00,$00,$00,LIVES_TILE,$00,NUMBERS_TILE_BASE+3,$00
  .byt FULL_HEALTH_TILE,FULL_HEALTH_TILE,EMPTY_HEALTH_TILE,EMPTY_HEALTH_TILE,$00,$00
  .byt CASH_TILE,NUMBERS_TILE_BASE+1,NUMBERS_TILE_BASE+2,NUMBERS_TILE_BASE+4,$00,$00
  .byt CLOCK_TILE,NUMBERS_TILE_BASE+3,CLOCK_SEP_TILE
  .byt NUMBERS_TILE_BASE+5,NUMBERS_TILE_BASE+6,$00,$00
  .byt NUMBERS_TILE_BASE+1,NUMBERS_TILE_BASE+8,NUMBERS_TILE_BASE+7
  .byt NUMBERS_TILE_BASE+9,NUMBERS_TILE_BASE+0,$00
statusBarAttrs:
  .byt $C0,$40,$50,$10,$40,$00,$00,$00

