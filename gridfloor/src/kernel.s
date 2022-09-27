.include "global.inc"
GRID_VIEW_HT = 64
LOG_CELL_DEPTH = 5

.zeropage
xscroll_sub: .res 1
slope_sub: .res 1
slope_px: .res 1
yslope_px: .res 1
camera_zpos: .res 1

.bss
scrolly: .res GRID_VIEW_HT

.code

.proc run_kernel
cycle_fraction = $00
combinetmp = $01
rowsleft = $02
  sta rowsleft
loop:
  lda cycle_fraction
  clc
  adc #171
  sta cycle_fraction
  bcs :+
  :  ; 12.67 cycles to add a fractional cycle

  lda #0  ; nametable in bits 11-10
  sta $2006
  lda scrolly,y
  sta $2005
  asl a
  asl a
  and #$E0
  sta combinetmp
  txa
  lsr a
  lsr a
  lsr a
  ora combinetmp
  stx $2005
  sta $2006  ; 42 cycles to drop in both writes

  clc
  lda xscroll_sub
  adc slope_sub
  sta xscroll_sub
  txa
  adc slope_px
  tax
  clc
  tya
  adc yslope_px
  tay  ; 27 cycles to update xy
  
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop

  dec rowsleft
  bne loop   ; 8 cycles to loop
  .assert >(*) = >(loop), error, "loop wraps"
  ; total: 87.67
  ; 26 free cycles on NTSC; add nops as needed to reach 25
  rts
.endproc

.proc calc_depths
  ldy #GRID_VIEW_HT-1
  ; 12 * GRID_VIEW_HT = 768
  clrloop:
    tya
    sta scrolly,y
    dey
    .assert GRID_VIEW_HT<128, error, "bpl loop inadequate for array size"
    bpl clrloop

  lda camera_zpos
  and #(1 << LOG_CELL_DEPTH) - 1
  ; 32 * (256 >> LOG_CELL_DEPTH) = 256
  zposloop:
    tax
    ldy depth_to_y,x
    .repeat ::LOG_CELL_DEPTH
      lsr a
    .endrepeat
    adc #GRID_VIEW_HT
    sta scrolly,y
    txa
    clc
    adc #1 << LOG_CELL_DEPTH
    bcc zposloop
  rts
.endproc

.rodata
depth_to_y:
  .repeat 256, I
    .byte 128 - 128 * 256 / (256 + I)
  .endrepeat
