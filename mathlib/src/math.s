;
; math.s
; Arithmetic and trigonometry routines for Thwaite
;
; Copyright (c) 2011 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

;
; The NES CPU has no FPU, nor does it have a multiplier or divider
; for integer math.  So we have to implement these in software.
; Here are subroutines to compute 8x8=16-bit product, a fractional
; quotient in 0.8 fixed point, 2-argument arctangent, and rectangular
; to polar coordinate conversion.  Also included are lookup tables of
; sine and cosine for angles expressed in units of 1/32 of a turn
; from due right, where cos(0) = cos(32) = sin(8) = 1.0.
; 
; Further information:
; http://en.wikipedia.org/wiki/Fixed-point_arithmetic
; http://en.wikipedia.org/wiki/Binary_multiplier
; http://en.wikipedia.org/wiki/Boxing_the_compass
; http://en.wikipedia.org/wiki/Binary_scaling#Binary_angles
;

.include "ram.h"
.segment "CODE"

;;
; Multiplies two 8-bit factors to produce a 16-bit product
; in about 153 cycles.
; @param A one factor
; @param Y another factor
; @return high 8 bits in A; low 8 bits in $0000
;         Y and $0001 are trashed; X is untouched
.proc mul8
factor2 = 1
prodlo = 0

  ; Factor 1 is stored in the lower bits of prodlo; the low byte of
  ; the product is stored in the upper bits.
  lsr a  ; prime the carry bit for the loop
  sta prodlo
  sty factor2
  lda #0
  ldy #8
loop:
  ; At the start of the loop, one bit of prodlo has already been
  ; shifted out into the carry.
  bcc noadd
  clc
  adc factor2
noadd:
  ror a
  ror prodlo  ; pull another bit out for the next iteration
  dey         ; inc/dec don't modify carry; only shifts and adds do
  bne loop
  rts
.endproc

;;
; Computes (256*a+x)/y, provided that a < y.
; 0-2 are trashed.
; out: remainder in A; quotient in 0
.proc divaxbyy
quotient = 0
divisor = 1
dividendlo = 2

  stx dividendlo
  sty divisor
fix2by1:
  ldy #1  ; when this gets ROL'd eight times, the loop ends
  sty quotient
loop:
  asl dividendlo
  rol a
  bcs alreadyGreater
  cmp divisor
  bcc nosub
alreadyGreater:
  sbc divisor
  sec
nosub:
  rol quotient
  bcc loop
  rts
.endproc

;;
; Alternate entry point to divaxbyy:
; in: dividend high in A, low in $02,
;     divisor in $01 which never modified
; out: quotient in 0, remainder in A
diva2by1 = divaxbyy::fix2by1

;;
; Computes 256*a/y.  Useful for finding slopes.
; 0-2 are trashed.
.proc getSlope1
quotient = 0
divisor = 1

  sty divisor
  ldy #1  ; when this gets ROL'd eight times, the loop ends
  sty quotient
loop:
  asl a
  bcs alreadyGreater
  cmp divisor
  bcc nosub
alreadyGreater:
  sbc divisor
  sec  ; without this, results using alreadyGreater are wrong
       ; thx to http://6502org.wikidot.com/software-math-intdiv
       ; for helping solve this
nosub:
  rol quotient
  bcc loop
  lda quotient
  rts
.endproc

UNITS_PER_TURN = 32

;;
; Find the angle of a vector pointing from (x1, y1) to (x2, y2),
; all coordinates unsigned.
; This is also called arctan2 or (on TI calculators) "R>Ptheta".
; @param 0 x1
; @param 1 y1
; @param 2 x2
; @param 3 y2
; @return A: angle (0-31);
;         0: slope reflected into first octant;
;         1: angle reflected into first octant;
;         2, 3: point reflected into first octant
;         Trashes Y and nothing else.
.proc getAngle
x1 = 0
y1 = 1
x2 = 2
y2 = 3
flags = 4

  lda y2
  cmp y1
  bne notHorizontal
  lda x2
  cmp x1
  lda #0  ; (+x, 0): 0 degrees
  sta 1
  bcs :+
  lda #UNITS_PER_TURN/2  ; (-x, 0): 180 degrees
:
  rts

notHorizontal:
  ; make sure x2 > x1
  lda x2
  cmp x1
  bne notVertical
  lda y2
  cmp y1
  lda #$FF
  sta 3
  lda #0  ; store first-octant angle
  sta 1
  lda #UNITS_PER_TURN*3/4  ; (0, -y): 270 degrees
  bcc :+
  lda #UNITS_PER_TURN*1/4  ; (0, +y): 90 degrees
