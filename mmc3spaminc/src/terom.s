.import nmi_handler, reset_handler, irq_handler, main
.export copychr_then_main

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 2          ; PRG ROM size in 16384 byte units
  .byt 4          ; CHR ROM size in 8192 byte units
  .byt $40        ; mirroring type and mapper number lower nibble
  .byt $00        ; mapper number upper nibble

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

copychr_then_main := main

; Include the CHR ROM data
.segment "CHR"
  .incbin "obj/nes/title16.chr"
  ; empty page 4 before results on 5-7
  ; first tile of page 4 must be transparent
  .res 1024, $00
  .incbin "obj/nes/resultfont16.chr"
