.include "nes.inc"
.include "global.inc"

TERM_BUFLEN = 64
SCREEN_H = 30

.segment "ZEROPAGE"
cursor_y: .res 1
tvSystem: .res 1

; Used by NMI handler
last_PPUCTRL: .res 1  ; bit 7 clear: skip most of NMI handler
update_y: .res 1
scroll_y: .res 1
term_busy: .res 1

; Calculated by NMI handler, used by IRQ handler
throbber_phase: .res 1
scroll_bits: .res 1
irq_step: .res 1
step2delay: .res 1
step3delay: .res 1
step4delay: .res 1
stable_scroll_y: .res 1

.segment "BSS"
term_buf: .res TERM_BUFLEN
term_length: .res 1  ; Number of characters in term_buf
term_linewidth: .res 1  ; Number of pixels in the first term_length characters
term_lastspace: .res 1  ; One past index of the last breaking character
term_prompt_length: .res 1  ; Length of output buffer at start of line
; (if bit 7 set, do not draw cursor)

.align 2
nmi_handler: .res 2
irq_handler: .res 2

; Initial setup of FME-7 and video memory ;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "CODE"
.proc term_init

  ; Enable NMIs but disable everything in the NMI handler
  ; except for signaling that NMI happened
  lsr last_PPUCTRL
  lda #VBLANK_NMI
  sta PPUCTRL
  lda #>term_nmi_body
  sta nmi_handler+1
  lda #<term_nmi_body
  sta nmi_handler
  lda #>term_irq_split
  sta irq_handler+1
  lda #<term_irq_split
  sta irq_handler
  lda #$FD
  sta throbber_phase

  ; Detect TV system
  jsr getTVSystem
  sta tvSystem
  
  ; Load palette
  lda #$3F
  sta PPUADDR
  ldx #$00
  stx PPUADDR
  stx term_busy
palloop:
  lda initial_palette,x
  sta PPUDATA
  inx
  cpx #initial_palette_end-initial_palette
  bcc palloop
  
  ; Load FME-7 bank numbers
  ldx #initial_fme7_regs_end-initial_fme7_regs-1
bankloop:
  stx $8000
  lda initial_fme7_regs,x
  sta $A000
  dex
  bpl bankloop

  ; Clear second nametable (used for status bar)
  ; We use a horizontal arrangement of nametables with vertical
  ; scrolling because the status bar hides the boundary between
  ; one bank and the next.
  ldx #$24
  lda #$FF
  ldy #%10101010
  jsr ppu_clear_nt
  lda #$24
  sta PPUADDR
  lda #$00
  sta PPUADDR
  ldy #$F0
  jsr do_one_nt_row
  lda #$27
  sta PPUADDR
  lda #$C0
  sta PPUADDR
  jsr some_sideborder_attrs

  ; Set up the main nametable
  lda #SCREEN_H
  sta cursor_y
  lda #$20
  ldy #$00
  sta PPUADDR
  sty PPUADDR
ntlineloop:
  jsr do_one_nt_row
  dec cursor_y
  bne ntlineloop

  ; and attributes
  ldy #8
attrsetuploop:
  jsr some_sideborder_attrs
  dey
  bne attrsetuploop
  jmp term_cls

do_one_nt_row:
  ldx #7
  lda #$FF
  sta PPUDATA
  sta PPUDATA
nttileloop:
  sty PPUDATA
  iny
  sty PPUDATA
  dey
  sty PPUDATA
  iny
  sty PPUDATA
  iny
  dex
  bne nttileloop
  sta PPUDATA
  sta PPUDATA
  iny
  iny
  rts
  
some_sideborder_attrs:
  ldx #7
:
  lda sideborder_attrs,x
  sta PPUDATA
  dex
  bpl :-
  rts
.endproc

.segment "RODATA"
initial_palette:
  .byte $0F,$2A,$0F,$2A, $0F,$0F,$2A,$2A
  .byte $0F,$0A
initial_palette_end:
initial_fme7_regs:
  .byte 0, 1, 2, 3, 4, 5, 6, 7  ; CHR RAM banks
  .byte 0, 0, 1, 2  ; PRG ROM banks
  .byte 0  ; Mirroring mode: Vertical
  .byte 0, $FF, $FF  ; no IRQ
initial_fme7_regs_end:

; Clear screen

