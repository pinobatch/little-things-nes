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
.macro wait4vbl
:
  bit PPUSTATUS
  bpl :-
.endmacro


.segment "INESHDR"

  .byt "NES", 26
  .byt 2  ; number of 16 KB program segments
  .byt 1  ; number of 8 KB chr segments
  .byt 0  ; mapper, mirroring, etc
  .byt 0  ; extended mapper info
  .byt 0,0,0,0,0,0,0,0  ; f you DiskDude

.segment "CODE"

nmihandler:
irqhandler:
  rti

main:

;;; Init CPU
  sei
  cld
  ldx #$ff
  txs
  inx

;;; Init PPU
  wait4vbl
  stx PPUCTRL  ; Inside first VBL, clear PPU registers
  stx PPUMASK
  wait4vbl  ; after second VBL we can write to ppu memory

;;; Load initial palette
  lda #$3f
  sta PPUADDR
  stx PPUADDR
@palclrloop:
  lda pal,x
  sta PPUDATA
  inx
  lda pal,x
  sta PPUDATA
  inx
  cpx #32
  bne @palclrloop

;;; Clear nametable $2000
  lda #$20
  jsr map_clear


;;; Write messages
  lda #<hello_str
  sta 0
  lda #>hello_str
  sta 1
  ldx #$20  ; $20e7 = (7, 7)
  ldy #$e7
  jsr draw_text
  lda #<button_names
  sta 0
  lda #>button_names
  sta 1
  ldx #$21  ; $2128 = (8, 9)
  ldy #$28
  jsr draw_text


main_loop:
  wait4vbl
  ldx #1
  stx JOY1
  dex
  stx JOY1
  stx PPUCTRL
  stx PPUMASK
  ldx #$21  ; $2148 = (8, 10)
  stx PPUADDR
  ldx #$48
  stx PPUADDR
  ldx #8
  ldy #0
@per_button:
  lda JOY1
  and #1
  sta PPUDATA
  sty PPUDATA
  dex
  bne @per_button

;;; turn on display
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  sta PPUCTRL
  lda #PPUMASK_BG0
  sta PPUMASK

  jmp main_loop




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


.segment "RODATA"

hello_str:
  .asciiz " [ HELLO  WORLD ] "
button_names:
  .byt    "A B ",4,5,6,7
  .asciiz "UPDNLTRT"
pal:
  .byt $30,$0f,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30
  .byt $30,$0f,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30

@die:
  jmp @die



.segment "VECTORS"

  .addr nmihandler, main, irqhandler

