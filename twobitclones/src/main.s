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

.segment "ZEROPAGE"
nmis:          .res 1
oam_used:      .res 1  ; starts at 0
cur_keys:      .res 2
new_keys:      .res 2

.segment "CODE"
;;
; This NMI handler is good enough for a simple "has NMI occurred?"
; vblank-detect loop.  But sometimes there are things that you always
; want to happen every frame, even if the game logic takes far longer
; than usual.  These might include music or a scroll split.  In these
; cases, you'll need to put more logic into the NMI handler.
.proc nmi_handler
  inc nmis
  rti
.endproc

; A null IRQ handler that just does RTI is useful to add breakpoints
; that survive a recompile.  Set your debugging emulator to trap on
; reads of $FFFE, and then you can BRK $00 whenever you need to add
; a breakpoint.
;
; But sometimes you'll want a non-null IRQ handler.
; On NROM, the IRQ handler is mostly used for the DMC IRQ, which was
; designed for gapless playback of sampled sounds but can also be
; (ab)used as a crude timer for a scroll split (e.g. status bar).
.proc irq_handler
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

replay:
  lda #BG_0000|OBJ_1000
  sta PPUCTRL  ; no NMI to avoid Genesis laryngitis

  jsr play2b_setup_channels
  lda #>intro_w2b
  sta src_hi
  lda #>(intro_w2b_end-intro_w2b)
  sta pages_left
  lda #VOLTAB_ALL
  sta volume_table_base
  jsr play2b_play_wave
  lda #>swapped_w2b
  sta src_hi
  lda #>(swapped_w2b_end-swapped_w2b)
  sta pages_left
  lda #VOLTAB_SWAPPED
  sta volume_table_base
  jsr play2b_play_wave
  lda #>authentic_w2b
  sta src_hi
  lda #>(authentic_w2b_end-authentic_w2b)
  sta pages_left
  lda #VOLTAB_UNSWAPPED
  sta volume_table_base
  jsr play2b_play_wave
  lda #$70
  sta $4000
  sta $4004
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  sta PPUCTRL

forever:
  jsr read_pads

  ; Good; we have the full screen ready.  Wait for a vertical blank
  ; and set the scroll registers to display it.
  lda nmis
vw3:
  cmp nmis
  beq vw3
  
  ; Turn the screen on
  ldx #0
  ldy #0
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  clc
  jsr ppu_screen_on

  lda new_keys
  and #KEY_A|KEY_START
  beq forever
  jmp replay

; And that's all there is to it.
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
  cpx #16
  bcc copypalloop
  rts
.endproc

.segment "RODATA"
.align 256
intro_w2b:
  .incbin "obj/nes/intro.w2b"
  .res <(intro_w2b-*), $AA
intro_w2b_end:
swapped_w2b:
  .incbin "obj/nes/swapped.w2b"
  .res <(intro_w2b-*), $AA
swapped_w2b_end:
authentic_w2b:
  .incbin "obj/nes/authentic.w2b"
  .res <(intro_w2b-*), $AA
authentic_w2b_end:

initial_palette:
  .byt $22,$12,$02,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Include the CHR ROM data
.segment "CHR"
  .incbin "obj/nes/bggfx.chr"
