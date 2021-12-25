;
; Spam Inc
; Copyright 2021 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.include "nes.inc"
.include "global.inc"

OAM = $0200

.segment "ZEROPAGE"
nmis:          .res 1
irqs:          .res 1
oam_used:      .res 1
cur_keys:      .res 2
new_keys:      .res 2

.segment "CODE"
;;
; This NMI handler is good enough for a simple "has NMI occurred?"
; vblank-detect loop.
.proc nmi_handler
  inc nmis
  rti
.endproc

; MMC3 IRQ
.proc irq_handler
  inc irqs
  rti
.endproc

.proc main

  jsr show_title_screen

  lda #0
  sta PPUMASK
forever:
  jmp forever
.endproc

; Include the CHR ROM data
.segment "CHR"
  .incbin "obj/nes/title16.chr"
