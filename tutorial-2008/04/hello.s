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
  sta PPUMASK  ; turn off display
  
  ; Set up stack pointer
  ldx #$FF
  txs

  ; Wait for PPU to stabilize
  warmup1:
    lda PPUSTATUS
    bpl warmup1
  warmup2:
    lda PPUSTATUS
    bpl warmup2

  ; Write palette entries 0-3: 3 shades of red and white
  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR
  lda #$16
  sta PPUDATA
  lda #$26
  sta PPUDATA
  lda #$36
  sta PPUDATA
  lda #$30
  sta PPUDATA

  ; Write text to VRAM $21CD, roughly the center of the background.
  ; This is 13 tiles from the left and 14 tiles from the top.
  lda #$21
  sta PPUADDR
  lda #$CD
  sta PPUADDR
  lda #'h'
  sta PPUDATA
  lda #'e'
  sta PPUDATA
  lda #'l'
  sta PPUDATA
  lda #'l'
  sta PPUDATA
  lda #'o'
  sta PPUDATA

  ; If you're going to turn on rendering, you don't need to reset the
  ; VRAM address.  Setting the scroll position does this for you.

  ; Turn on vblank notification
  lda #VBLANK_NMI
  sta PPUCTRL

  ; Wait for a vblank before turning the screen on

  jsr wait_vblank

  ; Set the scroll position of the background by writing (x, y)
  ; pixel coordinates to PPUSCROLL.   This should always be done
  ; as the last thing before turning on rendering.
  ; The earliest programs will always scroll to (0, 0), so write
  ; 0 twice.
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  ; PPUMASK controls whether sprites are displayed and whether the
  ; background is displayed.  Here, display only the background.
  lda #BG_ON
  sta PPUMASK


  ; And now da-ding like before
  lda #CH_ALL
  sta SND_CHN
  lda #15 | SQ_1_2
  sta SQ1_VOL  ; for pulse 1
  lda #SWEEP_OFF
  sta SQ1_SWEEP  ; for pulse 1
  ; The B nearly two octaves above middle C is 987.77 Hz.
  lda #112  ; (111860.8 / 987.77) - 1
  sta SQ1_LO
  lda #%00001000
  sta SQ1_HI

  ; Wait for a few vblanks.
  jsr wait_vblank
  jsr wait_vblank
  jsr wait_vblank
  jsr wait_vblank
  jsr wait_vblank
  
  ; Under most circumstances, we can only update the VRAM through
  ; PPUADDR and PPUDATA at one of two times: when rendering is turned
  ; off, and in the first 2200 or so cycles after vblank starts.
  ; The PPU is continuously accessing VRAM at all other times,
  ; so the CPU has to keep its hands off.
  ; But a vblank has just started, so we're safe.

  ; Now change color 0 to BLUE, and play a note
  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR
  lda #$02
  sta PPUDATA

  ; Write more text to VRAM $21ED.
  ; This is 13 tiles from the left and 15 tiles from the top.
  lda #$21
  sta PPUADDR
  lda #$ED
  sta PPUADDR
  lda #'w'
  sta PPUDATA
  lda #'o'
  sta PPUDATA
  lda #'r'
  sta PPUDATA
  lda #'l'
  sta PPUDATA
  lda #'d'
  sta PPUDATA
  
  ; Again, reset the VRAM address by writing to PPUCTRL and
  ; PPUSCROLL.  We need to do this every time we use PPUADDR and
  ; PPUDATA to load something into VRAM.
  lda #VBLANK_NMI
  sta PPUCTRL
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

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
