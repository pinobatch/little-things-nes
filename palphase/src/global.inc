OAM = $0200

; ppu
.global OAM
.global ppu_clear_oam, ppu_screen_on, read_pads

; keys
.global read_pads
.globalzp cur_keys, new_keys
