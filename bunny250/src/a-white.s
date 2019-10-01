;
; A=white for NES
; Copyright 2013 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.include "nes.inc"

.segment "ZEROPAGE"
nmis:          .res 1

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 1          ; PRG ROM size in 16384 byte units
  .byt 0          ; CHR RAM!
  .byt $00        ; mirroring type and mapper number lower nibble
  .byt $00        ; mapper number upper nibble

.segment "VECTORS"
.addr nmi, reset, irq

.segment "CODE"
;;
; This NMI handler is good enough for a simple "has NMI occurred?"
; vblank-detect loop.
.proc nmi
  inc nmis
  rti
.endproc

; A null IRQ handler
.proc irq
  rti
.endproc

; 
.proc reset
  ; put all sources of interrupts into a known state.
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

  ; Clear OAM and the zero page here.
  ldx #0
  txa
clear_zp:
  sta $00,x
  inx
  bne clear_zp
  
vwait2:
  bit PPUSTATUS  ; After the second vblank, we know the PPU has
  bpl vwait2     ; fully stabilized.


  ; Main loop: read button A on controller 1 and update $3F00
  lda #VBLANK_NMI|VRAM_DOWN
  sta PPUCTRL
  
forever:
  ldx #$3F
  stx PPUADDR
  inx
  stx PPUADDR
  ldx #$0F

  ; Read controller
  lda #$01
  sta $4016
  lsr a
  sta $4016
  lda $4016
  and #$03
  beq is_not_pressed
  ldx #$30
is_not_pressed:
  stx PPUDATA
  stx $4011
  jmp forever
.endproc

