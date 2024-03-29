.import nmi_handler, reset_handler, irq_handler

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 1          ; PRG ROM size in 16384 byte units
  .byt 1          ; CHR ROM size in 8192 byte units
  .byt $01        ; mirroring type and mapper number lower nibble
  .byt $00        ; mapper number upper nibble

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

; Include the CHR ROM data
.segment "CHR"
chrstart:
  .incbin "obj/nes/grid.u.chr"
  .res chrstart-*+4096
  .incbin "obj/nes/spritegfx.chr"
