.include "../common/nes.h"

; The iNES header tells the emulator which circuit board to emulate.
; The emulator can see it, but the emulated NES cannot.
.segment "INESHDR"
  .byt "NES", $1A  ; these four bytes identify a file as an NES ROM
  .byt 1  ; size of PRG, in 16384 byte units
  .byt 1  ; size of CHR, in 8192 byte units
  .byt 0, 0  ; mapper, mirroring, etc.  You'll learn these later.

  
.segment "ZEROPAGE"
; Reserve 1 byte for the variable 'retraces', used to detect
; the vertical blanking interrupt
retraces: .res 1

; Now the NMI routine actually does something!
.segment "VECTORS"
  ; NMI vector is at $FFFA, reset at $FFFC, IRQ at $FFFE
  .addr nmi, reset, irq

.segment "CODE"
.proc reset
  ; Turn off PPU
  lda #0
  sta PPUCTRL  ; turn off NMI
  sta PPUMASK  ; turn off mask
  
  ; In addition to register A, the NES also has a few more registers:
  ; X, Y, and the stack pointer.

  ; Sometimes, the CPU stores temporary information on a "stack".
  ; This occupies locations $0100 through $01FF of RAM.
  ; When the CPU "pushes" a value, it writes the value at the stack
  ; pointer and sets the stack pointer down by 1.  When it "pulls"
  ; a value, it sets the stack pointer up by 1 and then reads the
  ; value at the stack pointer.  For example, if the stack pointer
  ; is $FD, a "push" will write the value to $01FD and then set the
  ; stack pointer to $FC.
  ; Subroutines and interrupts push the program counter onto the
  ; stack so that the CPU knows where to go once the subroutine or
  ; interrupt handler has finished.
  ; Usually, we want to start the stack pointer at $FF, so that it
  ; has the maximum room to grow.  The 'ldx' and 'stx' instructions
  ; operate much like 'lda' and 'sta'.  The 'txs' instruction copies
  ; the value in register X to the stack pointer.
  ldx #$FF
  txs

  ; Wait for PPU to stabilize (PPUSTATUS bit 7 set twice).
  warmup1:
    lda PPUSTATUS
    bpl warmup1

  ; Repeat the process one more time.
  warmup2:
    lda PPUSTATUS
    bpl warmup2

  ; In this program, we are going to make the PPU generate NMI
  ; signals on vertical blanking.  This happens every time the PPU
  ; has finished rendering a frame, and that happens once every
  ; 16.64 milliseconds.
  lda #VBLANK_NMI
  sta PPUCTRL

  ; Write palette entry 0, this time to red
  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR
  lda #$16
  sta PPUDATA

  ; And reset the VRAM address
  lda #$00
  sta PPUADDR
  sta PPUADDR


  ; And now we ding a different way
  lda #CH_ALL
  sta SND_CHN
  
  ; set duty cycle and envelope
  lda #15 | SQ_1_2
  sta SQ1_VOL  ; for pulse 1

  ; turn off frequency sweep
  lda #SWEEP_OFF
  sta SQ1_SWEEP  ; for pulse 1
  
  ; set period and length counter value
  ; The B nearly two octaves above middle C is 987.77 Hz.
  lda #112  ; (111860.8 / 987.77) - 1
  sta SQ1_LO
  lda #%00001000
  sta SQ1_HI

  ; Wait for a few vblanks.  The 'jsr' instruction (jump to
  ; subroutine or jump and save return) is like 'jmp', but it pushes
  ; some information onto the stack so that the CPU knows where to go
  ; once the subroutine is done.  Five waits wait about 0.08 second.
  jsr wait_vblank
  jsr wait_vblank
  jsr wait_vblank
  jsr wait_vblank
  jsr wait_vblank
  
  ; Now change color 0 to BLUE, and play a note
  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR
  lda #$02
  sta PPUDATA
  lda #$00
  sta PPUADDR
  sta PPUADDR

  ; The E above that B is 1318.5 Hz.

  lda #84  ; (111860.8 / 1318.5) - 1
  sta SQ1_LO
  lda #%00001000
  sta SQ1_HI

  
  ; Spin until power off
  forever:
    jmp forever
.endproc

; When the PPU is told to generate interrupts on vertical blank,
; it sends a signal to the CPU that sends it here.
.proc nmi
  ; Set the 'retraces' variable up by 1 so that the main program
  ; can see that a vblank has happened.
  inc retraces
  
  rti
.endproc

; We don't use IRQ so don't do anything
.proc irq
  rti
.endproc

; This subroutine waits for the NMI handler to change retraces.
.proc wait_vblank
  lda retraces

  ; The 'cmp' (compare) instruction reads a value from a memory
  ; location and then performs a subtraction: register A minus the
  ; value from memory.  Then it discards the value, but it sets the
  ; minus flag based on bit 7 of the result, and it sets the equal
  ; flag if the result was zero.  So this loop will spin until
  ; the new value of retraces has become different from the old
  ; value, which indicates that the NMI handler has run.
  loop:
    cmp retraces
    beq loop

  ; To jump to the instruction after the 'jsr' that called a
  ; subroutine, use the 'rts' (return from subroutine, or return
  ; to saved) instruction.
  rts
.endproc

; Include a font.  Without a font, the NES isn't going to display
; anything.
.segment "CHR"
.incbin "../common/ascii.chr"
