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

; Set TEST_DMC_DMA to nonzero to turn on a stress test of glitch
; avoidance in pads.s.  This emits a high-pitched tone.
TEST_DMC_DMA = 0

.segment "ZEROPAGE"
nmis:          .res 1
oam_used:      .res 1  ; starts at 0
cur_keys:      .res 2
new_keys:      .res 2

SIZEOF_TABLET_BITS = 3
tablet_bits: .res SIZEOF_TABLET_BITS

advance_mode:        .res 1
draw_andmask:        .res 1
draw_ormask_plane_0: .res 1
draw_ormask_plane_1: .res 1
draw_addr_lo:        .res 1
draw_addr_hi:        .res 1

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

  ; Copy the palette while it's still vblank
  jsr load_main_palette
  jsr draw_title
  ldx #0
  jsr ppu_clear_oam
  dex
  stx cur_keys+0  ; ensure variables are initialized before first loop
  stx cur_keys+1
  
  press_start_loop:
    lda nmis
    :
      cmp nmis
      beq :-
    ldx #0
    ldy #0
    lda #VBLANK_NMI|BG_0000|OBJ_1000
    sec
    jsr ppu_screen_on
    jsr run_dma_and_read_pads
    lda new_keys
    and #KEY_START
    beq press_start_loop

  jsr init_canvas
  lda #3
  sta advance_mode

forever:

  ; Copy the display list from main RAM to the PPU and then
  ; read the controllers.  (To see why these are done together,
  ; read pads.s.)
  jsr run_dma_and_read_pads

  lda new_keys+0
  bpl no_toggle_advance_mode
    ; advance mode 1: advance bit on then off then read
    ; advance mode 3: advance bit on then read then off
    lda #2
    eor advance_mode
    sta advance_mode
  no_toggle_advance_mode:

  ; Read the tablet
  ; Bit 0 chooses between readable (1) and latch (0).
  ; I don't know how long bit 0 has to be in a particular state
  ; before the values become valid.  There could be some required
  ; minimum delay like with the Arkanoid controller.
  lda #$01  ; bit 0: select tablet for reading
  sta $4016
  .repeat ::SIZEOF_TABLET_BITS, I
    sta tablet_bits+I
  .endrepeat
  ldx #0
  read_bitloop:
    lda #$03  ; posedge bit 1 : advance to next bit
    sta $4016
    lda advance_mode
    sta $4016
    lda #$08
    and $4017
    eor #$08
    cmp #$01
    lda #$01
    sta $4016
    rol tablet_bits,x
    bcc read_bitloop
    inx
    cpx #SIZEOF_TABLET_BITS
    bcc read_bitloop

  ; find what address to modify
  ; 0000 YYYY XXXX 0yyy
  ; bit to modify is $80 >> ((X >> 1) & $07)
  lda #$FF
  sta draw_addr_hi
  sta OAM+0
  lda #$00
  sta OAM+1
  sta draw_ormask_plane_1
  sta OAM+2
  lda tablet_bits+2
  bpl no_draw_address  ; status bit 7: pen contact

    ; Draw a sprite while in contact
    lda tablet_bits+0
    lsr a
    clc
    adc #60
    sta OAM+3
    lda tablet_bits+1
    lsr a
    clc
    adc #59
    sta OAM+0

    ; If below $20 (boundary between toolbar and client area),
    ; draw into the pattern table
    lda tablet_bits+1
    cmp #$20
    bcc no_draw_address

    lsr a
    lsr a
    lsr a
    lsr a
    sta draw_addr_hi
    lda tablet_bits+1
    and #$0E
    lsr a
    eor tablet_bits+0
    and #$0F
    eor tablet_bits+0
    sta draw_addr_lo
    lda tablet_bits+0
    and #$0E
    lsr a
    tay
    lda one_shl_7_minus_x,y
    sta draw_ormask_plane_0
    bit tablet_bits+2  ; is the space bar held?
    bvc :+
      sta draw_ormask_plane_1
      inc OAM+2
    :
    eor #$FF
    sta draw_andmask
  no_draw_address:

  ; wait for the next frame
  lda nmis
vw3:
  cmp nmis
  beq vw3

  lda #$20
  sta PPUADDR
  lda #$E8
  sta PPUADDR
  lda advance_mode
  ora #$10
  sta PPUDATA
  ldx #0
  stx PPUDATA
  disp_xyloop:
    lda tablet_bits,x
    lsr a
    lsr a
    lsr a
    lsr a
    ora #$10
    sta PPUDATA
    lda tablet_bits,x
    and #$0F
    ora #$10
    sta PPUDATA
    lda #0
    sta PPUDATA
    inx
    cpx #2
    bne disp_xyloop
  
  lda tablet_bits+2
  sec
  rol a
  disp_bitloop:
    ldy #$10
    bcc :+
      iny
    :
    sty PPUDATA
    asl a
    bne disp_bitloop

  ; Drawing:
  ldy draw_addr_hi
  bmi no_draw
    sty PPUADDR
    ldx draw_addr_lo
    stx PPUADDR
    lda PPUDATA
    lda PPUDATA
    and draw_andmask
    ora draw_ormask_plane_0
    sty PPUADDR
    stx PPUADDR
    sta PPUDATA
    sty PPUADDR
    txa
    ora #8
    tax
    stX PPUADDR
    lda PPUDATA
    lda PPUDATA
    and draw_andmask
    ora draw_ormask_plane_1
    sty PPUADDR
    stx PPUADDR
    sta PPUDATA
  no_draw:

  ; Turn the screen on
  ldx #0
  ldy #0
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  sec
  jsr ppu_screen_on
  jmp forever

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
  cpx #32
  bcc copypalloop
  rts
.endproc

.segment "RODATA"
initial_palette:
  .byt $0F,$00,$10,$20
  .byt $0F,$00,$10,$20
  .byt $0F,$00,$10,$20
  .byt $0F,$00,$10,$20
  .byt $0F,$00,$10,$20
  .byt $0F,$26,$10,$20
  .byt $0F,$00,$10,$20
  .byt $0F,$00,$10,$20

one_shl_7_minus_x:
  .repeat 8, I
    .byt $80 >> I
  .endrepeat