.include "ram.h"


; 57 if any nonzero bits; less if all zero
.proc count_ones_masked
  ; bits to 2-bit units
  sta 0
  and #%01010101
  eor 0
  lsr a
  adc 0
  beq is_zero

  ; 2-bit units to nibbles
  sta 0
  and #%00110011
  eor 0
  lsr a
  lsr a
  adc 0

  sta 0
  and #%00001111
  eor 0
  lsr a
  lsr a
  lsr a
  lsr a
  adc 0
is_zero:
  rts
.endproc

; 12 plus 10 per one or less
.proc count_ones_shifting
  lsr a
  sta 0
  lda #0
loop:
  adc #0
  lsr 0
  bne loop
  rts
.endproc

; 11 plus 13 per one
.proc count_ones_subtract
  ldy #0
  cmp #1
  bcc done
loop:
  iny
  sta 0
  sbc #1
  and 0
  bne loop
done:
  tya
  rts
.endproc


; by Damian Yerrick
.proc parity_by_adding
bytetosend = 0
  lda bytetosend
  lsr a
  eor bytetosend
  ; diverge starts here
  and #%01010101  ; ,6.4.2.0
  ; Possible nibbles: 0, 1, 4, or 5.
  ; If we add 3, we get 3, 4, 7, or 8, whose bit 2
  ; is the nibble's parity.
  clc
  adc #%00110011  ; combine 0 into 2 and 4 into 6
  and #%01000100  ; .6...2..
  ; now possible bytes are $00, $04, $40, or $44
  adc #%00111100  ; combine bit 2 into bit 6
  and #%01000000
  ; At this point, bit 6 is parity and bit 7 is zero.
  ; Therefore we can AND #%01000000 if we want to BNE,
  ; ASL A if we want to BMI, or if we want to BCS:
  cmp #1
  rts
.endproc

; by Kevin Horton
; http://pastebin.com/eRibRP6G
.proc parity_by_shifting
bytetosend = 0
  lda bytetosend
  lsr a
  eor bytetosend
  ; begin diverge
  sta bytetosend
  lsr a
  lsr a
  eor bytetosend
  sta bytetosend
  lsr a
  lsr a
  lsr a
  lsr a
  eor bytetosend
  ; bit 0 is parity
  lsr a
  ; end diverge
  rts
.endproc