.proc term_cls
  ldy #0
  sty PPUMASK
  sty last_PPUCTRL
  sty term_lastspace
  sty term_length
  sty term_linewidth
  sty scroll_y
  sty cursor_y
  lda #VBLANK_NMI
  sta PPUCTRL

  ; Clear CHR RAM $0000-$1FFF
  ldx #256-8
  sty PPUADDR
  sty PPUADDR
  tya
clrchrloop:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  iny
  bne clrchrloop
  inx
  bne clrchrloop

  ; Load throbber tiles to $E0-$E1 of last pattable
  lda #$1E
  sta PPUADDR
  ldx #$00
  stx PPUADDR
throbber_load_tile_loop:
  ldy #8
  lda #$FF
:
  sta PPUDATA
  dey
  bne :-
  ldy #8
:
  lda zthrobber_frames,x
  inx
  sta PPUDATA
  dey
  bne :-
  cpx #32
  bcc throbber_load_tile_loop

  ; Clear last tile of each pattern table to gray
  lda #$1F
  jsr clr1tile
  lda #$0F
  jsr clr1tile

  ; Ready to run; prepare the refresh daemon
  lda #$FF
  sta update_y
  lda #VBLANK_NMI
  sta last_PPUCTRL
  cli

  ; Set initial status
  lda #>sample_status_msg
  ldy #<sample_status_msg
  jsr term_set_status
  rts

clr1tile:
  sta PPUADDR
  lda #$F0
  sta PPUADDR
  lda #$FF
  jsr :+
  lda #$00
:
  ldx #8
:
  sta PPUDATA

  dex
  bne :-
  rts
.endproc

; Output with word wrapping ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "CODE"
;;
; Add the character in A to the end of the output buffer.
.proc term_putc
  ldx term_length
  cmp #$0A
  bne not_newline
    stx term_lastspace
    jmp term_newline
  not_newline:
  
  ; If adding the character would cause it to overflow in length or
  ; width, emit a line before adding.
  cpx #TERM_BUFLEN
  bcs is_full
  tax
  lda term_linewidth
  clc
  adc vwfChrWidths-32,x
  cmp #lineImgBufLen
  txa
  bcc not_full

  is_full:
    pha
    jsr term_newline
    pla
  not_full:

  ; At this point there should be enough room for at least
  ; one more character in the buffer.
  tax
  lda term_linewidth
  clc
  adc vwfChrWidths-32,x
  sta term_linewidth
  txa
  ldx term_length
  sta term_buf,x
  inx
  stx term_length
  cmp #' '+1
  bcs notspace
    stx term_lastspace
  notspace:
  rts
.endproc

.proc term_flush
  ldy term_length
.endproc
;;
; Writes first Y characters of the current line out to CHR RAM.
; If the cu
; @param Y length of prefix of term_buf to write
; @param A number of pixels to invert (0-224)
; @return Y unchanged; X = length
; $04-$0D trashed
.proc term_draw_line
srcLen = $04
srcPos = $0C
horzPos = $0D

  pha
  sty srcLen
  ldy #0
  sty horzPos

  ; Wait for the NMI handler to copy the previous line, then
  ; clear this one
wait_for_clear:
  bit update_y
  bpl wait_for_clear
  jsr clearLineImg
  lda srcLen
  beq noCharsInLine

charloop:
  sty srcPos
  lda term_buf,y
  cmp #' '+1
  bcc is_space
    ldx horzPos
    jsr vwfPutTile
    ldy srcPos
  is_space:

  ldx term_buf,y
  lda horzPos
  clc
  adc vwfChrWidths-' ',x
  sta horzPos
  iny
  cpy srcLen
  bcc charloop
noCharsInLine:

  lda term_prompt_length
  bmi no_cursor
  ldx term_linewidth
  cpx #lineImgBufLen-5
  bcc :+
  ldx #lineImgBufLen-5
:
  lda #'_'
  jsr vwfPutTile
no_cursor:

  pla
  beq not_inverted
    lda #lineImgBufLen>>3
    jsr invertTiles
  not_inverted:
  lda cursor_y
  sta update_y

  ; If the cursor has moved onto the first line below the visible
  ; portion of the playfield, scroll a new line in
  ldx tvSystem
  lda visible_text_lines,x
  clc
  adc scroll_y
  cmp #SCREEN_H
  bcc :+
  sbc #30
:
  cmp cursor_y
  bne no_add_scroll
  inc scroll_y
  lda scroll_y
  cmp #30
  bcc no_add_scroll
  lda #0
  sta scroll_y
no_add_scroll:



  ldy srcLen
  ldx horzPos
  rts
.endproc

