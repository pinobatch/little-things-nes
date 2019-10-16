;
; Music sequence data for Sprite Cans demo
; Copyright 2010, 2019 Damian Yerrick
;
; To the extent permitted by law, copying and distribution of this
; file, with or without modification, are permitted in any medium
; without royalty provided the copyright notice and this notice are
; preserved in all copies of the source code.
; This file is offered as-is, without any warranty.
;

.include "pentlyseq.inc"

.segment "RODATA"

drumSFX:
  .byt 10, 9, 3
KICK  = 0*8
SNARE = 1*8
CLHAT = 2*8

instrumentTable:
  ; first byte: initial duty (0/4/8/c) and volume (1-F)
  ; second byte: volume decrease every 16 frames
  ; third byte:
  ; bit 7: cut note if half a row remains
  .byt $88, 8, $00, 0  ; bass
  .byt $48, 4, $00, 0  ; song start bass
  .byt $87, 3, $00, 0  ; bell between rounds
  .byt $87, 2, $00, 0  ; xylo

songTable:
  .addr csp_conductor

musicPatternTable:
  .addr csp_pat_warmup
  .addr csp_pat_repnote
  .addr csp_pat_bass

;____________________________________________________________________

csp_conductor:
  setTempo 440
  playPatSq2 0, 15, 1
  waitRows 12*6
  segno
  playPatSq1 1, 17, 1
  playPatSq2 1, 12, 1
  playPatTri 2, 17, 0
  waitRows 12
  dalSegno

csp_pat_warmup:
  .byt N_CS|D_D2
  .byt N_DS|D_D2
  .byt N_E|D_D2
  .byt N_FS|D_D2
  .byt N_GS|D_D2
csp_pat_repnote:
  .byt N_B|D_D2
  .byt 255
csp_pat_bass:
  .byt N_B|D_D8
  .byt 255
