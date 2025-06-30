;
; MMC3 oversize test
; Copyright 2025 Damian Yerrick
; SPDX-License-Identifier: Zlib
;
.include "nes.inc"
.include "global.inc"
.export main, nmi_handler, irq_handler

OAM = $0200

.zeropage
chr_is_ram: .res 1
nmis: .res 1
cursor_x: .res 1
cur_keys: .res 2
new_keys: .res 2
das_keys: .res 2
das_timer: .res 2

bank_results_buffer: .res 12

NUM_CTRL_REGS = 9

; Allow editing the high digit of ctrl register but not the low digit
; because editing the low digit can cause not all registers to get
; overwritten, which confuses the user.
CURSOR_X_MAX = NUM_CTRL_REGS*2-2

COLOR_PAPER = $02
COLOR_INK = $38

.code
.proc nmi_handler
  inc nmis
.endproc
.proc irq_handler
  rti
.endproc

.proc main
  bit PPUSTATUS
  lda #$80
  sta PPUCTRL
  asl a
  sta PPUMASK
  ldx #$3F
  stx PPUADDR
  sta PPUADDR
  ldx #$10
  :
    lda #COLOR_PAPER
    sta PPUDATA
    lda #COLOR_INK
    sta PPUDATA
    dex
    bne :-

  ; clear nametable
  lda #$20
  sta PPUADDR
  stx PPUADDR
  lda #' '
  .assert ' ' = $24, error, "charmap not loaded"
  ldx #$F0
  :
    sta PPUDATA
    sta PPUDATA
    sta PPUDATA
    sta PPUDATA
    dex
    bne :-
  txa
  ldx #$40
  :
    sta PPUDATA
    dex
    bne :-

  ; clear OAM to draw cursor sprite
  ; ldx #0
  lda #$FF
  :
    sta OAM,x
    inx
    bne :-

  ; Print UI headings
  ; ldx #0
  headings_loop:
    lda headings,x
    bmi headings_done
    sta PPUADDR
    inx
    lda headings,x
    sta PPUADDR
    inx
    headings_byteloop:
      lda headings,x
      inx
      cmp #$FF
      bcs headings_loop
      sta PPUDATA
      bcc headings_byteloop
  headings_done:
  
  ; Load CHR RAM if needed
  lda #$A5
  jsr does_chr_write_take
  bne clear_chr_is_ram
  lda #$69
  jsr does_chr_write_take
  bne clear_chr_is_ram
    ; Copy font to CHR RAM
    lda #$00
    sta PPUADDR
    sta PPUADDR
    lda #<font8x5_baseaddr
    sta $00
    lda #>font8x5_baseaddr
    sta $01
    ldy #<-(font8x5_end - font8x5)
    ldx #>-(font8x5_end - font8x5)
    chr_copy_loop:
      lda ($00),y
      sta PPUDATA
      iny
      bne chr_copy_loop
      inc $01
      inx
      bne chr_copy_loop

    ; Write bank markers
    ldx #$00
    lda #2  ; at $1000
    sta $8000
    write_chr_mark_loop:
      ldy #$10
      sty PPUADDR
      ldy #$00
      sty PPUADDR
      dex
      stx $8001
      stx PPUDATA
      bne write_chr_mark_loop
    lda #>CHR_RAM_LETTER_NT_ADDR
    sta PPUADDR
    lda #<CHR_RAM_LETTER_NT_ADDR
    sta PPUADDR
    lda #'A'
    sta PPUDATA
    bne have_chr_is_ram
  clear_chr_is_ram:
    lda #0
  have_chr_is_ram:
  sta chr_is_ram

