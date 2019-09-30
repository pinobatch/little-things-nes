;
; password save support routines
;
; Copyright 2010 Damian Yerrick
;
; Copying and distribution of this file, with or without modification,
; are permitted in any medium without royalty provided the copyright
; notice and this notice are preserved.  This file is offered as-is,
; without any warranty.
;
.include "nes.inc"
.include "global.inc"

.import pwPosition, pwSelectedChar, curPW

; Here we use a simple 40-bit block cipher whose mix of additions and
; XORs was inspired by XTEA.

PWKEY_A = 40
PWKEY_B = 80
PWKEY_C = 150
PWKEY_D = 160
PWKEY_E = 230
CHECK_BYTE = 42
NUM_ROUNDS = 16
PW_SHOW_RAW = 1
; The test password is RLNLGN90

.if PW_SHOW_RAW
.import curData, puthex
.endif
;;
; Encodes data stored in 0-3 to a password in the low 5 bits of 8-15.
.proc encodePassword
term2 = 5
pwout = 8
  lda #CHECK_BYTE
  sta 4
  ldx #NUM_ROUNDS
doRound:
  ; a ^= (b << 2) - (c >> 3) + 40
  lda 2
  lsr a
  lsr a
  lsr a
  sta term2
  lda 1
  asl a
  asl a
  sec
  sbc term2
  clc
  adc #PWKEY_A
  eor 0
  sta 0

  ; b += (c << 2) ^ (d >> 3) ^ 80;
  lda 3
  lsr a
  lsr a
  lsr a
  sta term2
  lda 2
  asl a
  asl a
  eor term2
  eor #PWKEY_B
  clc
  adc 1
  sta 1

  ; c ^= (d << 2) - (e >> 3) + 150;
  lda 4
  lsr a
  lsr a
  lsr a
  sta term2
  lda 3
  asl a
  asl a
  sec
  sbc term2
  clc
  adc #PWKEY_C
  eor 2
  sta 2

  ; d += (e << 2) ^ (a >> 3) ^ 160;
  lda 0
  lsr a
  lsr a
  lsr a
  sta term2
  lda 4
  asl a
  asl a
  eor term2
  eor #PWKEY_D
  clc
  adc 3
  sta 3

  ; e ^= (a << 2) - (b >> 3) + 230;
  lda 1
  lsr a
  lsr a
  lsr a
  sta term2
  lda 0
  asl a
  asl a
  sec
  sbc term2
  clc
  adc #PWKEY_E
  eor 4
  sta 4

  dex
  bne doRound

  ldx #0
pwoutloop:
  lda #0
  lsr 0
  rol a
  lsr 1
  rol a
  lsr 2
  rol a
  lsr 3
  rol a
  lsr 4
  rol a
  sta pwout,x
  inx
  cpx #8
  bcc pwoutloop
  rts
.endproc

;;
; Decodes a password in the low 5 bits of 8-15 to data in 0-3.
; Then compares the check digit to the expected one for BNE/BEQ.
.proc decodePassword
term2 = 5
pwin = 8
  ldx #7
pwinloop:
  lda pwin,x
  lsr a
  rol 4
  lsr a
  rol 3
  lsr a
  rol 2
  lsr a 
  rol 1
  lsr a
  rol 0
  dex
  bpl pwinloop

  ; now undo the rounds in reverse
  ldx #NUM_ROUNDS
doRound:
  lda 1
  lsr a
  lsr a
  lsr a
  sta term2
  lda 0
  asl a
  asl a
  sec
  sbc term2
  clc
  adc #PWKEY_E
  eor 4
  sta 4

  ; PROTIP: The idiom for reverse subtraction (M - A) is
  ; eor #$FF
  ; sec
  ; adc M
  lda 0
  lsr a
  lsr a
  lsr a
  sta term2
  lda 4
  asl a
  asl a
  eor term2
  eor #PWKEY_D ^ $FF
  sec
  adc 3
  sta 3

  lda 4
  lsr a
  lsr a
  lsr a
  sta term2
  lda 3
  asl a
  asl a
  sec
  sbc term2
  clc
  adc #PWKEY_C
  eor 2
  sta 2

  lda 3
  lsr a
  lsr a
  lsr a
  sta term2
  lda 2
  asl a
  asl a
  eor term2
  eor #PWKEY_B ^ $FF
  sec
  adc 1
  sta 1

  lda 2
  lsr a
  lsr a
  lsr a
  sta term2
  lda 1
  asl a
  asl a
  sec
  sbc term2
  clc
  adc #PWKEY_A
  eor 0
  sta 0

  dex
  bne doRound

  lda 4
  cmp #CHECK_BYTE
  rts
.endproc

pwChars:
  .byt "123BCDFG"
  .byt "456HJKLM"
  .byt "789NPQRT"
  .byt "*0#VWXYZ"
  
.proc drawPWCursor
  ldy #0
  lda pwSelectedChar
.if ::PW_SHOW_RAW
  bmi cursorIsInHex
.endif
  and #$07
  asl a
  asl a
  asl a
  asl a
  adc #60
  sta OAM+3,y
  sta OAM+11,y
  adc #8
  sta OAM+7,y
  sta OAM+15,y
  lda pwSelectedChar
  and #$18
  asl a
  adc #122
  sta OAM,y
  sta OAM+4,y
  adc #9
  sta OAM+8,y
  sta OAM+12,y
  lda #'L'
  sta OAM+1,y
  sta OAM+5,y
  sta OAM+9,y
  sta OAM+13,y
  lda #$80
  sta OAM+2,y
  eor #$40
  sta OAM+6,y
  eor #$80
  sta OAM+14,y
  eor #$40
  sta OAM+10,y

  ; So we've drawn the box around the letter. Now draw the cursor.
  lda #105
  sta OAM+16,y
  lda #'_'
  sta OAM+17,y
  lda #0
  sta OAM+18,y
  lda pwPosition
  asl a
  asl a
  asl a
  asl a
  adc #64
  sta OAM+19,y

  tya
  clc
  adc #20
  tay
.if ::PW_SHOW_RAW
  jmp clearRest
  
cursorIsInHex:
  
  lda #89
  sta OAM,y
  lda #'_'
  sta OAM+1,y
  lda #0
  sta OAM+2,y
  lda pwPosition
  lsr a
  clc
  adc pwPosition
  asl a
  asl a
  asl a
  adc #64
  sta OAM+3,y

  tya
  clc
  adc #4
  tay
  jmp clearRest
.endif

clearRest:
  lda #$FF
loop:
  sta OAM,y
  iny
  iny
  iny
  iny
  bne loop
  rts
.endproc


.proc drawPWForm
  lda #$3F
  ldx #$00
  stx PPUMASK
  sta PPUADDR
  stx PPUADDR
:
  lda pwScreenPal,x
  sta PPUDATA
  inx
  cpx #32
  bcc :-

  lda #$20
  ldx #$00
  sta PPUADDR
  stx PPUADDR
  txa
:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  inx
  bne :-

row = 0
  lda #0
  sta row

pwCharsRowLoop:
  ldx row
  lda #$22
  sta PPUADDR
  lda pwformRowBase,x
  sta PPUADDR
  txa
  asl a
  asl a
  asl a
  tax
  ldy #8
:
  lda pwChars,x
  sta PPUDATA
  lda #0
  sta PPUDATA
  inx
  dey
  bne :-
  inc row
  lda row
  cmp #4
  bcc pwCharsRowLoop

  lda #$21
  sta PPUADDR
  lda #$08
  sta PPUADDR
  ldx #0
:
  lda pwmsg1,x
  beq :+
  sta PPUDATA
  inx
  bne :-
:

  lda #$23
  sta PPUADDR
  lda #$22
  sta PPUADDR
  ldx #0
:
  lda pwmsg2,x
  beq :+
  sta PPUDATA
  inx
  bne :-
:

  rts
.endproc

.proc drawPWData

  lda #$21
  sta PPUADDR
  lda #$A8
  sta PPUADDR
  ldx #0
:
  lda curPW,x
  tay
  lda pwChars,y
  sta PPUDATA
  lda #' '
  sta PPUDATA
  inx
  cpx #8
  bcc :-

.if ::PW_SHOW_RAW
  lda #$21
  sta PPUADDR
  lda #$68
  sta PPUADDR
  ldx #0
:
  lda curData,x
  jsr puthex
  lda #' '
  sta PPUDATA
  inx
  cpx #5
  bcc :-
.endif
  rts
.endproc

.proc doPWDialog
wantExit = 7
  jsr drawPWForm
  lda #$09
  sta pwSelectedChar
  lda #0
  sta pwPosition
  sta wantExit
  
frameloop:
  jsr read_pads
.if ::PW_SHOW_RAW
  lda pwSelectedChar
  bpl isInPW
  jmp isInHex
