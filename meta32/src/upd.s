.include "nes.inc"
.list

.export upd_pokeColName, upd_pokeColAttr
.importzp last_ppuctrl

.segment "ZEROPAGE"
pokeColNameBuf: .res 30
pokeColAttrBuf: .res 8
pokeColX: .res 1
.exportzp pokeColNameBuf, pokeColAttrBuf, pokeColX

.segment "CODE"

;
; Pokes the column nametable buffer into VRAM at x tile position
; pokeColX % 64.
;
upd_pokeColName:
  lda last_ppuctrl
  ora #PPUCTRL_WRDOWN
  sta PPUCTRL

  ; Compute and set VRAM address
  lda pokeColX
  and #$20
  lsr a
  lsr a
  lsr a
  ora #$20
  sta PPUADDR
  lda pokeColX
  and #$1F
  sta PPUADDR

  ; Unrolled loop to copy nametable data
  .repeat 15,i
    lda pokeColNameBuf+i
    sta PPUDATA
    lda pokeColNameBuf+15+i
    sta PPUDATA
  .endrep
  rts

;
; Pokes the column nametable buffer into VRAM in the attribute column
; that covers x tile position pokeColX % 64.
;
upd_pokeColAttr:
  lda last_ppuctrl
  ora #PPUCTRL_WRDOWN
  sta PPUCTRL

  ; Compute VRAM address to XXAA
  lda pokeColX
  and #$20
  lsr a
  lsr a
  lsr a
  ora #$23
  tax
  lda pokeColX
  and #$1c
  lsr a
  lsr a
  ora #$c0

  ; Unrolled loop to copy nametable data
  .repeat 4,i
    .if i > 0
      adc #8
    .endif
    ; Seek
    stx PPUADDR
    sta PPUADDR

    ; Read
    ldy pokeColAttrBuf+0+i
    sty PPUDATA
    ldy pokeColAttrBuf+4+i
    sty PPUDATA
  .endrep
  rts
