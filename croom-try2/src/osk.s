.include "global.inc"

ENTRY_FIELD_TOP = 17
KEYBOARD_LEFT = 12
KEYBOARD_TOP = ENTRY_FIELD_TOP + 3
KEYBOARD_W = 12

; There are actually (KEYBOARD_H + 1) rows, including the
; spacebar.  To set this up, we need to use .define instead
; of = to set this one because if we use =, ca65 V2.11.0 on
; Windows XP will give "Error: Constant expression expected".
.define KEYBOARD_H 4

INITIAL_X = 4
INITIAL_Y = 1

DIRTY_ENTRY  = %00000001
DIRTY_KEYMAP = %00000010


.segment "CODE"

.proc prepareKeyMap
  keyMapBase = $2000 + KEYBOARD_TOP * 32

  ; clear transfer buffer
  ldx #KEYBOARD_H * 32 - 1
  lda #0
  firstClearLoop:
    sta xferBuffer,x
    dex
    bpl firstClearLoop

  ; copy keys
  ldy #0
  ldx keyboardShifted
  beq notShifted
    ldx #KEYBOARD_H*KEYBOARD_W
  notShifted:

  colLoop:
    .repeat KEYBOARD_H, I
      lda keyMapLower+KEYBOARD_LEFT*I,x
      sta xferBuffer+KEYBOARD_LEFT+32*I,y
    .endrepeat
    inx
    iny
    cpy #KEYBOARD_W
    bcc colLoop

  ; draw left and right frame
  lda #FRAMETILE::L
  .repeat KEYBOARD_H, I
    sta xferBuffer+KEYBOARD_LEFT-1+32*I
  .endrepeat
  lda #FRAMETILE::R
  .repeat KEYBOARD_H, I
    sta xferBuffer+KEYBOARD_LEFT+KEYBOARD_W+32*I
  .endrepeat

  ; set destination
  lda #<keyMapBase
  sta xferBufferDstLo
  lda #>keyMapBase
  sta xferBufferDstHi
  lda #KEYBOARD_H*2
  sta xferBufferLen
  rts
.endproc

.proc prepareEntryField
  entryBase = $2000 + (ENTRY_FIELD_TOP - 1) * 32

  ; clear transfer buffer
  ldy #32*3-1
  lda #0
  sta xferBuffer
  firstClearLoop:
    sta xferBuffer,y
    dey
    bne firstClearLoop

  ; copy the nul-terminated name of the entry blank, up to 9 chars
  lda (keyboardName),y
  copyNameLoop:
    sta xferBuffer+32+2,y
    iny
    lda (keyboardName),y
    bne copyNameLoop

  ; copy the value of the entry
  lda keyboardCurLen
  beq noTextInField
  ldx #0
  copyValueLoop:
    lda keyboardText,x
    sta xferBuffer+32+KEYBOARD_LEFT,x
    inx
    cpx keyboardCurLen
    bcc copyValueLoop
  noTextInField:

  ; draw frame around entry
  lda #FRAMETILE::TL
  sta xferBuffer+KEYBOARD_LEFT-1
  lda #FRAMETILE::L
  sta xferBuffer+KEYBOARD_LEFT+32-1
  lda #FRAMETILE::BL
  sta xferBuffer+KEYBOARD_LEFT+64-1
  ldx keyboardMaxLen
  lda #FRAMETILE::TR
  sta xferBuffer+KEYBOARD_LEFT,x
  lda #FRAMETILE::R
  sta xferBuffer+KEYBOARD_LEFT+32,x
  lda #FRAMETILE::BR
  sta xferBuffer+KEYBOARD_LEFT+64,x
  topBottomLoop:
    lda #FRAMETILE::T
    sta xferBuffer+KEYBOARD_LEFT-1,x
    lda #FRAMETILE::B
    sta xferBuffer+KEYBOARD_LEFT+64-1,x
    dex
    bne topBottomLoop

  ; set destination
  lda #<entryBase
  sta xferBufferDstLo
  lda #>entryBase
  sta xferBufferDstHi
  lda #6
  sta xferBufferLen
  rts
.endproc

;;
; Gets the horizontal position of the cursor inside the on-screen
; keyboard, clamped so that keyMapLeftSide < X < keyMapRightSide
; @param cursorY the vertical position
; @param cursorX the horizontal position
; @return the clamped horizontal position in A, vertical position in Y
.proc getClampedCursorX
  ldy cursorY
  lda cursorX

  ; clamp to right side of row
  cmp keyMapRightSide,y
  bcc notRightOfKeys
    lda keyMapRightSide,y
    sbc #1
  notRightOfKeys:

  ; clamp to left side of row
  cmp keyMapLeftSide,y
  bcs notLeftOfKeys
    lda keyMapLeftSide,y
  notLeftOfKeys:

  rts
.endproc

.proc keyboardDrawCursor

  ; cursor for keyboard
  lda cursorY
  asl a
  asl a
  asl a
  adc #KEYBOARD_TOP * 8 + 3
  sta OAM+4
  lda #4
  sta OAM+5
  lda #0
  sta OAM+6
  jsr getClampedCursorX
  asl a
  asl a
  asl a
  adc #KEYBOARD_LEFT * 8 + 4
  sta OAM+7

  ; cursor for entry field
  ldy #ENTRY_FIELD_TOP * 8 - 1
  lda retraces
  and #$10  ; 16 frames on, 16 off
  beq notBlinked
    ldy #$F0
  notBlinked:
  sty OAM+8
  lda #0
  sta OAM+9
  lda #%10000000
  sta OAM+10
  lda keyboardCurLen
  asl a
  asl a
  asl a
  adc #KEYBOARD_LEFT * 8
  sta OAM+11

  ldx #12
  lda #$F0
  clc
  clearDespritus:
    sta OAM,x
    inx
    inx
    inx
    inx
    bne clearDespritus
  rts
