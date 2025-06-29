;
; MMC3 init code
; Copyright 2025 Damian Yerrick
; SPDX-License-Identifier: Zlib
;
.include "nes.inc"
.import main
.exportzp mmc3_reg_values, mmc3_ctrl_value
.export reset_handler

.zeropage
mmc3_reg_values: .res 8
mmc3_ctrl_value: .res 1

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
  lda #$40
  sta P2          ; Disable APU Frame IRQ
  lda #$0F
  sta SNDCHN      ; Disable DMC playback, initialize other channels
  bit SNDCHN      ; Acknowledge DMC IRQ
  sta $E000       ; Disable MMC3 programmable interval timer IRQ

vwait1:
  bit PPUSTATUS   ; It takes one full frame for the PPU to become
  bpl vwait1      ; stable.  Wait for the first frame's vblank.

  ; Over the next 29700 cycles, get the rest of the chipset into a
  ; known state.  Start by turning off BCD addition for compatibility
  ; with poorly made famiclones.
  cld

  ; Clear zero page
  inx
  stx $A000      ; Set vertical mirroring
  stx mmc3_ctrl_value
  txa
clear_zp:
  sta $00,x
  inx
  bne clear_zp

  ; Set initial PRG and CHR banks
  ldx #mmc3init_values_end-mmc3init_values-1
mmc3init:
  stx $8000
  lda mmc3init_values,x
  sta mmc3_reg_values,x
  sta $8001
  dex
  bpl mmc3init

vwait2:
  bit PPUSTATUS  ; After the second vblank, we know the PPU has
  bpl vwait2     ; fully stabilized.

  ; Clock PA12 a few times to unjam the PIT
  ldx #$10
  txa
pa12loop:
  sta PPUADDR
  sta PPUADDR
  eor #$10
  dex
  bne pa12loop
  
  ; We're about 250 cycles into vblank, giving enough time to write
  ; a palette.  From here on out, vblank waiting is done with NMI.
  jmp main
.endproc

mmc3init_values:
  .byte 0, 2, 4, 5, 6, 7  ; initial CHR banks
  .byte 0, 1              ; initial PRG banks
mmc3init_values_end:
