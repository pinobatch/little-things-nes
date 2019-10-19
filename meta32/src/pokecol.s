.exportzp mtCol0LUT, mtCol1LUT, mtCol2LUT, mtCol3LUT, mtAttrLUT
.exportzp mtCol4LUT, mtCol5LUT, mtCol6LUT, mtCol7LUT
.export pokeColName, pokeColAttr
.export mapCache
.importzp pokeColX, pokeColNameBuf, pokeColAttrBuf

.segment "ZEROPAGE"

mtCol0LUT: .res 2
mtCol1LUT: .res 2
mtCol2LUT: .res 2
mtCol3LUT: .res 2
mtCol4LUT: .res 2
mtCol5LUT: .res 2
mtCol6LUT: .res 2
mtCol7LUT: .res 2
mtAttrLUT: .res 2



.segment "BSS"
.align 256
mapCache: .res 256


.segment "CODE"

pokeColName:
  lda pokeColX  ; 0 = column lut
  and #3
  asl a
  tax
  lda mtCol0LUT,x
  sta 0
  lda mtCol0LUT+1,x
  sta 1
  lda mtCol4LUT,x
  sta 4
  lda mtCol4LUT+1,x
  sta 5

  lda pokeColX  ; 2 = mapCache column
  and #$3C
  asl a
  asl a
  sta 2
  lda #>mapCache
  sta 3
  ldx #13

@loop:
  txa  ; A = row number
  tay
  lda (2),y  ; A = metatile number
  tay
  lda (0),y  ; A = hw 8x8 tile number top
  sta pokeColNameBuf,x
  lda (4),y  ; A = hw 8x8 tile number bottom
  sta pokeColNameBuf+15,x
  dex
  bpl @loop
  rts

pokeColAttr:
  lda pokeColX  ; 2 = mapCache column
  and #$3C
  asl a
  asl a
  sta 2
  lda #>mapCache
  sta 3
  ldx #0

@loop:
  ; FIXME
  txa  ; A = attribute row number
  asl a
  sta 4  ; A, 4 = mapCache row number
  tay
  iny
  lda (2),y  ; A = bottom metatile number
  tay
  lda (mtAttrLUT),y  ; A = bottom attribute
  asl a
  asl a
  asl a
  asl a  ; A = bottom attribute in high nibble
  sta 5  

  ldy 4
  lda (2),y  ; A = top metatile number
  tay
  lda (mtAttrLUT),y  ; A = top attribute
  ora 5  ; A = top and bottom attributes
  sta pokeColAttrBuf,x

  inx
  cpx #7
  bcc @loop

  rts

