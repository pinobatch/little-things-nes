.export read_mouse, mouse_change_sensitivity

;;
; @param X player number
.proc read_mouse
  lda #1
  sta 1
  sta 2
  sta 3
:
  lda $4016,x
  lsr a
  rol 1
  bcc :-
.if 0
  ldy #0
:
  dey
  bne :-
.endif
:
  lda $4016,x
  lsr a
  rol 2
  bcc :-
:
  lda $4016,x
  lsr a
  rol 3
  bcc :-
  rts
.endproc

.proc mouse_change_sensitivity
  lda #1
  sta $4016
  lda $4016,x
  lda #0
  sta $4016
  rts
.endproc

