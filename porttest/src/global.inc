.ifndef GLOBAL_INC
.define GLOBAL_INC

; init.s
.global reset_handler

; main.s
.global main, nmi_handler, irq_handler
.global OAM
.globalzp nmis, out4016value, time_since_irq

; bg.s
.global draw_bg, update_pins

; ppuclear.s
.global ppu_clear_nt, ppu_clear_oam, ppu_screen_on

; pads.s
.global read_fourscore
.globalzp cur_keys, cur_401x, new_keys

.endif
