; main.s
.globalzp cur_keys, new_keys, das_keys, das_timer
.globalzp nmis, FME7_lastreg
.global OAM
.global term_getc

; ppuclear.s
.global ppu_clear_oam, ppu_clear_nt, ppu_screen_on

; pads.s
.global read_pads, autorepeat

; vwf_draw.s
.globalzp lineImgBufLen
.global lineImgBuf, clearLineImg, copyLineImg, invertTiles
.global vwfPutTile, vwfGlyphWidth
.global vwfPuts0, vwfPuts, vwfStrWidth0, vwfStrWidth

; vwf7.s
.global vwfChrWidths

; term.s
.globalzp cursor_y, scroll_y, update_y, last_PPUCTRL
.global term_irq, irq_handler, term_nmi, nmi_handler
.global term_init, term_cls, term_putc, term_flush, term_remeasure
.global term_puts, term_puts0, term_set_status, term_discard_line
.global term_gets
.global term_length, term_prompt_length, term_buf, term_busy

; paldetect.s
.global getTVSystem
