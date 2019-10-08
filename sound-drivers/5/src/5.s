
;;; Copyright (C) 2003 Damian Yerrick
;
;   This program is free software; you can redistribute it and/or
;   modify it under the terms of the GNU General Public License
;   as published by the Free Software Foundation; either version 2
;   of the License, or (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program; if not, write to 
;     Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;     Boston, MA  02111-1307, USA.
;
;   Visit http://www.pineight.com/ for more information.


.p02


;;; Memory mapped registers

OAM       = $0200

PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
SPRADDR   = $2003  ; always write 0 here and use DMA from OAM
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007

SPRDMA    = $4014
SNDCHN    = $4015
JOY1      = $4016
JOY2      = $4017

PPUCTRL_NMI      = $80
PPUCTRL_8X8      = $00
PPUCTRL_8X16     = $20
PPUCTRL_BGHIPAT  = $10
PPUCTRL_SPRHIPAT = $08
PPUCTRL_WRDOWN   = $04  ; when set, PPU address increments by 32

PPUMASK_RED      = $80  ; when set, slightly darkens other colors
PPUMASK_GREEN    = $40
PPUMASK_BLUE     = $20
PPUMASK_SPR      = $14  ; SPR: show sprites in x=0-255
PPUMASK_SPRCLIP  = $10  ; SPRCLIP: show sprites in x=8-255
PPUMASK_BG0      = $0A  ; BG0: similarly
PPUMASK_BG0CLIP  = $08
PPUMASK_MONO     = $01  ; when set, zeroes the low nibble of palette values

PPUSTATUS_VBL  = $80  ; the PPU has entered a vblank since last $2002 read
PPUSTATUS_SPR0 = $40  ; sprite 0 has overlapped BG since ???
PPUSTATUS_OVER = $20  ; More than 64 sprite pixels on a scanline since ???


;;; Some helpful macros

;;; wait4vbl
;   Waits for the PPU to signal a vertical blank.
;   Apparently local labels cause the following:
;       Internal assembler error
;       WriteExpr: Cannot write EXPR_ULABEL nodes
.macro bootwait4vbl
:
  bit PPUSTATUS
  bpl :-
.endmacro

.macro wait4vbl
  lda nmis
  :
    cmp nmis
    beq :-
.endmacro


;;; Global variables

pads = $10
nmis = $12
dividend = $0c

MUS = $300






.segment "INESHDR"

  .byt "NES", 26
  .byt 2  ; number of 16 KB program segments
  .byt 1  ; number of 8 KB chr segments
  .byt 0  ; mapper, mirroring, etc
  .byt 0  ; extended mapper info
  .byt 0,0,0,0,0,0,0,0  ; f you DiskDude


.segment "CODE"

.import PKB_unpackblk

nmihandler:
  inc nmis
irqhandler:
  rti

main:

;;; Init CPU
  sei
  cld
  ldx #$ff
  txs
  inx

;;; Init machine
  bit PPUSTATUS
  bootwait4vbl
  stx PPUCTRL  ; After first VBL, clear PPU registers
  stx PPUMASK

  lda #$0f
  sta SNDCHN
  lda #$40
  sta $4011
  lda #8
  sta $4001
  sta $4005

  ldx #0
  ldy #$ef
  txa
@ramclrloop:
  sta 0,x
  sta $100,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  inx
  bne @ramclrloop

  bootwait4vbl  ; after second VBL we can write to ppu memory
  lda #$20
  jsr map_clear
  lda #$2c
  jsr map_clear

;;; Load initial palette
  lda #$3f
  sta PPUADDR
  ldx #0
  stx PPUADDR
@palclrloop:
  lda gamepal,x
  sta PPUDATA
  inx
  cpx #32
  bne @palclrloop

;;; load sprites
  lda #143
  sta OAM
  lda #16
  sta OAM+1
  lda #%00100011
  sta OAM+2
  lda #0
  sta OAM+3
  lda #$ef
  ldx #4
@sprclrloop:
  sta OAM,x
  inx
  sta OAM,x
  inx
  sta OAM,x
  inx
  sta OAM,x
  inx
  bne @sprclrloop

;;; Load initial nametable
  lda #%10000010
  sta PPUCTRL
  lda #$22
  sta PPUADDR
  lda #$00
  sta PPUADDR
  lda #16
  sta PPUDATA
  lda #$23
  sta PPUADDR
  lda #$c0     ; $23c0: attribute table
  sta PPUADDR
  lda #%01100110
  ldx #32
@attrclrloop:
  sta PPUDATA
  dex
  bne @attrclrloop
  lda #%00000011
  sta PPUDATA

  jsr draw_memory

loop:

  wait4vbl
  lda #0
  sta SPRADDR
  lda #>OAM
  sta SPRDMA
  lda #0
  sta PPUSCROLL
  ldy #224
  sty PPUSCROLL
  lda #%10000010
  sta PPUCTRL
  lda #%00011110
  sta PPUMASK

@wfs0c:
  bit PPUSTATUS
  bvs @wfs0c

  jsr music_play
@wfs0:
  bit PPUSTATUS
  bvc @wfs0
  lda #%00011111
  sta PPUMASK
  ldy #21
:
  dey
  bne :-
  lda #0
  sta PPUMASK
  jsr draw_memory
  lda #%00011111
  sta PPUMASK
  ldy #21
:
  dey
  bne :-
  lda #0
  sta PPUMASK

  jmp loop








music_play:
  ldx MUS
  inx
  cpx #50
  bcc @skip_loopnoise
  inc MUS+1
  lda MUS+1
  and #$10
  beq :+
  lda #$70
:
  clc
  adc MUS+1
  sta MUS+1
  sta $400e
  lda #5
  sta $400c
  lda #$40
  sta $400f

  ldx #0
@skip_loopnoise:
  stx MUS

  lda MUS+1
  eor #$80
  sta MUS+1
  sta $400e
  rts
















;;; map_clear:
;   Clears a nametable to all zeroes.
;   A: map address ($20 or $2C on std mirrorings;
;                   $20, $24, $28, or $2C on 4-screen)
;   Trashes A, X
map_clear:
  sta PPUADDR
  ldx #0
  stx PPUADDR
  txa
@ppuclrloop:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  inx
  bne @ppuclrloop
  rts


;;; draw_text:
;   Draws a nul-terminated line of text to the screen.
;   0: pointer to text src
;   X: high word of dst
;   Y: low word of dst
;   out: Y: length of string; A: 0
draw_text:
  stx PPUADDR
  sty PPUADDR
  ldy #0
  lda (0),y
  beq @skip
@loop:
  sta PPUDATA
  iny
  lda (0),y
  bne @loop
@skip:
  rts


read_pads:
  ldx #1
  stx JOY1
  dex
  stx JOY1
@button_loop:
  lda JOY1
  jsr @readpads_cycle
  lda JOY2
  jsr @readpads_cycle
  cpx #16
  bcc @button_loop
  rts

@readpads_cycle:
  and #$03  ; D0 for pad, D1 for Famicom external pad
  bne @down
  lda #0
  sta pads,x
  inx
  rts
@down:
  inc pads,x
  lda pads,x
  cmp #10
  bcc @skip
  lda #8
  sta pads,x
@skip:
  inx
  rts


.if 0
;;; div10
;   Given a 16-bit number in dividend, divides it by ten and
;   stores the result in dividend.
;   out: A: remainder; X: 0; Y: unchanged
div10:
  ldx #16
  lda #0
@divloop:
  asl dividend
  rol dividend+1
  rol a
  cmp #10
  bcc @no_sub
  sbc #10
  inc dividend
@no_sub:
  dex
  bne @divloop
  rts


;;; decimalize
;   Given a pointer to a text field, turns
;   in: 4: text field ptr
;       y: field length
;       dividend: number to decimalize
;   out: written
decimalize_loop:
  jsr div10
  cmp #0
  bne @nonzero
  ldx dividend
  bne @nonzero
  ldx dividend+1
  bne @nonzero
  rts
@nonzero:
  ora #'0'
  sta (4),y
decimalize:
  dey
  bpl decimalize_loop
  rts
.endif


.align 256
draw_memory:
  lda #$20
  sta PPUADDR
  ldx #$00
  stx PPUADDR
@draw_loop:
  lda $300,x
  lsr a
  lsr a
  lsr a
  lsr a
  ora #$10
  sta PPUDATA
  lda $300,x
  and #$0f
  ora #$10
  sta PPUDATA
  inx
  bne @draw_loop
  rts


.segment "RODATA"

gamepal:
  .byt $0f,$00,$10,$30,$0f,$06,$16,$26,$0f,$07,$17,$27,$0f,$0f,$0f,$0f
  .byt $0f,$00,$10,$30,$0f,$00,$10,$30,$0f,$00,$10,$30,$0f,$0f,$0f,$0f



.segment "VECTORS"

  .addr nmihandler, main, irqhandler

.segment "CHR"
.incbin "tilesets/5.chr"
