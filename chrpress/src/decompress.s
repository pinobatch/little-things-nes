.include "nes.inc"

ciSrc = 0
ciTmp2 = 2
ciTmp3 = 3
ciBits = 4
ciTmp5 = 5
ciTmp6 = 6
ciTmp7 = 7
decompressBuf = $0100

;;
; Gets a bit from the compressed stream and returns it in carry.
; A is unchanged, but Y may be incremented.
; Uses the sentinel "A is 0 but carry is true" to tell when a new
; byte is needed.
; Takes 12 cycles on average.
.macro ciGetBit
  .local noNewByte
  asl ciBits
  bne noNewByte
  jsr ciGetByte
noNewByte:
.endmacro

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

;;
; Reads a number from 0 to 3 into A.  Carry is clear.
.proc ciGet2Bits
  lda #0
  ciGetBit
  rol a
  ciGetBit
  rol a
  rts
.endproc

.proc ciGetGammaCode
; 1. Get the length of the number
  lda #0
  sec
loop1:
  ror a
  ciGetBit
  bcc loop1

; 2. Get the bits of the number
  bcs loop2entrance
loop2:
  ciGetBit
loop2entrance:
  rol a
  bcc loop2
  rts
.endproc

.proc decodeBlock
; initialize the byte buffer
  ldy #$80
  sty ciBits
  ldy #0

; get the block's mode
  jsr ciGet2Bits
  cmp #3
  bcc is1BitBlock
  jmp decode2BitBlock
is1BitBlock:
  rts
.endproc

.proc decode2BitBlock
  rts
.endproc

.export testCompression
.proc testCompression
left = 7
dstLo = 8
dstHi = 9

  ; initialize the byte buffer
  lda #<deniedpng2
  sta ciSrc
  lda #>deniedpng2
  sta ciSrc+1
  ldy #$80
  sty ciBits
  ldy #0
  tya

  lda #$00
  sta PPUADDR
  ldx #$00
  stx PPUADDR
  lda #64
  sta left

loop:
  jsr decompressBlock
  jsr blitCompressedData
  dec left
  bne loop
  rts
.endproc

.proc decompressBlock

firstColor = ciTmp2
colorXorValue = ciTmp3
commonRunLength = ciTmp5
curRunLength = ciTmp6


  ; fill bitplane 1 of all tiles with "8 bits left"
  ldx #15
  lda #1
:
  sta decompressBuf+32,x
  sta decompressBuf+48,x
  dex
  bpl :-

; get the mode
  lda #0
  ciGetBit
  rol a
  ciGetBit
  rol a
  bne is1BitTile
  jmp decompress2BitBlock
is1BitTile:
  ciGetBit
  rol a
  tax
  lda firstColorFor2Bit-2,x
  sta firstColor
  eor secondColorFor2Bit-2,x
  sta colorXorValue
  jsr ciGetGammaCode
  sta commonRunLength
  ldx #0
  ciGetBit
  bcc runloop
  lda firstColor
  eor colorXorValue
  sta firstColor
runloop:
  jsr ciGetGammaCode
  cmp commonRunLength
  bne notCommonRunLength
  lda #1
  bne gotRunLength
notCommonRunLength:
  cmp #1
  bne gotRunLength
  lda commonRunLength
gotRunLength:
  sta curRunLength
pxloop:
  lda firstColor
  lsr a
  rol decompressBuf,x
  lsr a
  rol decompressBuf+32,x
  bcc notNextByte
  inx
  cpx #32
  bcs bail
notNextByte:
  dec curRunLength
  bne pxloop
  lda firstColor
  eor colorXorValue
  sta firstColor
  jmp runloop
bail:
  rts
  
.endproc

.proc decompress2BitBlock
firstColor = ciTmp2
colorXorValue = ciTmp3
commonRunLength = ciTmp5
curRunLength = ciTmp6

  ; 1. Get most common xor value
  ciGetBit
  bcc :+
  ciGetBit
  adc #1
:
  adc #1
  sta colorXorValue
  ldx #$3F
  jsr ciGetGammaCode
  sta commonRunLength
  lda #0
  ciGetBit
  rol a
  ciGetBit
  rol a
  sta firstColor
  ldx #0
runloop:
  jsr ciGetGammaCode
  cmp commonRunLength
  bne notCommonRunLength
  lda #1
  bne gotRunLength
notCommonRunLength:
  cmp #1
  bne gotRunLength
  lda commonRunLength
gotRunLength:
  sta curRunLength
pxloop:
  lda firstColor
  lsr a
  rol decompressBuf,x
  lsr a
  rol decompressBuf+32,x
  bcc notNextByte
  inx
  cpx #32
  bcs bail
notNextByte:
  dec curRunLength
  bne pxloop

  ; get next color
  ciGetBit
  bcc :+
  ciGetBit
  adc #1
:
  adc #1
  cmp colorXorValue
  bne notCommonXorValue
  lda #1
  bne gotXorValue
notCommonXorValue:
  cmp #1
  bne gotXorValue
  lda colorXorValue  
gotXorValue:
  eor firstColor
  sta firstColor
  jmp runloop
bail:
  rts
.endproc

.proc blitCompressedData
  clc
  ldx #0
copyloop:
  .repeat 16,I
    lda decompressBuf+4*I,x
    sta PPUDATA
  .endrepeat
  inx
  cpx #4
  bcc copyloop
  rts
.endproc


.proc phex
  pha
  lsr a
  lsr a
  lsr a
  lsr a
  sta PPUDATA
  pla
  and #$0F
  sta PPUDATA
  rts
.endproc

.segment "RODATA"
firstColorFor2Bit:
  .byt 0, 0, 0, 1, 1, 2
secondColorFor2Bit:
  .byt 1, 2, 3, 2, 2, 3
testData:
  .byt $A7,$01,$98
deniedpng2:
  .incbin "obj/nes/lj65chr.2bt"

