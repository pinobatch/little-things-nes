.export mod30

mod30In = $0000

;;
; Calculates the remainder of a number / 30
; in roughly 70 cycles.
; For a four digit hex number $DCBA,
; D * 4096 + C * 256 + B * 16 + A
; is congruent to (D + C + B) * 16 + A (mod 30).
; @param mod30In a 16-bit number 
; @return the number mod 30, in register A
.proc mod30

; Calculate C * 16
  lda mod30In+1
  asl a
  asl a
  asl a
  asl a

; Add D * 16
  clc
  adc mod30In+1
  and #$F0

; At each addition, make 256 wrap around to 16
; because 256 is congruent to 16 (mod 30).
  bcc :+
  sbc #240
:

; Add B * 16 + A
  adc mod30In
  bcc :+
    sbc #240
  :

; Subtract off portions greater than 30
  cmp #240
  bcc :+
    sbc #240
  :
  cmp #120
  bcc :+
    sbc #120
  :
  cmp #60
  bcc :+
    sbc #60
  :
  cmp #30
  bcc :+
    sbc #30
  :
  rts
.endproc
