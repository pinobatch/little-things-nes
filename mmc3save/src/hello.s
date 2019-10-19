.p02
.include "nes.inc"
.include "global.inc"
.include "mmc3.inc"

.segment "INESHDR"
  .byt "NES",$1A
  .byt $01  ; two 8 KiB PRG banks
  .byt $01  ; eight 1 KiB CHR banks
  .byt $42  ; mapper $x4, battery RAM
  .byt $00  ; mapper $0x

.segment "ZEROPAGE"
retraces: .res 1
cursorhi: .res 1
cursorlo: .res 1
cur_keys: .res 2
new_keys: .res 2
das_keys: .res 2
das_timer: .res 2

.segment "VECTORS"
  .addr nmi, reset, irq

.segment "E0CODE"
nmi:
  inc retraces
irq:
  rti

.proc reset
  sei        ; ignore IRQs
  cld        ; disable decimal mode
  ldx #$40
  stx $4017  ; disable APU frame IRQ
  ldx #$ff
  txs        ; Set up stack
  inx        ; now X = 0
  stx $2000  ; disable NMI
  stx $2001  ; disable rendering
  stx $4010  ; disable DMC IRQs
  bit $2002  ; ack any existing vblank NMI
  lda #$0F
  sta $4015  ; set up sound channels
  lda #$08
  sta $4001
  sta $4005

  ; First of two waits for vertical blank to make sure that the
  ; PPU has stabilized
@vblankwait1:  
  bit PPUSTATUS
  bpl @vblankwait1

  ; We have nearly 30K cycles to burn.  Clear RAM and initialize
  ; the mapper during this time.
  txa
@clrmem:
  sta $000,x
  sta $100,x
  inx
  bne @clrmem

  jsr reset_mmc3_banks

@vblankwait2:
  bit PPUSTATUS
  bpl @vblankwait2
  
main_menu:
  lda #$3F
  ldx #$00
  stx PPUMASK
  sta PPUADDR
  stx PPUADDR
  lda #OBJ_1000|VBLANK_NMI
  sta PPUCTRL
@set_initial_palette:
  lda initial_palette,x
  sta PPUDATA
  inx
  cpx #4
  bcc @set_initial_palette

  jsr cls
  lda #>menu_msg
  ldx #<menu_msg
  jsr puts
  jsr wait_key
  ldx #0
  sec  ; make damn sure it terminates
:
  asl a
  beq found
  inx
  inx
  bne :-
found:
  jsr dispatcher
  jmp main_menu
dispatcher:
  lda tester_funcs+1,x
  pha
  lda tester_funcs,x
  pha
doNothing:
  rts

.segment "E0DATA"
initial_palette:
  .byt $30,$10,$00,$0F
menu_msg:
  .byt "MMC3 save retention and",10
  .byt "bank behavior tester",10
  .byt "By Damian Yerrick",10
  .byt "", 10
  .byt "left: clear PRG RAM to $69",10
  .byt "right: write across all banks",10
  .byt "A: read from all banks",10
  .byt "start: ding",0
tester_funcs:
   ; A, B, Select, Start, Up, Down, Left, Right, Invalid key
  .addr hex_dump_prg_ram-1
  .addr doNothing-1
  .addr doNothing-1
  .addr ding-1

  .addr doNothing-1
  .addr doNothing-1
  .addr clear_sram-1
  .addr write_across_all_banks-1

  .addr doNothing-1
.segment "E0CODE"

.endproc

.proc wait_key
  jsr screenBackOn
  jsr read_pads
  lda new_keys
  beq wait_key
  rts
.endproc

.proc screenBackOn
  lda retraces
vwait:
  cmp retraces
  beq vwait
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #OBJ_1000|VBLANK_NMI
  sta PPUCTRL
  lda #%00001010
  sta PPUMASK
  rts
.endproc

.proc puthex
  pha
  lsr a
  lsr a
  lsr a
  lsr a
  jsr puthex1
  pla
  and #$0F
puthex1:
  cmp #10
  bcc not_letter
  adc #'A'-'9'-2
not_letter:
  adc #'0'
  sta PPUDATA
  rts
.endproc

.proc cls
  lda #$20
  ldx #$00
  stx PPUMASK
  sta PPUADDR
  stx PPUADDR
  txa
@clear_nt:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  inx
  bne @clear_nt
  lda #$20
  sta cursorhi
  sta PPUADDR
  lda #$62
  sta cursorlo
  sta PPUADDR
knownrts:
  rts
.endproc

.proc puts
  sta 1
  stx 0
  ldy #0
charloop:
  lda (0),y
  beq done
  cmp #10
  beq newline
  sta PPUDATA
newline_done:
  iny
  bne charloop
  inc 1
  bne charloop
done:
  rts
newline:
  lda cursorlo
  clc
  adc #32
  sta cursorlo
  lda cursorhi
  adc #0
  sta cursorhi
  sta PPUADDR
  lda cursorlo
  sta PPUADDR
  jmp newline_done
.endproc

.proc reset_mmc3_banks
  ; set up initial MMC3 banks
  ldx #7
loop:
  stx MMC3SEL
  lda initial_mmc3_banks,x
  sta MMC3BANK
  dex
  bpl loop
  rts
