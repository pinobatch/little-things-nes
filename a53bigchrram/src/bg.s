.include "nes.inc"
.include "global.inc"

.define NTXY(xt,yt) ($2000 | ((xt)&$1F) | (((yt)&$1F)<<5))

.code
.proc draw_bg
  ; Clear the first pattern table
  lda #VBLANK_NMI
  sta PPUCTRL
  asl a
  tax
  tay
  jsr ppu_clear_nt
  ; PPU pointer is at $0400

  lda #<msgchr
  sta $00
  lda #>msgchr
  sta $01
  ldy #$00
  ldx #>msgchr_size
  copyloop:
    lda ($00),y
    sta PPUDATA
    iny
    bne copyloop
    inc $01
    dex
    bne copyloop

  ; Start by clearing the first nametable
  ldx #$20
  lda #$00
  tay
  jsr ppu_clear_nt

  ; Draw labels
  lda #>init_rects
  ldy #<init_rects
  jsr draw_rects_ay

  ; Draw test results
  lda testresult_size
  cmp #2
  bcc :+
    lda #2
  :
  asl a
  tax
  lda size_rects+1,x
  ldy size_rects+0,x
  jsr draw_rects_ay

  ldx testresult_bugged
  beq :+
    ldx #2
  :
  lda bug_rects+1,x
  ldy bug_rects+0,x
  jsr draw_rects_ay

  rts
.endproc

.proc draw_rects_ay
srclo = $00
srchi = $01

  sta srchi
  sty srclo
.endproc
.proc draw_rects_0
srclo = draw_rects_ay::srclo
srchi = draw_rects_ay::srchi
dsthi = $02
dstlo = $03
width = $04
height = $05
tileno = $06
  ldy #4
  paramloop:
    lda (srclo),y
    sta $02,y
    dey
    bpl paramloop
  lda dsthi
  bpl notdone
    rts
  notdone:

  ; Advance to next parameter
  lda #5
  clc
  adc srclo
  sta srclo
  bcc :+
    inc srchi
  :
  lineloop:
    lda dsthi
    sta PPUADDR
    lda dstlo
    sta PPUADDR
    clc
    adc #32
    sta dstlo
    bcc :+
      inc dsthi
      clc
    :
    ldy tileno
    tya
    adc #32
    sta tileno
    ldx width
    tileloop:
      sty PPUDATA
      iny
      dex
      bne tileloop
    dec height
    bne lineloop
  jmp draw_rects_0
.endproc

.rodata
msgchr: .incbin "obj/nes/e.chr"
msgchr_size = * - msgchr

init_rects:
  .dbyt NTXY( 4, 3)
  .byte 24, 2, $40  ; Action 53 CHR bank test
  .dbyt NTXY( 4, 6)
  .byte  2, 3, $80  ; Copr.
  .dbyt NTXY( 6, 6)
  .byte 20, 2, $82  ; 2017 Damian Yerrick
  .dbyt NTXY( 6,12)
  .byte  9, 2, $97  ; RAM size
  .dbyt NTXY(24,12)
  .byte  2, 2, $D4  ; K
  .dbyt NTXY( 6,15)
  .byte 11, 2, $C2  ; FCEUX bug
  .dbyt NTXY(15,17)
  .byte  2, 1, $E0  ; g tail
  .byte $FF
size_8k_rect:
  .dbyt NTXY(22,12)
  .byte  2, 2, $58  ; 8
  .byte $FF
size_16k_rect:
  .dbyt NTXY(21,12)
  .byte  3, 2, $5A  ; 16
  .byte $FF
size_32k_rect:
  .dbyt NTXY(21,12)
  .byte  3, 2, $5D  ; 32
  .byte $FF
no_bug_rect:
  .dbyt NTXY(23,15)
  .byte  3, 2, $D1  ; No
  .byte $FF
yes_bug_rect:
  .dbyt NTXY(22,15)
  .byte  4, 2, $CD  ; Yes
  .byte $FF

bug_rects:
  .addr no_bug_rect, yes_bug_rect
size_rects:
  .addr size_8k_rect, size_16k_rect, size_32k_rect