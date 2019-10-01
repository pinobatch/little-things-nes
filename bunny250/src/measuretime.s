.export wait_256_or_light
.importzp tvSystem

P2 = $4017
ZAPPER_LIGHT = $08

.segment "CODE"
.align 32
.proc wait_256_or_light
time_to_wait = 0
  ldx tvSystem
  lda time_to_wait_by_system,x
  sta time_to_wait
  ldx #0
  lda #ZAPPER_LIGHT
wait_another_ms:
  ldy time_to_wait
wait9:
  and P2
  dey
  bne wait9  ; 9*y-1
  and #ZAPPER_LIGHT
  beq hit
  inx
  bne wait_another_ms
  sec
  rts
hit:
  clc
  rts
.endproc

.segment "RODATA"
; Waiting time in units of 9000 Hz, minus one for loop overhead
; NTSC: 315/.176/9
; PAL 26601.7125/9 divided by 15 or 16
time_to_wait_by_system:
  .byt 199-1  ; Famicom, Vs., PlayChoice, NTSC NES
  .byt 185-1  ; PAL NES
  .byt 197-1  ; Dendy and other PAL famiclones