.segment "E0DATA"
initial_mmc3_banks:
  .byt 4, 6, 0, 1, 2, 3, 0, 1
.segment "E0CODE"
.endproc

; == Now that we have that menu boilerplate out of the way, =========
; here are the test routines.

.proc ding
  lda #$8F
  sta $4000
  lda #126
  sta $4002
  lda #$08
  sta $4003
  rts
.endproc

.proc clear_sram
dstLo = 10
dstHi = 11

  jsr cls
  lda #>start_msg
  ldx #<start_msg
  jsr puts
  jsr screenBackOn
  
  ; Clear the RAM that we'll be testing with
  lda #MMC3_RW
  sta MMC3WRAM
  ldx #$60
  stx dstHi
  ldy #0
  sty dstLo
  lda #$69
clearloop:
  sta (dstLo),y
  iny
  bne clearloop
  stx $4011
  inx
  stx dstHi
  cpx #$80
  bcc clearloop
  lda #MMC3_RO
  sta MMC3WRAM
  lda #0
  sta $6969

  lda #0
  sta PPUMASK
  lda #>end_msg
  ldx #<end_msg
  jsr puts
  jsr wait_key
  rts
.segment "E0DATA"
start_msg:
  .byt "Clearing PRG RAM...",0
end_msg:
  .byt 10
  .byt "PRG RAM cleared.  All bytes",10
  .byt "should have value $69, even",10
  .byt "$6969.",0
.segment "E0CODE"
.endproc

.proc write_across_all_banks
dstLo = 10
dstHi = 11
  jsr cls
  lda #>start_msg
  ldx #<start_msg
  jsr puts
  jsr screenBackOn

  lda #MMC3_RW
  sta MMC3WRAM
  lda #$70
  sta dstHi
  ldy #0
  sty dstLo

page_loop:
  ; while holding 7 of the 8 bank numbers constant
  jsr reset_mmc3_banks

  ; now vary one of the banks
  ; this shouldn't have any effect because MMC3 boards don't support
  ; more than 8 KiB of PRG RAM
  lda dstHi
  and #$07
  sta MMC3SEL
inner_loop:
  tya
  sta MMC3BANK
  sta (dstLo),y
  iny
  bne inner_loop
  ldx dstHi
  inx
  stx dstHi
  cpx #$78
  bcc page_loop
  
  lda #MMC3_RO
  sta MMC3WRAM
  
  jsr reset_mmc3_banks
  lda #0
  sta PPUMASK
  lda #>end_msg
  ldx #<end_msg
  jsr puts
  jsr wait_key
  rts
.segment "E0DATA"
start_msg:
  .byt "Filling PRG RAM...",0
end_msg:
  .byt 10
  .byt "PRG RAM $7000-$77FF filled",10
  .byt "with $00-$FF.",0
.segment "E0CODE"
.endproc

.proc hex_dump_prg_ram
curPageLo = 8
curPageHi = 9
curPRGBank = 10

  lda #0
  sta curPageLo
  sta curPRGBank
  lda #$60
  sta curPageHi
  jsr cls
  lda #>page_msg
  ldx #<page_msg
  jsr puts

showPage:

  ; switch to the appropriate bank
  jsr reset_mmc3_banks
  ldx #6
  lda curPRGBank
  stx MMC3SEL
  sta MMC3BANK
  inx
  sta MMC3BANK
  lda #MMC3_RO
  sta MMC3WRAM

  ; Write the current bank and page numbers to the screen
  lda #0
  sta PPUMASK
  lda #$20
  sta PPUADDR
  lda #$E9
  sta PPUADDR
  lda curPRGBank
  jsr puthex
  lda #$20
  sta PPUADDR
  lda #$F4
  sta PPUADDR
  lda curPageHi
  and #$1F
  ora #$60
  sta curPageHi
  jsr puthex

  ; And start the hexdump.
  lda #$21
  sta PPUADDR
  ldy #$00
  sty PPUADDR
hexloop:
  lda (curPageLo),y
  jsr puthex
  iny
  bne hexloop

keyagain:
  jsr wait_key

  lda new_keys
  and #KEY_B
  beq notB
  rts
notB:

  lda new_keys
  and #KEY_UP
  beq notUp
  dec curPRGBank
  jmp showPage
notUp:

  lda new_keys
  and #KEY_DOWN
  beq notDown
  inc curPRGBank
  jmp showPage
notDown:

  lda new_keys
  and #KEY_LEFT
  beq notLeft
  dec curPageHi
  jmp showPage
notLeft:

  lda new_keys
  and #KEY_RIGHT
  beq notRight
  inc curPageHi
  jmp showPage
notRight:

  jmp keyagain

.segment "E0DATA"
page_msg:
  .byt "PRG RAM viewer",10
  .byt "left/right: change RAM page",10
  .byt "up/down: bankswitch ROM",10
  .byt "B: back",10
  .byt "Bank: $xx  Page: $xx00",0
.segment "E0CODE"
.endproc

.segment "CHR"
.incbin "obj/nes/titlegfx.chr"
.incbin "obj/nes/gamegfx.chr"
