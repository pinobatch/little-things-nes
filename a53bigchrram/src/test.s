.include "nes.inc"
.include "global.inc"

.zeropage
testresult_size: .res 1
testresult_bugged: .res 1

.code
.proc run_test
  ; Measure RAM size, working around FCEUX bug by writing both
  ; CHR and PRG bank values.  First write the bank number to the
  ; first byte of each 8K CHR RAM bank.
  ldy #$03
  ramsize_loop:
    jsr fceux_bug_set_bank_y_ppu_0000
    sty PPUDATA
    dey
    bpl ramsize_loop

  ; Then the value in the last bank is the number of 8K banks minus 1
  ldy #$03
  jsr fceux_bug_set_bank_y_ppu_0000
  bit PPUDATA  ; prime the VRAM reader
  ldy PPUDATA
  sty testresult_size
  
  ; Check explicitly for FCEUX bug by switching only to CHR bank 0
  ; and seeing if the value is nonzero
  lda #$00
  sta PPUADDR
  sta PPUADDR
  ; lda #A53_CHR
  sta A53_SELECT
  sta A53_DATA
  bit PPUDATA  ; prime the VRAM reader
  ldy PPUDATA
  sty testresult_bugged

  ldy #0
  ; and fall through to finish
.endproc

;;
; Sets the PPU address to $0000, CHR bank to Y, and PRG bank to 1.
.proc fceux_bug_set_bank_y_ppu_0000
  lda #$00
  sta PPUADDR
  sta PPUADDR
  ; lda #A53_CHR
  sta A53_SELECT
  sty A53_DATA

  ; FCEUX 2.2.2 through r3339 require writing to PRG, MODE, or
  ; OUTER_PRG in order for a write to CHR take effect.
  lda #A53_PRG
  sta A53_SELECT
  sta A53_DATA
  rts
.endproc