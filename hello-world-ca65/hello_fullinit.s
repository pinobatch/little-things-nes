.p02

.segment "INESHDR"

  .byt "NES", 26
  .byt 2  ; number of 16 KB program segments
  .byt 1  ; number of 8 KB chr segments
  .byt 0  ; mapper, mirroring, etc
  .byt 0  ; extended mapper info
  .byt 0,0,0,0,0,0,0,0  ; f you DiskDude

.segment "CODE"

nmihandler:
irqhandler:
  rti

main:  ; CLEAR everything
  sei
  cld
  ldx #$c0
  stx $4017
  ldx #$0f
  stx $4015
  ldx #$ff
  txs
  inx
  stx $2000
  stx $2001
:
  bit $2002  ; catch first of two vbls
  bpl :-
  txa
@zpclrloop:
  sta 0,x
  inx
  bne @zpclrloop
:
  bit $2002  ; catch second vbl, after this we can hit the ppu
  bpl :-

  lda #$3f
  sta $2006
  stx $2006
@palclrloop:
  lda pal,x
  sta $2007
  inx
  lda pal,x
  sta $2007
  inx
  cpx #$20
  bne @palclrloop

  lda #$24
  sta $2006
  ldx #0
  stx $2006
  lda #0
@ppuclrloop:
  sta $2007
  sta $2007
  sta $2007
  sta $2007
  inx
  bne @ppuclrloop

  lda #$21
  sta $2006
  lda #7
  sta $2006
  ldx #0
@wrstrloop:
  lda hello_str,x
  beq :+
  sta $2007
  inx
  bne @wrstrloop
:
  bit $2002
  bpl :-

  lda #0
  sta $2005
  sta $2005
  sta $2000
  lda #%00001010
  sta $2001


die:
  jmp die




.segment "RODATA"

hello_str:
  .asciiz " [ HELLO  WORLD ] "
pal:
  .byt $0f,$00,$10,$30,$0f,$00,$10,$30,$0f,$00,$10,$30,$0f,$00,$10,$30
  .byt $0f,$00,$10,$30,$0f,$00,$10,$30,$0f,$00,$10,$30,$0f,$00,$10,$30



@die:
  jmp @die


.segment "VECTORS"

  .addr nmihandler, main, irqhandler

