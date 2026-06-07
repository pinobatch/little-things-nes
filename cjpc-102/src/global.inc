.ifndef GLOBAL_INC
.define GLOBAL_INC

; init.s
.global reset_handler

; main.s
.global main, nmi_handler, irq_handler
.global OAM
.globalzp cur_keys, cur_throttle, new_keys, oam_used
.globalzp throttle_digits

; bg.s
.global draw_bg, format_throttle, draw_throttle

; player.s
.global init_player, move_player, draw_player_sprite

; ppuclear.s
.global ppu_clear_nt, ppu_clear_oam, ppu_screen_on

; bcd.s
.global bcd8bit

; pads.s
.global read_pads, run_dma_and_read_pads, autorepeat

.endif
