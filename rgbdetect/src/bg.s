.include "nes.inc"
.include "global.inc"
.segment "CODE"
.proc draw_title_bg
  ; Start by clearing the first nametable
  lda #VBLANK_NMI
  sta PPUCTRL
  asl a
  sta PPUMASK
  bit PPUSTATUS
  tay  ; attribute value
  ldx #$20
  jsr ppu_clear_nt

  ; Draw a logo
dstlo = $00
dsthi = $01
rowsleft = $03
  lda #LOGO_NAM_HEIGHT
  sta rowsleft
  lda #<LOGO_NAM_TOPLEFT
  sta dstlo
  lda #>LOGO_NAM_TOPLEFT
  sta dsthi
  ldy #0
  namloop:
    lda dsthi
    sta PPUADDR
    lda dstlo
    sta PPUADDR
    clc
    adc #32
    bcc :+
      inc dsthi
    :
    sta dstlo
    ldx #LOGO_NAM_WIDTH
    :
      lda logo_nam,y
      iny
      sta PPUDATA
      dex
      bne :-
    dec rowsleft
    bne namloop

  lda #>NOTICE_MSG_TOPLEFT
  sta $03
  lda #<NOTICE_MSG_TOPLEFT
  sta $02
  lda #>notice_msg
  ldy #<notice_msg
  jsr puts_multiline_16

  ; Run open bus test
open_bus_result = $0F
  lda #VBLANK_NMI
  sta PPUCTRL
  lda PPUCTRL
  sta open_bus_result
  lda #>open_bus_result
  sta $0005
  lda #<open_bus_result
  sta $0004
  lda #>OPENBUS_RESULT_TOPLEFT
  ldx #<OPENBUS_RESULT_TOPLEFT
  ldy #1
  jsr hexdump8

  ; color the letters RGB
  ldx #$CA
  jsr oneattr
  ldx #$D2
oneattr:
  lda #$23
  sta PPUADDR
  stx PPUADDR
  lda #$55
  sta PPUDATA
  lda #$AA
  sta PPUDATA
  lda #$FF
  sta PPUDATA
  rts
.endproc


.proc cls_puts_multiline
  pha
  tya
  pha

  lda #VBLANK_NMI
  sta PPUCTRL
  asl a
  sta PPUMASK

  ; Start by clearing the first nametable
  ldx #$20
  lda #$40
  ldy #$00
  jsr ppu_clear_nt

  lda #$20
  sta $03
  lda #$40
  sta $02
  pla
  tay
  pla
  ; fall through to puts_multiline_16
.endproc

;;
; Writes the string at (AAYY) to lines starting at PPU address in
; $0002-$0003.
; At finish, $0000-$0001 points to start of last line, and Y is the
; length of the last line.
.proc puts_multiline_16
srclo = 0
srchi = 1
dstlo = 2
dsthi = 3
  sta srchi
  sty srclo
lineloop:
  lda dsthi
  ldx dstlo
  jsr puts_16
  lda dstlo
  clc
  adc #64
  sta dstlo
  bcc :+
  inc dsthi
:
  lda (srclo),y
  beq done
  tya
  sec
  adc srclo
  sta srclo
  bcc lineloop
  inc srchi
  bcs lineloop
done:
  rts
.endproc

;;
; Writes the string at ($0000) to the nametable at AAXX.
; Does not write to memory.
.proc puts_16
  sta PPUADDR
  stx PPUADDR
  pha
  txa
  pha
  ldy #0
copyloop1:
  lda (0),y
  cmp #' '
  bcc after_copyloop1
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
  cmp #' '
  bcc after_copyloop2
  rol a
  sta PPUDATA
  iny
  bne copyloop2
after_copyloop2:
  rts
.endproc

;;
; Writes the Y (1-8) bytes at (4) in spaced hex to the nametable at AAXX.
; Modifies $0002-$000B.
.proc hexdump8
strlo = 0
strhi = 1
dstlo = 2
dsthi = 3
hexsrc = 4
hexoffset = 6
hexbuf = 7
bytesleft = 11
  stx dstlo
  sta dsthi
  sty bytesleft
  lda #0
  sta hexbuf+2
  sta strhi
  sta hexoffset
  lda #<hexbuf
  sta 0
  lda #32
  sta hexbuf+3
  ldy hexoffset
loop:
  lda (hexsrc),y
  lsr a
  lsr a
  lsr a
  lsr a
  jsr hdig
  sta hexbuf+0
  lda (hexsrc),y
  iny
  sty hexoffset
  and #$0F
  jsr hdig
  sta hexbuf+1
  
  lda dstlo
  tax
  clc
  adc #3
  sta dstlo
  lda dsthi
  jsr puts_16
  ldy hexoffset
  dec bytesleft
  bne loop
  rts
hdig:
  cmp #10
  bcc :+
  adc #'A'-'0'-11
:
  adc #'0'
  rts
.endproc


.rodata
LOGO_NAM_WIDTH = 11
LOGO_NAM_HEIGHT = 10
LOGO_NAM_TOPLEFT = $2000 + 9 + 1*32
logo_nam: .incbin "obj/nes/logo.nam"

COPYRIGHT_SYMBOL = $7F
LF = $0A
NOTICE_MSG_TOPLEFT = $2000 + 0 + 12*32
notice_msg:
  .byte "v0.01  ", $7F, " 2023 Damian Yerrick",LF,LF
  .byte "PPU open bus result:",LF
  .byte "(80 normal; C0 interposed by",LF
  .byte "NESRGB or Hi-Def NES)", $00
OPENBUS_RESULT_TOPLEFT = $2000 + 20 + 16*32

; Include the CHR ROM data
.segment "CHR"
chrstart:
  .incbin "obj/nes/logo.u.chr"
.res chrstart+1024-*, $FF
  .incbin "obj/nes/fizzter16.chr"
