.ifndef GLOBAL_INC
.define GLOBAL_INC

; supported values: 0, 1, 4
MAPPER = 4

; init.s
.global reset_handler

; main.s
.global main, nmi_handler, irq_handler
.global OAM
.globalzp cur_keys, new_keys, oam_used

; bg.s
.global draw_title_bg

; ppuclear.s
.global ppu_clear_nt, ppu_clear_oam, ppu_screen_on

; pads.s
.global read_pads

.endif
