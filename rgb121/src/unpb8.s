.include "src/bitstream.h"
PPUADDR = $2006
PPUDATA = $2007
PB8_outbuf = $0100

.proc unpb8
  jsr unpb8_start
loop:
  jsr unpb8_some
  jsr unpb8_blit
  lda ciBlocksLeft
  bne loop
  rts
.endproc

.proc unpb8_start
  ldy #0
  lda (ciSrc),y
  sta ciBlocksLeft
  inc ciSrc
  bne :+
  inc ciSrc+1
:
  lda #$80
  sta ciBits
  rts
.endproc

.proc unpb8_some
  ldx #0
loop:
  jsr unpb8_oneplane
  jsr unpb8_oneplane
  dec ciBlocksLeft
  beq compdone
  cpx #128
  bcc loop
compdone:
  rts
.endproc

.proc unpb8_blit
  lda ciDst+1
  sta PPUADDR
  lda ciDst
  sta PPUADDR
  txa
  clc
  adc ciDst
  sta ciDst
  bcc :+
  inc ciDst+1
:
  ldy #0
copyloop:
  lda PB8_outbuf,y
  sta PPUDATA
  iny
  dex
  bne copyloop
  rts
.endproc

.proc unpb8_oneplane
  ldy #$00
  lda (ciSrc),y
  iny
  sec
  rol a
  sta ciBits
  lda #$00
byteloop:

  ; at this point:
  ; A: previous byte in this plane
  ; C = 0: copy byte from bitstream
  ; C = 1: repeat previous byte
  bcs noNewByte
  lda (ciSrc),y
  iny
noNewByte:
  sta PB8_outbuf,x
  inx
  asl ciBits
  bne byteloop
  clc
  tya
  adc ciSrc
  sta ciSrc
  bcc :+
  inc ciSrc+1
:
  rts
.endproc
