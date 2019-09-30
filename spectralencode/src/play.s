.import wave0, wave1, wave2, wave3, wave4, wave5, wave6, wavesilence
.import alphabetdata
.importzp WAVELEN
.export playroutine, initroutine

.zeropage
alphaptr: .res 1
muted_tones: .res 1
msgptrlo: .res 1
msgptrhi: .res 1

wave0ptr: .res 2
wave1ptr: .res 2
wave2ptr: .res 2
wave3ptr: .res 2
wave4ptr: .res 2
wave5ptr: .res 2
wave6ptr: .res 2

.code
.align 128
.proc playroutine

  ; The inner loop is 62 cycles, for an output rate of 28867 Hz.
  ; About 480 cycles can fit in a returning PLAY at 60.1 Hz.
  ; If we want to space the ASK carriers about 120 Hz apart,
  ; we'll need to repeat each wave twice.
  ldy #0
  uploop:
    jsr dosampley
    iny
    cpy #WAVELEN
    bne uploop
  downloop:
    dey
    jsr dosampley
    cpy #0
    bne downloop
  jmp getnextcol

dosampley:
  lda (wave0ptr),y
  adc (wave1ptr),y
  adc (wave2ptr),y
  adc (wave3ptr),y
  adc (wave4ptr),y
  adc (wave5ptr),y
  adc (wave6ptr),y
  lsr a
  sta $4011
  rts
.endproc

.proc getnextcol
  ldx alphaptr
  inx
  
  ; If the 8x8 cell is finished or the right side of the glyph
  ; has been reached, get a new letter
  txa
  and #$07
  beq newletter
have_x:
  lda alphabetdata,x
  bmi newletter
  stx alphaptr

  ldy #>wave0
  lsr a
  bcs :+
    ldy #>wavesilence
  :
  sty wave0ptr+1

  ldy #>wave1
  lsr a
  bcs :+
    ldy #>wavesilence
  :
  sty wave1ptr+1

  ldy #>wave2
  lsr a
  bcs :+
    ldy #>wavesilence
  :
  sty wave2ptr+1

  ldy #>wave3
  lsr a
  bcs :+
    ldy #>wavesilence
  :
  sty wave3ptr+1

  ldy #>wave4
  lsr a
  bcs :+
    ldy #>wavesilence
  :
  sty wave4ptr+1

  ldy #>wave5
  lsr a
  bcs :+
    ldy #>wavesilence
  :
  sty wave5ptr+1

  ldy #>wave6
  lsr a
  bcs :+
    ldy #>wavesilence
  :
  sty wave6ptr+1
  rts
newletter:
  ldy #0
  lda (msgptrlo),y
  beq initroutine
  inc msgptrlo
  bne :+
    inc msgptrhi
  :
  cmp #$21
  bcc :+
  cmp #$30
  bcs :+
    ora #%00010000
  :
  asl a
  asl a
  asl a
  tax
  jmp have_x
.endproc

.proc initroutine
  lda #0
  sta wave0ptr
  sta wave1ptr
  sta wave2ptr
  sta wave3ptr
  sta wave4ptr
  sta wave5ptr
  sta wave6ptr

  lda #<message
  sta msgptrlo
  lda #>message
  sta msgptrhi
  jmp getnextcol::newletter
.endproc

.rodata
message:
  ; For final R and S, use { and }.
  .incbin "msg.txt"
  .byte 0