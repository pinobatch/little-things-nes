;
; Simple sprite demo for NES
; Copyright 2011 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.include "nes.inc"
.include "global.inc"
.include "nes2header.inc"

nes2mapper 0
nes2prg 16384
nes2chr 8192
nes2tv 'P'
nes2end

.segment "ZEROPAGE"
nmis:          .res 1
oam_used:      .res 1  ; starts at 0
cur_keys:      .res 2
new_keys:      .res 2

; Game variables
bgcolor: .res 1
xfer_palette: .res 1
xfer_digits: .res 2

.segment "VECTORS"
.addr nmi, reset, irq

.segment "CODE"
;;
; This NMI handler is good enough for a simple "has NMI occurred?"
; vblank-detect loop.  But sometimes there are things that you always
; want to happen every frame, even if the game logic takes far longer
; than usual.  These might include music or a scroll split.  In these
; cases, you'll need to put more logic into the NMI handler.
.proc nmi
  inc nmis
  rti
.endproc

; A null IRQ handler that just does RTI is useful to add breakpoints
; that survive a recompile.  Set your debugging emulator to trap on
; reads of $FFFE, and then you can BRK $00 whenever you need to add
; a breakpoint.
;
; But sometimes you'll want a non-null IRQ handler.
; On NROM, the IRQ handler is mostly used for the DMC IRQ, which was
; designed for gapless playback of sampled sounds but can also be
; (ab)used as a crude timer for a scroll split (e.g. status bar).
.proc irq
  rti
.endproc

; 
.proc reset
  ; The very first thing to do when powering on is to put all sources
  ; of interrupts into a known state.
  sei             ; Disable interrupts
  ldx #$00
  stx PPUCTRL     ; Disable NMI and set VRAM increment to 32
  stx PPUMASK     ; Disable rendering
  stx $4010       ; Disable DMC IRQ
  dex             ; Subtracting 1 from $00 gives $FF, which is a
  txs             ; quick way to set the stack pointer to $01FF
  bit PPUSTATUS   ; Acknowledge stray vblank NMI across reset
  bit SNDCHN      ; Acknowledge DMC IRQ
  lda #$40
  sta P2          ; Disable APU Frame IRQ
  lda #$0F
  sta SNDCHN      ; Disable DMC playback, initialize other channels

vwait1:
  bit PPUSTATUS   ; It takes one full frame for the PPU to become
  bpl vwait1      ; stable.  Wait for the first frame's vblank.

  ; Burn 29700 cycles initializing the rest of the chipset

  ; Ensure additions don't use BCD even on clones
  cld

  ; Clear OAM and the zero page here.
  ldx #0
  jsr ppu_clear_oam  ; clear out OAM from X to end and set X to 0
  txa
clear_zp:
  sta $00,x
  inx
  bne clear_zp
  
vwait2:
  bit PPUSTATUS  ; After the second vblank, we know the PPU has
  bpl vwait2     ; fully stabilized.
  
  ; Now the PPU has stabilized, we're still in vblank.  Copy the
  ; palette right now because if you load a palette during forced
  ; blank (not vblank), it'll be visible as a rainbow streak.
  lda #VBLANK_NMI
  sta PPUCTRL
  jsr load_main_palette

  ; Load the background map
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  lda #>screen_data
  ldy #<screen_data
  jsr rldelta_unpack_ay
  
  ; Set up game variables, as if it were the start of a new level.
  lda #0
  sta bgcolor

forever:
  jsr read_pads
  jsr update_bgcolor

  ldx #0
  stx oam_used
  ; adds to oam_used
  jsr draw_oddeven_sprites
  ldx oam_used
  jsr ppu_clear_oam

  ; Good; we have the full screen ready.  Wait for a vertical blank
  ; and set the scroll registers to display it.
  lda nmis
vw3:
  cmp nmis
  beq vw3
  
  ; Copy the display list from main RAM to the PPU
  lda #0
  sta OAMADDR
  lda #>OAM
  sta OAM_DMA
  
  ; Update the palette
  lda #$3F
  sta PPUADDR
  ldx #$00
  stx PPUADDR
  lda xfer_palette
  sta PPUDATA
  bit PPUDATA  ; skip black
  clc
  adc #$10
  sta PPUDATA
  adc #$10
  sta PPUDATA