;;
; Writes term_buf[:term_lastspace] to the screen and deletes
; term_buf[:term_lastspace].
; AX and $04-$0D trashed, Y preserved
.proc term_newline
  tya
  pha
  
  ; If there is no space, draw the whole line
  ldy term_lastspace
  bne line_has_space
  ldy term_length
  sty term_lastspace
line_has_space:
  lda term_prompt_length
  pha
  lda #$FF
  sta term_prompt_length
  lda #0
  jsr term_draw_line
  pla
  sta term_prompt_length

  ; Subtract width of printed glyphs from line width
  txa
  eor #$FF
  sec
  adc term_linewidth
  bcs :+
  lda #0
:
  sta term_linewidth

  ; Shift everything after printed characters to start of line
  ldx #0
  ldy term_lastspace
  beq no_shiftup
shiftup_loop:
  lda term_buf,y
  sta term_buf,x
  inx
  iny
  cpy #TERM_BUFLEN
  bcc shiftup_loop

  ; Subtract printed characters from line length
  lda term_length
  ; already sec from previous bcc
  sbc term_lastspace
  sta term_length
  lda #0
  sta term_lastspace
no_shiftup:
  
  ; Finally move the cursor
  inc cursor_y
  lda cursor_y
  cmp #SCREEN_H
  bcc cursor_y_no_wrap
  lda #0
  sta cursor_y
cursor_y_no_wrap:

  pla
  tay
  rts
.endproc

;;
; Clears the line without printing it.
; Useful after term_flush() and input or other waiting.
.proc term_discard_line
  lda #0
  sta term_length
  sta term_lastspace
  sta term_linewidth
  rts
.endproc

;;
; Remeasures the length of the output buffer.
.proc term_remeasure
  lda #0
  sta term_lastspace
  ldy term_length
  beq nothing

  ; A is width, Y is offset, X is character
  clc
  tay
measureloop:
  ldx term_buf,y
  adc vwfChrWidths-32,x
  cmp #lineImgBufLen
  bcc :+
    lda #lineImgBufLen
  :
  iny
  cpx #' '+1
  bcs not_space
  sty term_lastspace
not_space:
  cpy term_length
  bcc measureloop
nothing:
  sta term_linewidth
  rts
.endproc

.proc term_puts
  sty $00
  sta $01
.endproc
.proc term_puts0
  ldy #0
msgloop:
  lda ($00),y
  beq msgdone
  jsr term_putc
  iny
  bne msgloop
  inc $01
  bne msgloop
msgdone:
  tya
  clc
  adc $00
  sta $00
  bcs :+
  inc $01
:
  rts
.endproc

; Input ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.proc term_gets
  lda term_length
  sta term_prompt_length
nextchar:
  jsr term_remeasure
  lda #0
  jsr term_flush
  jsr term_getc
  cmp #' '
  bcc not_printable

  ; Make sure the buffer is not full
  ldx term_length
  cpx #TERM_BUFLEN
  bcs nextchar
  tax
  lda term_linewidth
  clc
  adc vwfChrWidths-32,x
  cmp #lineImgBufLen
  txa
  bcs nextchar

  jsr term_putc  ; There's room, so add the character
  jmp nextchar
not_printable:
  cmp #$08
  bne not_bs
  lda term_prompt_length
  cmp term_length
  bcs nextchar
  dec term_length
  jmp nextchar
not_bs:
  cmp #$0D
  beq done
  cmp #$0A
  beq done
  jmp nextchar
done:
  rts
.endproc

; Status bar ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
; Replaces the text in the status bar with the NUL-terminated string
; at address (A << 8 | Y) (AAYY).  The part before the first tab
; character ($09) is left-aligned; the rest is right-aligned.
.proc term_set_status
  sty $00
  sta $01

  ; Wait for the NMI handler to copy the previous line, then
  ; clear this one and write the left-aligned portion
wait_for_clear:
  bit update_y
  bpl wait_for_clear
  jsr clearLineImg
  ldx #4
  jsr vwfPuts0

  ; Determine whether a tab was used
  sty $00
  sta $01
  ldy #$00
  lda ($00),y
  beq no_right_aligned_portion

  ; Calculate position of right-aligned portion and write it
  jsr vwfStrWidth0
  eor #$FF
  sec
  adc #lineImgBufLen - 8
  tax
  jsr vwfPuts0

no_right_aligned_portion:
  lda #28
  jsr invertTiles
  lda #31
  sta update_y
  rts
.endproc