forever:
  lda nmis
  :
    cmp nmis
    beq :-

  ; F around with the bank registers
  ldx #7
  :
    txa
    ora mmc3_ctrl_value
    sta $8000
    lda mmc3_reg_values,x
    sta $8001
    dex
    bpl :-

  ; And find out what that produces: CHR first
  ldx #7
  :
    txa
    asl a
    asl a
    sta PPUADDR
    lda #0
    sta PPUADDR
    bit PPUDATA
    lda PPUDATA
    sta bank_results_buffer,x
    dex
    bpl :-

  ; then PRG
  lda bankfooterE0&$9FFF
  sta bank_results_buffer+8
  lda bankfooterE0&$BFFF
  sta bank_results_buffer+9
  lda bankfooterE0&$DFFF
  sta bank_results_buffer+10
  lda bankfooterE0&$FFFF
  sta bank_results_buffer+11
  
  ; Print what was found
  lda #>REG_VALUES_NT_ADDR
  sta PPUADDR
  lda #<REG_VALUES_NT_ADDR
  sta PPUADDR
  ldx #<mmc3_reg_values
  ldy #9
  jsr prhex
  lda #>CHR_BANKS_NT_ADDR
  sta PPUADDR
  lda #<CHR_BANKS_NT_ADDR
  sta PPUADDR
  ldx #<bank_results_buffer
  ldy #8
  jsr prhex
  lda #>PRG_BANKS_NT_ADDR
  sta PPUADDR
  lda #<PRG_BANKS_NT_ADDR
  sta PPUADDR
  ldy #4
  jsr prhex

  ; Finish by setting scroll position  
  ldy #$00
  sty PPUSCROLL
  sty PPUSCROLL
  sty OAMADDR
  lda #>OAM
  sta OAM_DMA
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  sta PPUCTRL
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  
  ; and setting CHR for display
  ldx #2
  stx $8000
  sty $8001  ; OBJ bank 0
  sty $8000
  sty $8001  ; BG bank 0

  ; Vblank tasks finished! Move the cursor
  lda #$C0
  sta $4017  ; clock the APU frame counter manually
  jsr read_pad_1
  lda new_keys
  lsr a
  bcc not_right
    lda cursor_x
    cmp #CURSOR_X_MAX
    bcs right_wrap_if_not_das
    inc cursor_x
    bcc play_shift_sound
  right_wrap_if_not_das:
    lda das_timer
    cmp #DAS_DELAY
    bcc keys_done
    lda #0
    sta cursor_x
    bcs play_shift_sound
  not_right:

  lsr a
  bcc not_left
    lda cursor_x
    beq left_wrap_if_not_das
    dec cursor_x
  play_shift_sound:
    lda #$40
    sta $4000
    asl a
    sta $4001
    lda #126
    sta $4002
    lda #$28
    sta $4003
    jmp keys_done
  left_wrap_if_not_das:
    lda das_timer
    cmp #DAS_DELAY
    bcc keys_done
    lda #CURSOR_X_MAX
    sta cursor_x
    bcs play_shift_sound
  not_left:

  lsr a
  bcc not_down
    lda cursor_x
    lsr a
    tax
    lda #$F0
    bcc have_add_amount
    lda #$FF
    bcs have_add_amount
  not_down:
  lsr a
  bcc not_up
    lda cursor_x
    lsr a
    tax
    lda #$10
    bcc have_add_amount
    lda #$01
  have_add_amount:
    clc
    adc mmc3_reg_values,x
    sta mmc3_reg_values,x
    lda #$00
    sta $400C
    lda #$03
    sta $400E
    lda #$28
    sta $400F
  not_up:
  keys_done:


  ; Draw cursor
  lda #CURSOR_Y
  sta OAM+0
  lda #CURSOR_TILE
  sta OAM+1
  lda #0
  sta OAM+2
  lda cursor_x
  lsr a  ; A = number of spaces to skip
  clc
  adc cursor_x
  asl a
  asl a
  asl a
  adc #CURSOR_LEFT
  sta OAM+3
  jmp forever
.endproc

.proc does_chr_write_take
  bit PPUSTATUS
  ldx #$00
  stx PPUADDR
  stx PPUADDR
  sta PPUDATA
  stx PPUADDR
  stx PPUADDR
  bit PPUDATA
  eor PPUDATA
  rts
.endproc

;;
; Prints Y bytes starting at ZP address X, 41 cyc each
.proc prhex
  lda $00,x
  lsr a
  lsr a
  lsr a
  lsr a
  sta PPUDATA
  lda $00,x
  and #$0F
  sta PPUDATA
  bit PPUDATA
  inx
  dey
  bne prhex
  rts
.endproc

.segment "RODATA"
CHR_RAM_LETTER_NT_ADDR = CHR_BANKS_NT_ADDR-64+5
REG_VALUES_NT_ADDR = $21A2
CHR_BANKS_NT_ADDR = $2222
PRG_BANKS_NT_ADDR = $22A2

CURSOR_Y = ((REG_VALUES_NT_ADDR >> 2) & %11111000) + 7
CURSOR_LEFT = (REG_VALUES_NT_ADDR << 3) & %11111000
CURSOR_TILE = '^'

headings:
  .dbyt $2102
  .byte "MMC3 OVERSIZE TEST 0.02", $FF
  .dbyt $2122
  .byte $25," 2025 DAMIAN YERRICK",$FF
  .dbyt REG_VALUES_NT_ADDR-64
  .byte "CONTROL REGISTER VALUES", $FF
  .dbyt REG_VALUES_NT_ADDR-32
  .byte "C0 C2 C4 C5 C6 C7 P8 PA CR", $FF
  .dbyt CHR_BANKS_NT_ADDR-64
  .byte "CHR ROM BANKS",$FF
  .dbyt CHR_BANKS_NT_ADDR-32
  .byte "00 04 08 0C 10 14 18 1C",$FF
  .dbyt PRG_BANKS_NT_ADDR-64
  .byte "PRG ROM BANKS",$FF
  .dbyt PRG_BANKS_NT_ADDR-32
  .byte "80 A0 C0 E0",$FF
  .byte $FF

.segment "CHRC0"
.incbin "obj/nes/font8x5.chr"
.segment "CHRE0"
font8x5:
.incbin "obj/nes/font8x5.chr"
font8x5_end:
font8x5_size_rounded_up = (font8x5_end - font8x5 + $FF) & $FF00
font8x5_baseaddr = font8x5_end - font8x5_size_rounded_up

; Bank numbers are at $FFDF for PRG or $1000 for CHR
.segment "FOOTERC0"
bankfooterC0: .byte $00
.segment "FOOTERE0"
bankfooterE0: .byte $01
.res 26, $00  ; FamicomBox area
