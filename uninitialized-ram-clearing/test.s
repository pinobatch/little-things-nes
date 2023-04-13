; Test to generate thousands of dummy reads of uninitialized RAM
;
; By Damian Yerrick, April 2023
; Permission is granted to make use of this file without restriction.
; This file is offered as-is, without any warranty.

PPUCTRL = $2000
PPUMASK = $2001
PPUSTATUS = $2002
PPUADDR = $2006
PPUDATA = $2007

.segment "INESHDR"
.byte "NES",$1A
.byte $01,$00,$01,$00

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.code
irq_handler:
nmi_handler:
  rti

reset_handler:
  sei
  ldx #$FF
  txs
  inx
  stx PPUCTRL
  stx PPUMASK
  bit PPUSTATUS

  ; Make one uninitialized memory read to make sure
  ; detection of uninitialized memory reads is turned on
  ldy $0700

  ; Write $00 to all of RAM
  txa
  sta $00
  ldy #$02  ; skip overwriting the pointer the first time through
  pageloop:
    stx $01
    byteloop:
      ; The following instruction takes 6 cycles:
      ; 2 to read the opcode and operand,
      ; 2 to read the pointer from $0000-$0001,
      ; 1 to finish 16-bit addition of the value in register Y to
      ;   the pointer while performing a dummy read from an address
      ;   corresponding to the partial addition result, and
      ; 1 to write the value in A to the correct address.
      ; The dummy read causes an exception in emulators where
      ; "Uninitialized memory read" does not ignore dummy reads
      ; of a store instruction.
      sta ($00),y
      iny
      bne byteloop
    inx
    cpx #$08
    bne pageloop

  ; All is clear.  Turn the screen green to signal that the program
  ; has completed.
  vwait1:
    bit PPUSTATUS
    bpl vwait1
  vwait2:
    bit PPUSTATUS
    bpl vwait2
  ldy #$3F
  ldx #$1A     ; Green color
  sty PPUADDR  ; Seek to start of palette
  sta PPUADDR
  stx PPUDATA  ; Write value
  sty PPUADDR  ; Seek to start of palette...
  sta PPUADDR
  sta PPUADDR  ; Then seek to start of video memory.  These 2 seeks
  sta PPUADDR  ; are rumored to avoid palette corruption on some PPUs.
  forever:
    jmp forever
