.include "nes.inc"
.include "global.inc"

OAM = $0200
.segment "ZEROPAGE"
cur_keys:       .res 2
new_keys:       .res 2
nmis:           .res 1
bgcolorid:      .res 1
fgcolorid:      .res 1
bgemph:         .res 1
disappear_time: .res 1

xferbuf = $0100

.segment "CODE"
.proc nmi_handler
  inc nmis
  rti
.endproc
.proc irq_handler
  rti
.endproc

.proc main
  lda #VBLANK_NMI
  sta PPUCTRL

  lda #6
  sta fgcolorid
  lda #0
  sta bgcolorid
  lda #BG_ON
  sta bgemph

  ; set up palette
  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR
  lda #$0A
  sta PPUDATA
  lda #$1A
  sta PPUDATA
  lda #$2A
  sta PPUDATA
  lda #$3A
  sta PPUDATA

  jsr load_digit_tiles

  ; set up nametable
  lda #$06
  ldy #$00
  ldx #$20
  jsr ppu_clear_nt
  
  lda #$23
  sta PPUADDR
  lda #$D2
  sta PPUADDR
  ldx #6
  atloop:
    lda attributedata,x
    sta PPUDATA
    sta PPUDATA
    sta PPUDATA
    sta PPUDATA
    dex
    bpl atloop


loop:
  jsr read_pads
  
  lda new_keys+0
  bpl notA
    lda #TINT_R|TINT_G|TINT_B
    eor bgemph
    sta bgemph
    lda #120
    sta disappear_time
  notA:

  lda new_keys+0
  and #$0F
  beq notControlPad
    lsr a
    bcc notRight
      ; Right: make bg brighter
      lda bgcolorid
      cmp #6
      bcs notControlPad
        inc bgcolorid
        jmp reset_disappear
    notRight:

    lsr a
    bcc notLeft
      ; Left: make bg darker
      lda bgcolorid
      beq notControlPad
        dec bgcolorid
        jmp reset_disappear
    notLeft:

    lsr a
    bcc notDown
      ; Down: make fg darker
      lda fgcolorid
      beq notControlPad
        dec fgcolorid
        jmp reset_disappear
    notDown:

    lsr a
    bcc notControlPad
      ; Up: make fg brighter
      lda fgcolorid
      cmp #6
      bcs notControlPad
        inc fgcolorid
      reset_disappear:
        lda #120
        sta disappear_time
  notControlPad:
  
  jsr prepare_digits

  ; Load the palette
  ldx fgcolorid
  ldy bgcolorid
  lda nmis
:
  cmp nmis
  beq :-

  ; Set the palette
  lda #VBLANK_NMI
  sta PPUCTRL
  lda #$3F
  sta PPUADDR
  lda #$02
  sta PPUADDR
  lda bgcolors,y
  sta PPUDATA
  lda contrastcolors,y
  sta PPUDATA
  bit PPUDATA
  bit PPUDATA
  lda bgcolors,x
  sta PPUDATA
  lda contrastcolors,x
  sta PPUDATA

  ; Copy transfer buffer
  lda #VBLANK_NMI|VRAM_DOWN
  sta PPUCTRL
  ldx #3
  xferbufloop:
    lda #$22
    sta PPUADDR
    txa
    clc
    adc #$8E
    sta PPUADDR
    .repeat 6, I
      lda xferbuf+4*I,x
      sta PPUDATA
    .endrepeat
    dex
    bpl xferbufloop

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #VBLANK_NMI|BG_0000
  sta PPUCTRL
  lda bgemph
  sta PPUMASK
  
  jmp loop
.endproc

;;
; Unpacks 1-bit digit tiles to CHR RAM.
.proc load_digit_tiles
  ldy #$00
  sty PPUADDR
  sty PPUADDR
digloop:
  ldx #8
  :
    lda digits_1bp,y
    iny
    sta PPUDATA
    dex
    bne :-
  lda #$FF
  ldx #8
  :
    sta PPUDATA
    dex
    bne :-
  cpy #0
  bne digloop
  rts
.pushseg
.segment "RODATA"
digits_1bp:         .incbin "obj/nes/digits.1bpp"
.popseg
.endproc

.proc prepare_digits
  lda disappear_time
  bne not_disappear
    ldx #23
    lda #$06
    :
      sta xferbuf,x
      dex
      bpl :-
    rts
  not_disappear:

  dec disappear_time
  ldy fgcolorid
  ldx #0
  jsr onecolorid
  ldy bgcolorid
  ldx #8
  jsr onecolorid

  ; draw "em" if emphasized else none
  ldx #7
  lda bgemph
  bmi is_emph
  lda #6
  :
    sta xferbuf+16,x
    dex
    bpl :-
  rts
is_emph:  
  :
    lda em_toprow,x
    sta xferbuf+16,x
    dex
    bpl :-
  rts
  
onecolorid:
  lda bgcolors,y
  pha
  lsr a
  lsr a
  lsr a
  lsr a
  jsr onenibble
  pla
  and #$0F
  inx
  inx
onenibble:
  cmp #4
  bcc :+
    lda #4
  :
  tay
  lda digittopleft,y
  sta xferbuf+0,x
  lda digittopright,y
  sta xferbuf+1,x
  lda digitbottomleft,y
  sta xferbuf+4,x
  lda digitbottomright,y
  sta xferbuf+5,x
  rts
.endproc

.segment "RODATA"
bgcolors:         .byte $0D,$1D,$2D,$00,$10,$3D,$20
contrastcolors:   .byte $20,$20,$20,$20,$0F,$0F,$0F
digittopleft:     .byte $00,$02,$04,$04,$08
digittopright:    .byte $09,$03,$05,$07,$09
digitbottomleft:  .byte $18,$12,$14,$16,$18
digitbottomright: .byte $19,$13,$15,$17,$19
em_toprow:        .byte $0A,$0B,$0E,$0F
em_bottomrow:     .byte $18,$1B,$1E,$1F
attributedata:    .byte $05,$00,$55,$00,$55,$00,$55
