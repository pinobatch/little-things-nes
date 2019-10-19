.segment "CODE"
.include "nes.inc"

.importzp retraces
.import calcPalette, xfer, drawTitle, convertText, textBuf, setTextXferRow
.import curTruthTable
.export main

.proc main
  jsr drawTitle

  lda #$0D
  sta curTruthTable
  jsr calcPalette
  jsr mainScreenTurnOn

  ; test: draw text
  ldx #63
:
  lda helloMsg,x
  sta textBuf,x
  dex
  bpl :-
  ldx #64
  jsr convertText

  ldy #$22
  lda #$C0
  ldx #0
  jsr setTextXferRow
  ldy #$23
  lda #$00
  ldx #1
  jsr setTextXferRow



  jsr mainScreenTurnOn

die:
  jmp die
.endproc

.proc mainScreenTurnOn
  lda #VBLANK_NMI
  sta PPUCTRL
  lda retraces
:
  cmp retraces
  beq :-
  jsr xfer

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #VBLANK_NMI
  sta PPUCTRL

  lda #BG_ON
  sta PPUMASK
  rts
.endproc

helloMsg:
  .byt "  bc A = FALSE; B = TRUE        "
  .byt "  `a A LIMP B = FALSE           "