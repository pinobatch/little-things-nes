; A dialog box consists of a length, followed by 
; Up, Left: Move to previous item
; Down, Right, Select: Move to next item
; B: Accept cancel item
; A, Start: Accept current item
;
; offset 0: Number of items
; offset 1: B button item
; offset 2: X of first item
; offset 3: Y of first item
; offset 4: X of second item
; etc.
;
; @param 0 pointer to 
; @param 2 number of selected item (0 = first)
; @param 3 address of OAM entry to use (0, 4, 8, ..., 252)
.include "global.inc"
.proc doMenu

  ; move sprite
  lda 2
  sec
  adc #0
  asl a
  tay
  ldx 3
  lda (0),y
  sta OAM,x
  iny
  lda (1),y
  sta OAM+1,x

  ; wait for vblank
  lda retraces
  :
    cmp retraces
    beq :-
  lda #>OAM
  sta OAM_DMA
  jsr screenOn
  
  jsr readPad

  lda newKeys
  and #KEY_DOWN|KEY_RIGHT|KEY_SELECT
  beq noNext
    inc 2
    lda 2
    ldy #0
    cmp (0),y
    bcc noNext
      sta 2
  noNext:
  
  lda newKeys
  and #KEY_UP|KEY_LEFT
  beq noPrevious
    lda 2
    bne noPreviousWrap
      ldy #0
      lda (0),y
      sta 2
    noPreviousWrap:
    dec 2
  noPrevious:

  lda newKeys
  and #KEY_B
  beq noB
    ldy #0
    lda (0),y
    sta 2
  noB:

  lda newKeys
  and #KEY_A|KEY_B
  bne pressedA
    jmp doSel
  pressedA:
  rts
.endproc