; NMI and IRQ handlers ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This way we can display more than 4K of tiles at once 

; Bit 7 ($80) is count, and bit 0 ($01) is enable IRQ.
; Count+disable ($80) is supposed to acknowledge the IRQ but doesn't
; on Nestopia, which acknowledges only when count is turned off.
; This changes the usable interrupt periods from 256*n cycles
; to 256*n + 6 cycles
NESTOPIA_WORKAROUND = 1

.if NESTOPIA_WORKAROUND
  FME7_ACKVALUE = $00   ; Stop count, disable IRQ
  FME7_PERIOD_ADD = 6
.else
  FME7_ACKVALUE = $80   ; Continue count, disable IRQs
  FME7_PERIOD_ADD = 0
.endif

; The first IRQ happens on the last scanline of the status line
; which is Y=31 on NTSC and Y=7 on PAL NES and Dendy
NTSC_IRQ1_PERIOD  = (20 + 32) * 341 / 3      - 33
PAL_IRQ1_PERIOD   = (70 +  8) * 341 * 5 / 16 - 33
DENDY_IRQ1_PERIOD = (20 +  8) * 341 / 3      - 33

; Other IRQs are at top of content line 10, top of content line 20,
; and (for NTSC only) the bottom of content line 23 (of 0-23)
NTSC_IRQ2_DELAY   = 10 * 8 * 341 / 3       - FME7_PERIOD_ADD
NTSC_IRQ3_DELAY   = 20 * 8 * 341 / 3       - FME7_PERIOD_ADD * 2
NTSC_BOTTOM_DELAY = 24 * 8 * 341 / 3       - FME7_PERIOD_ADD * 3
PAL_IRQ2_DELAY    = 10 * 8 * 341 * 5 / 16  - FME7_PERIOD_ADD
PAL_IRQ3_DELAY    = 20 * 8 * 341 * 5 / 16  - FME7_PERIOD_ADD * 2

.segment "CODE"
.proc term_nmi
  inc nmis
  bit last_PPUCTRL
  bmi nmi_in_use
  rti
nmi_in_use:
  jmp (nmi_handler)
.endproc
.proc term_nmi_body
nmi_in_use:
  pha
  txa
  pha

  ; Set IRQ to bottom of status bar
  lda #$0D   ; Stop counter
  sta $8000
  lda #$00
  sta $A000
  lda #$0E   ; Counter low
  sta $8000
  ldx tvSystem
  lda irq1_period_lo,x
  sta $A000
  lda #$0F   ; Stop counter
  sta $8000
  lda irq1_period_hi,x
  sta $A000
  lda #$0D   ; Start counter
  sta $8000
  lda #$81
  sta $A000

  bit PPUSTATUS
  ; If a VRAM update is prepared, run the update
  lda update_y
  bmi no_update
  tya
  pha
  lda #0
  sta $8000
  lda update_y
  lsr a
  lsr a
  sta $A000
  lda update_y
  and #$03
  ldy #$FF
  sty update_y
  iny
  jsr copyLineImg
  pla
  tay
no_update:

  ; Throbber logic
  lda #$24
  sta PPUADDR
  lda #$1D
  sta PPUADDR
  lda throbber_phase
  sta PPUDATA

  ; Set scroll to the status bar and reenable display
  lda #0
  sta irq_step
  sta PPUSCROLL
  ldx tvSystem
  lda status_scroll_value,x
  sta PPUSCROLL
  lda #VBLANK_NMI|BG_1000|3
  sta PPUCTRL
  lda #BG_ON
  sta PPUMASK
  
  ; Calculate values for IRQs
  lda step2delays,x
  sta step2delay
  lda step3delays,x
  sta step3delay
  lda step4delays,x
  sta step4delay
  
  ; Calculate value for scroll split
  lda scroll_y
  sta stable_scroll_y
  asl a     ; . ..43 210.
  asl a     ; . .432 10..
  asl a     ; . 4321 0...
  asl a     ; 4 3210 ....
  adc #0    ; . 3210 ...4
  asl a     ; 3 210. ..4.
  adc #0    ; . 210. ..43
  sta scroll_bits

  ; Set initial CHR RAM banks
  lda #0
  jsr irq_load4banks

  ; update throbber
  lda nmis
  and #$0F
  bne no_update_throbber
  lda term_busy
  bne throbber_is_busy
  lda #$FD
  bne have_throbber_phase
throbber_is_busy:
  lda #0
  sta term_busy
  inc throbber_phase
  lda throbber_phase
  and #$03
  ora #$E0
