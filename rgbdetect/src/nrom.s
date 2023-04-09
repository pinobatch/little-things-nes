.include "global.inc"

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 1          ; PRG ROM size in 16384 byte units
  .byt 1          ; CHR ROM size in 8192 byte units
  .byt <(MAPPER<<4) | $00  ; mirroring type and mapper lower nibble
  .byt (MAPPER&$F0) | $00  ; mapper number upper nibble

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler


