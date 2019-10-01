.include "nes.inc"
.include "global.inc"

; I just sketched an implementation of sprite squashing on the NES
; and ran a cycle estimate.
; 74 cyc/row * 8 rows/tile * 8 tiles/frame = 4736 cycles to fill
; a 128-byte (size of big Mario) transfer buffer.

SCALE_PLANE_NTILES = 8
scale_plane0 = $0100
scale_plane1 = scale_plane0 + 8 * SCALE_PLANE_NTILES

;;
; Scales a sprite sliver stack.
; @param $00-$01 pointer to source tile data, in Game Boy format
; @param $02 height of source tile data in bytes (e.g. 16 = 8 pixels)
; @param $03 vertical scale factor (0-255: shrink by a factor of 1 to 1+255/256)
; @param A horizontal scale factor (0-4: shrink to a width of 8-4)
; @param X offset in copy buffer
.proc do_scale
src = 0
spriteht = 2
scaleamt = 3

scalersrc = 4
src_y = 6
fraccum = 7
skips = 8

  clc
  adc #>scaletab8to8
  sta scalersrc+1
  lda #<scaletab8to8
  sta scalersrc+0

  lda #0
  sta fraccum
  sta skips
  sta src_y
  lda #96
  sta spriteht

sliverloop:
  ; requires tiles to be Game Boy (!) formatted
  ; do plane 0, each plane taking 3+5+5+2+5+4 = 24
  ldy src_y
  lda (src),y
  tay
  lda (scalersrc),y
  sta scale_plane0,x
  ; do plane 1
  ldy src_y
  iny
  lda (src),y
  iny
  sty src_y
  tay
  lda (scalersrc),y
  sta scale_plane1,x
  inx
  ; 48 so far

  ; now skip a row if needed
  ; 2+3+3+3+3+2+2+3+3+2 = 26
  clc
  lda fraccum
  adc scaleamt
  sta fraccum
  lda src_y
  bcc not_skipline
  cmp spriteht
  bcs read_whole_sprite
  adc #2
  sta src_y
  inc skips
not_skipline:
  cmp spriteht
  bcc sliverloop

read_whole_sprite:
  ; now see how many rows to fill at end
  ldy skips
  beq no_xfill
  lda #$00
clrloop:
  sta scale_plane0,x
  sta scale_plane1,x
  inx
  dey
  bne clrloop
no_xfill:
  rts
.endproc

.proc copy_scale
  sta PPUADDR
  and #$80
  sta PPUADDR
  ldy #15
loop:
  ldx offtable,y
  .repeat 8, I
    lda scale_plane0+I,x
    sta PPUDATA
  .endrepeat
  dey
  bpl loop
  rts
.pushseg
.segment "RODATA"
offtable:
  .repeat ::SCALE_PLANE_NTILES, I
    .byte (2*SCALE_PLANE_NTILES-1-I)*8, (SCALE_PLANE_NTILES-1-I)*8
  .endrepeat
.popseg
.endproc

