;
; NES controller reading code (port 1, no DPCM safety, autorepeat)
; Copyright 2025 Damian Yerrick
; SPDX-License-Identifier: Zlib
;

.export read_pad_1
.importzp cur_keys, new_keys, das_keys, das_timer

JOY1      = $4016
JOY2      = $4017
DAS_DELAY = 15  ; time until autorepeat starts making keypresses
DAS_SPEED = 3   ; time between autorepeat keypresses

.segment "CODE"
;;
; Reads controller 1 with autorepeat.
; No rereading is performed, nor synchronization to APU put cycles.
.proc read_pad_1
  lda cur_keys
  pha
  lda #1  ; strobe
  sta JOY1
  sta cur_keys  ; init ring counter; when 1 bit reaches CF, it's done
  lsr a
  sta JOY1
  readloop:
    lda JOY1       ; read player 1's controller
    and #%00000011 ; keep only D0 (FC hardwired, NES plug-in) and D1 (FC plug-in)
    cmp #1         ; CLC if A=0, SEC if nonzero
    rol cur_keys   ; put one bit in the register
    bcc readloop

  ; Find which keys have been pressed since last read
  pla
  eor #$FF
  and cur_keys
  sta new_keys
  beq no_restart_das
    sta das_keys
    lda #DAS_DELAY
    sta das_timer
    bne no_das
  no_restart_das:
    lda cur_keys
    beq no_das
    dec das_timer
    bne no_das
    lda #DAS_SPEED
    sta das_timer
    lda das_keys
    and cur_keys
    ora new_keys
    sta new_keys
  no_das:
  rts
.endproc
