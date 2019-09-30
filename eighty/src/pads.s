;
; NES Four Score controller reading code
; Copyright 2012 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.export read_fourscore_once, read_fourscore
.importzp cur_keys, new_keys

JOY1      = $4016
JOY2      = $4017

presses_1 = $00
presses_2 = $01
presses_3 = $02
presses_4 = $03
sigbyte_1 = $04
sigbyte_2 = $05

.segment "CODE"
.proc read_fourscore
  jsr read_fourscore_once
  
  ; If there was a bit deletion from JOY1, replace with the pressses
  ; from the last frame
  lda sigbyte_1
  cmp #$10
  beq not_glitched_1p3p
  lda cur_keys+0
  sta presses_1
  lda cur_keys+2
  sta presses_3
not_glitched_1p3p:

  ; If there was a bit deletion from JOY2, replace with the pressses
  ; from the last frame
  lda 5
  cmp #$20
  beq not_glitched_2p4p
  lda cur_keys+1
  sta presses_2
  lda cur_keys+3
  sta presses_4
not_glitched_2p4p:

  ; For each player, calculate which buttons were just pressed since
  ; the last frame
  ldx #3
new_keys_loop:
  lda cur_keys,x  ; A = buttons pressed in previous frame
  eor #$FF        ; A = buttons NOT pressed in previous frame
  and presses_1,x ; A = buttons pressed now and not before
  sta new_keys,x
  lda presses_1,x ; A = buttons pressed now
  sta cur_keys,x
  dex
  bpl new_keys_loop
  rts
.endproc

.proc read_fourscore_once

  ; Request a pair of 3-byte reports and initialize the ring counters
  ldx #$01
  ; It's a ring counter. when rotated left eight times, the 1 bit
  ; in $01 will find its way into the carry and end the loop
  stx presses_2
  stx presses_4
  stx sigbyte_2
  stx JOY1
  dex
  stx JOY1

loop:
  ; Read a bit from each port
  lda JOY1
  lsr a
  rol presses_1,x
  lda JOY2
  lsr a
  rol presses_2,x
  bcc loop  ; $01 rotated left eight times sets carry

  ; Move on to next byte
  inx
  inx
  cpx #6
  bcc loop
  rts
.endproc

