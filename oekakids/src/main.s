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

tablet_x: .res 1
tablet_y: .res 1
tablet_buttons: .res 1

draw_andmask:        .res 1
draw_ormask_plane_0: .res 1
draw_ormask_plane_1: .res 1
draw_addr_lo:        .res 1
draw_addr_hi:        .res 1

.bss

SIZEOF_TABLET_BITS = 18
tablet_bits_read: .res 1
tablet_bits: .res SIZEOF_TABLET_BITS
ack_1_time:  .res SIZEOF_TABLET_BITS
ack_3_time:  .res SIZEOF_TABLET_BITS

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
  lda #$EF  ; $EF ensures 9 sprites bit turns on
  :
    sta OAM,x
    inx
    bne :-
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
  lda nmis
  :
    cmp nmis
    beq :-
  ldx #0
  ldy #0
  lda #VBLANK_NMI
  clc
  jsr ppu_screen_on

forever:

  ; Copy the display list from main RAM to the PPU and then
  ; read the controllers.  (To see why these are done together,
  ; read pads.s.)
  jsr run_dma_and_read_pads

  lda #$20  ; wait for 9 sprites bit to turn off (end of frame)
  :
    bit PPUSTATUS
    bne :-
  lda #BG_ON|OBJ_ON|LIGHTGRAY
  sta PPUMASK
  jsr read_oeka_kids_tablet
  lda #BG_ON|OBJ_ON
  sta PPUMASK

  ; If the pen is down, find the address of the pixel at the
  ; pen's X, Y coordinates on the drawing surface.
  ; 0000 YYYY XXXX 0yyy
  ; bit to modify is $80 >> ((X >> 1) & $07)
  lda #$FF
  sta draw_addr_hi
  sta OAM+0
  lda #$00
  sta OAM+1
  sta draw_ormask_plane_1
  sta OAM+2
  lda tablet_buttons
  bpl no_draw_address  ; status bit 7: pen contact

    ; Draw a sprite while in contact
    lda tablet_x
    lsr a
    clc
    adc #60
    sta OAM+3
    lda tablet_y
    lsr a
    clc
    adc #59
    sta OAM+0

    ; If below $20 (boundary between toolbar and client area),
    ; draw into the pattern table
    lda tablet_y
    cmp #$20
    bcc no_draw_address

    lsr a
    lsr a
    lsr a
    lsr a
    sta draw_addr_hi
    lda tablet_y
    and #$0E
    lsr a
    eor tablet_x
    and #$0F
    eor tablet_x
    sta draw_addr_lo
    lda tablet_x
    and #$0E
    lsr a
    tay
    lda one_shl_7_minus_x,y
    sta draw_ormask_plane_0
    bit tablet_buttons  ; is the space bar held?
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
  lda #$EC
  sta PPUADDR
  ldx #0
  disp_xyloop:
    lda tablet_x,x
    lsr a
    lsr a
    lsr a
    lsr a
    sta PPUDATA
    lda tablet_x,x
    and #$0F
    sta PPUDATA
    lda PPUDATA
    inx
    cpx #2
    bne disp_xyloop
  
  ldy #$00
  lda tablet_buttons
  bpl :+
    iny
  :
  sty PPUDATA
  ldy #$00
  asl a
  bpl :+
    iny
  :
  sty PPUDATA

  ; Draw a pixel to the canvas
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

  ; Draw the timeouts
  lda #$23
  sta PPUADDR
  lda #$27
  sta PPUADDR
  ldx #0
  :
    lda ack_1_time,x
    sta PPUDATA
    inx
    cpx #SIZEOF_TABLET_BITS
    bcc :-
  lda #$23
  sta PPUADDR
  lda #$47
  sta PPUADDR
  ldx #0
  :
    lda ack_3_time,x
    sta PPUDATA
    inx
    cpx #SIZEOF_TABLET_BITS
    bcc :-

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

.proc read_oeka_kids_tablet
  ldx #$01
  stx $4016
  dex  ; X = offset into raw tablet_bits

  ; The tablet calculates a new report when $4016 changes from
  ; $01 to $00.
  ; To read each bit of the report:
  ; 1. Write $01 to $4016.
  ; 2. Wait for the tablet to acknowledge: $4017 & #$04 becomes 0.
  ; 3. Write $03 to $4016.
  ; 4. Wait for the tablet to acknowledge: $4017 & #$04 becomes 0.
  ; 5. Read a report bit from $4017 & #$08.
  ; $08 means 0, $00 means 1, MSB first.
  ; Before May 2026, NESdev Wiki did not mention a requirement to
  ; wait for the tablet to acknowledge each $4016 edge.
  ; Thanks to Zorchenhimer for helping figure this out
  ; <https://github.com/zorchenhimer/keytest/blob/master/tablet.asm>
  bitloop:
    ldy #0
    lda #$04
    wait_for_ack_1:  ; Tablet acknowledges 1 with xxxx x0xx in $4017
      bit $4017
      bne acked_1
      iny
      bne wait_for_ack_1
      .assert >*=>wait_for_ack_1, error, "page crossing makes timing wrong"
    timeout:
      stx tablet_bits_read
      sec
      rts
    acked_1:

    lda #$03  ; begin second half of bit clock
    sta $4016
    tya
    sta ack_1_time,x
    ldy #0
    lda #$04
    wait_for_ack_3:  ; Tablet acknowledges 3 with xxxx x1xx in $4017
      bit $4017
      beq acked_3
      iny
      bne wait_for_ack_3
      .assert >*=>wait_for_ack_3, error, "page crossing makes timing wrong"
      jmp timeout
    acked_3:

    tya
    sta ack_3_time,x
    lda $4017  ; Data is in bit 3 in $4017, inverted, MSB first
    ldy #$01   ; begin first half of next bit clock
    sty $4016
    eor #$FF
    and #$08
    sta tablet_bits,x
    inx
    cpx #SIZEOF_TABLET_BITS
    bcc bitloop
  
  ; Successful read!
  stx tablet_bits_read

  ; Leave $4016 at $01 so that the next call to read_pads requests
  ; a position read ($01 to $00).
  ; Pack tablet bits to bytes
  ldx #7
  convertloop:
    lda tablet_bits+0,x
    cmp #1
    ror tablet_x
    lda tablet_bits+8,x
    cmp #1
    ror tablet_y
    dex
    bpl convertloop
  lda tablet_bits+16
  asl a
  ora tablet_bits+17
  .repeat 3
    asl a
  .endrepeat
  ; clc
  sta tablet_buttons
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
