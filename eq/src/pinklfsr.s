;
; Voss-McCartney pink noise generator
;
; Copyright 2017 Damian Yerrick
; 
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;


; The Voss-McCartney algorithm for pink noise
; http://www.firstpr.com.au/dsp/pink-noise/allan-2/spectrum2.html
; Take several sample-and-hold white noise generators with
; frequencies an octave apart, choose which one to clock based on
; count_trailing_zeroes(t), add these generators' outputs, and
; add some high-frequency white noise to fill the nulls

.export pinklfsr
.import ctzindex

NUM_CHANNELS = 16
.bss
prevval: .res NUM_CHANNELS

.code
.proc pinklfsr

samplecountlo = $0A
samplecounthi = $0B
cumul = $0C
lfsrlo = $0D
lfsrmd = $0E
lfsrhi = $0F
  lda #2
  sta lfsrlo
  sta lfsrmd
  sta lfsrhi
  lda #0
  sta cumul
  ldx #NUM_CHANNELS-1
clrloop:
  sta prevval,x
  dex
  bpl clrloop

  ; White noise to fill in "nulls" in the LFSR's output,
  ; particularly in the high end
  lda #$08
  sta $4015
  lda #$32
  sta $400C
  lda #$04
  sta $400E
  sta $400F

loop:

  ; Find which of the 16 channels to use
  lda #0
  cmp samplecountlo
  rol a
  tax  ; X is 1 if samplecountlo == 0 else 0
  ldy samplecountlo,x
  asl a
  asl a
  asl a
  adc ctzindex,y
  tax
  
  ; Remove the old value from the sum
  lda cumul
  sec
  sbc prevval,x
  sta cumul
  
  asl lfsrlo
  rol lfsrmd
  rol lfsrhi
  lda #$FF
  adc #0
  eor #$FF
  and #$06
  eor lfsrlo
  sta lfsrlo
  and #$04
  sta prevval,x
  clc
  adc cumul
  sta cumul
  sta $4011

  clc
  lda #1
  adc samplecountlo
  sta samplecountlo
  bcc loop
  lda #0
  adc samplecounthi
  sta samplecounthi

  ; Once every 4096 samples, give option to exit
  and #$0F
  bne loop
  lda #$01
  sta $4016
  lsr a
  sta $4016
  lda $4016
  lda #3
  and $4016
  beq loop
  lda #$00
  sta $400C
  rts
.endproc