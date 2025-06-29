;
; Header for smallest possible MMC3 ROM
; Copyright 2025 Damian Yerrick
; SPDX-License-Identifier: Zlib
;
.import nmi_handler, reset_handler, irq_handler

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 1          ; PRG ROM size in 16384 byte units
  .byt 0          ; CHR ROM size in 8192 byte units
  .byt $40        ; mirroring type and mapper number lower nibble
  .byt $08        ; mapper number upper nibble, NES 2.0 flag
  .byt $00        ; mapper number top nibble and variant
  .byt $00        ; upper bits of ROM size
  .byt $00        ; WRAM size
  .byt $09        ; VRAM size

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
