.include "global.inc"

; ld65 won't spit out a function's address in the map
; unless the address is actually used in the program.
; Here I waste a byte to do just that.

s1 = mul8 ^ getSlope1 ^ getAngle ^ bcd8bit ^ bcdConvert ^ divaxbyy
s2 = diva2by1 ^ pctageDigit ^ sqrt16 ^ UNITS_PER_TURN
s3 = getCurBeatFraction ^ parity_by_shifting ^ parity_by_adding
.segment "RODATA"
.byt <(s1 ^ s2 ^ s3)

