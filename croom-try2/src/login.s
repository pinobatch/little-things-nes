.include "global.inc"

.proc load8PlayerEmblems
  playerNo = 15
  
  ldx #$0E
  stx PPUADDR
  ldx #0
  stx PPUADDR
  stx playerNo
  
  ; example emblems are in bank 0
  stx $E000
  stx $E000
  stx $E000
  stx $E000
  stx $E000
  
  forEachPlayer:
    lda playerNo
    asl a
    asl a
    asl a
    asl a
    tax
    lda sramPrefsData,x
    beq playerNotPresent

    lda sramPrefsData+8,x
    ; If emblem number is invalid (240-255), set to the last
    ; valid emblem number
    cmp #240
    bcc :+
      lda #239
    :

    ; copy emblem chr
    jsr getBankAndPage
    tax
    jsr getEmblemData
    ldy #0
    :
      lda (0),y
      sta PPUDATA
      iny
      cpy #64
      bcc :-
    jmp continue

    playerNotPresent:
      ldy #64
      lda #$00
      :
        sta PPUDATA
        dey
        bne :-

    continue:      
    inc playerNo
    lda playerNo
    cmp #8
    bcc forEachPlayer
  rts
.endproc

col1_x = 4
col2_x = 17
col1_y = 6
.proc loginGetPlayerVRAMPosition
  pha
  and #$03
  lsr a
  ror a
  ror a
  sta 0  ; 0 = A = row * 64
  lsr a  ; A = row * 32
  adc 0  ; A = row * 96
  sta 0
  php  ; push carry from multiplication by 96
  clc
  adc #col1_y*32+col1_x
  sta 0
    
  lda #$20
  adc #0  ; add carry from addition
  plp
  adc #0  ; add carry from multiplication by 96
  sta 1

  pla
  and #$04
  beq :+
    lda #col2_x - col1_x
  :
  adc 0
  sta 0
  rts
.endproc

.proc draw8PlayerNames
  playerNo = 15

  ldx #0
  stx playerNo

  forEachPlayer:  
    lda playerNo
    jsr loginGetPlayerVRAMPosition
    lda 1
    sta PPUADDR
    lda 0
    sta PPUADDR

    lda playerNo
    asl a
    asl a
    asl a
    asl a
    tax
    lda sramPrefsData,x
    bne playerPresent
    lda #'-'
    ldx #11
    :
      sta PPUDATA
      dex
      bne :-
    beq continue
    
    playerPresent:
    
      ; top row of player is the top row of the emblem plus
      ; the player's name
      lda playerNo
      asl a
      asl a
      ora #$E0
      sta PPUDATA
      ora #$02
      sta PPUDATA
      lda ' '
      sta PPUDATA
      ldy #8
      
      copyNameLoop:
        lda sramPrefsData,x
        beq copyNameDone
        sta PPUDATA
        inx
        dey
        bne copyNameLoop
      copyNameDone:
      
      ; bottom row of player is the bottom row of the emblem
      lda 0
      clc
      adc #32
      sta 0
      lda 1
      adc #0
      sta PPUADDR
      lda 0
      sta PPUADDR
      lda playerNo
      asl a
      asl a
      ora #$E1
      sta PPUDATA
      ora #$02
      sta PPUDATA
        
    continue:
    inc playerNo
    lda playerNo
    cmp #8
    bcc forEachPlayer
  rts
.endproc

.proc loginDrawSprites
  lda #4
  sta OAM+5
  lda #%00000000  ; no flip, color 0
  sta OAM+6

  lda cursorY
  cmp #4
  bcs isOnRetire
  asl a
  adc cursorY
  asl a
  asl a
  asl a
  adc #col1_y*8-1
  sta OAM+12
  sta OAM+4
  sta OAM+8
  lda #col1_x * 8 - 8
  ldx cursorX
  beq notCol2
    lda #col2_x * 8 - 8
  notCol2:
  sta OAM+7
  adc #8
  sta OAM+11
  adc #8
  sta OAM+15

  lda cursorX
  asl a
  asl a
  ora cursorY
  asl a
  asl a
  pha  ; stack: player no * 4
  
  asl a
  asl a
  tax
  lda sramPrefsData,x
  beq playerNotPresent
  lda sramPrefsData+8,x
  jsr getBankAndPage
  tax
  jsr getEmblemMetadata
  ldy #25
  lda (0),y
  sta 2
  iny
  lda (0),y
  sta 3
  jmp playerPresentContinue

  playerNotPresent:
    lda #$2A
    sta 2
    lda #$1A
    sta 3

  playerPresentContinue:
  
  pla  ; unstack: player no * 4
  ora #$E0
  sta OAM+9
  ora #2
  sta OAM+13
  lda #0
  sta OAM+10
  sta OAM+14
  lda #16
  sta oamAddress
  jmp clearRestOfOAM
  
  isOnRetire:
    lda #168-1-4
    sta OAM+4
    lda #48
    sta OAM+7
    lda #$26
    sta 2
    lda #$16
    sta 3
    lda #8
    sta oamAddress
    jmp clearRestOfOAM
.endproc

loginArrow:
.byt %10000000 
.byt %11000000 
.byt %11100000 
.byt %11110000 
.byt %00111000 
.byt %00001100 
.byt %00000010 
.byt %00000000
.byt %00000000 
.byt %00000000 
.byt %00000000 
.byt %00000000 
.byt %11000000 
.byt %11110000 
.byt %11111100 
.byt %11111111

.byt %00000010 
.byt %00001100 
.byt %00111000 
.byt %11110000 
.byt %11100000 
.byt %11000000 
.byt %10000000 
.byt %00000000
.byt %11111110 
.byt %11111100 
.byt %11111000 
.byt %11110000 
.byt %11100000 
.byt %11000000 
.byt %10000000 
.byt %00000000

.proc drawLoginScreen
  ; clear palette
  lda #$3f
  sta PPUADDR
  stx PPUADDR
  lda #$30
  sta PPUDATA
  lda #$10
  sta PPUDATA
  stx PPUDATA
  lda #$0F
  sta PPUDATA
  ldx #7
  lda #$30
  ldy #$16
  :
    sta PPUDATA
    sty PPUDATA
    sty PPUDATA
    sty PPUDATA
    dex
    bne :-

  lda #$20
  sta PPUADDR
  ldx #0
  stx PPUADDR
  txa
  clearLoop:
    sta PPUDATA
    sta PPUDATA
    sta PPUDATA
    sta PPUDATA
    inx
    bne clearLoop

  lda #28
  sta 0
  lda #13
  sta 1
  ldx #1
  ldy #4
  jsr drawFrame
  lda #28
  sta 0
  lda #3
  sta 1
  ldx #1
  ldy #19
  jsr drawFrame

  lda #$20
  sta PPUADDR
  lda #$6C
  sta PPUADDR
  ldx #0
  copyLoginText:
    lda loginText,x
    beq :+
    sta PPUDATA
    inx
    bne copyLoginText
  :
  
  lda #$22
  sta PPUADDR
  lda #$A7
  sta PPUADDR
  ldx #0
  copyRetireText:
    lda retireText,x
    beq :+
    sta PPUDATA
    inx
    bne copyRetireText
  :

  lda #$23
  sta PPUADDR
  ldx #0
  stx PPUADDR
  copyResetText:
    lda resetWarningText,x
    beq :+
    sta PPUDATA
    inx
    bne copyResetText
  :
  
  ; copy arrow
  ldx #$00
  stx PPUADDR
  lda #$40
  sta PPUADDR
  :
    lda loginArrow,x
    sta PPUDATA
    inx
    cpx #32
    bcc :-

  jsr load8PlayerEmblems
  jsr draw8PlayerNames
  rts
  
.endproc

.proc doLogin
  lda #0
  sta PPUMASK
  lda #1
  sta cursorX
  lda #2
  sta cursorY
  jsr drawLoginScreen

loginLoop:
  jsr loginDrawSprites
  lda retraces
  :
    cmp retraces
    beq :-
  lda #$3F
  sta PPUADDR
  lda #$11
  sta PPUADDR
  lda 2
  sta PPUDATA
  lda 3
  sta PPUDATA
  lda #$0F
  sta PPUDATA
  lda #>OAM
  sta OAM_DMA
  jsr screenOn
  jsr readPad

  lda newKeys
  and #KEY_UP
  beq notUp
    lda cursorY
    beq notUp
    dec cursorY
  notUp:
  
  lda newKeys
  and #KEY_DOWN
  beq notDown
    lda cursorY
    cmp #4
    bcs notDown
    inc cursorY
  notDown:
  
  lda newKeys
  and #KEY_LEFT
  beq notLeft
    lda cursorX
    beq notLeft
    dec cursorX
  notLeft:
  
  lda newKeys
  and #KEY_RIGHT
  beq notRight
    lda cursorX
    cmp #1
    bcs notRight
    inc cursorX
  notRight:
  
  lda newKeys
  and #KEY_A|KEY_START
  beq loginLoop
  rts
.endproc

loginText: .asciiz "Log in:"
retireText: .byt "Retire Author", 142, ".", 0
resetWarningText:
  .byt "  Be sure to hold RESET while   "
  .byt "  turning off the NES power.", 0
