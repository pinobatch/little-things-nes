;
; 2-bit-per-sample wave player
; Copyright 2025 Damian Yerrick
; License: zlib
;
.exportzp src_lo, src_hi, pages_left, volume_table_base
.export play2b_setup_channels, play2b_play_wave
.exportzp VOLTAB_ALL, VOLTAB_UNSWAPPED, VOLTAB_SWAPPED, VOLTAB_PWM

.zeropage
bytebits: .res 1
src_lo: .res 1
src_hi: .res 1
pages_left: .res 1
volume_table_base: .res 1

.code
;;
; Sets pulse 1 and pulse 2 to play 12429 Hz tones, 8 cycles offset
; between the two.
.proc play2b_setup_channels
  lda #$0F
  sta $4015
  lda #$B0
  sta $4000  ; Set channel level
  sta $4004
  lda #$08
  sta $4001  ; Turn off sweep
  sta $4005
  ldy #$00
  sty $4002  ; Set pulse channels to maximum frequency.  The APU
  sty $4006  ; mutes this; the important part is that the divider is
  sty $4003  ; predictable after they wrap.
  sty $4007
  wrapwait:
    jsr knownrts1
    iny
    bne wrapwait
  sta $4002  ; Set pulse channels to maximum frequency that
  sty $4003  ; isn't muted: 12429 Hz or one cycle per 144 CPU cycles.
  sta $4006  ; Space their initialization writes 8 cycles apart to
  sty $4007  ; match the loop structure.
knownrts1:
  rts
.endproc

;;
; Plays a wave with 2 bits per sample through the pulse waves at
; 144 cycles per sample (12429 Hz).
; @param src_hi pointer to sample data, high byte
; @param pages_left length of wave in 256-byte (1024-sample) pages
; @param volume_table_base offset into volume_table for this play
.proc play2b_play_wave
  ldy #0
  sty src_lo
  sec
  bcs isnewbyte
sampleloop:
  ; about 1/4 of the time is spent fetching a new byte in constant time
  asl bytebits
  beq isnewbyte
    .repeat 6
      nop
    .endrepeat
    jmp play_crumb_in_13
  isnewbyte:  ; 14 to play_crumb_in_13
    lda (src_lo),y
    rol a
    sta bytebits
    iny
    beq isnewpage
  play_crumb_in_13:
    .repeat 5
      nop
    .endrepeat
    jmp play_crumb
  isnewpage:
    inc src_hi
    dec pages_left
    beq playback_done
  play_crumb:
  .assert >* = >sampleloop, error, "branch across page boundary!"
  ; 35 cycles so far
  lda #0
  rol a
  asl bytebits
  rol a
  ora volume_table_base
  tax
  lda volume_table+0,x
  sta $4000
  lda volume_table+4,x
  sta $4004
  ; that makes 32 more cycles, totaling 67
  ; we want 144, so 77 more
  ldx #70/5
  :
    dex
    bne :-
  ldx volume_table_base
  jmp sampleloop
playback_done:
  rts
.endproc

; The original NES APU is unswapped.  This means the high nibble
; 3, 7, B, F of a pulse channel's duty/volume register corresponds to
; 1/8, 2/8, 4/8, and 6/8 duty cycle respectively.
; Many clone APUs are swapped.  This means the high nibble
; 3, 7, B, F of a pulse channel's duty/volume register corresponds to
; 1/8, 4/8, 2/8, and 6/8 duty cycle respectively.
; In either case, the low nibble controls the volume level.
;
; This difference can be used to make something audible only on
; unswapped or swapped devices by having pulse amplitude modulation
; (PAM) with the volume level cancel out pulse width modulation
; (PWM) with the duty cycle.
; 
; Each row in volume_table has 8 bytes.  Bytes 0-3 control the
; value written to pulse 1 duty and volume ($4000) for a sample with
; level 0-3.  Bytes 4-7 control the same for pulse 2 ($4004).
.rodata
.align 8
volume_table:
volume_audible_on_all:        .byte $FF,$FA,$F5,$F0, $F0,$F0,$F0,$F0
volume_swapped_only:          .byte $7C,$7C,$B6,$B6, $76,$B3,$76,$B3
volume_unswapped_only:        .byte $BC,$BC,$76,$76, $B6,$73,$B6,$73
volume_pwm:                   .byte $FF,$BF,$7F,$3F, $F0,$F0,$F0,$F0
VOLTAB_ALL = <(volume_audible_on_all - volume_table)
VOLTAB_UNSWAPPED = <(volume_unswapped_only - volume_table)
VOLTAB_SWAPPED = <(volume_swapped_only - volume_table)
VOLTAB_PWM = <(volume_pwm - volume_table)
