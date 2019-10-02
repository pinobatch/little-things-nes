;
; Simple sprite demo for NES
; Copyright 2011-2014 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.include "nes.inc"
.include "global.inc"

OAM = $0200
DOWN_DOES_IRQ = 0

.segment "ZEROPAGE"
nmis:          .res 1
out4016value:  .res 1
time_since_irq:.res 1

.segment "CODE"
;;
; This NMI handler is good enough for a simple "has NMI occurred?"
; vblank-detect loop.
.proc nmi_handler
  inc nmis
  rti
.endproc

; Test the
.proc irq_handler
  pha
  lda #30
  sta time_since_irq
  pla
  rti
.endproc

.proc main

  ; Now the PPU has stabilized, and we're still in vblank.  Copy the
  ; palette right now because if you load a palette during forced
  ; blank (not vblank), it'll be visible as a rainbow streak.
  jsr load_main_palette

  ; While in forced blank we have full access to VRAM.
  ; Load the nametable (background map).
  jsr draw_bg

forever:

  ; Read controller
  jsr read_fourscore
  lda out4016value
  sta $4016
  
  ; Check for IRQs
  cli
  nop
  nop
  sei
  dec time_since_irq
  bpl :+
    inc time_since_irq
  :
  
  ; Act on player 1 bits.
  ; An external device counts reads from each controller port
  ; and displays bit 0 of the count.  A and B perform an extra
  ; read to toggle the count.
  bit new_keys
  bpl notA
    lda $4016
  notA:
  bvc notB
    lda $4017
  notB:

  ; An external device displays the D2-D0 outputs on the DA15
  ; port.  Left, Up, and Right toggle the state of the outputs
  ; while the controllers aren't being read.
  lda new_keys
  lsr a
  bcc notRight
    lda #$01
    eor out4016value
    sta out4016value
    bcs pad_done
  notRight:
  lsr a
  bcc notLeft
    lda #$04
    eor out4016value
    sta out4016value
    bcs pad_done
  notLeft:
  lsr a
.if ::DOWN_DOES_IRQ
  bcc notDown
    ; cc65 doesn't support the argument to brk, so I have to use a
    ; .dbyt with high byte $00 instead
    .dbyt $0069
    bcs pad_done
  notDown:
.endif
  lsr a
  bcc notUp
    lda #$02
    eor out4016value
    sta out4016value
    bcs pad_done
  notUp:
  pad_done:

  ; Wait for vblank and update background
  lda nmis
vw3:
  cmp nmis
  beq vw3

  jsr update_pins
  
  ; Turn the screen on
  ldx #0
  ldy #0
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  clc
  jsr ppu_screen_on
  jmp forever
.endproc

.proc load_main_palette
  ; seek to the start of palette memory ($3F00-$3F1F)
  ldx #$3F
  stx PPUADDR
  ldx #$00
  stx PPUADDR
copypalloop:
  lda initial_palette,x
  sta PPUDATA
  inx
  cpx #4
  bcc copypalloop
  rts
.endproc

.segment "RODATA"
initial_palette:
  .byt $0F,$00,$10,$20

; Include the CHR ROM data
.segment "CHR"
  .incbin "obj/nes/bggfx.chr"
