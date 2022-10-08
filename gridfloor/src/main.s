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

  .ifdef ::CHRRAM
    .import load_chrram_data
    jsr load_chrram_data
  .endif

  ; While in forced blank we have full access to VRAM.
  ; Load the nametable (background map).
  jsr draw_bg
  
  ; Set up game variables, as if it were the start of a new level.
  .ifndef ::CHRRAM
    jsr init_player
  .endif
  lda #0
  sta camera_zpos
  jsr calc_depths

forever:

  .ifndef ::CHRRAM
    ; Game logic
    jsr read_pads
    jsr move_player
  .endif

  ; The first entry in OAM (indices 0-3) is "sprite 0".  In games
  ; with a scrolling playfield and a still status bar, it's used to
  ; help split the screen.  This demo doesn't use scrolling, but
  ; yours might, so I'm marking the first entry used anyway.

  lda #142
  sta OAM+0
  lda #4
  sta OAM+1
  lda #$A0  ; flip&behind
  sta OAM+2
  lda #8
  sta OAM+3
  ldx #4

  .ifndef ::CHRRAM
    stx oam_used
    ; adds to oam_used
    lda cur_keys
    and #KEY_SELECT
    bne :+
      jsr draw_player_sprite
    :

    ldx oam_used
  .endif
  jsr ppu_clear_oam

  lda nmis
  eor #$FF
  lsr a
  lsr a
  lsr a
  sta camera_zpos
  jsr calc_depths
  
  lda #%11000000
  s0bottomwait:
    bit PPUSTATUS
    beq s0bottomwait
  bmi s0nope
    ldy #244
    :
      dey
      bne :-
    lda #<-1
    sta yslope_px
    lda #$80
    sta xscroll_sub
    lda nmis
    and #31
    pha
    clc
    adc #16
    lsr a
    tax
    ror xscroll_sub
    pla
    asl a
    sec
    sbc #32
    sta slope_sub
    lda #0
    adc #$FF
    sta slope_px
    lda #64
    ldy #63
    jsr run_kernel
    jsr waste12
    jsr waste12
    jsr waste12
    lda #OBJ_ON
    sta PPUMASK

    lda nmis
    vw3:
      cmp nmis
      beq vw3
  s0nope:
  
  ; Copy the display list from main RAM to the PPU
  lda #0
  sta OAMADDR
  lda #>OAM
  sta OAM_DMA
  
  ; Turn the screen on
  lda #0
  sta PPUSCROLL
  lda #240-8
  sta PPUSCROLL
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  sta PPUCTRL
  lda #BG_ON|OBJ_ON
  sta PPUMASK

  ; If sprite 0 was hit, draw the top segment
  bit PPUSTATUS
  bvc no_hit
    topwait:
      bit PPUSTATUS
      bvs topwait
    ldy #<360
    :
      dey
      bne :-
    lda #OBJ_ON
    sta PPUMASK
    :
      dey
      bne :-
    lda #BG_ON|OBJ_ON
    sta PPUMASK

    lda #1
    sta yslope_px
    lda #$80
    sta xscroll_sub
    lda nmis
    and #31
    tax
    asl a
    eor #$FF
    clc
    adc #32
    sta slope_sub
    lda #0
    sbc #0
    sta slope_px
    lda #64
    ldy #0
    jsr run_kernel
    jsr waste12
    nop
    nop
    nop
    nop
    lda #0
    ldx #$01
    ldy #$20
    sta PPUSCROLL
    bit PPUSTATUS
    stx PPUADDR
    sty PPUADDR
  
  no_hit:
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
  cpx #32
  bcc copypalloop
waste12:
  rts
.endproc

waste12 = load_main_palette::waste12

.segment "RODATA"
initial_palette:
  .byt $0f,$1A,$2A,$3A,$0f,$0f,$10,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$26,$0f
  .byt $0F,$08,$22,$37,$0F,$06,$16,$26,$0F,$0A,$1A,$2A,$0F,$02,$12,$22
