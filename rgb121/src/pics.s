.export chnaddrs, chnbanks
.exportzp NUM_PICS, MAX_IM_HEIGHT

NUM_PICS = 10
MAX_IM_HEIGHT = 168

.segment "RODATA"
; directory goes here
chnaddrs:
  .addr logo, pic01, pic02, pic03
  .addr pic04, pic05, pic06, pic07
  .addr pic08, pic09
chnbanks:
  .byte <.bank(logo), <.bank(pic01), <.bank(pic02), <.bank(pic03)
  .byte <.bank(pic04), <.bank(pic05), <.bank(pic06), <.bank(pic07)
  .byte <.bank(pic08), <.bank(pic09)

.segment "BANK00"
pic01: .incbin "obj/nes/su1.121"
pic02: .incbin "obj/nes/im_3figs.121"
.segment "BANK01"
pic03: .incbin "obj/nes/eloi_1.121"
pic04: .incbin "obj/nes/top_half.121"
.segment "BANK02"
pic05: .incbin "obj/nes/071031_14.121"
pic06: .incbin "obj/nes/071031_16.121"
.segment "BANK03"
pic07: .incbin "obj/nes/im_front_yard.121"
pic08: .incbin "obj/nes/im_diwheel.121"
.segment "BANK04"
pic09: .incbin "obj/nes/im_discipline.121"
logo:  .incbin "obj/nes/logo.121"
