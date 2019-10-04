.p02
.include "global.inc"

PICKER_Y = 22
PICKER_BASE = $2000 + ((PICKER_Y + 2) * 32)

lastColor = 14
curColor = 15
  

;;
; Draws a color picker.
; Returns the chosen color.
; @param A color
; @return chosen color in A if player accepted;
; previous color in A if player canceled
.proc colorPicker

  sta lastColor
  sta curColor

  ; step 1: draw border
  lda #28
  sta 0
  lda #5
  sta 1
  ldx #1
  ldy #PICKER_Y
  lda retraces
  :
    cmp retraces
    beq :-
  jsr drawFrame

  ; set initial color of preview square
  lda #$3F
  sta PPUADDR
  lda #$05
  sta PPUADDR
  lda curColor
  sta PPUDATA

  ; clear out remnant of help text
  lda #>(PICKER_BASE - 32 + 2)
  sta PPUADDR
  lda #<(PICKER_BASE - 32 + 2)
  sta PPUADDR
  ldx #7
  lda #' '
  :
    .repeat 4
      sta PPUDATA
    .endrepeat
    dex
    bne :-
  
  jsr screenOn

  ; step 2: draw dialog content
  lda retraces
  :
    cmp retraces
    beq :-
  lda #>PICKER_BASE
  sta PPUADDR
  lda #<PICKER_BASE
  sta PPUADDR
  ldx #0
  ldy #8*3
  clc
  copyDialogText:
    .repeat 4, I
      lda colorPicker_nam+I,x
      sta PPUDATA
    .endrepeat
    txa
    adc #4
    tax
    dey
    bne copyDialogText
  jsr screenOn
  
  loop:
    lda PPUSTATUS
    lda retraces
    :
      cmp retraces
      beq :-
    jsr colorPickerUpdatePreview
    jsr screenOn
      
    jsr readPad

    lda newKeys
    and #KEY_DOWN
    beq notDown
      lda curColor
      cmp #$10
      bcc notUp
      sbc #$10
      sta curColor
    notDown:

    lda newKeys
    and #KEY_UP
    beq notUp
      lda curColor
      cmp #$30
      bcs notUp
      adc #$10
      sta curColor
    notUp:

    lda newKeys
    and #KEY_LEFT
    beq notLeft
      lda curColor
      and #$0F
      beq notLeft
      dec curColor
    notLeft:

    lda newKeys
    and #KEY_RIGHT
    beq notRight
      lda curColor
      and #$0F
      cmp #$0C
      bcs notRight
      inc curColor
    notRight:

    lda newKeys
    and #KEY_A|KEY_B|KEY_START
    beq loop

  and #KEY_B
  beq notB
    lda lastColor
    sta curColor
  notB:
  
  lda retraces
  :
    cmp retraces
    beq :-
  lda #<(PICKER_BASE - 64)
  sta xferBufferDstLo
  lda #>((PICKER_BASE - 64) | $8000)
  sta xferBufferDstHi
  lda #14
  sta xferBufferLen
  jsr blastXferBuffer
  jsr screenOn
  jsr readPad

  lda curColor
  rts
.endproc

.proc colorPickerUpdatePreview
  COLOR_BASE = PICKER_BASE + 16
  BRIGHT_BASE = PICKER_BASE + 2*32 + 17

  ; update preview square
  lda #$3F
  sta PPUADDR
  lda #$05
  sta PPUADDR
  lda curColor
  sta PPUDATA

  ; update displayed color number
  lda #>COLOR_BASE
  sta PPUADDR
  lda #<COLOR_BASE
  sta PPUADDR
  ldx #' '  ; tens digit
  lda curColor
  and #$0F
  cmp #10
  bcc notGt10
    ; if color is greater than 10:
    sbc #10  ; adjust the ones digit
    ldx #'1'  ; and carry the 1 to the tens digit
  notGt10:
  stx PPUDATA
  ora #'0'
  sta PPUDATA

  ; update displayed brightness number
  ; simpler because always 0, 1, 2, or 3
  lda #>BRIGHT_BASE
  sta PPUADDR
  lda #<BRIGHT_BASE
  sta PPUADDR
  ldx #' '
  lda curColor
  lsr a
  lsr a
  lsr a
  lsr a
  ora #'0'
  sta PPUDATA
  rts
.endproc

.proc screenOn
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda lastPPUCTRL
  sta PPUCTRL
  lda #%00011110
  sta PPUMASK
  rts
.endproc

.segment "RODATA"
colorPicker_nam:
  .incbin "screens/colorPicker.nam"
