.include "popslide.inc"
.include "popslideinternal.inc"

.bss
popslide_used: .res 1
sp_save: .res 1

.code

popslide_init:
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
next_packet:
  pla
  bmi done
next_packet_yes:
  ; Seek in VRAM
  sta PPUADDR
  pla
  sta PPUADDR

  ; Bit 7: VRAM address increment horizontal (+1) or vertical (+32)
  ldx #VBLANK_NMI
  pla
  bpl :+
    and #$7F
    ldx #VBLANK_NMI|VRAM_DOWN
  :
  stx PPUCTRL

  ; Bit 6: Literal or run
  cmp #$40  ; save run bit for later
  and #$3F  ; save run length
  tax
  bcs is_run

  nonrunloop:  ; 15 bytes/cycle
    pla
    sta PPUDATA
    dex
    bpl nonrunloop
  .assert >* = >runloop, ldwarning, "literal decoder crosses page boundary - slow"
  bcc next_packet

is_run:
  pla
  runloop:  ; 9 bytes/cycle
    sta PPUDATA
    dex
    bpl runloop
  .assert >* = >runloop, ldwarning, "run decoder crosses page boundary - slow"
  pla
  bpl next_packet_yes

done:
  ldx sp_save
  txs
  ldx #POPSLIDE_SLACK
  stx popslide_used
  jmp popslide_return

.if 0
  .out .sprintf("popslide total size: %d bytes", * - popslide_init)
.endif

