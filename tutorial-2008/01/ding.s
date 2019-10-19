.include "../common/nes.h"

; The iNES header tells the emulator which circuit board to emulate.
; The emulator can see it, but the emulated NES cannot.
.segment "INESHDR"
  .byt "NES", $1A  ; these four bytes identify a file as an NES ROM
  .byt 1  ; size of PRG, in 16384 byte units
  .byt 1  ; size of CHR, in 8192 byte units
  .byt 0, 0  ; mapper, mirroring, etc.  You'll learn these later.


; When the processor starts up, it reads an address from $FFFC
; (reset) and jumps to it.  So the reset vector should point to
; the start of your program's code.
.segment "VECTORS"
  ; NMI vector is at $FFFA, reset at $FFFC, IRQ at $FFFE
  .addr nmi, reset, irq

.segment "CODE"
.proc reset
  ; Turn on the sound chip.
  ; The instruction 'lda #' copies a constant value into
  ; CPU register A.
  ; CH_ALL is a constant defined in nes.h
  lda #CH_ALL
  ; The instruction 'sta' stores the value of CPU register A
  ; to a register.
  sta SND_CHN
  
  ; set duty cycle and envelope
  lda #15 | SQ_1_2
  sta SQ1_VOL  ; for pulse 1
  sta SQ2_VOL  ; and pulse 2

  ; turn off frequency sweep
  lda #SWEEP_OFF
  sta SQ1_SWEEP  ; for pulse 1
  sta SQ2_SWEEP  ; and pulse 2
  
  ; set period and length counter value
  lda #253  ; A is 440 Hz; this is (111860.8 / 440.00) - 1
  sta SQ1_LO
  lda #%00001000
  sta SQ1_HI  ; for pulse 1

  lda #213  ; C is 523.25 Hz; this is (111860.8 / 523.25) - 1
  sta SQ2_LO
  lda #%00001000
  sta SQ2_HI  ; and pulse 2

  ; The NES has no concept of the end of a program.  Actual games
  ; for the NES jump back to the title screen when they "end",
  ; but that comes later.  So we'll just stop by jumping in place
  ; until the power is turned off.
  ; A line starting with a word and a colon creates a label at
  ; that line.  The 'jmp' instruction sets the program counter to
  ; the given address, causing the execution to go to that label.
  forever:
    jmp forever
.endproc

; We don't use interrupts for anything in this program,
; so use interrupt handlers that do nothing.
.proc nmi
  ; The 'rti' instruction pops a return address and the
  ; flags register from the stack.
  rti
.endproc

.proc irq
  rti
.endproc

; Include a font.  Without a font, the NES isn't going to display
; anything.
.segment "CHR"
.incbin "../common/ascii.chr"