; top halves of digits
  lda #$20
  sta PPUADDR
  lda #$AD
  sta PPUADDR
  lda xfer_digits+0
  sta PPUDATA
  eor #$01
  sta PPUDATA
  lda xfer_digits+1
  sta PPUDATA
  eor #$01
  sta PPUDATA

; bottom halves of digits
  lda #$20
  sta PPUADDR
  lda #$CD
  sta PPUADDR
  lda xfer_digits+0
  ora #$20
  sta PPUDATA
  eor #$01
  sta PPUDATA
  lda xfer_digits+1
  ora #$20
  sta PPUDATA
  eor #$01
  sta PPUDATA

  ; Turn the screen on
  ldx #0
  ldy #0
  lda #VBLANK_NMI|BG_0000|OBJ_8X16
  sec
  jsr ppu_screen_on
  jmp forever

; And that's all there is to it.
.endproc

.proc load_main_palette
  ; seek to the start of palette memory ($3F00-$3F1F)
  ldx #$3F
  stx PPUADDR
  ldx #$01
  stx PPUADDR
copypalloop:
  lda initial_palette,x
  sta PPUDATA
  inx
  cpx #20
  bcc copypalloop
  rts
.endproc
.segment "RODATA"
initial_palette = *-1
  .byte     $0F,$10,$20
  .byte $FF,$11,$14,$18
  .byte $FF,$12,$15,$19
  .byte $FF,$13,$17,$1A
  .byte $00,$16,$1B,$1C

.segment "CODE"

.proc update_bgcolor
  ldy bgcolor
  lda new_keys
  lsr a
  bcc notRight
  iny
  cpy #$0D
  bcc keys_done
  ldy #$00
  beq keys_done
notRight:
  lsr a
  bcc keys_done
  dey
  bpl keys_done
  ldy #$0C
keys_done:
  tya
  sta bgcolor

  ; calculate the new actual background color
  beq :+
  ora #$10
:
  sta xfer_palette

  ; calculate the tiles to display the background color
  ldy #$C0
  and #$0F
  beq :+
  ldy #$C3
:
  sty xfer_digits+0
  asl a
  ora #$C0
  sta xfer_digits+1
  rts
.endproc

;;
; Decompresses a block compressed with delta-1 RLE.
; The block starts with the total size of uncompressed data
; as a negative number in network byte order.  For example,
; $FD $80 means $10000 - $FD80 = 640 bytes.
; To make a 16-bit NBO negative number in ca65 use this:
;   .dbyt 65536-size
;
; This is followed by 
; $00-$7F: 1-128 following literal bytes
; $80-$BF: 2-65 copies of the following byte
; $C0-$FF: 2-65 copies of the following byte, increasing by 1
;
; There are 3 entry points:
; rldelta_unpack_ay: block start address in AAYY
; rldelta_unpack_0: block start address in $00-$01
; rldelta_unpack_0_raw: block start address in $00-$01,
;   with no 2-byte length header
.proc rldelta_unpack_ay
  sta $01
  sty $00
.endproc
.proc rldelta_unpack_0
src = $00
remlenlo = $02
remlenhi = $03
rundelta = $04
  ldy #0
  lda (src),y
  iny
  sta remlenhi
  lda (src),y
  iny
  sta remlenlo

next_run:
  tya
  clc
  adc src+0
  sta src+0
  bcc have_src
  inc src+1
have_src:
  ldy #0
  lda (src),y
  bmi not_literal
  iny
  tax
literal_loop:
  lda (src),y
  iny
  sta PPUDATA
  inc remlenlo
  bne :+
  inc remlenhi
  beq done
:
  dex
  bpl literal_loop
  jmp next_run

not_literal:
  cmp #$C0  ; carry = false for add 0 or true for add 1
  and #$3F
  tax
  inx  ; X = number of bytes minus 1
  lda #0
  rol a  ; A = change in value after each output byte
  sta rundelta
  iny
  lda (src),y
  iny
