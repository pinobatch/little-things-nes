.include "nes.inc"
.export main, irq, nmi

vblanked = $10


.segment "INESHDR"
  .byt "NES", 26, 1, 1, 0, 0
  .byt 0, 0, 0, 0, 0, 0, 0, 0


MUS_BASE = $300
freqlo = MUS_BASE + 0
freqhi = MUS_BASE + 1
freqhi_last = MUS_BASE + 2
vol = MUS_BASE + 3
inst_lo = MUS_BASE + 16
inst_hi = MUS_BASE + 17
inst_cd = MUS_BASE + 18
inst_num = MUS_BASE + 19
base_note = MUS_BASE + 32
pattern_rows_cd = MUS_BASE + 33
pattern_data = MUS_BASE + 34

tempo_count = MUS_BASE + 48
tempo_count_hi = tempo_count+1
tempo = MUS_BASE + 50
tempo_hi = tempo + 1

.segment "CODE"
nmi:
  pha

  lda #$80
  sta vblanked
  lda #0
  sta OAMADDR
  lda #>OAM
  sta OAM_DMA
  pla

irq:
  rti


;; wait4vbl
;; Waits for 'y' vblanks by NMI method.
;;
wait4vbl:
  tya
  pha
  jsr upd_chn
  pla
  tay
:
  bit vblanked
  bpl :-
  lsr vblanked
  dey
  bne wait4vbl
  rts

main:
  jsr init_sound
  lda #$80
  sta PPUCTRL
  ldy #1
  jsr wait4vbl
  lda #$3F
  sta PPUADDR
  sty PPUADDR
  jsr puts
  .byt $02,$12,$22,$32,$00
  lda #$29
  sta PPUADDR
  lda #0
  sta PPUADDR
  jsr puts
  .byt "     DOES THIS MAKE A SOUND     "
  .byt "     ON THE REAL HARDWARE?",0
  lda #$3F
  sta PPUADDR
  lda #0
  sta PPUADDR
  sta PPUSCROLL
  sta PPUSCROLL
  lda #$82
  sta PPUCTRL
  lda #$0A
  sta PPUMASK

  ldy #1
  jsr wait4vbl

  lda #<(90*4)
  sta tempo
  lda #>(90*4)
  sta tempo+1

  lda #2
  sta inst_num+0
  lda #<test_pattern0
  sta pattern_data+0
  lda #>test_pattern0
  sta pattern_data+1
  lda #2
  sta inst_num+4
  lda #<test_pattern4
  sta pattern_data+4
  lda #>test_pattern4
  sta pattern_data+5
  lda #6
  sta inst_num+8
  lda #<test_pattern8
  sta pattern_data+8
  lda #>test_pattern8
  sta pattern_data+9
  lda #0
  sta inst_num+12
  lda #<test_pattern12
  sta pattern_data+12
  lda #>test_pattern12
  sta pattern_data+13
  jsr tempo_demo

:
  ldy #255
  jsr wait4vbl

  jmp :-





tempo_demo:
  ldy #1
  jsr wait4vbl
  clc
  lda tempo_count
  adc tempo
  sta tempo_count
  lda tempo_count_hi
  adc tempo_hi
  sta tempo_count_hi
  cmp #$0f
  bcc :+
  sec
  sbc #>3600
  sta tempo_count_hi
  lda tempo_count
  sbc #<3600
  sta tempo_count

  ldx #12
  jsr interpret_pattern
  ldx #8
  jsr interpret_pattern
  ldx #4
  jsr interpret_pattern
  ldx #0
  jsr interpret_pattern

;  lda #3
;  jsr trigger_inst

:
  jmp tempo_demo

interpret_pattern:
  lda pattern_rows_cd,x
  beq :+
  dec pattern_rows_cd,x
  rts
:
  lda pattern_data+1,x
  bne :+
  rts
:
  sta 1
  lda pattern_data,x
  sta 0
@pattern_loop:
  ldy #0
  lda (0),y
  sta 2
  inc 0
  bne :+
  inc 1
