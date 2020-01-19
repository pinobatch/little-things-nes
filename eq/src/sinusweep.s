;
; Sine sweep generator
;
; Copyright 2017, 2020 Damian Yerrick
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

.export sinusweep
.import sine4011

.code
.align 64  ; don't cross page boundaries
.proc sinusweep
freq0 = $0C
freq1 = $0D
freq2 = $0E
freq3 = $0F

  ; Begin at 1 sample per 4 sample periods, or 1 cycle per 1024
  ; sample periods
  ldx #0
  ldy #0
  stx freq0
  stx freq1
  stx freq3
  lda #$40
  sta freq2

more:
  ; Each sample period is currently 66 cycles.
  ; Add frequency to position, stored in XXYY
  lda freq1
  asl a
  tya
  adc freq2
  tay
  txa
  adc freq3
  tax
  lda sine4011,x
  sta $4011

  ; increase frequency exponentially
  ; f = f0 * (65537/65536)^t
  ; or a doubling about every 45426 samples
  clc
  lda freq2
  adc freq0
  sta freq0
  lda freq3
  adc freq1
  sta freq1
  lda #0
  adc freq2
  sta freq2
  lda #0
  adc freq3
  sta freq3

  ; Terminate when frequency is 1 cycles per 2 sample periods
  ; for a total of 9 octaves
  bpl more
  rts
.endproc

; this triangle wave was used for testing before sine4011
; was finished
.if 0
.rodata
.align 256
tri4011:
  .repeat 128, I
    .byte I
  .endrepeat
  .repeat 128, I
    .byte 127-I
  .endrepeat
.endif