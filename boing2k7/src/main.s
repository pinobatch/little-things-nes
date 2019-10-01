;
; boing 2007 demo
; demonstrates a behavior of the NES PPU that wasn't discovered
; until 2010-06-10
; http://nesdev.com/bbs/viewtopic.php?t=6401
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
.p02

LOWWATER = 192
DRAW_SCANLINES = 0

.if DRAW_SCANLINES
DRAW_SCANLINES_TARGET = PPUMASK
.else
DRAW_SCANLINES_TARGET = $400D
.endif

.segment "ZEROPAGE"
nmis: .res 1
cur_keys: .res 2
new_keys: .res 2
psg_sfx_state: .res 32

.segment "BSS"
yhi:  .res 1
ylo:  .res 1
dyhi:  .res 1
dylo:  .res 1

.segment "INESHDR"
  .byt "NES",$1A
  .byt 1  ; 16 KiB PRG ROM
  .byt 1  ; 8 KiB CHR ROM
  .byt 0  ; horizontal mirroring; low mapper nibble: 0
  .byt 0  ; high mapper nibble: 0

.segment "VECTORS"
  .addr nmi, reset, irq

.segment "CODE"
.proc squash
linesLeft = 0
skipDensity = 1
skipAccum = 2
partialCycleAccum = 3
dbgcalc = 4
  lda yhi
  eor #$80
  sta linesLeft
  eor #$FF
  adc #0
  asl a
  asl a
  sta skipDensity
  lda #%00011110
  sta dbgcalc
  lda #0
  sta skipAccum
  sta partialCycleAccum
  
vblendwait:
  bit PPUSTATUS
  bvs vblendwait
s0wait:
  bit PPUSTATUS
  bmi bail
  bvc s0wait
lineloop:
  lda #%11100000
  eor dbgcalc
  sta dbgcalc
  sta DRAW_SCANLINES_TARGET
  clc
  lda partialCycleAccum
  adc #$AA
  sta partialCycleAccum
  bcs wasteOne
wasteOne:
  clc
  lda skipAccum
  adc skipDensity
  sta skipAccum
  bcc noStore
  lda PPUDATA  ; skip a line?
afterStore:
  nop
  nop
  jsr bail
  jsr bail
  jsr bail
  jsr bail
  jsr bail
  dec linesLeft
  bne lineloop
bail:
  rts
noStore:
  bcc afterStore
  
.endproc

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
  lda $4015      ; ack DPCM IRQ
  ; Set up the stack
  dex
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
  jsr loadLeftText
  
  ; Wait for the PPU to warm up (part 2 of 2)
vwait2:
  bit PPUSTATUS
  bpl vwait2

; step 1: load a palette while we're still solidly in blanking
  lda #$3F
  ldy #$00
  sta PPUADDR
  sty PPUADDR
  sty PPUCTRL
palloop:
  lda testpal,y
  sta PPUDATA
  iny
  cpy #$20
  bcc palloop

  jsr loadBallMap

  ; step 4: turn on the screen
  lda #$80
  sta dylo
  lda #$06
  sta dyhi
  lda #0
  sta ylo
  sta yhi

  lda #VBLANK_NMI
  sta PPUCTRL
floop:

  lda #0
  sta 0
  lda yhi
  cmp #LOWWATER
  bcc no_squash
  jsr squash
no_squash:


  ; compute bouncing
  lda yhi
  cmp #LOWWATER
  bcc dyNotBouncing
  lda #$60
  clc
  adc dylo
  sta dylo
  lda #$00
  adc dyhi
  sta dyhi
  jmp after_dy
dyNotBouncing:
  lda dylo
  clc
  adc #$E0
  sta dylo
  lda dyhi
  adc #$FF
  sta dyhi
after_dy:
  
  lda ylo
  clc
  adc dylo
  sta ylo
  lda yhi
  adc dyhi
  sta yhi
  jsr sets0

  lda nmis
