; Bitstream access ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.globalzp ciSrc, ciBank, ciDst, ciBits, ciBlocksLeft
.global ciGetByte, ciGetGammaCode

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

; Codecs

.global PKB_unpackblk
.global un2btStart, un2btSome, un2btFull, un2btBlit
.global unpb8, unpb8_start, unpb8_some, unpb8_blit

