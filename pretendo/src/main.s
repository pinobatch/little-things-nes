;
; Pretendo
; Demo of randomness through $2007 reads
; Copyright 2013 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;
; Nintendo and Game Boy are trademarks of Nintendo.  This is a parody
; of the Game Boy boot screen, and NintenDON'T sponsor or endorse it.
;

.include "nes.inc"
.include "global.inc"

.segment "ZEROPAGE"
nmis: .res 1
y_position: .res 1
dading_time: .res 1

.segment "RODATA"
xdigits8b_chr:
  .incbin "obj/nes/xdigits8b.chr"

.segment "CODE"
;;
; Sets up the pattern table and the nametable for the scrolling
; fake Nintendo logo.
.proc setup_nametable
  ldx #$00
  stx PPUADDR
  stx PPUADDR
expandchr_tileloop:
  ldy #8
:
  lda xdigits8b_chr,x
  sta PPUDATA
  inx
  dey
  bne :-
  tya
  ldy #8
  jsr st6loop
  cpx #160
  bcc expandchr_tileloop

rownum = 0
  lda #$20
  sta PPUADDR
  sty PPUADDR  ; 0 from the last st6loop
  sty rownum
rowloop:
  jsr draw_leftside
  lda rownum
  clc
  adc #PATTERN_FIRST_TILENO
midloop:
  sta PPUDATA
  adc #2
  bcc midloop
  jsr draw_rightside
  inc rownum
  lda rownum
  cmp #2
  bcc rowloop

  ldx #28
belowloop:
  jsr draw_leftside
  ldy #20
  lda #$10
  jsr st6loop
  jsr draw_rightside
  dex
  bne belowloop

  ; attrs
  jsr clearattr
  ldy #192
  lda #$11
  jsr st6loop
  jsr st6loop
  jsr st6loop
  jsr st6loop
clearattr:
  ldy #64
  lda #0
  beq st6loop

draw_leftside:
draw_rightside:
  ldy #6
  lda #$11
st6loop:
  sta PPUDATA
  dey
  bne st6loop
  rts
.endproc

;;
; Sets the scroll position and turns PPU rendering on.
; @param A value for PPUCTRL ($2000) including scroll position
; MSBs; see nes.h
; @param X horizontal scroll position (0-255)
; @param Y vertical scroll position (0-239)
; @param C if true, sprites will be visible
.proc ppu_screen_on
  stx PPUSCROLL
  sty PPUSCROLL
  sta PPUCTRL
  lda #BG_ON
  bcc :+
  lda #BG_ON|OBJ_ON
:
  sta PPUMASK
  rts
.endproc

;;
; @param X the X coordinate of the one on the left
; @param Y the offset in OAM
; @param A the hex byte to draw
.proc unpack2hexsprites
  pha
  and #$0F
  sta OAM+5,y
  pla
  lsr a
  lsr a
  lsr a
  lsr a
  sta OAM+1,y
  txa
  sta OAM+3,y
  clc
  adc #8
  sta OAM+7,y
  lda #0
  sta OAM+2,y
  sta OAM+6,y
  lda #144+48-9
  sta OAM+0,y
  sta OAM+4,y
  rts
.endproc

; I need a few bits of entropy to initialize the cut scene
; correctly.  On 10 February 2013 in #nesdev, Kevin Horton said
; CRCing $2007 reads during rendering will bring a whole bunch of
; analog effects into play.
.proc cksum_vram_page
  ldy #0
loop:
  lda PPUDATA
  jsr crc16_update
  iny
  bne loop
  rts
.endproc

.proc nmi
  inc nmis
.endproc
.proc irq
  rti
.endproc

.proc reset
  sei
  cld
  ldx #$00
  stx PPUCTRL
  stx PPUMASK
  stx $4010
  dex
  txs
  lda #$40
  sta $4017
  bit $4015
  bit PPUSTATUS
vw1:
  bit PPUSTATUS
  bpl vw1
vw2:
  bit PPUSTATUS
  bpl vw2
  
  ; prepare OAM incl. sprite 0 used for timing
  txa  ; A = #$FF which is below the screen
  ldx #24
clroamloop:
  sta OAM,x
  inx
  bne clroamloop

  ; sprite 0: top of raster split
  ; sprite 1: the trademark sign
  ; have to use a sprite because it's not necessarily tile aligned
  lda #46
  sta OAM+0
  ldx #$11
  stx OAM+1
  stx OAM+3
  inx
  stx OAM+5
  lda #%00100000  ; behind bg
  sta OAM+2
  sta OAM+6
  
  ; Gather entropy while the rendering is turned on
  ldx #0
  ldy #0
  stx CRCLO
  stx CRCHI
  lda #VBLANK_NMI
  clc
  jsr ppu_screen_on
  jsr cksum_vram_page

  ; write the hex value to sprites 2-5
  ldy #8
  ldx #112
  lda CRCHI
  jsr unpack2hexsprites
  ldy #16
  ldx #128
  lda CRCLO
  jsr unpack2hexsprites


  ; set palette
  ldx #$3F
  ldy #$00
  sty PPUMASK
  stx PPUADDR
  sty PPUADDR
  lda #$29  ; Game Boy display is puke green
  sta PPUDATA
  lda #$0B
  sta PPUDATA
  stx PPUADDR
  ldy #$11
  sty PPUADDR
  sta PPUDATA
  jsr setup_nametable

  lda CRCLO
  lsr a
  and #$07
  tax
  inx
  inx

  ; change this during debugging to pick a pattern
  ; 0: test; 1: Nintendo logo; 2-9: parodies
;  ldx #3

.if 0
  ; debug code: show pattern number
  lda #7
  sta assembled_pattern+70
  sta assembled_pattern+74
  stx assembled_pattern+71
  stx assembled_pattern+73
  stx assembled_pattern+72
.endif

  jsr get_pattern_x
  jsr center_pattern
  ; position the trademark symbol with its left side at
  ; X = (L + W) * 2 + 48
  clc
  lda 0
  adc 1
  asl a
  adc #48
  sta OAM+7
  jsr rotate_pattern
  lda #240-32
  sta y_position

forever:
  lda #239
  sec
  sbc y_position
  sta OAM+4
  lda nmis
vw:
  cmp nmis
  beq vw
  bit PPUSTATUS
  ldx #0
  stx OAMADDR
  lda #>OAM
  sta OAM_DMA
  ldy y_position
  lda #VBLANK_NMI|1
  sec
  jsr ppu_screen_on
  
  ldy y_position
  bpl dading_wait
  lda nmis
  lsr a
  tya
  sbc #0
  sta y_position
  bmi done_scrolling

  ; start da-ding sound
  lda #$01
  sta $4015
  lda #$8C
  sta $4000
  lda #105
  sta $4002
  lda #8
  sta $4001
  sta $4003
  lda #6
  sta dading_time
  
dading_wait:
  lda dading_time
  beq done_scrolling
  dec dading_time
  bne done_scrolling
  lda #52
  sta $4002
done_scrolling:

s0wait0:
  bit PPUSTATUS
  bvs s0wait0
s0wait1:
  bit PPUSTATUS
  bmi no_raster
  bvc s0wait1
  lda #VBLANK_NMI
  sta PPUCTRL
  ldy #188
  ldx #13
waitpastscreen:
  dey
  bne waitpastscreen
  dex
  bne waitpastscreen
  lda #VBLANK_NMI|1
  sta PPUCTRL
no_raster:

  jmp forever
.endproc

.segment "VECTORS"
  .addr nmi, reset, irq
.segment "INESHDR"
  .byt "NES",$1a
  .byt 1, 0, 1, 0
