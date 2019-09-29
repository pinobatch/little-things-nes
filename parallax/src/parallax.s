.include "nes.inc"
.include "global.inc"
.include "popslide.inc"

.code
.proc scroll_tile_row
texture_row = $00
texture_xscroll = $01

col0ptr = $04
col0byte = $06
col1ptr = $07
col1byte = $09
col2ptr = $0A
col2byte = $0C
col3ptr = $0D
col3byte = $0F
  
  ; Set up the transfer header
  ldx popslide_used
  lda #$0F
  sta popslide_buf,x
  inx
  lda texture_row
  lsr a
  ror a
  ror a
  sta popslide_buf,x
  inx
  lda #64-1
  sta popslide_buf,x
  inx
  stx popslide_used

  ; Set up pointers to the texture source columns
  lda texture_xscroll
  clc
  adc #4
  and #$18
  adc texture_row
  adc texture_row
  asl a
  asl a
  asl a
  sta col0ptr+0
  adc #64
  sta col1ptr+0
  clc
  adc #64
  sta col2ptr+0
  clc
  adc #64
  sta col3ptr+0
  lda #>texture
  sta col0ptr+1
  sta col1ptr+1
  sta col2ptr+1
  sta col3ptr+1
  
  ldy #0
  rowloop:
    lda (col3ptr),y
    sta col3byte
    lda (col2ptr),y
    sta col2byte
    lda (col1ptr),y
    sta col1byte
    lda (col0ptr),y
    sta col0byte
    lda texture_xscroll
    and #7
    bne morethan0scroll
      lda col0byte
      jmp have_final_col0byte
    morethan0scroll:
    cmp #4
    bcc lessthan4scroll
    
      ; scroll right by (8 - A) pixels
      eor #$07
      tax

      lda col3byte
      rorloop:
        lsr a  ; prime the carry flag
        ror col0byte
        ror col1byte
        ror col2byte
        ror col3byte
        dex
        bpl rorloop
      lda col0byte
      jmp have_final_col0byte

    lessthan4scroll:
      tax
      lda col0byte
      rolloop:
        cmp #$80
        rol col3byte
        rol col2byte
        rol col1byte
        rol a
        dex
        bne rolloop
      
  have_final_col0byte:
    ldx popslide_used
    sta popslide_buf,x
    lda col1byte
    sta popslide_buf+16,x
    lda col2byte
    sta popslide_buf+32,x
    lda col3byte
    sta popslide_buf+48,x
    inx
    stx popslide_used

    iny
    cpy #16
    bcc rowloop
  txa
  adc #48-1  ; compensate for carry set
  sta popslide_used
  rts
.endproc

.rodata
.align 256
texture:  .incbin "obj/nes/realtexture32.chr"