run_loop:
  sta PPUDATA
  clc
  adc rundelta
  inc remlenlo
  bne :+
  inc remlenhi
  beq done
:
  dex
  bpl run_loop
  jmp next_run
done:
  rts
.endproc
rldelta_unpack_0_raw = rldelta_unpack_0::have_src

.segment "RODATA"
LIT = -1
RUN = 126
INCRUN = 190
.define ATTR(tl, tr, bl, br) ((tl) | ((tr) << 2) | ((bl) << 4) | ((br) << 6))
EVEN1 = $06
ODD1 = $07
EVEN2 = $22
ODD2 = $23
EVEN3 = $26
ODD3 = $27
EVENWORD = $08
ODDWORD = $0D
BGWORD = $11

screen_data:
  .dbyt 65536 - 1024
  ; Title
  .byte RUN+65, $00
  .byte INCRUN+30, $40
  .byte RUN+2, $00
  .byte INCRUN+30, $60
  ; descenders of 'p' and 'y'
  .byte RUN+6, $00
  .byte LIT+1, $02
  .byte RUN+10, $00
  .byte LIT+1, $03
  .byte RUN+15+1, $00  ; position 1 past line start

  .byte INCRUN+11, BGWORD, RUN+20+1, $00
  .byte INCRUN+11, BGWORD|$20, RUN+20, $00
  .byte RUN+5,$00, LIT+2, BGWORD+11, BGWORD+12, RUN+25, $00

  .byte RUN+64, $00

  ; hex 11-16
  .byte RUN+6, $00  ; position 6 after line start
  .byte LIT+23
  .byte $C2,$C2,$00,$00,$C2,$C4,$C5,$00,$C2,$C6,$C7,$00
  .byte $C2,$C8,$C9,$00,$C2,$CA,$CB,$00,$C2,$CC,$CD
  .byte RUN+9, $00
  .byte LIT+23
  .byte $E2,$E2,$00,$00,$E2,$E4,$E5,$00,$E2,$E6,$E7,$00
  .byte $E2,$E8,$E9,$00,$E2,$EA,$EB,$00,$E2,$EC,$ED
  .byte RUN+4,$00  ; position 1 after line start

  ; even: 5 blocks of color
  .byte INCRUN+5,EVENWORD
  .byte RUN+12,EVEN1,RUN+8,EVEN2
  .byte RUN+7,$00
  .byte INCRUN+5,EVENWORD+$20
  .byte RUN+12,EVEN1,RUN+8,EVEN2  ; position 6 before line start
  ; bottom of block
  .byte RUN+12,$00,RUN+12,EVEN1,RUN+8,EVEN2
  .byte RUN+8,$00  ; position 2 after line start

  ; odd: 5 blocks of color
  .byte INCRUN+4,ODDWORD
  .byte RUN+12,ODD1,RUN+8,ODD2
  .byte RUN+8,$00
  .byte INCRUN+4,ODDWORD+$20
  .byte RUN+12,ODD1,RUN+8,ODD2  ; position 6 before line start
  ; bottom of block
  .byte RUN+12,$00,RUN+12,ODD1,RUN+8,ODD2
  .byte RUN+64,$00
  .byte RUN+6+6,$00  ; position 6 after line start

  ; hex 17-1C
  .byte LIT+23
  .byte $C2,$CE,$CF,$00,$C2,$D0,$D1,$00,$C2,$D2,$D3,$00
  .byte $C2,$D4,$D5,$00,$C2,$D6,$D7,$00,$C2,$D8,$D9
  .byte RUN+9, $00
  .byte LIT+23
  .byte $E2,$EE,$EF,$00,$E2,$F0,$F1,$00,$E2,$F2,$F3,$00
  .byte $E2,$F4,$F5,$00,$E2,$F6,$F7,$00,$E2,$F8,$F9
  .byte RUN+4,$00

  ; even: 4 blocks of color
  .byte INCRUN+5,EVENWORD
  .byte RUN+4,EVEN2,RUN+12,EVEN3
  .byte RUN+11,$00
  .byte INCRUN+5,EVENWORD+$20
  .byte RUN+4,EVEN2,RUN+12,EVEN3  ; position 6 before line start
  ; bottom of block
  .byte RUN+16,$00,RUN+4,EVEN2,RUN+12,EVEN3
  .byte RUN+12,$00  ; position 2 after line start

  ; odd: 4 blocks of color
  .byte INCRUN+4,ODDWORD
  .byte RUN+4,ODD2,RUN+12,ODD3
  .byte RUN+12,$00
  .byte INCRUN+4,ODDWORD+$20
  .byte RUN+4,ODD2,RUN+12,ODD3  ; position 6 before line start
  ; bottom of block
  .byte RUN+16,$00,RUN+4,ODD2,RUN+12,ODD3
  ; last 2 rows blank
  .byte RUN+64,$00  ; position 10 before line start

  ; Attribute table time!
  ; 2 rows: top 6 lines of headings
  .byte RUN+35, $00
  ; 2 rows: color bars 1
  .byte LIT+29
  .byte ATTR(0,1,0,1),ATTR(1,2,1,2),ATTR(2,3,2,3),ATTR(3,1,3,1),ATTR(1,2,1,2),ATTR(2,0,2,0)
  .byte $00,$00
  .byte ATTR(0,1,0,0),ATTR(1,2,0,0),ATTR(2,3,0,0),ATTR(3,1,0,0),ATTR(1,2,0,0),ATTR(2,0,0,0)
  .byte $00,$00
  ; 2 rows: text color bars 2
  .byte ATTR(0,0,0,3),ATTR(0,0,3,1),ATTR(0,0,1,2),ATTR(0,0,2,3),ATTR(0,0,3,0)
  .byte $00,$00,$00
  .byte ATTR(0,3,0,3),ATTR(3,1,3,1),ATTR(1,2,1,2),ATTR(2,3,2,3),ATTR(3,0,3,0)
  ; 1 row: bottom of screen
  .byte RUN+10, $00

