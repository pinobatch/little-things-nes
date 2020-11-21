.p02
.include "nes.inc"

OAM = $200

.segment "INESHDR"
.byt 'N','E','S',$1A
.byt 1, 1, 1, 0

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "ZEROPAGE"
nmis: .res 1
irqheight: .res 1
enable_timer: .res 1

.segment "CODE"
.proc irq_handler
  rti
.endproc

.proc nmi_handler
  inc nmis
  rti
.endproc

.proc stretchLines
  sta 2
stretchingloop:

  iny
  iny
  tya
  and #$38
  asl a
  asl a
  ldx #0
  stx $2006
  sty $2005
  stx $2005
  sta $2006
  
  ; If not debugging, turn the first sta into lda
  lda #%00011111
  sta PPUMASK
  lda #%00011110
  sta PPUMASK

  ldx #58
:
  dex
  bne :-
  
  dec 2
  bne stretchingloop

  rts
.endproc

.proc reset_handler
  sei  ; IRQs while initializing hardware: OFF!
  ldx #$00
  stx PPUCTRL  ; Vblank NMI: OFF!
  stx PPUMASK  ; Rendering: OFF!
  stx $4010
  stx $4015    ; DPCM and tone generators: OFF!
  stx enable_timer  ; ISR functionality: OFF!
  lda #$40
  sta $4017  ; APU IRQ: OFF!
  
  lda $4015  ; DPCM: ACK!
  cld  ; Decimal mode on famiclones: OFF!
  lda PPUSTATUS  ; Vblank NMI: ACK!
  dex
  txs
  
vwait1:
  lda PPUSTATUS
  bpl vwait1
  
  ; Clear zero page and sprite page
  ; (the demo doesn't use anything else)
  ldx #0
  txa
clear_ram:
  sta $00,x
  inx
  bne clear_ram
  lda #$F0
clear_ram2:
  sta OAM,x
  inx
  bne clear_ram2

vwait2:
  lda PPUSTATUS
  bpl vwait2

  ; Clear a nametable
  lda #$20
  sta PPUADDR
  stx PPUADDR
  txa
clear_vram:
  .repeat 4
    sta PPUDATA
  .endrepeat
  inx
  bne clear_vram
  
  ; Write a green-tinted palette to the PPU to show that the program
  ; counter has reached this point
  ldx #$00
  stx PPUCTRL
  lda PPUSTATUS
  lda #$3F
  sta PPUADDR
  stx PPUADDR
set_initial_palette:
  lda initial_palette,x
  sta PPUDATA
  inx
  cpx #32
  bcc set_initial_palette
  
  jsr sayHello
  lda #0
  sta PPUMASK
  
  ; # START ###############################################

  lda #23
  sta OAM
  lda #'l'*2
  sta OAM+1
  lda #0
  sta OAM+2
  lda #88
  sta OAM+3

  lda #%10000000   ; nmi enable, vram down
  sta PPUCTRL

  lda PPUSTATUS
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  lda #0
  sta $2003
  lda #>OAM
  sta $4014
  lda #%00010100
  sta PPUMASK
:
  lda nmis
  cmp #32
  bcc :-
  
  ; acknowledge all relevant interrupts and enable them at the CPU
  lda $4015
  cli

forever:
  ldx nmis
:
  cpx nmis
  beq :-

  ldx #$00
  stx PPUMASK
  lda #$3F
  sta PPUADDR
  stx PPUADDR
  lda nmis
  and #$08
  ora #$02
  ;sta PPUDATA
  lda #0
  sta PPUSCROLL
  lda #16
  sta PPUSCROLL
  lda #0
  sta $2003
  lda #>OAM
  sta $4014
  lda #%10000000
  sta PPUCTRL
  lda #%00011110
  sta PPUMASK

  ; Wait for sprite 0
  sei
s0endwait:
  bit PPUSTATUS
  bvs s0endwait
s0wait:
  bit PPUSTATUS
  bmi forever
  bvc s0wait

  ; jitter the effect up and down per frame  
  ldy #40
  lda nmis
  lsr a
  bcc even_frame
  ldy #22
:
  dey
  bne :-
  ldy #41
  
even_frame:
  nop
  nop
  nop
  nop

  lda #64  ; half the number of scanlines to stretch
  jsr stretchLines  
  jmp forever
.endproc



.proc sayHello
  lineIdx = 2
  vramDstHi = 3
  vramDstLo = 4
  
  lda #0
  sta lineIdx
  lda #$20
  sta vramDstHi
  lda #$A2
  sta vramDstLo

  
lineloop:
  ldx lineIdx
  lda helloLines,x
  sta 0
  inx
  lda helloLines,x
  sta 1
  inx
  stx lineIdx
  ora #0  ; skip null pointers
  beq skipLine
  lda vramDstHi
  ldx vramDstLo
  jsr puts
skipLine:
  
  lda vramDstLo
  clc
  adc #64
  sta vramDstLo
  lda vramDstHi
  adc #0
  sta vramDstHi
  lda lineIdx
  cmp #20
  bcc lineloop
  
  lda PPUSTATUS
  lda #$80
  sta PPUCTRL
  
  lda nmis
:
  cmp nmis
  beq :-
  lda PPUSTATUS

  lda #$80
  sta PPUCTRL
  lda #$0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #%00001010
  sta PPUMASK
  rts
.endproc

.proc puts
  bit PPUSTATUS
  sta PPUADDR
  stx PPUADDR
  pha
  txa
  pha
  ldy #0
copyloop1:
  lda (0),y
  beq after_copyloop1
  asl a
  sta PPUDATA
  iny
  bne copyloop1
after_copyloop1:
  
  pla
  clc
  adc #32
  tax
  pla
  adc #0
  sta PPUADDR
  stx PPUADDR
  ldy #0
copyloop2:
  lda (0),y
  beq after_copyloop2
  sec
  rol a
  sta PPUDATA
  iny
  bne copyloop2
after_copyloop2:

  rts
.endproc

.segment "RODATA"
initial_palette:
  .byt $0A,$1A,$2A,$3A,$0A,$1A,$2A,$3A,$0A,$1A,$2A,$3A,$0A,$1A,$2A,$3A
  .byt $0A,$16,$26,$36,$0A,$1A,$2A,$3A,$0A,$1A,$2A,$3A,$0A,$1A,$2A,$3A
helloLines:
  .addr hello1, 0, hello3, hello4, hello5, hello6, 0, hello8, 0, 0

hello1: .byt "Tall Pixel (NTSC version)",0
;hello2: .byt "",0
hello3: .byt "This demo shows how to",0
hello4: .byt "stretch an image so that",0
hello5: .byt "cut scenes use 33% less CHR.",0
hello6: .byt "Use the effect in homebrew.",0
;hello7: .byt "",0
hello8: .byt $18,$19,$1A,$1B,$1C,$1D,$1E,$1F,"  Your friend, Pino",0

.segment "CHR"
.incbin "obj/nes/bggfx16.chr"
.incbin "obj/nes/finkheavy16.chr"
