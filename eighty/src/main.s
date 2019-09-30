;
; Eighty: an NES Four Score test program
; Main function and controller graphics
; Copyright 2012 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.include "nes.inc"
.include "global.inc"

.segment "ZEROPAGE"
nmis:          .res 1
oam_used:      .res 1  ; starts at 0
cur_keys:      .res 4
new_keys:      .res 4

OAM = $0200
copybuf = $0100

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 1          ; PRG ROM size in 16384 byte units
  .byt 1          ; CHR ROM size in 8192 byte units
  .byt $00        ; mirroring type and mapper number lower nibble
  .byt $00        ; mapper number upper nibble

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

  ; We have about 29700 cycles to burn until the second frame's
  ; vblank.  Use this time to get most of the rest of the chipset
  ; into a known state.

  ; Most versions of the 6502 support a mode where ADC and SBC work
  ; with binary-coded decimal.  Some 6502-based platforms, such as
  ; Atari 2600, use this for scorekeeping.  The second-source 6502 in
  ; the NES ignores the mode setting because its decimal circuit is
  ; dummied out to save on patent royalties, and games either use
  ; software BCD routines or convert numbers to decimal every time
  ; they are displayed.  But some post-patent famiclones have a
  ; working decimal mode, so turn it off for best compatibility.
  cld

  ; Clear OAM and the zero page here.
  ldx #0
  jsr ppu_clear_oam  ; clear out OAM from X to end and set X to 0

  ; There are "holy wars" (perennial disagreements) on nesdev over
  ; whether it's appropriate to zero out RAM in the init code.  Some
  ; anti-zeroing people say it hides programming errors with reading
  ; uninitialized memory, and memory will need to be initialized
  ; again anyway at the start of each level.  Others in favor of
  ; clearing say that a lot more variables need set to 0 than to any
  ; other value, and a clear loop like this saves code size.  Still
  ; others point to the C language, whose specification requires that
  ; uninitialized variables be set to 0 before main() begins.
  txa
clear_zp:
  sta $00,x
  inx
  bne clear_zp
  
  ; Other things to do here (not shown):
  ; Set up PRG RAM
  ; Copy initial high scores, bankswitching trampolines, etc. to RAM
  ; Set up initial CHR banks
  ; Set up your sound engine

vwait2:
  bit PPUSTATUS  ; After the second vblank, we know the PPU has
  bpl vwait2     ; fully stabilized.
  
  ; There are two ways to wait for vertical blanking: spinning on
  ; bit 7 of PPUSTATUS (as seen above) and waiting for the NMI
  ; handler to run.  Before the PPU has stabilized, you want to use
  ; the PPUSTATUS method because NMI might not be reliable.  But
  ; afterward, you want to use the NMI method because if you read
  ; PPUSTATUS at the exact moment that the bit turns on, it'll flip
  ; from off to on to off faster than the CPU can see.

  ; Now the PPU has stabilized, we're still in vblank.  Copy the
  ; palette right now because if you load a palette during forced
  ; blank (not vblank), it'll be visible as a rainbow streak.
  jsr load_main_palette
  
  jsr title_screen
  lda #0
  sta PPUMASK

  ; While in forced blank we have full access to VRAM.
  ; Load the nametable (background map).
  jsr draw_bg
  
  ; Set up game variables, as if it were the start of a new level.

forever:

  ; Game logic
  jsr read_fourscore

  ; Draw lights
  ldx #0
  lda cur_keys+0
  jsr prepare_binary_lights
  inx
  inx
  lda cur_keys+1
  jsr prepare_binary_lights
  lda cur_keys+2
  jsr prepare_binary_lights
  inx
  inx
  lda cur_keys+3
  jsr prepare_binary_lights
  lda 4
  jsr prepare_binary_lights
  inx
  inx
  lda 5
  jsr prepare_binary_lights
  
  lda new_keys+0
  and #KEY_SELECT
  beq :+
  jsr play_droid