.segment "CODE"

;;
; Draws the player's character to the display list as six sprites.
; In the template, we don't need to handle half-offscreen actors,
; but a scrolling game will need to "clip" sprites (skip drawing the
; parts that are offscreen).
.proc draw_oddeven_sprites
sprite_y = $00
sprite_tile = $01
sprite_x = $03
metasprites_remain = $04
sprite_x_left = $05
width_cd = $06
rows_left = $07
  
  ldx oam_used
  ldy #2
metasprite_loop:
  sty metasprites_remain
  lda oddeven_sprite_tile,y
  sta sprite_tile
  lda oddeven_sprite_y,y
  sta sprite_y
  lda oddeven_sprite_x,y
  sta sprite_x_left
  lda #3  ; height
  sta rows_left
row_loop:
  lda sprite_x_left
  sta sprite_x
  ldy #4  ; width
cell_loop:
  lda sprite_y
  sta OAM,x
  inx
  lda sprite_tile
  sta OAM,x
  inx
  lda #0
  sta OAM,x
  inx
  lda sprite_x
  sta OAM,x
  inx
  clc
  adc #8
  sta sprite_x
  dey
  bne cell_loop

  ; Go to next row
  lda sprite_tile
  eor #$02
  sta sprite_tile
  lda rows_left
  eor #$01
  lsr a  ; on row 1, advance 17 pixels instead of 16
  lda #16
  adc sprite_y
  sta sprite_y
  dec rows_left
  bne row_loop

  ldy metasprites_remain
  dey
  bpl metasprite_loop
  stx oam_used
  rts
.endproc

.segment "RODATA"
oddeven_sprite_tile:
  .byte $04,$20,$24
oddeven_sprite_x:
  .byte 13*16,11*16,13*16
oddeven_sprite_y:
  .byte 6*16-1, 11*16-1, 11*16-1

; Include the CHR ROM data
.segment "CHR"
  .incbin "obj/nes/bggfx.chr"
  .incbin "obj/nes/spritegfx.chr"