:
  cmp #$48
  bcs @not_note
  lda inst_num,x
  bne @not_inst0
  jsr set_note
  lda 2
  jsr trigger_inst
  jmp @pattern_exit
@not_inst0:
  jsr trigger_inst
  ldy 2
  jsr set_note
@pattern_exit:
  lda 0
  sta pattern_data,x
  lda 1
  sta pattern_data+1,x
  rts

@not_note:
  cmp #$60
  bcs @not_ctrl
;; handle control commands
  cmp #$4F
  bcc :+
  lda #0
  sta pattern_data+1,x
  rts

@not_ctrl:
  cmp #$80
  bcs @not_rowwait
;; Handle hold and rest commands
  sta 2
  and #$10
  beq :+
  lda #0  ; cut note
  sta vol,x
  sta inst_hi,x
:
  lda 2
  and #$0f
  sta pattern_rows_cd,x
  jmp @pattern_exit
@not_rowwait:
  jmp @pattern_exit





test_pattern0:
  .byt $0e,$60,$71,$0e,$60,$71,$78,$7F,$7F,$7F, $4F
test_pattern4:
  .byt $13,$60,$71,$13,$60,$73,$13,$70,$13,$70,$13,$70
  .byt $16,$62,$13,$60,$11,$70,$16,$62,$13,$60,$11,$60
  .byt $16,$60,$13,$60,$16,$60,$18,$60,$19,$1a,$13,$60,$11,$60,$16,$60
  .byt $71,$13,$64,$78,$4F
test_pattern8:
  .byt $13,$60,$71,$13,$60,$70,$1a,$60,$0e,$1d,$60,$1d,$60,$1a,$60
  .byt $13,$60,$71,$13,$60,$70,$1a,$60,$0e,$1d,$60,$1d,$1a,$18,$16
  .byt $13,$60,$71,$13,$60,$70,$1a,$60,$0e,$1d,$60,$1d,$60,$1a,$60
  .byt $13,$60,$71,$13,$60,$70,$1a,$60,$0e,$1d,$60,$1d,$1a,$18,$16, $4F
test_pattern12:
  .byt $03,$60,$01,$60,$04,$60,$01,$60,$03,$60,$03,$60,$04,$60,$01,$60
  .byt $03,$60,$01,$60,$04,$60,$01,$04,$03,$60,$03,$60,$04,$60,$05,$60
  .byt $03,$60,$01,$60,$04,$60,$01,$60,$03,$60,$03,$60,$04,$60,$01,$60
  .byt $03,$60,$01,$60,$04,$60,$01,$04,$03,$60,$03,$60,$04,$60,$04,$04,$4F






puts:
  pla
  sta 0
  pla
  sta 1
  ldy #1
@loop1:
: lda (0),y
  beq @nomore
  sta PPUDATA
  iny
  bne @loop1
@nomore:
  tya
  sec
  adc 0
  sta 0
  lda #0
  adc 1
  sta 1
: jmp (0)



;;; init_sound
;   Initializes the sound chip and CPU memory used therefor.
init_sound:
;; to fully disable the sweep circuitry so that it doesn't interfere
;; with square wave periods above $3FF
  lda #0
  sta DMC_RAW
  lda #$08
  sta SQ1_SWEEP
  sta SQ2_SWEEP
;; to turn on the sound channels
  lda #$0F
  sta SND_CHN
;; to force a full frequency reload the first time
  lda #$FF
  sta freqhi_last+0
  sta freqhi_last+4
  sta freqhi_last+12
  rts



;;; set_note
;   
;   y (in): note number (0-72)
;   X (in): channel number (0, 4, 8, 12)
set_note:
  cpy #128
  bcc :+
  ldy #0
:
  cpy #72
  bcc :+
  ldy #71
:
  tya
  sta base_note,x
  cpx #12
  bcc @set_note_tone
  lda @set_note_noise_freqs,y
  sta freqlo,x
@skip:
  rts
@set_note_noise_freqs:
  ; The highest 4 noise freqs ($00-$03) sound like quieter versions of
  ; $04 because speaker just filters them, so use only the lowest 12:
  .byt $0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04
  ; But all 16 loopnoise freqs are useful:
  .byt $8f,$8e,$8d,$8c,$0b,$8a,$89,$88,$87,$86,$85,$84
  .byt $83,$82,$81,$80
