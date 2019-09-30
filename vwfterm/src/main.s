.include "nes.inc"
.include "global.inc"

OAM = $0200

.segment "ZEROPAGE"
cur_keys: .res 2
new_keys: .res 2
das_keys: .res 2
das_timer: .res 2
nmis:  .res 1
oam_used: .res 1
FME7_lastreg: .res 1

.segment "CODE"
.proc reset
  sei
  cld
  ldx #$FF
  txs
  inx
  stx PPUCTRL
  stx PPUMASK
  stx $4010   ; dmc irq off
  stx SNDCHN  ; audio off
  lda #$40
  sta P2      ; apu frame irq off
  bit PPUSTATUS  ; ack any pending nmi
  ; wait for end of first frame
:
  bit PPUSTATUS
  bpl :-

  ; PPU should be warmed up by the start of the second frame, so
  ; wait for the end of the second frame to make sure
:
  bit PPUSTATUS
  bpl :-
  
  jsr term_init

  lda #>hello_msg
  ldy #<hello_msg
  jsr term_puts
  lda #1
  jsr term_flush
  jsr term_getc
  jsr term_discard_line

  lda #>moar_msg
  ldy #<moar_msg
  jsr term_puts
  
forever:
  lda #>prompt_msg
  ldy #<prompt_msg
  jsr term_puts
  jsr term_gets
  jmp forever

.if 0
  lda new_keys
  and #KEY_UP
  beq notUp
  lda #29
  clc
  adc scroll_y
  sta scroll_y
notUp:
  lda new_keys
  and #KEY_DOWN
  beq notDown
  inc scroll_y
notDown:
  lda scroll_y
  cmp #30
  bcc :+
  sbc #30
  sta scroll_y
:
  jmp forever
.endif
.endproc

.proc term_getc
  lda nmis
:
  cmp nmis
  beq :-
  jsr read_pads
  lda new_keys
  beq term_getc
  sta term_busy  ; debugging
  ldx #0
findcharloop:
  asl a
  bcs found
  inx
  bne findcharloop
found:
  lda term_getc_buttons,x
  rts
.endproc

.segment "RODATA"
hello_msg:
  .byte "Credits:",10
  .byte "VWF terminal by Damian Yerrick",10
  .byte "Z-machine interpreter and keyboard adapter by tpw_rules",10
  .byte "",10
  .byte "[Moar]",0
moar_msg:
  .byte "At this point, the terminal is essentially done. "
  .byte "The bottleneck now is providing enough memory for the Z-machine, ",10
  .byte "and that's in the hands of emulator authors.",10
  .byte "",10
  .byte "Try typing now:",0

prompt_msg:
  .byte 10, "pino@nes:~/develop/vwfterm$ ",0
;  .byte 10, "> ",0
;  .byte 10, "IIIIiiii!!!!....IIIIiiii!!!!....IIIIiiii!!!!....",0

term_getc_buttons:
  .byte ' '  ; A: space
  .byte $08  ; B: backspace
  .byte $09  ; Select: Tab
  .byte $0D  ; Start: Enter
  .byte 'n'  ; Up: n for north
  .byte 's'  ; Down: s for south
  .byte 'w'  ; Left: w for west
  .byte 'e'  ; Right: e for east

.segment "INESHDR"
  .byte "NES",$1A,$02,$00,$50,$40
.segment "VECTORS"
  .addr term_nmi, reset, term_irq
