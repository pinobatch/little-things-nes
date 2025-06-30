;
; MMC3 oversize test: global variables
; Copyright 2025 Damian Yerrick
; SPDX-License-Identifier: Zlib
;
.globalzp mmc3_reg_values, mmc3_ctrl_value
.globalzp cur_keys, new_keys, das_keys, das_timer
.global autorepeat, read_pad_1
.globalzp DAS_DELAY

.repeat 10, I
  .charmap $30+I,$00+I  ; map 0-9 at $00
.endrepeat
.repeat 26, I
  .charmap $41+I,$0A+I  ; map A-Z at $0A
  .charmap $61+I,$0A+I  ; map a-z also at $0A
.endrepeat
.charmap $20,$24  ; space
.charmap $5E,$26  ; up arrow
