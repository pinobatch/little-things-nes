;
; NES hardware init for Test78
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

.segment "CODE"
.proc reset_handler
  ; The very first thing to do when powering on is to put all sources
  ; of interrupts into a known state.
  sei             ; Disable interrupts
  ldx #$00
  stx PPUCTRL     ; Disable NMI and set VRAM increment to 32
  stx PPUMASK     ; Disable rendering
  stx $4010       ; Disable DMC IRQ
  dex             ; Subtracting 1 from $00 gives $FF, which is a
  txs             ; quick way to set the stack pointer to $01FF
  bit PPUSTATUS   ; Acknowledge stray vblank NMI across reset
  bit SNDCHN      ; Acknowledge DMC IRQ
  lda #$40
  sta P2          ; Disable APU Frame IRQ
  lda #$0F
  sta SNDCHN      ; Disable DMC playback, initialize other channels

vwait1:
  bit PPUSTATUS   ; It takes one full frame for the PPU to become
  bpl vwait1      ; stable.  Wait for the first frame's vblank.

  cld
vwait2:
  bit PPUSTATUS  ; After the second vblank, we know the PPU has
  bpl vwait2     ; fully stabilized.
  
  jmp main
.endproc
