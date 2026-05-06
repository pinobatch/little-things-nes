.include "nes.inc"
.include "global.inc"
.segment "CODE"
.proc draw_title
  lda #$80
  sta PPUCTRL
  asl a
  sta PPUMASK

  lda #$00
  tay
  ldx #$03
  jsr copy_gfx_pages
  lda #$02
  ldy #$10
  ldx #$01
  jsr copy_gfx_pages

  ; clear the first nametable
  lda #$17
  ldy #$00
  ldx #$20
  jsr ppu_clear_nt

  ; todo: write text
  
  ldy #$00
  text_lineloop:
    lda title_text,y
    bmi text_done
    sta PPUADDR
    iny
    lda title_text,y
    sta PPUADDR
    iny
    lda title_text,y
    text_byteloop:
      sta PPUDATA
      iny
      lda title_text,y
      bpl text_byteloop
    iny
    jmp text_lineloop
  text_done:
  rts
.endproc

.proc init_canvas
  lda #$80
  sta PPUCTRL
  asl a
  sta PPUMASK

  ; clear CHR RAM
  ldy #$02
  sty PPUADDR
  tay
  sty PPUADDR
  ldx #$0E
  :
    sta PPUDATA
    dey
    bne :-
    dex
    bne :-

  ; clear nametable
  lda #$17
  ldy #$00
  ldx #$20
  jsr ppu_clear_nt

  ; draw ruler
  lda #VBLANK_NMI|VRAM_DOWN
  sta PPUCTRL
  lda #$20
  sta PPUADDR
  lda #$23
  sta PPUADDR
  ldx #0  ; Digits half
  :
    inx
    stx PPUDATA
    cpx #$0F
    bcc :-
  lda #$20
  sta PPUADDR
  lda #$22
  sta PPUADDR
  lda #$1E  ; markings half
  :
    sta PPUDATA
    dex
    bne :-
  lda #VBLANK_NMI
  sta PPUCTRL

  ; draw border
  ldy #$18
  lda #$21
  ldx #$27
  jsr draw_top_or_bottom_row
  ldy #$1D
  lda #$23
  ldx #$07
  jsr draw_top_or_bottom_row

  ; draw interior
dstlo = $00
dsthi = $01

  lda #$21
  sta dsthi
  lda #$47
  sta dstlo
  ldy #$20
  border_rowloop:
    lda dsthi
    sta PPUADDR
    lda dstlo
    sta PPUADDR
    clc
    adc #32
    sta dstlo
    bcc :+
      inc dsthi
    :
    lda #$1b
    sta PPUDATA
    ldx #16
    :
      sty PPUDATA
      iny
      dex
      bne :-
    lda #$1c
    sta PPUDATA
    tya
    bne border_rowloop
  rts

draw_top_or_bottom_row:
  sta PPUADDR
  stx PPUADDR
  sty PPUDATA
  iny
  ldx #16
  :
    sty PPUDATA
    dex
    bne :-
  iny
  sty PPUDATA
  rts  
.endproc


;;
; copies X*256 bytes from offset A<<8 into gfx to PPU address Y<<8
.proc copy_gfx_pages
src = $00
  clc
  adc #>gfx
  sta src+1
  lda #<gfx
  sta src+0
  sty PPUADDR
  ldy #0
  sty PPUADDR
  byteloop:
    lda (src),y
    sta PPUDATA
    iny
    bne byteloop
    inc src+1
    dex
    bne byteloop
  rts
.endproc


.rodata

gfx:
  .incbin "obj/nes/gfx.chr"

.repeat 10, I
  .charmap $30+I,I  ; 0-9
.endrepeat
.repeat 6, I
  .charmap $61+I,$0A+I  ; a-f
.endrepeat
.charmap $43,$27  ; copyright
.charmap $6b,$28  ; k
.charmap $72,$29  ; r
.charmap $69,$2a  ; i
.charmap $73,$2b  ; s
.charmap $74,$2c  ; t
.charmap $79,$2d  ; y
.charmap $2e,$2e  ; .
.charmap $70,$2f  ; p
.charmap $20,$17  ; space
.charmap $4F,$00  ; O

title_text:
  .dbyt $2089
  .byte "Oeka kids test", $FF
  .dbyt $220b
  .byte "press start", $FF
  .dbyt $2308
  .byte "C 2026 d.yerrick", $FF
  .byte $FF
