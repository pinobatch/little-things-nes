;
; Popslide
; The fastest possible general-purpose VRAM update routine for NES
; Copyright 2016 Damian Yerrick
;

.include "popslide.inc"
.include "popslideinternal.inc"

.bss
.align 2
nonrun_vector: .res 2
run_vector: .res 2
sp_save: .res 1
popslide_used: .res 1

; The display list consists of packets.
; Literal packet: 3 + n bytes, ~26 cycle penalty
;   VRAM address high, VRAM address low, length, 1-64 bytes
; Run packet: 4 bytes, ~34 + 4n cycle penalty
;   VRAM address high, VRAM address low, length, value
; Length byte:
; 7654 3210
; ||++-++++- Number of bytes to write
; |+-------- 0: literal; 1: run
; +--------- 0: add 1 to VRAM address; 1: add 32 (3-cycle penalty)
; A VRAM address at least $8000 ends the buffer.
;
; You will need about 560 bytes of ROM because both loops are
; unrolled by a factor of 64.

.code
.align 256
popslide_nonrun_base:
  .repeat 64
    pla
    sta PPUDATA
  .endrepeat
popslide_nextpacket:
  ; Get destination address: 18, or 23 if leaving
  pla
  bmi popslide_done
  sta PPUADDR
  pla
  sta PPUADDR

  ; Get direction: 13 for right, 16 for down
  ldx #VBLANK_NMI
  pla
  bpl :+
    ldx #VBLANK_NMI|VRAM_DOWN
    and #$7F
  :
  stx PPUCTRL

  ; Calculate length: 19 for non-run, 35 for run
  eor #$7F
  cmp #$40
  bcc isrun
  asl a
  asl a
  sta nonrun_vector
  jmp (nonrun_vector)
popslide_done:
  ldx sp_save
  txs
  ldx #POPSLIDE_SLACK
  stx popslide_used
  jmp popslide_return
isrun:
  sta run_vector
  asl a
  adc run_vector
  adc #<popslide_run_base
  sta run_vector
  pla
  jmp (run_vector)
popslide_run_base:
  .repeat 64
    sta PPUDATA
  .endrepeat
popslide_run_max = * - 3
  .assert (popslide_run_max - popslide_nextpacket) < 256, error, "popslide_run_base crosses page boundary"
  jmp popslide_nextpacket

popslide_init:
  lda #>popslide_run_base
  sta run_vector+1
  lda #>popslide_nonrun_base
  sta nonrun_vector+1
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

.if 0
  .out "nonrunbase: $000"
  .out .sprintf("nextpacket: $%03x", popslide_nextpacket - popslide_nonrun_base)
  .out .sprintf("done: $%03x", popslide_done - popslide_nonrun_base)
  .out .sprintf("isrun: $%03x", isrun - popslide_nonrun_base)
  .out .sprintf("run_base: $%03x", popslide_run_base - popslide_nonrun_base)
  .out .sprintf("run_max: $%03x", popslide_run_max - popslide_nonrun_base)
  .out .sprintf("popslide total size: %d bytes", * - popslide_nonrun_base)
.endif