.endproc

.proc addChar
  lda keyboardCurLen
  cmp keyboardMaxLen
  bcs tooLong

    ; get the offset into the keymap
    jsr getClampedCursorX
    sta 0
    lda cursorY
    cmp #KEYBOARD_H
    bcc notSpace
      lda #' '
      jmp writeCharInA    
    notSpace:
      asl a
      adc cursorY
      asl a
      asl a
      adc 0
      ldx keyboardShifted
      beq notShifted
        adc #KEYBOARD_W*KEYBOARD_H
      notShifted:

      tax
      lda keyMapLower,x
    writeCharInA:

    ldx keyboardCurLen
    sta keyboardText,x
    inc keyboardCurLen
    lda #DIRTY_ENTRY
    ora dirtyRow
    sta dirtyRow
  tooLong:
  rts
.endproc

.proc rubChar
  lda keyboardCurLen
  beq tooShort
    dec keyboardCurLen
    lda #DIRTY_ENTRY
    ora dirtyRow
    sta dirtyRow
  tooShort:

  rts
.endproc

.proc doKeyboardKeys
  lda newKeys
  and #KEY_A
  beq notA
    jsr addChar
  notA:

  lda newKeys
  and #KEY_B
  beq notB
    jsr rubChar
  notB:

  lda newKeys
  and #KEY_SELECT
  beq notSelect
    ldx #0
    lda keyboardShifted
    bne @turningShiftedOff
      inx
    @turningShiftedOff:
    stx keyboardShifted
    lda #DIRTY_KEYMAP
    ora dirtyRow
    sta dirtyRow
  notSelect:

  lda newKeys
  and #KEY_DOWN
  beq notDown
    lda cursorY
    cmp #KEYBOARD_H
    bcc notBelowKeys
      lda #0
      sta cursorY
      jmp notDown
    notBelowKeys:
      inc cursorY
  notDown:

  lda newKeys
  and #KEY_UP
  beq notUp
    lda cursorY
    bne notAboveKeys
      lda #KEYBOARD_H
      sta cursorY
      jmp notDown
    notAboveKeys:
      dec cursorY
  notUp:

  lda newKeys
  and #KEY_LEFT
  beq notLeft
    jsr getClampedCursorX
    cmp keyMapLeftSide,y
    bne dontWrapXToRight
      lda keyMapRightSide,y
    dontWrapXToRight:

    sec
    sbc #1
    sta cursorX
  notLeft:

  lda newKeys
  and #KEY_RIGHT
  beq notRight
    jsr getClampedCursorX
    clc
    adc #1
    cmp keyMapRightSide,y
    bcc dontWrapXToLeft
      lda keyMapLeftSide,y
    dontWrapXToLeft:

    sta cursorX
  notRight:

  rts
.endproc

.proc doKeyboard
  ldx #INITIAL_X
  stx cursorX
  ldx #INITIAL_Y
  stx cursorY
  ldx #0
  stx keyboardShifted
  stx PPUMASK
  
  ; set palette
  lda #$3F
  sta PPUADDR
  stx PPUADDR
  lda #$30
  sta PPUDATA
  ldy #$10
  sty PPUDATA
  stx PPUDATA
  dey
  sty PPUDATA

  ; draw everything but the title and keymap
  ldy #1  ; keyboard frame
  jsr loadCHR

  ; draw what was left out of the .nam
  lda lastPPUCTRL
  sta PPUCTRL
  jsr prepareKeyMap
  jsr blastXferBuffer
  ;jsr prepareEntryField
  ;jsr blastXferBuffer
  lda #DIRTY_ENTRY
  sta dirtyRow

  forever:

    ; Update one dirty thing at once
    lda dirtyRow
    and #DIRTY_ENTRY
    beq entryNotDirty
      lda #<~DIRTY_ENTRY
      and dirtyRow
      sta dirtyRow
      jsr prepareEntryField
      jmp doneUpdating
    entryNotDirty:

    lda dirtyRow
    and #DIRTY_KEYMAP
    beq doneUpdating
      lda #<~DIRTY_KEYMAP
      and dirtyRow
      sta dirtyRow
      jsr prepareKeyMap
    doneUpdating:

    jsr keyboardDrawCursor

    lda retraces
    :
      cmp retraces
      beq :-
    lda PPUSTATUS
    jsr blastXferBuffer
    lda #>OAM
    sta OAM_DMA
    lda #0
    sta PPUSCROLL
    sta PPUSCROLL
    lda lastPPUCTRL
    sta PPUCTRL
    lda #%00011110
    sta PPUMASK

    jsr readPad
    jsr doKeyboardKeys
    lda newKeys
    and #KEY_START
    beq forever
  rts
.endproc


.segment "RODATA"
keyMapLower:
  .byt "1234567890-="
  .byt "qwertyuiop[]"
  .byt "asdfghjkl;'\"
  .byt "`zxcvbnm,./", 1
  .byt "!@#$%^&*()_+"
  .byt "QWERTYUIOP{}"
  .byt "ASDFGHJKL:", 34, "|"
  .byt "~ZXCVBNM<>?", 1

keyMapLeftSide:
  .byt 0, 0, 0, 0, 5
keyMapRightSide:
  .byt 12, 12, 12, 11, 6