:

  ; The first entry in OAM (indices 0-3) is "sprite 0".  In games
  ; with a scrolling playfield and a still status bar, it's used to
  ; help split the screen.  This demo doesn't use scrolling, but
  ; yours might, so I'm marking the first entry used anyway.  
  ldx #4
  stx oam_used
  lda $4015
  and #$10
  beq :+
  jsr draw_droid
:
  jsr draw_all_keysprites
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
  
  ; Copy the lights
  jsr copy_binary_lights
  
  ; Turn the screen on
  ldx #0
  ldy #0
  lda #VBLANK_NMI|BG_0000|OBJ_0000
  sec
  jsr ppu_screen_on
  jmp forever

; And that's all there is to it.
.endproc

.proc load_main_palette
  ; seek to the start of palette memory ($3F00-$3F1F)
  ldx #$3F
  stx PPUADDR
  ldx #$00
  stx PPUADDR
copypalloop:
  lda initial_palette,x
  sta PPUDATA
  inx
  cpx #32
  bcc copypalloop
  rts
.endproc
.segment "RODATA"
initial_palette:
  .byt $0F,$00,$16,$10,$0F,$00,$18,$10,$0F,$00,$1A,$10,$0F,$00,$1C,$10
  .byt $0F,$00,$2C,$20,$0F,$29,$39,$20,$0F,$00,$1A,$10,$0F,$00,$1C,$10

.segment "CODE"

.proc draw_bg
  ; Start by clearing the first nametable
  ldx #$20
  lda #$00
  tay
  jsr ppu_clear_nt

  ldy #0
gamepads_loop:
  lda gamepad_pos_hi,y
  ldx gamepad_pos_lo,y
  iny
  jsr draw_one_gamepad
  cpy #4
  bcc gamepads_loop
  
  ldx #26*3-1
  lda #0
clr_copybuf:
  sta copybuf,x
  dex
  bpl clr_copybuf
  
  ldx #0
  lda #$23
  ldy #$08
  jsr copy_sig_msg
  lda #$20
  ldy #$C9
copy_sig_msg:
  sta PPUADDR
  sty PPUADDR
copy_sig_msg_loop:
  lda sig_msg,x
  beq done_sig_msg
  sta PPUDATA
  inx
  bne copy_sig_msg_loop
done_sig_msg:
  inx
  rts
.endproc

.segment "RODATA"


gamepad_pos_hi:
  .byt $21, $21, $22, $22
gamepad_pos_lo:
  .byt $03, $11, $03, $11
sig_msg:
  .byt "SIGNATURE BYTES",0
  .byt "BUTTON PRESSES",0

.segment "CODE"

.proc draw_one_gamepad
dst_hi = 1
dst_lo = 0
player_number = 2

  sta dst_hi
  stx dst_lo
  sty player_number

  lda #VBLANK_NMI  ; clear VRAM_DOWN
  sta PPUCTRL
  txa
  clc
  adc #4
  pha
  lda dst_hi
  pha
  ldx #0
rowloop:
  lda dst_hi
  sta PPUADDR
  lda dst_lo
  sta PPUADDR
  clc
  adc #32
  sta dst_lo
  bcc :+
  inc dst_hi
:
  ldy #12
tileloop:
  lda gamepad_map_data,x
  sta PPUDATA
  inx
  dey
  bne tileloop
  cpx #gamepad_map_len
  bcc rowloop

  ; Now fill in the dots corresponding to player number
  ; $F6 for two dots; $F5 for any dots left
  pla
  sta PPUADDR
  pla
  sta PPUADDR
  ldy player_number
  beq pn_done
  tya
pn_loop:
  cmp #2
  bcc pn_less_than_2
  lda #2
pn_less_than_2:
  eor #$F4
  sta PPUDATA
  eor #<~$F4
  sec
  adc player_number
  sta player_number
  bne pn_loop
