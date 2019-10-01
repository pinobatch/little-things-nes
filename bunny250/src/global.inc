OAM = $0200

.global OAM

; ppuclear.s
.global ppu_clear_nt, ppu_clear_oam, ppu_screen_on
; bcd.s
.global bcd8bit
; puts.s
.global puts_multiline_16, puts_16
; paldetect.s
.global getTVSystem
.globalzp tvSystem
.globalzp nmis
; pads.s
.global read_pads
.globalzp cur_keys, new_keys
;measuretime.s
.global wait_256_or_light
