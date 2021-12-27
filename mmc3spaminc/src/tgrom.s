.include "nes.inc"
.import nmi_handler, reset_handler, irq_handler, ppu_clear_nt, main
.export copychr_then_main

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 2          ; PRG ROM size in 16384 byte units
  .byt 0          ; CHR ROM size in 8192 byte units
  .byt $40        ; mirroring type and mapper number lower nibble
  .byt $00        ; mapper number upper nibble

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.code
.proc copychr_then_main
srclo = $00
srchi = $01
  lda #<chrdata
  sta srclo
  lda #>chrdata
  sta srchi

  ; fill pages 0-3
  lda #$00
  ldx #$10
  jsr copy_x_pages_to_a

  ; fill page 4
  ldx #$10
  lda #0
  tay
  jsr ppu_clear_nt

  lda #$14
  ldx #$0C
  jsr copy_x_pages_to_a
  jmp main

copy_x_pages_to_a:
  ldy #0
  sty PPUCTRL
  sta PPUADDR
  sty PPUADDR
  :
    lda (srclo),y
    sta PPUDATA
    iny
    bne :-
    inc srchi
    dex
    bne :-
  rts
.endproc

; Include the CHR ROM data
.segment "RODATA"
chrdata:
  .incbin "obj/nes/title16.chr"
  ; empty page 4 before results on 5-7
  ; first tile of page 4 must be transparent
  .incbin "obj/nes/resultfont16.chr"
