;
; Header for Test78
;
; Copyright 2017 Damian Yerrick
; 
; This software is provided 'as-is', without any express or implied
; warranty. In no event will the authors be held liable for any
; damages arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any
; purpose, including commercial applications, and to alter it and
; redistribute it freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must
;    not claim that you wrote the original software. If you use this
;    software in a product, an acknowledgment in the product
;    documentation would be appreciated but is not required.
; 
; 2. Altered source versions must be plainly marked as such, and must
;    not be misrepresented as being the original software.
; 
; 3. This notice may not be removed or altered from any source
;    distribution.

.import nmi_handler, reset_handler, irq_handler

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 1          ; PRG ROM size in 16384 byte units
  .byt 1          ; CHR ROM size in 8192 byte units
  .byt $e0        ; mirroring type and mapper number lower nibble
  .byt $48        ; mapper number upper nibble; NES 2.0 marker
  .byt $00        ; submapper

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler


