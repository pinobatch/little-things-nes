;
; Code to handle loading and saving of emblems.
;
;
;

.include "global.inc"

.segment "CODE"
;;
; Computes (curPage * 10 + x) * 64 and leaves the result in A:0.
.proc getCurPagePlusX
  stx 1
  lda #0
  sta 0

  ; EMBLEMS are in bank 0
  sta $E000
  sta $E000
  sta $E000
  sta $E000
  sta $E000

  lda curPage
  asl a
  asl a
  adc curPage
  asl a
  adc 1
  lsr a
  ror 0
  lsr a
  ror 0
  rts
.endproc
  
;;
; Computes the base address of an emblem.
; @param curBank bank of emblems to load (0-2)
; @param curPage page of emblems to load (0-7)
; @param X which emblem (0-9)
.proc getEmblemData
  jsr getCurPagePlusX
  ldx curBank
  adc bankDataBaseHi,x
  sta 1
  rts

bankDataBaseHi: .byt $6B, >presetsB16, >presetsA16
.endproc

;;
; Computes the base address of an emblem.
; @param curBank bank of emblems to load (0-2)
; @param curPage page of emblems to load (0-7)
; @param X which emblem (0-9)
.proc getEmblemMetadata
  jsr getCurPagePlusX
  lsr a
  ror 0
  ldx curBank
  adc bankMetadataBaseHi,x
  sta 1
  rts

bankMetadataBaseHi: .byt $61, >presetsBnames, >presetsAnames
.endproc

;;
; Converts a single emblem number in 0-239 to a combination of a
; bank number (0-2), page number (0-8), and emblem number within
; the bank (0-9).
; @param A emblem number
; @return bank in curBank; page in curPage; emblem number in A
.proc getBankAndPage
  ldx #0
  stx curPage
  bankLoop:
    cmp #80
    bcc bankDone
    notDone:
    sbc #80
    inx
    bne bankLoop
  bankDone:
  stx curBank

  cmp #40
  bcc :+
    sbc #40
  :
  rol curPage
  cmp #20
  bcc :+
    sbc #20
  :
  rol curPage
  cmp #10
  bcc :+
    sbc #10
  :
  rol curPage
  rts

.endproc
