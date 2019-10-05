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
  ; Here's the new part.  We turn off the PPU and wait for it to
  ; stabilize before we do anything.
  lda #0
  sta PPUCTRL  ; turn off NMI
  sta PPUMASK  ; turn off mask
  
  ; The PPU indicates that it has stabilized by setting bit 7
  ; of PPUSTATUS to true (1) twice.
  ; The 'lda' instruction reads a value from the specified memory
  ; address into register A.  It also sets the minus flag
  ; based on bit 7 of the value.  The 'bpl' instruction jumps
  ; to the given label only if the minus flag is false (0).
  ; So this loop will spin until bit 7 becomes true.
  warmup1:
    lda PPUSTATUS
    bpl warmup1

  ; Repeat the process one more time.
  warmup2:
    lda PPUSTATUS
    bpl warmup2

  ; Now that the PPU has warmed up, it's safe to access the PPU.
  ; The CPU accesses the PPU's memory through two ports: PPUADDR
  ; and PPUDATA.  To set the address that the program will write to,
  ; write the upper 8 bits to PPUADDR and then the lower 8 bits to
  ; PPUADDR.
  ; The palette starts at $3F00, so write $3F then $00 to PPUADDR.
  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR
  
  ; The whole screen displays the first color of the palette when
  ; rendering is turned off.
  ; The first digit of a color is the brightness (0-3).  The second
  ; is the hue (0 = gray, 1-C = various colors, F = black).
  ; Here, we choose a shade of green.
  lda #$1A
  sta PPUDATA

  ; When displaying a solid color from $3F00, we need to set the
  ; VRAM address anywhere outside the palette area ($3F00-$3FFF).
  ; Here we write $00 twice to set the VRAM address to $0000.
  lda #$00
  sta PPUADDR
  sta PPUADDR


  ; And now we ding, just like in 01
  lda #CH_ALL
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
  lda #253
  sta SQ1_LO
  lda #%00001000
  sta SQ1_HI
  lda #213
  sta SQ2_LO
  lda #%00001000
  sta SQ2_HI

  ; Spin until power off
  forever:
    jmp forever
.endproc

; We don't use interrupts for anything in this program,
; so use interrupt handlers that do nothing.
.proc nmi
  rti
.endproc

.proc irq
  rti
.endproc

; Include a font.  Without a font, the NES isn't going to display
; anything.
.segment "CHR"
.incbin "../common/ascii.chr"
