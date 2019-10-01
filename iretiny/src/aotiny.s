.import nmi_handler, reset_handler, irq_handler

.ifndef USE_MAPPER_218
USE_MAPPER_218 = 0
.endif

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 1          ; PRG ROM size in 16384 byte units
  .byt 0          ; CHR ROM size in 8192 byte units
.if USE_MAPPER_218
  .byt $A9        ; mirroring type and mapper number lower nibble
  .byt $D0        ; mapper number upper nibble
.else
  .byt $70
  .byt $00
.endif

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler


