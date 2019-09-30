;
; password entry demo
;
; Copyright 2010 Damian Yerrick
;
; Copying and distribution of this file, with or without modification,
; are permitted in any medium without royalty provided the copyright
; notice and this notice are preserved.  This file is offered as-is,
; without any warranty.
;
.include "nes.inc"
.include "global.inc"

.export pwPosition, pwSelectedChar, curPW, curData, puthex

.segment "ZEROPAGE"
nmis: .res 1
new_keys: .res 2
cur_keys: .res 2
das_keys: .res 2
das_timer: .res 2

.segment "BSS"
pwSelectedChar: .res 1  ; 0-31
pwPosition: .res 1  ; offset into curPW
curData: .res 5  ; including check byte
curPW: .res 8

.segment "INESHDR"
  .byt "NES",$1A
  .byt 1  ; 16 KiB PRG ROM
  .byt 1  ; 8 KiB CHR ROM
  .byt 1  ; vertical mirroring; low mapper nibble: 0
  .byt 0  ; high mapper nibble: 0

.segment "VECTORS"
  .addr nmi, reset, irq

.segment "CODE"
.proc irq
  rti
.endproc
.proc nmi
  inc nmis
  rti
.endproc

.proc reset
  sei
  
  ; Acknowledge and disable interrupt sources during bootup
  ldx #0
  stx PPUCTRL    ; disable vblank NMI
  stx PPUMASK    ; disable rendering (and rendering-triggered mapper IRQ)
  lda #$40
  sta $4017      ; disable frame IRQ
  stx $4010      ; disable DPCM IRQ
  bit PPUSTATUS  ; ack vblank NMI
  bit $4015      ; ack frame IRQ
  cld            ; disable decimal mode to help generic 6502 debuggers
                 ; http://magweasel.com/2009/08/29/hidden-messagin/
  dex            ; Set up the stack
  txs
  
  ; Wait for the PPU to warm up (part 1 of 2)
vwait1:
  bit PPUSTATUS
  bpl vwait1

  ; While waiting for the PPU to finish warming up, we have about
  ; 29000 cycles to burn without touching the PPU.  So we have time
  ; to initialize some of RAM to known values.
  ; Ordinarily the "new game" initializes everything that the game
  ; itself needs, so we'll just do zero page and shadow OAM.
  ldy #$00
  lda #$F0
  ldx #$00
clear_zp:
  sty $00,x
  sta OAM,x
  inx
  bne clear_zp
  
  ; Wait for the PPU to warm up (part 2 of 2)
vwait2:
  bit PPUSTATUS
  bpl vwait2
  
  lda #VBLANK_NMI
  sta PPUCTRL
  ldx #7
  lda #0
:
  sta curPW,x
  dex
  bpl :-
  
  jsr doPWDialog
  ; if bit 7 of A is true, user canceled;
  ; otherwise, user put in a password
  asl a
  lda #0
  sta PPUMASK
  lda #$20
  sta PPUADDR
  lda #$82
  sta PPUADDR
  bcc notCancel
  lda #'n'
  sta PPUDATA
  lda #'/'
  sta PPUDATA
  lda #'m'
  sta PPUDATA
  bne cancelOrNotCancel
notCancel:
  lda #'-'
  sta PPUDATA
  lda #'>'
  sta PPUDATA
  
  lda 0
  jsr puthex
  lda 1
  jsr puthex
  lda 2
  jsr puthex
  lda 3
  jsr puthex

cancelOrNotCancel:
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #VBLANK_NMI
  sta PPUCTRL
  lda #BG_ON
  sta PPUMASK
:
  jmp :-
.endproc

.proc puthex
  pha
  lsr a
  lsr a
  lsr a
  lsr a
  jsr puthex1
  pla
.endproc
.proc puthex1
  and #$0F
  cmp #$0A
  bcc notLetter
  adc #'A'-'9'-2
notLetter:
  adc #'0'
  sta PPUDATA
  rts
.endproc

.segment "CHR"
.incbin "obj/nes/titlegfx.chr"
.incbin "obj/nes/gamegfx.chr"
