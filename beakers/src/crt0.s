.p02
.import main
.exportzp retraces

.include "nes.inc"

.segment "ZEROPAGE"
retraces: .res 1

.segment "INESHDR"
  .byt "NES", $1a
  .byt 1, 1, 0
  

.segment "CODE"
.proc reset
  sei
  ldx #0
  stx PPUCTRL
  stx PPUMASK
  dex
  txs
  lda PPUSTATUS  ; clear vblank flag
  lda #$40
  sta P2         ; disable apu irq
  lda #$0F
  sta SNDCHN     ; enable sound
  lda #$08
  sta $4001      ; disable ch1/ch2 sweep
  sta $4005
  inx            ; get 0 back into A and X
  txa
  sta $4000      ; clear volumes
  sta $4004
  sta $4008
  sta $400C
@vwait1:
  bit PPUSTATUS  ; wait for warmup1
  bpl @vwait1
@clearRAM:
  sta 0,x
  sta $100,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  inx
  bne @clearRAM
@vwait2:
  bit PPUSTATUS  ; wait for warmup2
  bpl @vwait2
  ldy #$24
  sty PPUADDR    ; clear $2400-$2BFF
  sta PPUADDR    ; works in either mirroring
@clearVRAM:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  inx
  bne @clearVRAM
  jmp main
.endproc

nmi:
  inc retraces
irq:
  rti

.segment "VECTORS"
  .addr nmi, reset, irq