.include "ram.h"

tempoCounterLo = 8
tempoCounterHi = 9
tvSystem = 10
rpb = 11

.proc getCurBeatFraction
  ldx tvSystem
  beq isNTSC_1
  ldx #1
isNTSC_1:

  ; as an optimization in the music engine, tempoCounter is
  ; actually stored as a negative number: -3606 through -1
  clc
  lda tempoCounterLo
  adc fpmLo,x
  sta 0
  lda tempoCounterHi
  adc fpmHi,x

  ; at this point, A:0 = tempoCounter + fpm (which I'll
  ; call ptc for positive tempo counter)
  ; Divide by 16 by shifting bits 4-11 up into A
  .repeat 4
    asl 0
    rol a
  .endrepeat

  ldy reciprocal_fpm,x
  ; A = ptc / 16, Y = 65536*6/fpm
  jsr mul8

  ; A:0 = ptc * 4096*6 / fpm, in other words, A = ptc * 96 / fpm
  sta 2
  
  ; now shift rpb to the right in case it's a power of 2
  lda rpb
rpbloop:
  lsr a
  bcs rpbdone
  lsr 2
  bpl rpbloop
rpbdone:

  ; The supported values of rpb are 1<<n (simple meter) and
  ; 3<<n (compound meter).  Handle 1<<n quickly.
  bne rpb_not_one
  lda 2
  rts
rpb_not_one:

  ; Otherwise, rpb is 3<<n, which is slightly slower because we
  ; have to divide by 3 by multiplying by 85/256.
  lda 2
  ldy #$55
  jmp mul8
.endproc


.segment "RODATA"

fpmLo: .byt <3606, <3000
fpmHi: .byt >3606, >3000
; Reciprocals of frames per second:
; int(round(65536*6/n)) for n in [3606, 3000]
reciprocal_fpm: .byt 109, 131

