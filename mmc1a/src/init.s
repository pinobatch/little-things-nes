.include "nes.inc"
.include "global.inc"

.segment "CODE"
.proc reset_handler
  ; The very first thing to do when powering on is to put all sources
  ; of interrupts into a known state.
  sei             ; Disable interrupts
  ldx #$00
  stx PPUCTRL     ; Disable NMI and set VRAM increment to 32
  stx PPUMASK     ; Disable rendering
  stx $4010       ; Disable DMC IRQ
  dex             ; Subtracting 1 from $00 gives $FF, which is a
  txs             ; quick way to set the stack pointer to $01FF
  bit PPUSTATUS   ; Acknowledge stray vblank NMI across reset
  bit SNDCHN      ; Acknowledge DMC IRQ
  lda #$40
  sta P2          ; Disable APU Frame IRQ
  lda #$0F
  sta SNDCHN      ; Disable DMC playback, initialize other channels

vwait1:
  bit PPUSTATUS   ; It takes one full frame for the PPU to become
  bpl vwait1      ; stable.  Wait for the first frame's vblank.

  ; Burn 29700 cycles until the second frame's vblank by setting
  ; up the rest of the chipset.
  ; First turn off BCD for famiclone compatibility
  cld

  ; Clear OAM and the zero page here.
  ; We don't copy the cleared OAM to the PPU until later.
  ldx #0
  txa
clear_zp:
  sta $00,x
  inx
  bne clear_zp

  ; Do no mapper initialization because we want to test the
  ; state at power-up

vwait2:
  bit PPUSTATUS  ; After the second vblank, we know the PPU has
  bpl vwait2     ; fully stabilized.  Use NMI from here on out.
  jmp main
.endproc

