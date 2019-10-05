; http://pinocchio.jk0.org/meta32.zip


.include "nes.inc"
.importzp pokeColNameBuf, pokeColAttrBuf, pokeColX
.import upd_pokeColName, upd_pokeColAttr
.importzp mtCol0LUT, mtCol1LUT, mtCol2LUT, mtCol3LUT, mtAttrLUT
.importzp mtCol4LUT, mtCol5LUT, mtCol6LUT, mtCol7LUT
.import pokeColName, pokeColAttr, mapCache
.export camXCol, camXSub



;;; Some helpful macros

;;; wait4vbl
;   Waits for the PPU to signal a vertical blank.
;   Apparently local labels cause the following:
;       Internal assembler error
;       WriteExpr: Cannot write EXPR_ULABEL nodes
.macro wait4vbl
:
  bit PPUSTATUS
  bpl :-
.endmacro

.segment "INESHDR"

  .byt "NES", 26
  .byt 1  ; number of 16 KB program segments
  .byt 1  ; number of 8 KB chr segments
  .byt 1  ; mapper, mirroring, etc
  .byt 0  ; extended mapper info
  .byt 0,0,0,0,0,0,0,0  ; f you DiskDude

.segment "ZEROPAGE"
cur_scroll: .res 1
last_ppuctrl: .res 1
vblanked:
  .res 1
camXSub:
  .res 1
camXCol:
  .res 1
dakframe:
  .res 1
.export last_ppuctrl

.segment "CODE"

nmihandler:
  inc vblanked
irqhandler:
  rti

main:

;;; Init CPU
  sei
  cld
  ldx #$ff
  txs
  inx
  stx PPUCTRL
  stx PPUMASK

;;; Init PPU
  wait4vbl

:
  lda #$ef
  sta OAM,x
  inx
  bne :-
:
  lda #0
  sta 0,x
  inx
  bne :-

  wait4vbl  ; after second VBL we can write to ppu memory

;;; Load initial palette
  lda #$3f
  sta PPUADDR
  stx PPUADDR
@palclrloop:
  lda pal,x
  sta PPUDATA
  inx
  lda pal,x
  sta PPUDATA
  inx
  cpx #32
  bne @palclrloop

;;; Clear nametable $2000
  lda #$20
  jsr map_clear
  lda #$24
  jsr map_clear


  ; Set up metatile lookup tables
  lda #<defaultMtCol0
  sta mtCol0LUT
  lda #>defaultMtCol0
  sta mtCol0LUT+1
  lda #<defaultMtCol1
  sta mtCol1LUT
  lda #>defaultMtCol1
  sta mtCol1LUT+1
  lda #<defaultMtCol2
  sta mtCol2LUT
  lda #>defaultMtCol2
  sta mtCol2LUT+1
  lda #<defaultMtCol3
  sta mtCol3LUT
  lda #>defaultMtCol3
  sta mtCol3LUT+1
  lda #<defaultMtCol4
  sta mtCol4LUT
  lda #>defaultMtCol4
  sta mtCol4LUT+1
  lda #<defaultMtCol5
  sta mtCol5LUT
  lda #>defaultMtCol5
  sta mtCol5LUT+1
  lda #<defaultMtCol6
  sta mtCol6LUT
  lda #>defaultMtCol6
  sta mtCol6LUT+1
  lda #<defaultMtCol7
  sta mtCol7LUT
  lda #>defaultMtCol7
  sta mtCol7LUT+1
  lda #<defaultMtAttr
  sta mtAttrLUT
  lda #>defaultMtAttr
  sta mtAttrLUT+1

  ; Set up a fake map

  ldx #0
:
  lda defaultMap,x
  sta mapCache,x
  inx
  bne :-

  ; Draw the map

  lda #0
  sta pokeColX
:
  jsr pokeColName
  jsr upd_pokeColName
  jsr pokeColAttr
  jsr upd_pokeColAttr
  inc pokeColX
  jsr pokeColName
  jsr upd_pokeColName
  inc pokeColX
  jsr pokeColName
  jsr upd_pokeColName
  inc pokeColX
  jsr pokeColName
  jsr upd_pokeColName
  inc pokeColX

  lda pokeColX
  cmp #64
  bcc :-



  ; Write messages
  lda #$8A
  sta PPUCTRL
  sta last_ppuctrl

  lda #<hello_str
  sta 0
  lda #>hello_str
  sta 1
  ldx #$20  ; $2023 = (5, 1) on left nametable
  ldy #$23
  jsr draw_text
  lda #<button_names
  sta 0
  lda #>button_names
  sta 1
  ldx #$24  ; $2428 = (8, 1) on right nametable
  ldy #$28
  jsr draw_text


main_loop:
  lda vblanked
  beq main_loop
  lda #0
  sta vblanked
  ldx #1
  stx JOY1
  dex
  stx JOY1
  stx PPUMASK
  lda last_ppuctrl
  sta PPUCTRL
  ldx #$24  ; $2448 = (8, 10)
  stx PPUADDR
  ldx #$48
  stx PPUADDR
  ldx #8
@per_button:
  lda JOY1
  and #1
  beq :+
  lda #'-'
:
  sta PPUDATA
  sta PPUDATA
  dex
  bne @per_button