:
  cmp nmis
  beq :-
  lda #0
  sta OAMADDR
  lda #>OAM
  sta OAM_DMA
  lda #0
  sta PPUSCROLL
  lda yhi
  cmp #LOWWATER
  bcc :+
  sbc #16
:
  sta PPUSCROLL
  lda #0
  rol a
  rol a
  ora #VBLANK_NMI|OBJ_8X16|VRAM_DOWN
  sta PPUCTRL
  lda #%00011110
  sta PPUMASK

  jmp floop
.endproc

.proc loadBallMap
  lda #$24
  sta PPUADDR
  ldy #$00
  sty PPUADDR
  tya
  ldx #8
:
  sta PPUDATA
  dey
  bne :-
  dex
  bne :-
  lda #$21
  sta 1
  lda #$90
  sta 0
  ldx #0
rowloop:
  ldy #14
  lda 1
  sta PPUADDR
  lda 0
  sta PPUADDR
  clc
  adc #32
  sta 0
  bcc charloop
  inc 1
charloop:
  lda ballmap,x
  sta PPUDATA
  inx
  dey
  bne charloop
  cpx #224
  bcc rowloop
  rts
.endproc

.proc loadLeftText
sx = 0
sy = 1
  lda #40
  sta sy
  lda #20
  sta sx
  ldy #0
  ldx #4
chrloop:
  lda lefttext,y
  beq done
  cmp #$0D
  bne notReturn
  lda #20
  sta sx
  lda sy
  clc
  adc #16
  sta sy
  iny
  bne chrloop
notReturn:
  iny
  and #$FE
  beq isspace  ; 01: space
  sta OAM+1,x
  lda sy
  sta OAM,x
  lda #0
  sta OAM+2,x
  lda sx
  sta OAM+3,x
  inx
  inx
  inx
  inx
isspace:
  lda sx
  clc
  adc #8
  sta sx
  txa
  bne chrloop
done:
  lda #$F0
finishloop:
  sta OAM,x
  inx
  inx
  inx
  inx
  bne finishloop
.endproc
.proc sets0
  lda yhi
  cmp #LOWWATER
  bcc s0nope
  eor #$FF
  adc #$5e
  bcc :+
s0nope:
  lda #$F0
:
  sta OAM
  lda #$80
  sta OAM+1
  lda #%00100000  ; behind
  sta OAM+2
  lda #80
  sta OAM+3
  rts
.endproc
  

.segment "RODATA"
testpal:
  .byt $06,$16,$26,$30,$0C,$00,$00,$11,$0C,$00,$00,$12,$0C,$00,$00,$13
  .byt $06,$32,$22,$12,$0C,$00,$00,$00,$0C,$00,$00,$00,$0C,$00,$00,$00
ballmap:
  .byt $00,$00,$00,$03,$04,$05,$06,$07,$08,$09,$0A,$00,$00,$00
  .byt $00,$00,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$00,$00
  .byt $00,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$20,$00
  .byt $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D
  .byt $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D
  .byt $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D
  .byt $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D
  .byt $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D
  .byt $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8A,$8B,$8C,$8D
  .byt $90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D
  .byt $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD
  .byt $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD
  .byt $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD
  .byt $00,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$D0,$00
  .byt $00,$00,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$00,$00
  .byt $00,$00,$00,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$00,$00,$00
lefttext:
  .byt $1E,$8E,$4E,$7E,$3E,$0D     ; boing
  .byt $CE,$AE,$AE,$DE,$0D,$0D     ; 2007
  .byt $10,$01,$CE,$AE,$BE,$AE,$0D ; copr. 2010
  .byt $0C,$1C,$6E,$4E,$1C,$7E,$0D ; Damian
  .byt $0E,$2E,$9E,$9E,$4E,$2C,$5E ; Yerrick
  .byt $00

.segment "CHR"
.incbin "obj/nes/ball.chr"
