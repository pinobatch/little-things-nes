;
; NES controller reading code
; Copyright 2009-2011 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

;
; 2011-07: Damian Yerrick added labels for the local variables and
;          copious comments and made USE_DAS a compile-time option
;

.export read_fourscore
.exportzp cur_keys, cur_401x, new_keys


JOY1      = $4016
JOY2      = $4017
.zeropage
cur_keys: .res 4
cur_401x: .res 3
new_keys: .res 1

.code
.proc read_fourscore
lastFrameKeys = $04

  ; store controller 1's state to detect key-down later
  lda cur_keys+0
  sta lastFrameKeys

  ; thisRead+1 and thisRead+3 are ring counters
  lda #$01
  sta cur_keys+1
  sta cur_keys+3

  ; Write 1 then 0 to JOY1 to send a latch signal, telling the
  ; controllers to copy button states into a shift register
  sta JOY1
  lsr a
  sta JOY1
  loop_12p:
    lda JOY1        ; read player 1's controller
    sta cur_401x+0  ; save expansion bits
    lsr a           ; carry=D0; ignore D1-D7
    rol cur_keys+0  ; put one bit in the register
    lda JOY2        ; read player 2's controller the same way
    sta cur_401x+1
    lsr a
    rol cur_keys+1
    bcc loop_12p    ; once $01 has been shifted 8 times, we're done

  lda lastFrameKeys   ; A = keys that were down last frame
  eor #$FF            ; A = keys that were up last frame
  and cur_keys+0      ; A = keys down now and up last frame
  sta new_keys+0

  ; same for players 3 and 4
  loop_34p:
    lda JOY1
    lsr a
    rol cur_keys+2
    lda JOY2
    lsr a
    rol cur_keys+3
    bcc loop_34p
  
  lda $4018
  sta cur_401x+2

  rts
.endproc

