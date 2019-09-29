;
; Background drawing for Test78
;
; Copyright 2017 Damian Yerrick
; 
; This software is provided 'as-is', without any express or implied
; warranty. In no event will the authors be held liable for any
; damages arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any
; purpose, including commercial applications, and to alter it and
; redistribute it freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must
;    not claim that you wrote the original software. If you use this
;    software in a product, an acknowledgment in the product
;    documentation would be appreciated but is not required.
; 
; 2. Altered source versions must be plainly marked as such, and must
;    not be misrepresented as being the original software.
; 
; 3. This notice may not be removed or altered from any source
;    distribution.

.include "nes.inc"
.export draw_bg, draw_mirror_result

.code

.proc draw_bg
src = $00
  lda #VBLANK_NMI
  ldy #$00
  sta PPUCTRL
  sty PPUMASK

  ; Load the palette
  lda #$3F
  sta PPUADDR
  sty PPUADDR
  ldx #$02
  stx PPUDATA
  sta PPUDATA
  ldx #$10
  stx PPUDATA
  ldx #$20
  stx PPUDATA

  ; Load the nametable  
  stx PPUADDR
  sty PPUADDR
  lda #<bgnam
  sta src+0
  lda #>bgnam
  sta src+1
  ldx #<-4
  loop:
    lda (src),y
    sta PPUDATA
    iny
    bne loop
    inc src+1
    inx
    bne loop

  
  rts
.endproc

MIRROR_RESULT_DST = $224A
MIRROR_RESULT_TILE_BASE = $C8

MIRROR_RESULT_UCHUUSEN = %00001111
MIRROR_RESULT_HOLYDIVER = %00110101
MIRROR_RESULT_ARROW_Y = 8
MIRROR_RESULT_ARROW_X = 3
MIRROR_RESULT_ARROW_TILE = MIRROR_RESULT_TILE_BASE + 8



.proc draw_mirror_result
bits = $00
arrowaddrlo = $01
  sta bits
  ldy #VBLANK_NMI|VRAM_DOWN
  sty PPUCTRL

  ; Compare to known values
  ldy #MIRROR_RESULT_ARROW_Y
  cmp #MIRROR_RESULT_UCHUUSEN
  beq have_arrow_y
  ldy #MIRROR_RESULT_ARROW_Y+3
  cmp #MIRROR_RESULT_HOLYDIVER
  beq have_arrow_y
  ldy #MIRROR_RESULT_ARROW_Y+6  ; none of the above
have_arrow_y:

  ; Seek to this (X, Y) location
  lda #MIRROR_RESULT_ARROW_X << 3
  sta arrowaddrlo
  tya
  sec  ; $2000
  .repeat 3
    ror a
    ror arrowaddrlo
  .endrepeat
  tay
  ldx arrowaddrlo
  lda #MIRROR_RESULT_ARROW_TILE
  jsr draw1metatile

  ldx #<MIRROR_RESULT_DST
  ldy #>MIRROR_RESULT_DST
  
  digitloop:

    ; Choose digit
    asl bits
    lda #MIRROR_RESULT_TILE_BASE >> 3
    rol a
    asl a
    asl a
    jsr draw1metatile
    cpx #<MIRROR_RESULT_DST + 16
    bcc digitloop
  rts

draw1metatile:
  ; Draw left half
  sty PPUADDR
  stx PPUADDR
  sta PPUDATA
  eor #$01
  sta PPUDATA
  eor #$03
  inx

  ; Draw right half
  sty PPUADDR
  stx PPUADDR
  sta PPUDATA
  eor #$01
  sta PPUDATA
  inx
  rts
.endproc

.rodata
bgnam: .incbin "obj/nes/bg.nam"

.segment "CHR"
.incbin "obj/nes/bg.chr", 0, MIRROR_RESULT_TILE_BASE*16
.incbin "obj/nes/arrowsprite16.chr"