.endif
isInPW:
  lda new_keys
  and #KEY_A
  beq inPW_notA
  ldx pwPosition
  lda pwSelectedChar
  sta curPW,x
  inx
  txa
  and #$07
  sta pwPosition
  
.if !::PW_SHOW_RAW
  bne inPW_notA
.endif
  ldx #7
:
  lda curPW,x
  sta 8,x
  dex
  bpl :-
  jsr decodePassword
  
.if ::PW_SHOW_RAW
  ldx #4
:
  lda 0,x
  sta curData,x
  dex
  bpl :-
.else
  bne badPW
  inc wantExit
badPW:
.endif


inPW_notA:

  lda new_keys
  and #KEY_B
  beq inPW_notB
  lda pwPosition
  beq inPW_notB
  dec pwPosition
inPW_notB:
  
  lda new_keys
  and #KEY_UP
  beq inPW_notUp
  lda pwSelectedChar
  clc
  adc #24
  and #$1F
  sta pwSelectedChar
inPW_notUp:
  
  lda new_keys
  and #KEY_DOWN
  beq inPW_notDown
  lda pwSelectedChar
  clc
  adc #8
  and #$1F
  sta pwSelectedChar
inPW_notDown:
  
  lda new_keys
  and #KEY_LEFT
  beq inPW_notLeft
  lda pwSelectedChar
  clc
  adc #31
  and #$1F
  sta pwSelectedChar
inPW_notLeft:
  
  lda new_keys
  and #KEY_RIGHT
  beq inPW_notRight
  lda pwSelectedChar
  clc
  adc #1
  and #$1F
  sta pwSelectedChar
inPW_notRight:
  
  lda new_keys
  and #KEY_SELECT
  beq inPW_notSelect
.if ::PW_SHOW_RAW
  lda #$80
  sta pwSelectedChar
inPW_notSelect:
  jmp doneProcessingKeys
isInHex:
  lda new_keys
  and #KEY_SELECT
  beq inHex_notSelect
  lda #$00
  sta pwSelectedChar
inHex_notSelect:
  
  lda new_keys
  and #KEY_LEFT
  beq inHex_notLeft
  lda #7
  bne hexAddToPwPosition
inHex_notLeft:
  
  lda new_keys
  and #KEY_RIGHT
  beq inHex_notRight
  lda #1
hexAddToPwPosition:
  clc
  adc pwPosition
  and #$07
  sta pwPosition
inHex_notRight:

  lda new_keys
  and #KEY_DOWN
  beq inHex_notDown
  lda pwPosition
  lsr a
  tax
  lda #$F0
  bcc :+
    lda #$FE
  :
  adc curData,x
  sta curData,x
  jmp inHex_needReencode
  
inHex_notDown:
  lda new_keys
  and #KEY_UP
  beq doneProcessingKeys
  lda pwPosition
  lsr a
  tax
  lda #$10
  bcc :+
    lda #$00
  :
  adc curData,x
  sta curData,x
inHex_needReencode:
  ldx #3
  :
    lda curData,x
    sta 0,x
    dex
    bpl :-
  jsr encodePassword
  ldx #7
  :
    lda 8,x
    sta curPW,x
    dex
    bpl :-
  jsr decodePassword
  lda 4
  sta curData+4

.else
  ; the select handler
  lda #$80
  sta wantExit
inPW_notSelect:

.endif
doneProcessingKeys:
  jsr drawPWCursor
  lda nmis
:
  cmp nmis
  beq :-
  jsr drawPWData
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  sta OAMADDR
  lda #>OAM
  sta OAM_DMA
  lda #VBLANK_NMI
  sta PPUCTRL
  lda #BG_ON|OBJ_ON
  sta PPUMASK

  lda wantExit
  bne :+
    jmp frameloop
  :
  rts
.endproc

.segment "RODATA"
pwScreenPal:
  .byt $02,$12,$10,$38,$02,$12,$10,$38
  .byt $02,$12,$10,$38,$02,$12,$10,$38
  .byt $02,$12,$10,$38,$02,$12,$10,$38
  .byt $02,$12,$10,$38,$02,$12,$10,$38
pwformRowBase:
  .byt $08, $48, $88, $C8
pwmsg1:
  .byt "Enter Password:",0
pwmsg2:
  .byt "+: Move  A: Type  B: Back Up    "
.if PW_SHOW_RAW
  .byt "Select: Switch Lines",0
.else
  .byt "Select: Cancel",0
.endif