;;; turn on display
  lda #>OAM
  sta $4014

  lda camXSub
  sta 0
  lda camXCol
  asl 0
  rol a
  asl 0
  rol a
  asl 0
  rol a
  sta PPUSCROLL
  lda #232
  sta PPUSCROLL
  lda last_ppuctrl
  adc #0
  sta PPUCTRL
  lda #PPUMASK_BG0|PPUMASK_SPR
  sta PPUMASK

  ; move camera
  clc
  lda camXSub
  adc #9
  sta camXSub
  lda camXCol
  adc #0
  sta camXCol

  ; draw pm
  sec
  lda #128
  sbc camXSub
  sta 0
  lda #1
  sbc camXCol
  asl 0
  rol a
  asl 0
  rol a
  asl 0
  rol a
  bcs @no_sprite
  sta 0

  lda #155
  sta OAM+60
  lda #$1B
  sta OAM+61
  lda #1
  sta OAM+62
  lda 0
  sta OAM+63
  lda #166
  sta OAM+64
  lda #$1F
  sta OAM+65
  lda #1
  sta OAM+66
  lda 0
  sta OAM+67
  lda #160
  sta OAM+68
  lda #$12
  sta OAM+69
  lda #2
  sta OAM+70
  lda 0
  sta OAM+71
  lda #168
  sta OAM+72
  lda #$13
  sta OAM+73
  lda #2
  sta OAM+74
  lda 0
  sta OAM+75
  jmp @sprite_anyway
@no_sprite:
  lda #$f0
  sta OAM+60
  sta OAM+64
  sta OAM+68
  sta OAM+72
@sprite_anyway:


  ; draw weeble
  lda #32
  sta OAM+76
  lda dakframe
  and #$0f
  cmp #2
  lda #1
  adc dakframe
  cmp #96
  bcc :+
  sbc #96
:
  sta dakframe
  lsr a
  lsr a
  lsr a
  and #$0e
  ora #$20
  sta OAM+77
  lda #0
  sta OAM+78
  lda #120
  sta OAM+79
  lda #40
  sta OAM+80
  lda OAM+77
  ora #1
  sta OAM+81
  lda #0
  sta OAM+82
  lda #120
  sta OAM+83

  jmp main_loop




;;; map_clear:
;   Clears a nametable to all zeroes.
;   A: map address ($20 or $2C on std mirrorings;
;                   $20, $24, $28, or $2C on 4-screen)
;   Trashes A, X
map_clear:
  sta PPUADDR
  ldx #0
  stx PPUADDR
  txa
@ppuclrloop:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  inx
  bne @ppuclrloop
  rts


;;; draw_text:
;   Draws a nul-terminated line of text to the screen.
;   0: pointer to text src
;   X: high word of dst
;   Y: low word of dst
;   out: Y: length of string; A: 0
draw_text:
  stx PPUADDR
  sty PPUADDR
  ldy #0
  lda (0),y
  beq @skip
@loop:
  sta PPUDATA
  iny
  lda (0),y
  bne @loop
@skip:
  rts


.segment "RODATA"

hello_str:
  .byt 3," 2006 DAMIAN YERRICK",0
button_names:
  .byt    "A B ",4,5,6,7
  .asciiz "UPDNLTRT"
pal:
  .byt $31,$30,$10,$00,$31,$36,$26,$16,$31,$2A,$1A,$0A,$31,$32,$22,$12
  .byt $31,$27,$12,$08,$31,$27,$16,$0f,$31,$27,$1A,$0f,$31,$27,$30,$0f

defaultMtCol0:
  .byt $20,$60,$69,$6A,$69,$60,$69,$69,$66,$66,$20,$77,$20,$7E,$77,$76
  .byt $69,$20,$84,$20
defaultMtCol1:
  .byt $20,$62,$69,$6A,$6C,$62,$69,$69,$67,$67,$20,$79,$20,$62,$79,$78
  .byt $69,$20,$86,$20
defaultMtCol2:
  .byt $20,$62,$69,$6A,$6D,$62,$69,$69,$67,$67,$73,$20,$73,$72,$20,$62
  .byt $80,$20,$69,$20
defaultMtCol3:
  .byt $20,$64,$69,$6A,$69,$64,$69,$69,$68,$68,$7e,$20,$75,$74,$20,$7F
  .byt $82,$20,$69,$20
defaultMtCol4:
  .byt $20,$61,$69,$6B,$69,$61,$69,$69,$61,$61,$62,$20,$6E,$6F,$7E,$69
  .byt $81,$20,$7E,$20
defaultMtCol5:
  .byt $20,$63,$69,$6B,$6C,$63,$69,$69,$63,$63,$62,$20,$70,$71,$62,$69
  .byt $83,$20,$62,$20
defaultMtCol6:
  .byt $20,$63,$69,$6B,$6D,$63,$69,$69,$63,$63,$7f,$20,$62,$69,$7A,$7B
  .byt $62,$20,$85,$20
defaultMtCol7:
  .byt $20,$65,$69,$6B,$69,$65,$69,$69,$65,$65,$20,$20,$7F,$69,$7C,$7D
  .byt $7F,$20,$87,$20
defaultMtAttr:
  .byt $00,$00,$00,$0F,$00,$0A,$0A,$0F,$00,$0A,$0A,$0A,$0A,$0A,$0A,$0A
  .byt $0A,$0A,$0A,$0A

defaultMap:
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$00,$03,$07,$07,$00,$00
  .byt $00,$00,$05,$00,$00,$01,$02,$02,$02,$02,$02,$03,$07,$07,$00,$00
  .byt $00,$00,$05,$00,$00,$01,$04,$04,$04,$04,$08,$02,$02,$02,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$00,$0c,$0d,$06,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$0c,$0d,$06,$06,$00,$00

  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$05,$06,$06,$06,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$05,$06,$06,$06,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$00,$05,$06,$06,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$05,$06,$09,$06,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$05,$06,$06,$12,$0f,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$0e,$0f,$06,$06,$09,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$0e,$0f,$06,$06,$00,$00
  .byt $00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00


.segment "VECTORS"

  .addr nmihandler, main, irqhandler

.segment "CHR"
.incbin "tilesets/hello.chr"
.incbin "tilesets/spr.chr"
