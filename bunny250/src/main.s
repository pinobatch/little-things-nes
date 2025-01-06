;
; Simple sprite demo for NES
; Copyright 2011 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in any source
; code copies.  This file is offered as-is, without any warranty.
;

.include "nes.inc"
.include "global.inc"

.segment "ZEROPAGE"
nmis:          .res 1
tvSystem:      .res 1
cur_keys:      .res 2
new_keys:      .res 2
seen_instructions:   .res 1
last_result_time: .res 1
last_result_overflow:  .res 1

; Game variables
player_xlo:       .res 1  ; horizontal position is xhi + xlo/256 px
player_xhi:       .res 1
player_dxlo:      .res 1  ; speed in pixels per 256 s
player_yhi:       .res 1
player_facing:    .res 1
player_frame:     .res 1
player_frame_sub: .res 1

.segment "BSS"
linebuffer: .res 32

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 1          ; PRG ROM size in 16384 byte units
  .byt 1          ; CHR ROM size in 8192 byte units
  .byt $00        ; mirroring type and mapper number lower nibble
  .byt $00        ; mapper number upper nibble

.segment "VECTORS"
.addr nmi, reset, irq

.segment "CODE"
;;
; This NMI handler is good enough for a simple "has NMI occurred?"
; vblank-detect loop.  But sometimes there are things that you always
; want to happen every frame, even if the game logic takes far longer
; than usual.  These might include music or a scroll split.  In these
; cases, you'll need to put more logic into the NMI handler.
.proc nmi
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
.proc irq
  rti
.endproc

; 
.proc reset
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

start_over:
  lda #VBLANK_NMI
  sta PPUCTRL
  ldx #$3F
  lda #$00
  sta PPUMASK
  stx PPUADDR
  sta PPUADDR
  stx PPUDATA
  lda #$0A
  sta PPUDATA
  lda #$1A
  sta PPUDATA
  lda #$2A
  sta PPUDATA
  ldx #$20
  lda #' '*2
  ldy #$00
  jsr ppu_clear_nt
  
  ; Sprite 0 to detect end of vblank
  ldx #$04
  jsr ppu_clear_oam
  lda #32-1
  sta OAM+0
  lda #('T'<<1)
  sta OAM+1
  lda #%00100000  ; behind bg
  sta OAM+2
  lda #16
  sta OAM+3
  
  jsr getTVSystem
  sta tvSystem
  
  lda #$20
  sta 3
  lda #$82
  sta 2
  lda #>hw_msg
  ldy #<hw_msg
  jsr puts_multiline_16
  
  lda seen_instructions
  bne skip_instructions
  lda #$21
  sta 3
  lda #$C2
  sta 2
  lda #>instructions_msg
  ldy #<instructions_msg
  sta seen_instructions
  jsr puts_multiline_16
  jmp skip_last_result
skip_instructions:
  lda last_result_overflow
  beq wasnt_overflow
  ldy #<time_overflow_msg
  lda #>time_overflow_msg
  bne print_last_result
wasnt_overflow:
  ldx #0
:
  lda millisecs_msg,x
  sta linebuffer,x
  beq :+
  inx
  bne :-
:
  lda last_result_time
  bne wasnt_underflow
  ldy #<time_underflow_msg
  lda #>time_underflow_msg
  bne print_last_result
wasnt_underflow:
  ; neither an overflow nor an underflow
  jsr bcd8bit
  ora #'0'
  sta linebuffer+2
  lda 0
  beq no_highdigits
  and #$0F
  ora #'0'
  sta linebuffer+1
  lda 0
  lsr a
  lsr a
  lsr a
  lsr a
  beq no_highdigits
  ora #'0'
  sta linebuffer+0
no_highdigits:
  lda #>linebuffer
  ldy #<linebuffer
print_last_result:
  sta 1
  sty 0
  lda #$21
  ldx #$42
  jsr puts_16

skip_last_result:

wait_for_trigger:
  lda nmis
:
  cmp nmis
  beq :-
  ldx #0
  ldy #0
  sty OAMADDR
  lda #>OAM
  sta OAM_DMA
  lda #VBLANK_NMI
  sec
  jsr ppu_screen_on
  jsr read_pads
  bit new_keys+1
  bpl wait_for_trigger
  jsr handle_trigger
  jmp start_over
.endproc

.segment "RODATA"
hw_msg:
  .byt "TV lag measuring tool",10
  .byt "Copr. 2013 Damian Yerrick",0
instructions_msg:
  .byt "Plug a Zapper into port 2,",10
  .byt "point it at the screen, and",10
  .byt "pull the trigger to measure",10
  .byt "display lag.  For an LCD,",10
  .byt "you may need to crank up",10
  .byt "the backlight brightness.",0
time_overflow_msg:
  .byt "Over 250 ms (not toward TV)",0
time_underflow_msg:
  .byt "Pointed at a light bulb?",0
millisecs_msg:
  .byt "  x ms of lag",0

.segment "CODE"

.proc handle_trigger

  ; Set the palette black without killing sprite 0
  lda #VBLANK_NMI
  sta PPUCTRL
  ldx #$3F
  lda #$00
  sta PPUMASK
  stx PPUADDR
  sta PPUADDR
  stx PPUDATA  ; $3F is also black
  stx PPUDATA
  stx PPUDATA
  stx PPUDATA

  ; Turn the screen on with an all-black palette so that sprite 0
  ; still triggers, and wait 15 frames for even the worst anticipated
  ; lag to expire
  tax
  tay
  lda #VBLANK_NMI|VRAM_DOWN
  sec
  jsr ppu_screen_on
  ldx #15
framewaitloop:
  lda nmis
:
  cmp nmis
  beq :-
  dex
  bne framewaitloop

  ; Make sure sprite 0 actually hit.  Otherwise we're sort of screwed.  
  bit PPUSTATUS
  bvs s0ok
  rts
s0ok:

  ; Now set the backdrop white and turn rendering off.  (We had set
  ; the VRAM increment to +32, which leaves the VRAM address pointing
  ; at the backdrop color, the last time we turned rendering on.)
  ldy #0
  sty PPUMASK
  ldx #$3F
  stx PPUADDR
  sty PPUADDR
  lda #$20
  sta PPUDATA
  lda #$00
  sta PPUADDR
  sta PPUADDR
  sta PPUMASK

  ; And wait for vertical blanking to end to start the timer
  bit PPUSTATUS
  bvs s0ok

  jsr wait_256_or_light
  stx last_result_time
  lda #0
  rol a
  sta last_result_overflow
  rts
.endproc

.segment "CHR"
  .res 32*32
  .incbin "obj/nes/finkheavy16.chr"
