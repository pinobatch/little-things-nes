.include "popslide.inc"
.include "popslideinternal.inc"

.bss
.align 2
vector: .res 2
sp_save: .res 1
popslide_used: .res 1

.code
.align 256
popslide_nonrun_base:
  .repeat 16
    pla
    sta PPUDATA
  .endrepeat
  inx
  bne popslide_nonrun_base

popslide_nextpacket:
  pla
  bmi popslide_done
  sta PPUADDR
  pla
  sta PPUADDR

  ; Get direction
  ldx #VBLANK_NMI
  pla
  bpl :+
    ldx #VBLANK_NMI|VRAM_DOWN
    and #$7F
  :
  stx PPUCTRL

  ; Calculate length
  eor #$7F
  tax
  cmp #$40
  and #$0F
  bcc isrun
  asl a
  asl a
have_veclo:
  sta vector+0

  ; calculate -ceil(length / 16)
  txa
  lsr a
  lsr a
  lsr a
  lsr a
  ora #%11111100
  tax
  jmp (vector)

popslide_done:
  ldx sp_save
  txs
  ldx #POPSLIDE_SLACK
  stx popslide_used
  jmp popslide_return

isrun:
  sta vector+0
  asl a
  adc vector+0
  adc #<popslide_run_base
  sta vector+0
  txa
  lsr a
  lsr a
  lsr a
  lsr a
  ora #%11111100
  tax
  pla
  jmp (vector)
popslide_run_base:
  .repeat 16
    sta PPUDATA
  .endrepeat
popslide_run_max = * - 3
  inx
  bne popslide_run_base
  jmp popslide_nextpacket
  .assert (popslide_run_max - popslide_nonrun_base) < 256, error, "popslide_run_base crosses page boundary"


popslide_init:
  lda #>popslide_nonrun_base
  sta vector+1
popslide_clearbuf:
  ldx #POPSLIDE_SLACK
  stx popslide_used
  lda #$FF
  sta popslide_buf + POPSLIDE_SLACK
popslide_rts:
  rts

popslide_terminate_blit:
  ldx popslide_used
  cpx #POPSLIDE_SLACK + 1
  bcc popslide_rts
  lda #$FF
  sta popslide_buf,x
popslide_blit:
  tsx
  stx sp_save
  ldx #POPSLIDE_SLACK - 1
  txs
  jmp popslide_nextpacket
