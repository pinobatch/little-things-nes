.p02
.include "nes.inc"
.segment "CODE"
;;
; Reads the controller safely.
; 
; If the DPCM DMA reads memory at exactly the same cycle that
; the program reads $4016/$4017, the NES may send out a spurious
; clock pulse, causing the controller to skip a button.
; Wait until we get 2 reads in a row with the same data.
; 
; @param X number of controller to read
;        (0: player 1; 1: player 2)
; @return Controller data in Y
.proc safeReadPad
  joyData = 0

  ; Register Y holds the last read data.
  jsr readPadOnce
@loop:
  ldy joyData
  jsr readPadOnce
  cpy joyData
  bne @loop
  rts

readPadOnce:
  lda #1
  sta joyData ; when the 1 gets shifted out, we're done
  sta P1
  lda #0
  sta P1
@button:
  lda P1,x    ; read a button state from the controller
  and #$03    ; only interested in D0 or D1
  cmp #1      ; set carry iff D0 or D1 is set
  rol joyData ; store the button state and retrieve the stop bit
  bcc @button ; loop while the stop bit is still 0
  rts

.endproc
