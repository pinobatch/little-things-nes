.include "global.inc"

.segment "ZEROPAGE"

spriteMovementPhase: .res 1
spriteCurCel: .res 1
spriteX: .res 1

.segment "RODATA"
studioPalette:
  .byt $30,$10,$00,$3B, $30,$10,$00,$0F, $30,$0F,$0F,$0F, $30,$0F,$0F,$0F
  .byt $30,$38,$16,$0F, $30,$0F,$0F,$0F, $30,$0F,$0F,$0F, $30,$08,$37,$38

  
.proc loadStudio
  lda #0
  sta PPUMASK
  lda #$3F
  sta PPUADDR
  ldx #0
  stx PPUADDR
  :
    lda studioPalette,x
    sta PPUDATA
    inx
    cpx #32
    bcc :-
  ldy #0
  jsr loadCHR
  ldy #2
  jsr loadCHR
  ldy #3
  jmp loadCHR
.endproc

.proc setupCopy160
  ; compute source address
  lda spriteMovementPhase
  beq :+
  lda #160
:
  clc
  adc 0
  sta 0
  lda 1
  adc #0
  sta 1
  
  ; copy 160 bytes
  ldy #159
  loop:
    lda (0),y
    sta emblemPixels,y
    dey
    bne loop
  lda (0),y
  sta emblemPixels

  ; compute destination address
  lda spriteMovementPhase
  beq :+
  lda #160
:
  sta xferBufferDstLo
  lda #$10
  sta xferBufferDstHi

  lda spriteCurCel
  and #1
  beq notOddCel
    clc
    lda #64
    adc xferBufferDstLo
    sta xferBufferDstLo
    lda #1
    adc xferBufferDstHi
    sta xferBufferDstHi
  notOddCel:

  ; set length of copy (10 tiles)
  lda #10
  sta xferBufferLen
  rts
.endproc

.proc updateWeebleAnim
  lda spriteMovementPhase
  
  ; if at time 0 or 1 of a cel, load tile data
  lda spriteMovementPhase
  cmp #2
  bcs not1
    lda spriteCurCel
    jsr getSpriteCelTileData
    jsr setupCopy160

    ; if at time 1 of a cel, also load oam data
    lda spriteMovementPhase
    cmp #1
    bne not1
      lda #47
      sta 12
      lda spriteCurCel
      and #1
      beq notOddCel
        lda #20
      notOddCel:
      ora #1
      sta 13
      lda #%00000011
      sta 14
      lda spriteX
      sta 15
      lda spriteCurCel
      jsr drawSpriteCel
  not1:
  
  ; go to next time
  inc spriteMovementPhase
  lda spriteMovementPhase
  cmp #5
  bcc notNextFrame

    ; move sprite forward
    lda spriteCurCel
    lsr a
    lda #3
    adc spriteX
    sta spriteX

    ; go to next frame
    lda #0
    sta spriteMovementPhase
  
    inc spriteCurCel
    lda spriteCurCel
    cmp #12
    bcc notNextFrame
      lda #0
      sta spriteCurCel
  notNextFrame:

  rts
.endproc