@set_note_tone:
  .import tone_freqs_lo, tone_freqs_hi
  lda tone_freqs_lo,y
  sta freqlo,x
  lda tone_freqs_hi,y
  sta freqhi,x
  rts

upd_chn:
  ldx #0
  jsr @upd_one_chn
  ldx #4
  jsr @upd_one_chn
  ldx #8
  jsr @upd_one_chn
  ldx #12
@upd_one_chn:

;; Handle instrument first.
  lda inst_cd,x  ; unless in a run
  beq :+
  dec inst_cd,x
  jmp @no_env
:
  lda inst_hi,x
  beq @no_env
  sta 1
  lda inst_lo,x
  sta 0

;; Interpret instrument bytecode.
@upd_inst:
  ldy #0
  lda (0),y
  inc 0
  bne :+
  inc 1
:
  sta 2
  and #$30
  beq @vol_and_exit
  lda 2
  cmp #$40
  bcc @set_wait_and_exit
  cmp #$80
  bcc @add_note
  cmp #$c0
  bcc @subtract_note

  cmp #$ff
  beq @goto

  jmp @inst_exit

@set_wait_and_exit:
  adc #$f1
  sta inst_cd,x
  jmp @inst_exit

@add_note:
  sec
  sbc #$50
  adc base_note,x
  tay
  jsr set_note
  jmp @upd_inst

@subtract_note:
  sec
  sbc #$8F
  eor #$ff
  adc base_note,x
  tay
  jsr set_note
  jmp @upd_inst

@goto:
  lda (0),y
  inc 0
  bne :+
  inc 1
:
  sec
  eor #$ff
  adc 0
  sta 0
  lda 1
  adc #$ff
  sta 1
  jmp @upd_inst

@vol_and_exit:
  lda 2
  sta vol,x
@inst_exit:
  lda 0
  sta inst_lo,x
  lda 1
  sta inst_hi,x

@no_env:
;; Now that we have the instrument handled, update volume
  lda #$30
  ora vol,x
  cpx #8
  bne @upd_vol_not_triangle
;; Triangle vol 4-15: on; 0-3: off
  and #$0c
  beq @upd_vol_not_triangle
  lda #$FF
  sta freqhi_last+8
  lda #$c8
@upd_vol_not_triangle:
  sta SQ1_VOL,x

;; 2nd, update period
  lda freqlo,x
  sta SQ1_LO,x
  lda freqhi,x
  cmp freqhi_last,x
  beq :+
  sta SQ1_HI,x
  sta freqhi_last,x
:
  rts


;;; trigger_inst
;   Start instrument a on channel x.
trigger_inst:
;  sta inst_num,x
  asl a
  tay
  lda inst_ptrs,y
  sta inst_lo,x
  lda inst_ptrs+1,y
  sta inst_lo+1,x
  lda #0
  sta inst_cd,x
  rts


inst_ptrs:
  .addr silence_note
  .addr hat_note
  .addr long_note
  .addr kick_note
  .addr snare_note
  .addr ohat_note
  .addr tri_note

silence_note:
  .byt $00,$3f,$ff,$04
hat_note:
  .byt $5a,$05,$00,$ff,$03
long_note:
  .byt $49,$10,$48,$10,$47,$10,$46,$11,$45,$12,$44,$14,$43,$18,$42,$ff,$03
kick_note:
  .byt $5a,$06,$99,$0a,$09,$08,$07,$06,$90,$05,$04,$03,$02,$01,$00,$ff,$03
snare_note:
  .byt $5a,$06,$93,$09,$08,$07,$10,$06,$10,$05,$10,$04,$03,$02,$01,$00,$ff,$03
ohat_note:
  .byt $5a,$07,$06,$05,$10,$04,$11,$03,$11,$02,$11,$01,$12,$00,$ff,$03
tri_note:
  .byt $08,$9b,$08,$ff,$03

.segment "CHR"
.incbin "tilesets/t.chr"
