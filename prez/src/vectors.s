.include "nes.inc"
.include "global.inc"

.segment "ZEROPAGE"
nmis: .res 1

.segment "CODE"

.proc start
  bit PPUSTATUS
  cld

  vwait1:  ; wait for PPU warm-up #1
    bit PPUSTATUS
    bpl vwait1

  ; init sound
  lda #$0F
  sta SNDCHN
  lda #$08
  sta $4001
  sta $4005
  ldx #0
  txa
  clearRAM1:
    sta $00,x
    sta $100,x
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x
    inx
    bne clearRAM1

  vwait2:
    bit PPUSTATUS
    bpl vwait2
  ldy #$3F
  sty PPUADDR
  sta PPUADDR
  copy_pal:
    lda initial_palette,x
    sta PPUDATA
    inx
    cpx #$20
    bne copy_pal

  ldx #$24
  stx PPUADDR
  lda #0
  sta PPUADDR
  ldy #2
  clearOneNT:
    ldx #224
    clearNametableBody:
      sta PPUDATA
      sta PPUDATA
      sta PPUDATA
      sta PPUDATA
      dex
      bne clearNametableBody
    ldx #64
    lda #1
    clearNametableBottomRows:
      sta PPUDATA
      dex
      bne clearNametableBottomRows
    ldx #64
    lda #%10101010
    clearAttrs:
      sta PPUDATA
      dex
      bne clearAttrs
    dey
    bne clearOneNT

  jmp main

initial_palette:
  .byt $22,$00,$10,$30,$22,$18,$28,$38,$22,$08,$19,$29,$22,$06,$16,$36
  .byt $22,$0F,$38,$27,$22,$0F,$16,$27,$22,$0F,$1a,$27,$22,$0F,$12,$27
.endproc

.segment "VECTORS"
nmi:
  inc nmis
irq:
  rti
reset:
  sei
  ldx #0  ; init PPU
  stx PPUCTRL
  stx PPUMASK
  dex  ; set up stack pointer
  txs
  jmp start

  .res $1A+nmi-*
  .addr nmi, reset, irq

.segment "INESHDR"
  .byt "NES",$1A
  .byt 8, 0, $21, 0
  .byt 0, 0, 0, 0, 0, 0, 0, 0