:
  rts
notVertical:

  ; At this point, we have already eliminated the special cases of a
  ; perfectly horizontal or vertical ray.
  ; So now compute the sign and abs of (y2 - y1)
  sec
  lda y2
  sbc y1
  bcs noVerticalFlip
  eor #$FF
  adc #1
noVerticalFlip:
  sta y1

  lda #0
  rol a
  sta flags  ; flag 2: SKIP y flip (angle = 360 deg - angle)

  ; Compute the sign and abs of (x2 - x1)
  sec
  lda x2
  sbc x1
  bcs noHorizontalFlip
  eor #$FF
  adc #1
noHorizontalFlip:
  sta x1
  rol flags  ; flag 1: SKIP x flip (angle = 180 deg - angle)

  ; if x1 > y1 then swap x1 and y1
  lda y1
  cmp x1
  bcc noDiagonalFlip
  ldy x1
  sty y1
  sta x1
noDiagonalFlip:
  rol flags  ; flag 0: PERFORM diagonal flip (angle = 90 deg - angle)

  lda y1
  sta y2
  ldy x1
  sty x2
  jsr getSlope1
  sta x1

  ldy #UNITS_PER_TURN/8
tansearch:
  cmp tantable-1,y
  bcs foundTan
  dey
  bne tansearch
foundTan:
  tya
  sta y1

  lsr flags
  bcc noUndoDiagonal
  eor #$FF  ; reverse-subtract 8
  adc #UNITS_PER_TURN/4
noUndoDiagonal:

  lsr flags
  bcs noUndoHorizontal
  eor #$FF  ; reverse-subtract 16
  adc #UNITS_PER_TURN/2+1   ; plus one because we came in with clc
noUndoHorizontal:

  lsr flags
  bcs noUndoVertical
  eor #$FF  ; reverse-subtract 32
  adc #UNITS_PER_TURN+1   ; plus one because we came in with clc
noUndoVertical:

  ; 2013-12-27: Nova reported returning UNITS_PER_TURN instead of
  ; 0 for some angles that were close to due east.
  ; Wrap them.
  and #UNITS_PER_TURN-1
  rts
.endproc

.segment "RODATA"

; Tangents of angles between the ordinary angles, used by getAngle.
; Made with mktrigtable.py
tantable:
.if UNITS_PER_TURN = 32
  .byt 25,78,137,210
.elseif UNITS_PER_TURN = 64
  .byt 13,38,64,92,121,153,190,232
.elseif UNITS_PER_TURN = 128
  .byt 6,19,32,44,57,71,85,99,113,129,145,162,180,200,221,244
.elseif UNITS_PER_TURN = 256
  .byt 3,9,16,22,28,35,41,48,54,61,67,74,81,88,95,102,110,117,125,133,141,149,158,167,176,185,195,205,215,226,238,250
.else
  .error "Unknown UNITS_PER_TURN"
.endif

.segment "CODE"

;;
; Takes the square root and remainder of a 16-bit integer.
; Per http://6502org.wikidot.com/software-math-sqrt
; out: root in $02; remainder in $03;
;      high bit of remainder in carry
.proc sqrt16
numLo = 0
numHi = 1
root = 2
remainder = 3

  ldx #0
  stx root
  stx remainder
  ldx #8
loop:
  sec
  lda numHi
  sbc #$40
  tay
  lda remainder
  sbc root
  bcc no_store
  sty numHi
  sta remainder
no_store:
  rol root
  asl numLo
  rol numHi
  rol remainder
  asl numLo
  rol numHi
  rol remainder
  dex
  bne loop
  rts
.endproc


.segment "RODATA"

; Accurate sin/cos table used by measureFromSilo.
; These are indexed by angle in quadrant 1, and scaled by 256.
; (90*7/8)s*256=
sine256Q1:
  .byt 0, 50, 98, 142, 181, 213, 237, 251
cosine256Q1:
  .byt  0, 251, 237, 213, 181, 142, 98, 50

; Less precise sin/cos table used by e.g. missile smoke generation.
; These are indexed by angle through the whole circle
; and scaled by 64.
; (90*7/8)s*64=
missileSine:
  .byte   0, 12, 24, 36, 45, 53, 59, 63
missileCosine:
  .byte   64,  63,  59,  53,  45,  36,  24,  12
  .byte    0,<-12,<-24,<-36,<-45,<-53,<-59,<-63
  .byte <-64,<-63,<-59,<-53,<-45,<-36,<-24,<-12
  .byte    0,  12,  24,  36,  45,  53,  59,  63

