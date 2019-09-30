.include "nes2header.inc"

nes2prg 16384
nes2mapper 28
nes2chrram 32768
nes2tv 'N','P'
nes2end

.import nmi_handler, reset_handler, irq_handler

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler


