;;
; Clocks the LFSR several times and returns the 8 low
; bits of the state.
; @param Y number of times to clock the LFSR

.import tableauCards

.segment "ZEROPAGE"
randSeed: .res 4

.segment "CODE"
.proc getLFSRBits
  asl randSeed
  rol randSeed+1
  rol randSeed+2
  rol randSeed+3
  lda randSeed
  bcc :+
    eor #$C5
  :
  sta randSeed
  dey
  bne getLFSRBits
  rts
.endproc


.proc shuffleTableau
  ldx #71
  clearLoop:
    txa
    sta tableauCards,x
    dex
    bpl clearLoop
  
  ldx #71
  shuffleLoop:

    ; randomly choose a card to swap with
    ldy #4
    jsr getLFSRBits
    cmp #144
    bcc :+
      sbc #144
    :
    cmp #72
    bcc :+
      sbc #72
    :

    ; swap card X with the random card
    tay
    lda tableauCards,x
    pha
    lda tableauCards,y
    sta tableauCards,x
    pla
    sta tableauCards,y
    
    dex
    bpl shuffleLoop
  rts
.endproc
