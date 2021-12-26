;
; Spam Inc
; Copyright 2021 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.include "nes.inc"
.include "global.inc"

OAM = $0200

.segment "ZEROPAGE"
nmis:          .res 1
irqs:          .res 1
oam_used:      .res 1
cur_keys:      .res 2
new_keys:      .res 2

.segment "CODE"
;;
; This NMI handler is good enough for a simple "has NMI occurred?"
; vblank-detect loop.
.proc nmi_handler
  inc nmis
  rti
.endproc

; MMC3 IRQ
.proc irq_handler
  inc irqs
  rti
.endproc

.proc main

  jsr show_title_screen

  ; Tests are run in nametable $2800, so that $A000 bit 7 selects
  ; which NT page is used.  Fill NT page 0 with transparent ($00)
  ; and page 1 with opaque ($80).
  lda #0
  sta PPUMASK
  tay
  ldx #$20
  jsr ppu_clear_nt
  lda #$80
  ldx #$2C
  jsr ppu_clear_nt

  ldx #0  ; 0: inc bank; 1: asl CHR swap; 2: lsr mirroring
  jsr setup_selfmodarea
  jsr setup_usual_chr_banks

  ; TODO: Control group

  ; TODO: Short spam

  ; TODO: Long spam

  ; TODO: Display results

forever:
  jmp forever
.endproc

;;
; Set up the CHR bank arrangement used by most tests.
; CHR page 0's first tile is transparent; CHR page 2's is opaque.
; Most tests use page 0 at PPU $0000 and page 2 at $0800, $1000,
; $1400, $1800, and $1C00, with page 0 selected for $8001 writes,
; and vertical nametable mirroring.
.proc setup_usual_chr_banks
  lda #2
  ldx #5
  :
    stx $8000  ; Select a window
    sta $8001  ; Set that window to CHR page 2
    dex
    bne :-
  stx $8000    ; Select window 0 (PPU $0000-$07FF)
  stx $8001
  stx $A000    ; Set vertical mirroring
  rts
.endproc

; Include the CHR ROM data
.segment "CHR"
  .incbin "obj/nes/title16.chr"
  ; empty page 4 before results on 5-7
  ; first tile of page 4 must be transparent
  .res 1024, $00
  .incbin "obj/nes/resultfont16.chr"
