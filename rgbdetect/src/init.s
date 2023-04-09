.include "nes.inc"
.include "global.inc"

.segment "STARTUP"
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

  ; improve compatibility with debuggers and certain famiclones
  cld

  ; During 29700 cycles to burn until the second frame's vblank,
  ; put the hardware in a known state.  Start with the mapper.
  ; This is a polyglot for MMC1 and MMC3, as requested by TmEE
  ; in <https://forums.nesdev.org/viewtopic.php?p=287479#p287479>

  ; $80-$87 (MMC1): continuously reset shift register
  ; $80-$87 (MMC3): select window and temporarily swap CHR ROM pages
  ldx #$87  ; continuously reset MMC1 shift register during this
  mmc3loop:
    stx $8000
    lda mmc3_init_values-128,x
    sta $8001
    dex
    bmi mmc3loop

  ; init MMC1 without affecting MMC3
  lda #$80
  sta $E000  ; MMC1: reset shift register; MMC3: IRQ off
  asl a
  sta $8000  ; MMC1: 1-screen mirroring, 32K PRG banks, 8K CHR banks
  sta $8000  ; MMC3: unswap CHR ROM pages and select window 0
  sta $8000
  sta $8000
  sta $8000

  ; Clear OAM and the zero page here.  Comporomise between "clear
  ; everything for reproducibility" and "clear nothing for runtime
  ; detection of uninitialized variables" camps.
  tax
clear_zp:
  sta $00,x
  inx
  bne clear_zp
  jsr ppu_clear_oam  ; clear OAM from X to end and set X to 0

vwait2:
  bit PPUSTATUS  ; After the second vblank, we know the PPU has
  bpl vwait2     ; fully stabilized.  Henceforth wait for vblank
                 ; via NMI instead of $2002.
  jmp main       ; main is entered at the start of vblank
.endproc

mmc3_init_values:
  .byte 0, 2, 4, 5, 6, 7, 0, 1
