.ifndef GLOBAL_INC
.define GLOBAL_INC

; init.s
.global reset_handler

; main.s
.global main, nmi_handler, irq_handler
.global OAM
.globalzp nmis, cur_keys, new_keys, oam_used

; title.s
.global show_title_screen

; ppuclear.s
.global ppu_clear_nt, ppu_clear_oam, ppu_screen_on, ppu_vsync

; pads.s
.global read_pads

; selfmodengine.s
.global setup_selfmodarea, selfmodarea

.endif
