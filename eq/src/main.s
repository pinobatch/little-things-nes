;
; Main loop for EQ test
;
; Copyright 2017 Damian Yerrick
; 
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;

.include "nes.inc"
.include "global.inc"

OAM = $0200

.segment "ZEROPAGE"
nmis:          .res 1
oam_used:      .res 1  ; starts at 0
cur_keys:      .res 2
new_keys:      .res 2

.segment "CODE"
.proc nmi_handler
  inc nmis
  rti
.endproc

.proc irq_handler
  rti
.endproc

.proc main
  jsr draw_bg

forever:

  ; Game logic
  jsr read_pads
  
  lda new_keys
  lsr a
  bcc notRight
    lda #0
    sta PPUCTRL
    sta PPUMASK
    
    ; background color $0D to reduce PPU crosstalk
    ldy #$3F
    sty PPUADDR
    sta PPUADDR
    ldy #$0D
    sty PPUDATA
    sta PPUADDR
    sta PPUADDR
    jsr sinusweep
    jmp testDone
  notRight:
  lsr a
  bcc notLeft
    lda #0
    sta PPUCTRL
    jsr pinklfsr
  testDone:
    lda #0
    sta SNDCHN
    sta $4011
    lda #VBLANK_NMI|BG_0000|OBJ_1000
    sta PPUCTRL
  notLeft:
  notPressed:

  ; is it can be vblank time?
  lda nmis
vw3:
  cmp nmis
  beq vw3
  jsr load_main_palette
  
  ; Turn the screen on
  ldx #0
  ldy #0
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  clc
  jsr ppu_screen_on
  jmp forever

.endproc

.proc load_main_palette
  ; seek to the start of palette memory ($3F00-$3F1F)
  ldx #$3F
  stx PPUADDR
  ldx #$00
  stx PPUADDR
copypalloop:
  lda initial_palette,x
  sta PPUDATA
  inx
  cpx #4
  bcc copypalloop
  rts
.endproc

.segment "RODATA"
initial_palette:
  .byt $17,$27,$20,$20

; Include the CHR ROM data
.segment "CHR"
  .res $0400
  .incbin "obj/nes/fizzter16.chr"
  .res $1000
