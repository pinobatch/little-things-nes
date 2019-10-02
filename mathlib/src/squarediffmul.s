.export squarediff_mul

.segment "CODE"
; A * Y in ~55 cycles
.proc squarediff_mul
fac_b = 2
a_lo = 1

  sty fac_b
  sta a_lo
  sec
  sbc fac_b
  bcs no_negate_amb
  eor #$FF
  adc #1
  sec
no_negate_amb:
  tax  ; X = abs(A - B)

prodlo = 0
a_hi = 2

  ; table[x + y] = (&(table[x]))[y]
  lda #>xsqdiv4_lo
  sta a_hi
  lda (a_lo),y
  sbc xsqdiv4_lo,x
  sta prodlo
  lda #>xsqdiv4_hi
  sta a_hi
  lda (a_lo),y
  sbc xsqdiv4_hi,x
  rts
.endproc

.segment "RODATA"
.align 256
xsqdiv4_lo:
  .repeat 512, I
    .byt <(I * I / 4)
  .endrepeat
xsqdiv4_hi:
  .repeat 512, I
    .byt >(I * I / 4)
  .endrepeat

