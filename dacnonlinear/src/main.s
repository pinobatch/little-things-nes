.include "nes.inc"
.include "global.inc"

nmi_handler:
irq_handler:
  rti

.proc main
  lda #$00
  sta SNDCHN
  
  ; Solid color $0D reduces PPU crosstalk with audio
  ldx #$0D
  jsr set_solid_color_x

  jsr triseparator
  jsr dacpulseramp
  jsr triseparator
  jsr triramp
  jsr triseparator
  jsr noiseramp
  jsr triseparator
  ldx #$1A
  jsr set_solid_color_x
  :
    jmp :-
.endproc

.proc set_solid_color_x
  ldy #$3F
  lda #$00
  sta PPUMASK
  sta PPUCTRL  ; run without NMI
  sty PPUADDR
  sta PPUADDR
  stx PPUDATA
  sty PPUADDR
  sta PPUADDR
  rts
.endproc