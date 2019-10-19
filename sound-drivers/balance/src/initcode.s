.include "nes.inc"

BOOTEDSIG0 = $b0
BOOTEDSIG1 = $07
BOOTEDSIG2 = $ed

.segment "CODE"

.export nes_start
.import main, irq, nmi
nes_start:
  sei
  cld

;; OMIT: Should reset the mapper here.

;; Disable frame IRQ, picture, and sound, and set up stack pointer
  ldx #$40
  stx JOY2
  ldx #0
  stx SND_CHN
  stx PPUCTRL
  stx PPUMASK
  dex
  txs

;; OMIT: Should initialize the lockout defeat here on carts that
;; need it controlled in software (e.g. Color Dreams).

;; Wait for the PPU to warm up.  Must read two vblanks from $2002
;; before any writes to $2003-$2007 or $4014.
@vbl1:
  bit PPUSTATUS
  bpl @vbl1

;; While waiting for the PPU to warm up, prepare the CPU.
;; First clear most of CPU RAM.
  lda #0
  tax
@clrloop:
  sta $00,x
  sta $100,x
  sta $200,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  inx
  bne @clrloop

;; Clear reset-saved CPU RAM
  lda #BOOTEDSIG0
  ldx #BOOTEDSIG1
  ldy #BOOTEDSIG2
  cmp $700
  bne @clrsave
  cpx $701
  bne @clrsave
  cpy $702
  beq @vbl2
@clrsave:
  sta $700
  stx $701
  sty $702
  ldx #3
  lda #0
@clrsaveloop:
  sta $700,x
  inx
  bne @clrsaveloop

;; Init sweep unit so that periods >$3FF work.
  lda #$08
  sta SQ1_SWEEP
  sta SQ2_SWEEP

;; Turn on all sound channels' length counters.
  lda #$0F
  sta SND_CHN

;; Second of two waits for the PPU to warm up
@vbl2:
  bit PPUSTATUS
  bpl @vbl2

;; Now we're free to write to the PPU, so clear the nametables.
;; Except on 1-screen mapper and 4-screen mappers, writing to
;; $2400-$2BFF should clear everything.
  ldx #$24
  stx PPUADDR
  lda #0
  sta PPUADDR
  tax
@ppuclrloop:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA

  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  inx
  bne @ppuclrloop

;; Current state:  palette not written, OAM address set but data not
;; written, blank nametables, CHR RAM data not written (on applicable
;; carts), blank CPU RAM (except $703-$7FF if soft reset), video and
;; sound turned off, SP = $01FF, 4-step APU frame counter w/o IRQ,
;; PPUCTRL = #$00
  jmp main

.segment "VECTORS"
  .addr nmi, nes_start, irq
