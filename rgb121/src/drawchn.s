.include "nes.inc"
.include "cigetbit.inc"

.export decodechn
.exportzp drawchn_x, drawchn_y, drawchn_2000, drawchn_tilebase
.export drawchn_namwidth, drawchn_namheight, drawchn_namtiles

drawchn_src = ciSrc
drawchn_x = 2  ; X position in tiles
drawchn_y = 3  ; Y position in tiles
drawchn_2000     = 4  ; bit 4: which pattern table; bit 1-0: which nametable
drawchn_tilebase = 5

.segment "BSS"
drawchn_namwidth: .res 1
drawchn_namheight: .res 1
drawchn_namtiles: .res 1
drawchn_linebuf: .res 32

.segment "CODE"
;;
; @param ciSrc starting address of .chn file
; @param 5 base tile number
; @return ciDst: address of pb8 data
.proc decodechn
widleft = 0
htleft = 1
run_greatest = 8  ; greatest tile seen yet
run_length = 9
run_lastblk = 10
run_mostcommon = 11  ; most common back-referenced tile
run_delta = 12

  ; Load the header: width, height, # unique tiles, skip, most common
  ldy #0
  lda (drawchn_src),y
  iny
  sta drawchn_namwidth
  sta widleft
  lda (drawchn_src),y
  iny
  sta drawchn_namheight
  sta htleft
  lda (drawchn_src),y
  iny
  iny
  sta drawchn_namtiles

  ; Push callee-saved locations
  lda 8
  pha
  lda 9
  pha
  lda 10
  pha
  lda 11
  pha
  lda 12
  pha

  lda #$80
  sta ciBits
  lda (drawchn_src),y
  sta run_mostcommon
  iny
  ldx #$FF
  stx run_greatest
  inx

  ; Phase 1: Decode RLE'd tiles

get_next_run:
  ; the start of a new run
  jsr ciGetGammaCode
  sta run_length
  ciGetBit
  bcc is_literal_run
  ciGetBit
  bcc is_new_tile_run

  ; 11: Most common tile
  lda #0
  sta run_delta
  lda run_mostcommon
  bcs have_lastblk

is_new_tile_run:
  ; 10: New tiles
  lda #1
  sta run_delta
  lda run_greatest
  jmp have_lastblk
  
is_literal_run:
  ; as many bits as in the last literal run
  lda run_greatest
  sta run_delta
  beq have_lastblk
  lda #0
  sta run_lastblk
getliteralloop:
  ciGetBit
  rol run_lastblk
  lsr run_delta
  bne getliteralloop
  lda run_lastblk
have_lastblk:

  clc
  adc drawchn_tilebase
  sta run_lastblk
runloop:
  lda run_delta
  beq not_runofnewtiles
  inc run_greatest
  inc run_lastblk
not_runofnewtiles:
  lda run_lastblk
  sta drawchn_linebuf,x
  inx
  cpx drawchn_namwidth
  bcc not_new_row
  
  ; Move cursor to next row
  jsr finish_row
  dec htleft
  beq rle_done
not_new_row:
  dec run_length
  bne runloop
  jmp get_next_run
rle_done:

  ; and finalize the indexing into the compressed stream
  tya
  clc
  adc ciSrc
  sta ciSrc
  bcc :+
  inc ciSrc+1
:
  ; Restore callee-saved ZP locations
  pla
  sta 12
  pla
  sta 11
  pla
  sta 10
  pla
  sta 9
  pla
  sta 8

  ; And prepare to decompress CHR data

  ; Now drawchn_src is pointed at CHR data to be unpacked
  ; so calculate the destination address
  lda drawchn_2000
  and #BG_1000
  beq pat_0000
  lda #$01
pat_0000:

  ; calculate the source and destination addresses
  .repeat 4
  asl drawchn_tilebase
  rol a
  .endrepeat
  sta ciDst+1
  lda drawchn_tilebase
  sta ciDst
  rts
.endproc

.proc finish_row
  ntadlo = 6
  ntadhi = 7
  lda drawchn_y
  inc drawchn_y
  sec
  ror a
  ror ntadlo
  lsr a
  ror ntadlo
  lsr a
  ror ntadlo
  sta PPUADDR
  ora #$04
  sta ntadhi
  lda ntadlo
  and #$E0
  ora drawchn_x
  sta PPUADDR
  sta ntadlo
  ldx #0
  jsr cpline
  lda ntadhi
  sta PPUADDR
  lda ntadlo
  sta PPUADDR
cpline:
  lda drawchn_linebuf,x
  sta PPUDATA
  inx
  cpx drawchn_namwidth
  bcc cpline
  ldx #0
  rts
.endproc