pn_done:
  rts
.endproc

.segment "RODATA"
gamepad_map_data:
  .byt $C0,$03,$03,$F2, $03,$03,$03,$03, $03,$03,$03,$C6
  .byt $EC,$00,$00,$ED, $EE,$EE,$EE,$EF, $FC,$FD,$FE,$FF
  .byt $EC,$C1,$C2,$C3, $C4,$C5,$C4,$C7, $C8,$C9,$CA,$FF
  .byt $D0,$D1,$D2,$D3, $D4,$D5,$D6,$D7, $D8,$D9,$DA,$FF
  .byt $E0,$E1,$E2,$E3, $E4,$E5,$E6,$E7, $E8,$E9,$EA,$FF
  .byt $F0,$F1,$F1,$F3, $F4,$F4,$F4,$F7, $F8,$F9,$FA,$FB
gamepad_map_len = * - gamepad_map_data

.segment "CODE"

;;
; Translates an 8-bit number in A to a set of 8 binary lights
; and a hexadecimal number.
.proc prepare_binary_lights
data_shiftreg = 0
data_orig = 1

  ; First the lights
  sta data_orig
  sec
  rol a
  sta data_shiftreg
loop:
  lda #$0E >> 1
  rol a
  sta copybuf,x
  inx
  asl data_shiftreg
  bne loop

  ; then two spaces
  lda #' '
  sta copybuf,x
  inx
  lda #'$'
  sta copybuf,x
  inx

  ; then the first hex hibble
  lda data_orig
  lsr a
  lsr a
  lsr a
  lsr a
  jsr onehex

  ; then the second hex hibble
  lda data_orig
  and #$0F
onehex:
  cmp #$0A
  bcc hexnotletter
  adc #'A'-'9'-2
hexnotletter:
  adc #'0'
  sta copybuf,x
  inx
  rts
.endproc

.proc copy_binary_lights
  ldx #0
  ldy #0
rowloop:
  sty 0
  lda lights_hi,y
  sta PPUADDR
  lda lights_lo,y
  sta PPUADDR
  ldy #26
lightsloop:
  lda copybuf,x
  sta PPUDATA
  inx
  dey
  bne lightsloop
  ldy 0
  iny
  cpy #3
  bcc rowloop
  rts
.endproc
.segment "RODATA"
lights_hi:
  .byt $21, $22, $23
lights_lo:
  .byt $C3, $C3, $23
.segment "CODE"

.proc draw_keysprites
ybase = 0
xbase = 1
keybits = 2
  sta keybits
  stx xbase
  sty ybase
  ldx oam_used
  ldy #7
loop:
  lsr keybits
  bcc not_this_sprite
  clc
  lda ybase
  adc keysprite_y,y
  sta OAM,x
  inx
  lda #$0C
  sta OAM,x
  inx
  lda #$00
  sta OAM,x
  inx
  clc
  lda xbase
  adc keysprite_x,y
  sta OAM,x
  inx
  beq done
not_this_sprite:
  dey
  bpl loop
done:
  stx oam_used
  rts
.endproc
.segment "RODATA"
keysprite_x: .byt 77,64,35,47,13,13, 7,20
keysprite_y: .byt 30,30,30,30,17,32,24,24
keysprite_tl_x:  .byt 24, 136, 24, 136
keysprite_tl_y:  .byt 63, 63, 127, 127
.segment "CODE"

.proc draw_all_keysprites
controller_no = 3
  ldy #3
  sty controller_no
keysprloop:
  lda nmis
  and #1
  eor controller_no
  tay
  lda cur_keys,y
  pha
  ldx keysprite_tl_x,y
  lda keysprite_tl_y,y
  tay
  pla
  jsr draw_keysprites
  dec controller_no
  bpl keysprloop
  rts
.endproc

.segment "CHR"
.incbin "obj/nes/bggfx.chr"
.incbin "obj/nes/spritegfx.chr"
