.include "cigetbit.inc"

.segment "ZEROPAGE"
; these are used for streaming decompression
; (one block per vblank)
ciSrc: .res 2
ciDst: .res 2
ciBits: .res 1
ciBlocksLeft: .res 1
ciBank: .res 1

.segment "CODE"
; about 27 cycles
.proc ciGetByte
  pha
  lda (ciSrc),y
  iny
  bne :+
  inc ciSrc+1
:
  rol a
  sta ciBits
  pla
  rts
.endproc

.proc ciGetGammaCode
; 1. Get the length of the number
  lda #0
  sec
loop1:
  ror a
  beq twofiftysix
  ciGetBit
  bcc loop1

; 2. Get the bits of the number
  bcs loop2entrance
loop2:
  ciGetBit
loop2entrance:
  rol a
  bcc loop2
twofiftysix:
  rts
.endproc
