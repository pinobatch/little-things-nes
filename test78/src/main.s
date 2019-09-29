;
; Test78: what kind of mirroring does this IREM board use?
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

.include "nes.inc"
.include "global.inc"

OAM = $0200

.zeropage
nmis: .res 1
mirror_result: .res 1

.code
.proc nmi_handler
  inc nmis
.endproc
.proc irq_handler
  rti
.endproc

.proc main
  jsr perform_test
  jsr draw_bg
  lda mirror_result
  jsr draw_mirror_result

  ; Turn on rendering
  lda nmis
  :
    cmp nmis
    beq :-
  ldx #0
  stx PPUSCROLL
  stx PPUSCROLL
  lda #VBLANK_NMI|BG_0000|OBJ_8X16
  sta PPUCTRL
  lda #BG_ON
  sta PPUMASK
  :
    jmp :-
.endproc


; Test procedure:
; Set mapper to page $00
; Write $01 to $2C00 and $00 to $2000
; Set mapper to page $08
; Write $00 to $2000 and $01 to $2C00
; Set mapper to page $00
; Read $2000, $2400, $2800, $2C00
; Set mapper to page $08
; Read $2000, $2400, $2800, $2C00
.proc perform_test
  ldx #$00
  stx *-1      ; On page 0
  ldy #$01

  lda #$2C
  sta PPUADDR
  stx PPUADDR
  sty PPUDATA  ; $2C00 = $01
  lda #$20
  sta PPUADDR
  stx PPUADDR
  stx PPUDATA  ; $2000 = $00

  lda #$08
  sta *-1      ; On page 1
  
  lda #$20
  sta PPUADDR
  stx PPUADDR
  stx PPUDATA  ; $2000 = $00
  lda #$2C
  sta PPUADDR
  stx PPUADDR
  sty PPUDATA  ; $2C00 = $01

  ; Now read it back
  lda #$00
  sta *-1
  jsr fetch4bytes
  lda #$08
  sta *-1
  
; Read bytes back from nametable using current mirroring
fetch4bytes:

  ldy #$20
  fetchloop:
    sty PPUADDR  ; seek to nametable
    stx PPUADDR
    lda PPUDATA  ; fetch byte
    lda PPUDATA  ; read
    lsr a
    rol mirror_result
    iny
    iny
    iny
    iny
    cpy #$30
    bcc fetchloop
  rts
.endproc

