.ifndef GLOBAL_INC
.define GLOBAL_INC

A53_SELECT = $5000
  A53_CHR = $00
  A53_PRG = $01
  A53_MODE = $80
    A53_MODE_32K = $00
    A53_MODE_64K = $10
    A53_MODE_128K = $20
    A53_MODE_256K = $30
    A53_MODE_FIXLO = $08
    A53_MODE_FIXHI = $0C
    A53_MIRR_0 = $00
    A53_MIRR_1 = $01
    A53_MIRR_V = $02
    A53_MIRR_H = $03
  A53_OUTER_PRG = $81
A53_DATA = $8000

; init.s
.global reset_handler

; main.s
.global main, nmi_handler, irq_handler
.global OAM
.globalzp cur_keys, new_keys, oam_used

; bg.s
.global draw_bg

; test.s
.global run_test
.globalzp testresult_size, testresult_bugged

; ppuclear.s
.global ppu_clear_nt, ppu_clear_oam, ppu_screen_on

.endif
