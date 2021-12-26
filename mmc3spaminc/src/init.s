.include "nes.inc"
.include "global.inc"

.segment "ONCE"
.proc reset_handler
  ; The very first thing to do when powering on is to put all sources
  ; of interrupts into a known state.
  sei             ; Disable interrupts
  ldx #$00
  stx PPUCTRL     ; Disable NMI and set VRAM increment to 32
  stx PPUMASK     ; Disable rendering
  stx $4010       ; Disable DMC IRQ
  stx $E000       ; Disable MMC3 IRQ
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

  ; Burn 29700 cycles before next vblank: init the mapper and
  ; clear zero page
  cld
  ldx #mmc3_default_banks_end - mmc3_default_banks - 1
  :
    stx $8000
    lda mmc3_default_banks,x
    sta $8001
    dex
    bpl :-
  inx
  stx $A000  ; vertical mirroring
  stx $E000  ; disable IRQ
  txa
  clear_zp:
    sta $00,x
    inx
    bne clear_zp

vwait2:
  bit PPUSTATUS  ; After the second vblank, we know the PPU has
  bpl vwait2     ; fully stabilized.
  
  ; There are two ways to wait for vertical blanking: spinning on
  ; bit 7 of PPUSTATUS (as seen above) and waiting for the NMI
  ; handler to run.  Before the PPU has stabilized, you want to use
  ; the PPUSTATUS method because NMI might not be reliable.  But
  ; afterward, you want to use the NMI method because if you read
  ; PPUSTATUS at the exact moment that the bit turns on, it'll flip
  ; from off to on to off faster than the CPU can see.
  jmp main
.endproc

mmc3_default_banks:
  .byte 0, 2, 2, 2, 2, 2, 0, 1
mmc3_default_banks_end:
