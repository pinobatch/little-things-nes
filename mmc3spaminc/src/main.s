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

OAM := $0200
NUM_CTRLGROUP = 5
NUM_SELFMODS = 4
NUM_TESTS = 12
FRAMES_PER_TEST = 20
LONG_SPAM_ITERATIONS = 80

.zeropage
nmis:          .res 1
irqs:          .res 1
oam_used:      .res 1
cur_keys:      .res 2
new_keys:      .res 2

frames_left:   .res 1
tests_done:    .res 1
test_results:  .res NUM_TESTS

.code
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
  jsr setup_test_vram

  ; Control group: Ensure MMC3 banking and sprite 0 work as expected
  ; in the first place
  ldx #0
  stx tests_done
  ctrlloop:
    ctrl_dstlo := $00
    ctrl_dsthi := $01
    jsr setup_usual_chr_banks
    ; Make ONE write
    ldx tests_done
    lda ctrlgroup_addrhi,x
    sta ctrl_dsthi
    lda ctrlgroup_addrlo,x
    sta ctrl_dstlo
    lda ctrlgroup_data,x
    ldy #0
    sta (ctrl_dstlo),y
    ; And run this test
    jsr run_test
    inc tests_done
    lda tests_done
    cmp #NUM_CTRLGROUP
    bcc ctrlloop

  ; Spam in the place where we live
  testloop:
    jsr setup_usual_chr_banks
    lda tests_done
    sec
    sbc #NUM_CTRLGROUP
    cmp #NUM_SELFMODS
    bcc :+
      sbc #NUM_SELFMODS
    :
    tax
    jsr setup_selfmodarea
    jsr run_test
    inc tests_done
    lda tests_done
    cmp #NUM_TESTS
    bcc testloop

  ; Display
  lda #>results_txt
  ldy #<results_txt
  jsr cls_puts_multiline
  ldx #0
  resultloop:
    lda test_results,x
    beq no_draw
      txa
      pha

      ; Calculate line address
      clc
      adc #>(HIT_MSG_ADDR * 4)
      lsr a
      sta ctrl_dsthi
      lda #<(HIT_MSG_ADDR * 4)
      ror a
      lsr ctrl_dsthi
      ror a
      tax

      ; And draw the text to the screen
      ldy ctrl_dsthi
      lda #>hit_msg
      sta ctrl_dsthi
      lda #<hit_msg
      sta ctrl_dstlo
      tya
      jsr puts_16
      pla
      tax
    no_draw:
    inx
    cpx #NUM_TESTS
    bcc resultloop

  ; Switch in text bank
  ldx #0
  lda #4
  stx $8000
  sta $8001
  inx
  lda #6
  stx $8000
  sta $8001

  lda #$80
  jsr ppu_vsync
  ldx #0
  ldy #0
  lda #VBLANK_NMI|BG_0000|OBJ_8X16
  clc
  jsr ppu_screen_on
forever:
  jmp forever
.endproc

.proc setup_test_vram
  ; Put a sprite with tile $180 at top center (124, 16)
  ldx #0
  stx PPUMASK
  jsr ppu_clear_oam
  lda #15
  sta OAM+0
  lda #$81
  sta OAM+1
  lda #$20  ; Behind bit (for better visibility)
  sta OAM+2
  lda #124
  sta OAM+3

  ; Tests are run in nametable $2800, so that $A000 bit 7 selects
  ; which NT page is used.  Fill NT page 0 with transparent ($00)
  ; and page 1 with opaque ($80)
  txa
  tay
  ldx #$20
  jsr ppu_clear_nt
  lda #$80
  ldx #$2C
  jmp ppu_clear_nt
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

;;
; Runs the test with the modification to the usual CHR banks
; and the usual 
; @param tests_done index into test_results to save the result
.proc run_test
  ; Run one frame without sprites to both clear sprite 0 hit flag
  ; and let the sprite evaluation state machine stabilize
  jsr ppu_vsync
  ldx tests_done
  lda #0
  sta test_results,x
  tax
  tay
  lda #VBLANK_NMI|BG_0000|OBJ_8X16|2
  clc
  jsr ppu_screen_on

  lda #FRAMES_PER_TEST
  sta frames_left
  frameloop:
    jsr ppu_vsync
    ldx #0
    ldy #0
    lda #>OAM
    stx OAMADDR
    sta OAM_DMA
    lda #VBLANK_NMI|BG_0000|OBJ_8X16|2
    sec
    jsr ppu_screen_on

    ; Save this test result
    ldx tests_done
    lda PPUSTATUS
    and #$40
    ora test_results,x
    sta test_results,x

    ; 0-4 tests done: no spam
    ; 5-7 tests done: one iteration
    ; 8-10 tests done: a good fraction of a frame
    cpx #NUM_CTRLGROUP
    bcc no_spam
      ldy #1
      cpx #NUM_CTRLGROUP+NUM_SELFMODS
      bcc short_spam
        ldy #LONG_SPAM_ITERATIONS
      short_spam:
      jsr selfmodarea
    no_spam:

    dec frames_left
    bne frameloop
  rts
.endproc


.rodata
; Control group starts with setup_usual_chr_banks, does ONE write
; to ONE address, and sees whether sprite 0 hit.
; 1. CHR page 0-1 in window 0 (that is, no change): Expect no hit
; 2. CHR page 4-5 in window 0: Expect no hit
; 3. CHR page 2-3 in window 0: Expect hit
; 4. Horizontal mirroring: Expect hit
; 5. Window 2 at PPU $0000: Expect hit
;                       Pg0  Pg4  Pg3  Mir  Win2
ctrlgroup_addrhi: .byte $80, $80, $80, $A0, $80
ctrlgroup_addrlo: .byte $01, $01, $01, $00, $00
ctrlgroup_data:   .byte $00, $04, $03, $01, $80
.assert NUM_CTRLGROUP = * - ctrlgroup_data, error, "control group data is incomplete"

LF = $0A
results_txt:
  .byte "Baseline",LF
  .byte "  CHR page 4-5",LF
  .byte "  CHR page 2-3",LF
  .byte "  horizontal mirroring",LF
  .byte "  swap 0000/1000",LF
  .byte "short inc CHR page",LF
  .byte "short lsr mirroring",LF
  .byte "short asl swap 00/10",LF
  .byte "short dec CHR page",LF
  .byte "long inc CHR page",LF
  .byte "long lsr mirroring",LF
  .byte "long asl swap 00/10",$00

HIT_MSG_ADDR = $207B
hit_msg:
  .byte "Hit", $00
