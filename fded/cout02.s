.p02

PPUCTRL = $2000
PPUMASK = $2001
PPUSTATUS = $2002
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007

P1 = $4016
P2 = $4017

.segment "ZEROPAGE"
rleCount: .res 12
  .res 4
rleValue: .res 12

retraces: .res 3
joy1: .res 1
last_joy1: .res 1
joy1new: .res 1


.segment "SBSS"
decodedMap: .res 12*256


.segment "VECTORS"
reset:
  SEI
  LDX #0
  STX PPUCTRL
  STX PPUMASK
  lda #$40
  sta P2
  CLD
  DEX
  TXS

@mapperwrite1:
  asl a  ; value is now $80, meaning "reset mmc1"
  STA @mapperwrite1+1
  JMP main

  .RES $1a+reset-*
  .addr nmi, reset, irq


.segment "CODE"
nmi:
  inc retraces
irq:
  rti

setMMC1CTRL:
  sta $8000
  lsr a
  sta $8000
  lsr a
  sta $8000
  lsr a
  sta $8000
  lsr a
  sta $8000
  rts

setMMC1CHR0:
  sta $A000
  lsr a
  sta $A000
  lsr a
  sta $A000
  lsr a
  sta $A000
  lsr a
  sta $A000
  rts

setMMC1CHR1:
  sta $C000
  lsr a
  sta $C000
  lsr a
  sta $C000
  lsr a
  sta $C000
  lsr a
  sta $C000
  rts

setMMC1PRG:
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  rts

main:

@warmup1:
  bit PPUSTATUS
  bpl @warmup1

; we have nearly 29000 cycles to init other parts of the NES
; so do it while waiting for the PPU to signal that it's warming up


  ; set horizontal mirroring, u*rom style banking,
  ; 8 KiB CHR switching
  lda #$0F
  jsr setMMC1CTRL

  ; CHR bank $0000
  lda #0
  jsr setMMC1CHR0

  ; CHR bank for $1000
  lda #0
  jsr setMMC1CHR1

  ; PRG bank for $8000 = 0, enable WRAM
  lda #0
  jsr setMMC1PRG

@clearZP:
  sta $00,x
  dex
  bne @clearZP

; done with tasks; wait for warmup

@warmup2:
  bit PPUSTATUS
  bpl @warmup2

; set palette
  ldy #$3F
  sty PPUADDR
  iny
  sty PPUADDR
  lda #$0F
  sta PPUDATA
  lda #$06
  sta PPUDATA
  lda #$16
  sta PPUDATA
  lda #$26
  sta PPUDATA

; clear out nametable
  lda #$20
  sta PPUADDR
  ldx #0
  stx PPUADDR
  lda #$10
  tax
:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  inx
  bne :-
  txa

; clear out attributes
  ldx #$10
:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  dex
  bne :-

.segment "RODATA"
drawing_cout:
  .incbin "drawing.cout"
.segment "CODE"

  ldy #<drawing_cout
  sty 0
  ldy #>drawing_cout
  sty 1
  jsr cout_decompress


  ldy #<decodedMap
  sty 0
  ldy #>decodedMap
  sty 1
  ldy #0
  sty 4
viewerLoop:
  ldy #$84  ; will be writing DOWN
  sty PPUCTRL
  jsr wait4vbl
  ldy #0
  sty PPUMASK
  ldy #$21
  sty PPUADDR
  ldy 4
  sty PPUADDR
  ldy #0
@copy:
  lda (0),y
  sta PPUDATA
  iny
  cpy #12
  bcc @copy

  ; carry is set, so add 1 less than the stride
  lda #11
  adc 0
  sta 0
  lda #0
  adc 1
  sta 1

  ; turn the screen back on
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #$80
  sta PPUCTRL
  lda #%00001010
  sta PPUMASK

  ; next column
  inc 4
  lda 4
  cmp #32
  bcc viewerLoop

:
  jmp :-


.proc wait4vbl
  lda retraces
:
  cmp retraces
  beq :-
  rts
.endproc


;;
; Decompresses a map to decodedMap using the cout
; algorithm.
; 0: source address, low 8 bits
; 1: source address, high 8 bits
.proc cout_decompress
src = 0
dst = 2
column = 4

; Set up local variables
  ldy #<decodedMap
  sty dst
  ldy #>decodedMap
  sty dst+1
  ldy #0
  sty column
  tya
  ldx #11
@clear_rleCount:
  sta rleCount,x
  dex
  bpl @clear_rleCount

doColumn:
  ldx #0

doRow:
  lda rleCount,x
  bne inRun

  lda (src),y
  inc src
  bne :+
  inc src+1
:
  cmp #193
  bcs isRunLength

; We have a single byte
  sta rleValue,x
  lda #1
  sta rleCount,x
  bne inRun

isRunLength:
  sbc #192
  sta rleCount,x
  lda (src),y
  inc src
  bne :+
  inc src+1
:
  sta rleValue,x

inRun:

; Copy rleValue[y] to tile at (x, y)
  lda rleValue,x
  sta (dst),y
  inc dst
  bne :+
  inc dst+1
:
  dec rleCount,x

  inx
  cpx #12
  bcc doRow

; Go to next column
  inc column
  bne doColumn
  rts
.endproc
