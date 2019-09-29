.include "popslide.inc"

.code

; Several NES games by Nintendo use the "NES Stripe Image RLE" data
; format (N-Stripe for short) to store title screen map layouts in
; ROM.  Because we use PB8 instead for ROM data, we use N-Stripe only
; in RAM as a transfer buffer format.  Not needing to decode from
; anywhere outside popslide_buf ($0100-$01BF) allows a simpler decoder.
;
; Each packet begins with a 3-byte header.
; Byte 1: bit 7: stop; 6-0 first PPUADDR write
; Byte 2: second PPUADDR write
; Byte 3: bit 7: vertical; bit 6: run; bit 5-0: data length minus 1
; If this is a run, exactly 1 data byte follows; otherwise, n+1
; literal bytes follow.
;
; We make one change to Nintendo's format.  Nintendo uses a VRAM
; address in $0000-$00FF as a terminator because Doki Doki Panic is
; the only game that uses N-Stripe to update CHR RAM.  We instead
; use an address in $8000-$FFFF as a terminator.
;
; The decode buffer is read only about half as fast as an unrolled
; copy, so don't try to send more than about 64 bytes in a frame.
;
; Source: http://wiki.nesdev.com/w/index.php/Tile_compression


;;
; Converts a column-major rectangle of tiles to an N-Stripe.
; @param nstripe_left, nstripe_top, nstripe_width, nstripe_height in tiles
; @param nstripe_srclo start of data in column-major order
.proc nstripe_draw_rect
nstripe_toplo = $06
htleft = $07
  ldy #0
  sty nstripe_toplo
  lda nstripe_top
  and #$1F
  sec
  .repeat 3
    ror a
    ror nstripe_toplo
  .endrepeat
  sta nstripe_top
  ldx popslide_used
  colloop:

    ; Calculate destination address
    lda nstripe_left
    and #$20  ; bit 5: which nametable
    beq :+
      lda #$04
    :
    ora nstripe_top
    sta popslide_buf,x
    inx
    lda nstripe_left
    inc nstripe_left
    and #$1F
    ora nstripe_toplo
    sta popslide_buf,x
    inx

    ; Calculate length
    lda nstripe_height
    sta htleft
    clc
    adc #$80 - 1  ; $80-$BF: copy 1-64 bytes incrementing by 32
    sta popslide_buf,x
    inx
    
    tileloop:
      lda (nstripe_srclo),y
      iny
      sta popslide_buf,x
      inx
      dec htleft
      bne tileloop
    dec nstripe_width
    bne colloop
  stx popslide_used
  sec
  ror popslide_buf,x
  rts
.endproc


.proc append_engine
bytesleft = nstripe_height

  ; Append stripe
stripeloop:
  iny
  bit nstripe_top
  bmi normal_top
    ; A is low byte; nstripe_top is high byte
    sta popslide_buf+1,x
    lda nstripe_top
    sta popslide_buf,x
    bne address_written
  normal_top:
    ; A is high byte; next byte is low byte
    sta popslide_buf,x
    lda (nstripe_srclo),y
    iny
    sta popslide_buf+1,x
  address_written:
  inx
  inx
  lda (nstripe_srclo),y  ; direction, run flag, and length
  iny
  sta popslide_buf,x
  inx
  and #$7F
  cmp #$40  ; For runs, copy only one byte
  bcc notrun
    lda #0
  notrun:
  sta bytesleft
  bytesloop:
    lda (nstripe_srclo),y
    iny
    sta popslide_buf,x
    inx
    dec bytesleft
    bpl bytesloop
nextstripe:
  lda (nstripe_srclo),y  ; copy palette index
  bpl stripeloop
stripesdone:
  sta popslide_buf,x
  stx popslide_used
  rts
.endproc

;;
; Appends a set of stripes to the update buffer.
; @param XXAA pointer to the stripe
.proc nstripe_append
  ldy #$FF
.endproc

;;
; Appends a set of stripes to the update buffer.
; @param XXAA pointer to the stripe
; @param Y $00-$3F high byte of each destination address in
; video memory; $80+: stripes contain 2-byte destinations
.proc nstripe_append_yhi
  sty nstripe_top
.endproc

;;
; Appends a set of stripes to the update buffer.
; @param XXAA pointer to the stripe
; @param nstripe_top $00-$3F high byte of each destination address in
; video memory; $80+: stripes contain 2-byte destinations
.proc nstripe_append_tophi
  stx nstripe_srchi
  sta nstripe_srclo
.endproc

;;
; Appends a set of stripes to the update buffer.
; @param nstripe_src pointer to the stripe
; @param nstripe_top $00-$3F high byte of each destination address in
; video memory; $80+: stripes contain 2-byte destinations
.proc nstripe_append_src
  ldy #0
  ldx popslide_used
  jmp append_engine::nextstripe
.endproc

_nstripe_append = nstripe_append
.export _nstripe_append
