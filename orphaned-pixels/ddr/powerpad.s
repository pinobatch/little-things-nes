.include "nes.inc"
.importzp cur_keys, new_keys, b_button_action
.export read_pads

padreadbuf = $C0

D4=%00010000
D3=%00001000
D1=%00000010
D0=%00000001

; Use this to skip an SBC or CLC instruction.
; It assembles to an SKB (6502) or BIT #imm (65C02/6280/65816).
.macro skb89
  .byt $89
.endmacro

.segment "CODE"

;; Read the controllers once
; @param Y 0 (first read) or 8 (second read)
; @return X = 0; Y increased by 8
.proc powerpad_readonce
  lda #$01
  sta P1
  lsr a
  sta P1
  ldx #8
loop:
  ; Bit 0: NES plugin controller or Famicom hardwired controller
  ; Bit 1: Famicom plugin controller
  ; Bit 3: Power Pad buttons 2, 1, 5, 9, 6, 10, 11, 7
  ; Bit 4: Power Pad buttons 4, 3, 12, 8, signature 1111
  lda #(D0|D1|D3|D4)
  and P1
  sta padreadbuf,y
  lda #(D0|D1|D3|D4)
  and P2
  sta padreadbuf+16,y
  iny
  dex
  bne loop
  rts
.endproc

;;
; DPCM-safe comparison code
; @param Y 0 (player 1) or 16 (player 2)
; @return differ: X>0 and Z flag false; same: X=0 and Z flag true
.proc powerpad_compare
  ldx #8
loop:
  lda padreadbuf,y
  cmp padreadbuf+8,y
  bne done
  iny
  dex
  bne loop
done:
  rts
.endproc

; 1  2  3  4
; 5  6  7  8
; 9 10 11 12

;D4: 4, 3, 12, 8
;D3: 2, 1, 5, 9, 6, 10, 11, 7
;D1, D0: A, B, Select, Start, Up, Down, Left, Right

;that's equivalent to
;D4: Start, Up, ???, Right
;D3: Up, Select, Left, ???, Left, Down, Down, Right
;D1, D0: Right, UpDownOther, Select, Start, Up, Down, Left, Right

.pushseg
.segment "RODATA"
padmapping_d0:
  .byt KEY_RIGHT, KEY_B, KEY_SELECT, KEY_START
  .byt KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT
padmapping_d3:
  .byt KEY_UP, KEY_SELECT, KEY_LEFT, 0
  .byt KEY_LEFT, KEY_DOWN, KEY_DOWN, KEY_RIGHT
padmapping_d4:
  .byt KEY_START, KEY_UP, 0, KEY_RIGHT
  .byt 0, 0, 0, 0
.popseg

;;
; Decode PowerPad into Select, Start, Up, Down, Left, Right
; @param Y 0 or 8 (player 1); 16 or 24 (player 2)
.proc powerpad_decode
decode_result = 0
  ldx #0
  stx decode_result

loop:
  lda padreadbuf,y
  and #D0|D1
  beq no_d0d1
  lda padmapping_d0,x
  ora decode_result
  sta decode_result
no_d0d1:

  lda padreadbuf,y
  and #D3
  beq no_d3
  lda padmapping_d3,x
  ora decode_result
  sta decode_result
no_d3:

  lda padreadbuf,y
  and #D4
  beq no_d4
  lda padmapping_d4,x
  ora decode_result
  sta decode_result
no_d4:

  iny
  inx
  cpx #8
  bcc loop

  ; B button correction
  ldx #0
  cpy #16
  bcc not_p2
  inx
not_p2:

  ; If Up or Down is held, set B's action to the opposite
  lda decode_result
  and #KEY_UP|KEY_DOWN
  beq updown_not_held
  cmp #KEY_UP
  ; CC: Down is held. CS: Up is held.
  lda #KEY_UP
  bcc down_is_held
  lda #KEY_DOWN
down_is_held:
  sta b_button_action,x
updown_not_held:

  lda decode_result
  and #KEY_B
  beq b_not_held
  eor decode_result
  ora b_button_action
  sta decode_result
b_not_held:
  lda decode_result
  rts
.endproc

.proc read_pads
  ldy #0
  jsr powerpad_readonce
  jsr powerpad_readonce

  lda cur_keys+0
  sta 2
  lda cur_keys+1
  sta 3
  ldy #0
  jsr powerpad_compare
  bne differ0
  jsr powerpad_decode
  sta 2
differ0:
  ldy #16
  jsr powerpad_compare
  bne differ1
  jsr powerpad_decode
  sta 3
differ1:

  ldx #1
new_keys_loop:
  lda cur_keys,x
  eor #$FF
  and 2,x
  sta new_keys,x
  lda 2,x
  sta cur_keys,x
  dex
  bpl new_keys_loop
  rts
.endproc

