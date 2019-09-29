.include "nes.inc"
.include "global.inc"

DAC = $4011
SNDCHN_TRI = $04
SNDCHN_NOISE = $08

.code

;;
; Writes a 1 kHz pulse wave to the DAC.
; @param $00 low value
; @param $01 high value
; @param $02 number of cycles, or length in ms
.proc onekpulse
lowvalue = $00
highvalue = $01
numcycles = $02

  ; At 1.790 MHz, we want 447 low, 895 high, 448 low
  lda lowvalue
  sta DAC
  loop:
    ; 447 low: 440+4+3
    jsr delay440
    lda highvalue
    sta DAC
    ; 895 high: 440+440+4+4+4+3
    jsr delay440
    jsr delay440
    bit $FFFF
    bit $FFFF
    lda lowvalue
    sta DAC
    ; 448 low: 440+2+3+3
    jsr delay440
    nop
    dec numcycles
    bne loop
  .assert >* = >loop, error, "onekpulse::loop crosses page"
  clc
  lda lowvalue
  adc highvalue
  ror a
  sta DAC
  rts
.endproc

.proc delay_50_ms
  ldy #50
.endproc
.proc delay_y_ms
  ; each cycle takes 1790 cycles
  ; waste 1760
  jsr delay440
  jsr delay440
  jsr delay440
  jsr delay440
  ; waste 25 more
  jsr delay12
  bit $FFFF
  bit $FFFF
  bit $FF
  nop
  ; loop counting takes 5
  dey
  bne delay_y_ms
.assert >* = >delay_y_ms, error, "delay_y_ms crosses page"
delay12:
  rts
.endproc

.proc delay440
  bit $FFFF
  bit $FFFF
  jsr delay216
.endproc
.proc delay216
  jsr delay108
.endproc
.proc delay108
  jsr delay36
  jsr delay36
.endproc
.proc delay36
  jsr delay12
  jsr delay12
delay12:
  rts
.endproc

;;
; Enables the triangle channel playing a ultrasonic (55 kHz) tone.
; This is above the Nyquist rate of even a 96 kHz sample.
.proc set_tri_ultrasonic
  lda #SNDCHN_TRI
  sta SNDCHN
  lda #$00
  sta $400A
  sta $400B
  lda #$C0
  sta $4008
  sta $4017
  rts
.endproc

;; 
; Produces 50 ms 1000 Hz tones on DAC, each preceded by roughly 50 ms
; silence.  Levels start at (0, 7), advance to (0, 127) in steps of
; 8, and advance to (120, 127) in steps of 8.  The triangle wave is
; ultrasonic during this test.
.proc dacpulseramp
lowvalue = $00
highvalue = $01
numcycles = $02

  ; Set the initial DAC value
  lda #0
  sta lowvalue
  lda #7
  sta highvalue
  lsr a
  sta DAC
  jsr set_tri_ultrasonic

  ; Wait for levels to stabilize first
  jsr delay_50_ms
  loop1:
    ldy #50
    sty numcycles
    jsr delay_y_ms
    jsr onekpulse
    clc
    lda lowvalue
    bne increasing_lowvalue
    
      ; In the phase from
      lda highvalue
      adc #8
      bmi increasing_lowvalue
      sta highvalue
      jmp loop1
    increasing_lowvalue:

    ; In the phase from 8,127 to 120,127
    lda lowvalue
    adc #8
    sta lowvalue
    bpl loop1

  ; Also wait for stability after the test
  jmp delay_50_ms
.endproc

TRI_1K_PERIOD = 55
TRI_500HZ_PERIOD = 111

;;
; Produces 50 ms 1000 Hz tones on triangle with DAC set to 4, 12, 20,
; ..., 124, with 50 ms of triangle ultrasound between them.
.proc triramp
lowvalue = $00

  lda #4
  sta lowvalue
  sta DAC
  jsr set_tri_ultrasonic

  ; Wait for levels to stabilize first
  jsr delay_50_ms
  loop:
    jsr delay_50_ms
    lda lowvalue
    sta DAC
    lda #TRI_1K_PERIOD
    sta $400A
    jsr delay_50_ms
    lda #0
    sta $400A
    clc
    lda lowvalue
    adc #8
    sta lowvalue
    bpl loop
  jmp delay_50_ms
.endproc

;;
; Produces 50 ms LFSR noise on triangle with DAC set to 4, 12,
; 20, ..., 124, with 50 ms of triangle ultrasound between them.
.proc noiseramp
lowvalue = $00

  lda #4
  sta lowvalue
  sta DAC
  
  ; Enable noise at 0 volume
  jsr set_tri_ultrasonic
  lda #SNDCHN_NOISE|SNDCHN_TRI
  sta SNDCHN
  lda #$30
  sta $400C
  lda #$33  ; FamiTracker pitch C-#
  sta $400E
  lda #$00
  sta $400F

  ; Wait for levels to stabilize first
  jsr delay_50_ms
  loop:
    jsr delay_50_ms
    lda lowvalue
    sta DAC
    lda #$3F
    sta $400C
    jsr delay_50_ms
    lda #$30
    sta $400C
    clc
    lda lowvalue
    adc #8
    sta lowvalue
    bpl loop
  jmp delay_50_ms
.endproc

.proc triseparator
  jsr delay_50_ms
  jsr set_tri_ultrasonic
  lda #0
  sta DAC
  jsr delay_200_ms

  lda #TRI_500HZ_PERIOD
  sta $400A
  jsr delay_200_ms
  
  lda #0
  sta $400A
delay_200_ms:
  ldy #200
  jmp delay_y_ms
.endproc