have_throbber_phase:
  sta throbber_phase
no_update_throbber:

  ; and restore everything
  lda FME7_lastreg
  sta $8000
  pla
  tax
  pla
  rti
.endproc

.proc term_irq
  jmp (irq_handler)
.endproc

.proc term_irq_split
fourth_split_PPUADDR = $400 + 32 * 26
  pha
  lda irq_step
  beq split_below_status
  lsr a
  beq first_split
  bcc second_split

  ; Fourth and final split, at the bottom of the NTSC screen (not PAL)
  .if ::NESTOPIA_WORKAROUND
    lda $00
    lda $00
  .else
    jsr waste12
    jsr waste12
  .endif
  jsr waste12
  jsr waste12
  jsr waste12
  lda #>fourth_split_PPUADDR
  sta PPUADDR
  lda #<fourth_split_PPUADDR
  sta PPUADDR
  lda #VBLANK_NMI|BG_1000|3
  sta PPUCTRL
  jmp ack

split_below_status:
  lda #VBLANK_NMI|BG_0000
  sta PPUCTRL
  lda scroll_bits
  and #$03
  sta PPUADDR
  lda scroll_bits
  and #$E0
  sta PPUADDR
  
  ; Schedule first bank change
  lda #$0F
  sta $8000
  lda step2delay
  sta $A000
  jmp ack
waste12:
  rts
  
first_split:  ; After 10 lines of text
  lda #BG_ON|LIGHTGRAY
;  sta PPUMASK

  ; Schedule second bank change
  lda #$0F
  sta $8000
  lda step3delay
  sta $A000

  lda #10
  jsr irq_load4banks
  lda #BG_ON
  sta PPUMASK

  jmp ack

second_split:  ; After 20 lines of text
  lda #BG_ON|LIGHTGRAY
;  sta PPUMASK

  ; Schedule turning off screen
  lda #$0F
  sta $8000
  lda step4delay
  sta $A000

  lda #20
  jsr irq_load4banks
  lda #BG_ON
  sta PPUMASK

ack:  ; Acknowledge IRQ
  lda #$0D
  sta $8000
  
  lda #FME7_ACKVALUE
  sta $A000
  ; Count+reenable
  lda #$81  ; Count + reenable
  sta $A000
  lda FME7_lastreg
  sta $8000
  inc irq_step
  pla
  rti

ntsc_bottom:
  lda #VBLANK_NMI|BG_1000
  sta PPUCTRL
  lda #0
  sta PPUADDR
  sta PPUADDR
  beq ack
.endproc

.proc irq_load4banks
  clc
  adc stable_scroll_y
  cmp #SCREEN_H
  bcc :+
  sbc #SCREEN_H
:
  lsr a
  lsr a
  clc
  jsr irq_load1bank
  jsr irq_load1bank
  jsr irq_load1bank
.endproc
.proc irq_load1bank
  pha
  and #$03
  sta $8000
  pla
  and #$07
  sta $A000
  adc #1
  rts
.endproc

.segment "RODATA"
irq1_period_lo:
  .lobytes NTSC_IRQ1_PERIOD, PAL_IRQ1_PERIOD, DENDY_IRQ1_PERIOD
irq1_period_hi:
  .hibytes NTSC_IRQ1_PERIOD, PAL_IRQ1_PERIOD, DENDY_IRQ1_PERIOD
status_scroll_value:
  .byte 240-24, 0, 0
visible_text_lines:
  .byte 24, 29, 29
step2delays:
  .byte >NTSC_IRQ2_DELAY, >PAL_IRQ2_DELAY, >NTSC_IRQ2_DELAY
step3delays:
  .byte >NTSC_IRQ3_DELAY - >NTSC_IRQ2_DELAY - 1
  .byte >PAL_IRQ3_DELAY  - >PAL_IRQ2_DELAY  - 1
  .byte >NTSC_IRQ3_DELAY - >NTSC_IRQ2_DELAY - 1
step4delays:
  .byte >NTSC_BOTTOM_DELAY - >NTSC_IRQ3_DELAY - 2
  .byte $FF
  .byte $FF
sample_status_msg:
  .byte "VWF terminal WIP",9,"Copr. 2015 Damian Yerrick",0
sideborder_attrs:
  ; from right to left
  .byte $99,$11,$11,$11,$11,$11,$11,$22
zthrobber_frames:
  .incbin "obj/nes/zthrobber.1bpp"
