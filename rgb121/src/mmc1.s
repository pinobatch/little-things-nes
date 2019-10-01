
.include "mmc1.inc"
.import nmi, reset, irq, bankcall_table

.segment "ZEROPAGE"
lastPRGBank: .res 1
lastBankMode: .res 1
bankcallsaveA: .res 1

; Each bank has 16384 bytes: 16368 for you to use as you wish and
; 16 for a piece of code that puts the mapper in a predictable state.
; This code needs to be repeated in all the banks because we don't
; necessarily know which bank is switched in at power-on or reset.
;
; Writing a value with bit 7 true (that is, $80-$FF) to any MMC1
; port causes the PRG bank mode to be set to fixed $C000 and
; switchable $8000, which causes 'reset' to show up in $C000-$FFFF.
; And on most discrete logic mappers (AOROM 7, BNROM 34, GNROM 66),
; and Crazy Climber UNROM (180), writing a value with bits 5-0 true
; (that is, $3F, $7F, $BF, $FF) switches in the last PRG bank, but
; it has to be written to a ROM address that has the same value.
.macro resetstub_in segname
.segment segname
.scope
resetstub_entry:
  sei
  ldx #$FF
  txs
  stx $FFF2  ; Writing $80-$FF anywhere in $8000-$FFFF resets MMC1
  jmp reset
  .addr nmi, resetstub_entry, irq
.endscope
.endmacro

.segment "CODE"
.import nmi, reset, irq
resetstub_in "STUB00"
resetstub_in "STUB01"
resetstub_in "STUB02"
resetstub_in "STUB03"
resetstub_in "STUB04"
resetstub_in "STUB05"
resetstub_in "STUB06"
resetstub_in "STUB07"
resetstub_in "STUB08"
resetstub_in "STUB09"
resetstub_in "STUB10"
resetstub_in "STUB11"
resetstub_in "STUB12"
resetstub_in "STUB13"
resetstub_in "STUB14"
resetstub_in "STUB15"

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 16         ; size of PRG ROM in 16384 byte units
  .byt 0          ; size of CHR ROM in 8192 byte units
  .byt $12        ; lower mapper nibble, enable SRAM
  .byt $00        ; upper mapper nibble
  
.segment "CODE"
; To write to one of the four registers on MMC1, write bits 0 through
; 3 to D0 of any mapper port address ($8000-$FFFF), then write bit 4
; to D0 at the correct address (e.g. $E000-$FFFF).
; The typical sequence is sta lsr sta lsr sta lsr sta lsr sta.
.proc setPRGBank
  sta lastPRGBank
  .repeat 4
    sta $E000
    lsr a
  .endrepeat
  sta $E000
  rts
.endproc

.proc setMMC1BankMode
  sta lastBankMode
  .repeat 4
    sta $8000
    lsr a
  .endrepeat
  sta $8000
  rts
.endproc

; Inter-bank method calling system.  There is a table of up to 85
; different methods that can be called from a different PRG bank.
; Typical usage:
;   ldx #move_character
;   jsr bankcall
.proc bankcall
  sta bankcallsaveA
  lda lastPRGBank
  pha
  lda bankcall_table+2,x
  jsr setPRGBank
  lda bankcall_table+1,x
  pha
  lda bankcall_table,x
  pha
  lda bankcallsaveA
  rts
.endproc

; Functions in the bankcall_table MUST NOT exit with 'rts'.
; Instead, they MUST exit with 'jmp bankrts'.
.proc bankrts
  sta bankcallsaveA
  pla
  jsr setPRGBank
  lda bankcallsaveA
  rts
.endproc


