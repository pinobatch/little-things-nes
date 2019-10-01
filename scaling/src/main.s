;
; Simple sprite demo for NES
; Copyright 2011-2014 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.include "nes.inc"
.include "global.inc"

.import ppu_clear_nt, ppu_clear_oam, ppu_screen_on, read_pads
.exportzp cur_keys, new_keys

OAM = $0200


.segment "ZEROPAGE"
nmis:          .res 1
oam_used:      .res 1  ; starts at 0
cur_keys:      .res 2
new_keys:      .res 2

scale_dst: .res 1

; Game variables
player_xlo:       .res 1  ; horizontal position is xhi + xlo/256 px
player_xhi:       .res 1
player_dxlo:      .res 1  ; speed in pixels per 256 s
player_yhi:       .res 1
player_facing:    .res 1
player_frame:     .res 1
player_frame_sub: .res 1
player_shrink:    .res 1

frame_to_scale:   .res 1
shrink_to_scale:  .res 1
shrink_to_show:   .res 1

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 1          ; PRG ROM size in 16384 byte units
  .byt 0          ; CHR ROM size in 8192 byte units
  .byt $00        ; mirroring type and mapper number lower nibble
  .byt $00        ; mapper number upper nibble

.segment "VECTORS"
.addr nmi, reset, irq

.segment "CODE"
;;
; This NMI handler is good enough for a simple "has NMI occurred?"
; vblank-detect loop.
.proc nmi
  inc nmis
  rti
.endproc

; need not use irq
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

  ; post-patent famiclone compat
  cld

  ; Clear OAM and the zero page here.
  ldx #0
  jsr ppu_clear_oam  ; clear out OAM from X to end and set X to 0

  ; clear zero page
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
  jsr load_main_palette
  
  lda #$00
  sta PPUADDR
  sta PPUADDR
  lda #>bggfx
  ldy #<bggfx
  ldx #>(bggfx_end - bggfx)
  jsr load_chr
  lda #$10
  sta PPUADDR
  lda #$00
  sta PPUADDR
  lda #>spritegfx
  ldy #<spritegfx
  ldx #>(spritegfx_end - spritegfx)
  jsr load_chr
  
  ; While in forced blank we have full access to VRAM.
  ; Load the nametable (background map).
  jsr draw_bg
  
  ; Set up game variables, as if it were the start of a new level.
  lda #0
  sta player_xlo
  sta player_dxlo
  sta player_facing
  sta player_frame
  lda #48
  sta player_xhi
  lda #192
  sta player_yhi
  lda #0
  sta player_shrink
  
  lda #VBLANK_NMI
  sta PPUCTRL

forever:

  ; Game logic
  jsr read_pads
  jsr move_player
  jsr move_shrink

  ; The first entry in OAM (indices 0-3) is "sprite 0".  In games
  ; with a scrolling playfield and a still status bar, it's used to
  ; help split the screen.  This demo doesn't use scrolling, but
  ; yours might, so I'm marking the first entry used anyway.  
  ldx #4
  stx oam_used
  ; adds to oam_used
  jsr draw_player_sprite
  jsr draw_scaled_sprite

  ldx oam_used
  jsr ppu_clear_oam

  ; Now prepare the NEXT frame of animation
  ; find which column of the sprite to scale
  ; xstrip * 96
  lda frame_to_scale
  asl a
  asl a
  eor nmis
  and #%11111100
  eor nmis
  sta $01
  asl a
  adc $01  ; A = 3 * x
  lsr a
  sta $01  ; 1 = 1.5*x
  lda #0
  ror a    ; 1:A = 384 * X
  lsr $01
  ror a
  lsr $01
  ror a  ; 1:A = 96
  
  clc
  adc #<(tiles_to_scale)
  sta $00  ; src data pointer
  lda #>(tiles_to_scale)
  adc $01
  sta $01
  
  lda shrink_to_scale
  sta $03  ; scale amount
  clc
;  adc #$20
  and #$C0
  rol a
  rol a
  rol a
  ldx #0
  jsr do_scale
  lda nmis
  and #$07
  eor #$1C
  sta scale_dst
  and #$03
  cmp #$03
  bne :+
  lda shrink_to_scale
  sta shrink_to_show
  lda player_shrink
  sta shrink_to_scale
  lda player_frame
  sta frame_to_scale
:
  ; Now push this stuff to video memory
  lda nmis
vw3:
  cmp nmis
  beq vw3
  
  ; Copy the display list from main RAM to the PPU.
  ; Do sprites and palette first, then the background.
  lda #0
  sta PPUMASK
  sta OAMADDR
  lda #>OAM
  sta OAM_DMA

  ; Copy to backgrounds
  lda scale_dst
  jsr copy_scale
  
  ; Turn the screen on
  ldx #0
  ldy #0
  lda #VBLANK_NMI|BG_0000|OBJ_1000
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
  .byt $22,$18,$28,$38,$0F,$06,$16,$26,$0F,$08,$19,$2A,$0F,$02,$12,$22
  .byt $22,$08,$16,$37,$0F,$06,$16,$26,$0F,$0A,$1A,$2A,$0F,$02,$12,$22

.segment "CODE"

.proc load_chr
src = 0
  sta src+1
  sty src
  ldy #0
loop:
  lda (src),y
  sta PPUDATA
  iny
  bne loop
  inc src+1
  dex
  bne loop
  rts
.endproc

.proc draw_bg
  ; Start by clearing the first nametable
  ldx #$20
  lda #$00
  ldy #$AA
  jsr ppu_clear_nt

  ; Draw a floor
  lda #$23
  sta PPUADDR
  lda #$00
  sta PPUADDR
  lda #$0B
  ldx #32
floorloop1:
  sta PPUDATA
  dex
  bne floorloop1
  
  ; Draw areas buried under the floor as solid color
  ; (I learned this style from "Pinobee" for GBA.  We drink Ritalin.)
  lda #$01
  ldx #5*32
floorloop2:
  sta PPUDATA
  dex
  bne floorloop2

  ; Draw blocks on the sides, in vertical columns
  lda #VBLANK_NMI|VRAM_DOWN
  sta PPUCTRL
  
  ; At position (2, 20) (VRAM $2282) and (28, 20) (VRAM $229C),
  ; draw two columns of two blocks each, each block being 4 tiles:
  ; 0C 0D
  ; 0E 0F
  ldx #2

colloop:
  lda #$22
  sta PPUADDR
  txa
  ora #$80
  sta PPUADDR

  ; Draw $0C $0E $0C $0E or $0D $0F $0D $0F depending on column
  and #$01
  ora #$0C
  ldy #4
tileloop:
  sta PPUDATA
  eor #$02
  dey
  bne tileloop

  ; Columns 2, 3, 28, and 29 only  
  inx
  cpx #4  ; Skip columns 4 through 27
  bne not4
  ldx #28
not4:
  cpx #30
  bcc colloop

  ; The attribute table elements corresponding to these stacks are
  ; (0, 5) (VRAM $23E8) and (7, 5) (VRAM $23EF).  Set them to 0.
  ldx #$23
  lda #$E8
  ldy #$00
  stx PPUADDR
  sta PPUADDR
  sty PPUDATA
  lda #$EF
  stx PPUADDR
  sta PPUADDR
  sty PPUDATA

  rts
.endproc


; constants used by move_player
; PAL frames are about 20% longer than NTSC frames.  So if you make
; dual NTSC and PAL versions, or you auto-adapt to the TV system,
; you'll want PAL velocity values to be 1.2 times the corresponding
; NTSC values, and PAL accelerations should be 1.44 times NTSC.
WALK_SPD = 100   ; speed limit in 1/256 px/frame
WALK_ACCEL = 4  ; movement acceleration in 1/256 px/frame^2
WALK_BRAKE = 8  ; stopping acceleration in 1/256 px/frame^2

.proc move_player

  ; Acceleration to right: Do it only if the player is holding right
  ; on the Control Pad and has a nonnegative velocity.
  lda cur_keys
  and #KEY_RIGHT
  beq notRight
  lda player_dxlo
  bmi notRight
  
  ; Right is pressed.  Add to velocity, but don't allow velocity
  ; to be greater than the maximum.
  clc
  adc #WALK_ACCEL
  cmp #WALK_SPD
  bcc :+
  lda #WALK_SPD
:
  sta player_dxlo
  lda player_facing  ; Set the facing direction to not flipped 
  and #<~$40         ; turn off bit 6, leave all others on
  sta player_facing
  jmp doneRight

  ; Right is not pressed.  Brake if headed right.
notRight:
  lda player_dxlo
  bmi doneRight
  cmp #WALK_BRAKE
  bcs notRightStop
  lda #WALK_BRAKE+1  ; add 1 to compensate for the carry being clear
notRightStop:
  sbc #WALK_BRAKE
  sta player_dxlo
doneRight:

  ; Acceleration to left: Do it only if the player is holding left
  ; on the Control Pad and has a nonpositive velocity.
  lda cur_keys
  and #KEY_LEFT
  beq notLeft
  lda player_dxlo
  beq :+
  bpl notLeft
:

  ; Left is pressed.  Add to velocity.
  lda player_dxlo
  sec
  sbc #WALK_ACCEL
  cmp #256-WALK_SPD
  bcs :+
  lda #256-WALK_SPD
:
  sta player_dxlo
  lda player_facing  ; Set the facing direction to flipped
  ora #$40
  sta player_facing
  jmp doneLeft

  ; Left is not pressed.  Brake if headed left.
notLeft:
  lda player_dxlo
  bpl doneLeft
  cmp #256-WALK_BRAKE
  bcc notLeftStop
  lda #256-WALK_BRAKE
notLeftStop:
  adc #8-1
  sta player_dxlo
doneLeft:

  ; In a real game, you'd respond to A, B, Up, Down, etc. here.

  ; Move the player by adding the velocity to the 16-bit X position.
  lda player_dxlo
  bpl player_dxlo_pos
  ; if velocity is negative, subtract 1 from high byte to sign extend
  dec player_xhi
player_dxlo_pos:
  clc
  adc player_xlo
  sta player_xlo
  lda #0          ; add high byte
  adc player_xhi
  sta player_xhi

  ; Test for collision with side walls
  cmp #28
  bcs notHitLeft
  lda #28
  sta player_xhi
  lda #0
  sta player_dxlo
  beq doneWallCollision
notHitLeft:
  cmp #212
  bcc notHitRight
  lda #211
  sta player_xhi
  lda #0
  sta player_dxlo
notHitRight:
doneWallCollision:
  
  ; Animate the player
  ; If stopped, freeze the animation on frame 0
  lda player_dxlo
  bne notStop1
  lda #$C0
  sta player_frame_sub
  lda #0
  beq have_player_frame
notStop1:

  ; Take absolute value of velocity (negate it if it's negative)
  bpl player_animate_noneg
  eor #$FF
  clc
  adc #1
player_animate_noneg:

  lsr a  ; Multiply abs(velocity) by 5/16
  lsr a
  sta 0
  lsr a
  lsr a
  adc 0

  ; And 16-bit add it to player_frame, mod $600  
  adc player_frame_sub
  sta player_frame_sub
  lda player_frame
  adc #0  ; add only the carry
  cmp #8  ; frame 0: still; 1-7: scooting
  bcc have_player_frame
  lda #1
have_player_frame:
  sta player_frame
  rts
.endproc

.proc move_shrink
  lda cur_keys
  and #KEY_UP
  beq notUp
  lda player_shrink
  beq notUp
  dec player_shrink
notUp:

  lda cur_keys
  and #KEY_DOWN
  beq notDown
  inc player_shrink
  bne notDown
  dec player_shrink
notDown:

  rts
.endproc

;;
; Draws the player's character to the display list as six sprites.
; In the template, we don't need to handle half-offscreen actors,
; but a scrolling game will need to "clip" sprites (skip drawing the
; parts that are offscreen).
.proc draw_player_sprite
draw_y = 0
cur_tile = 1
x_add = 2         ; +8 when not flipped; -8 when flipped
draw_x = 3
rows_left = 4
row_first_tile = 5
draw_x_left = 7

  lda #3
  sta rows_left
  
  ; In platform games, the Y position is often understood as the
  ; bottom of a character because that makes certain things related
  ; to platform collision easier to reason about.  Here, the
  ; character is 24 pixels tall, and player_yhi is the bottom.
  ; On the NES, sprites are drawn one scanline lower than the Y
  ; coordinate in the OAM entry (e.g. the top row of pixels of a
  ; sprite with Y=8 is on scanline 9).  But in a platformer, it's
  ; also common practice to overlap the bottom row of a sprite's
  ; pixels with the top pixel of the background platform that they
  ; walk on to suggest depth in the background.
  lda player_yhi
  sec
  sbc #24
  sta draw_y

  ; set up increment amounts based on flip value
  ; A: actual X coordinate of first sprite
  ; X: distance to move (either 8 or -8)
  lda player_xhi
  ldx #8
  bit player_facing
  bvc not_flipped
  clc
  adc #8
  ldx #(256-8)
not_flipped:
  sta draw_x_left
  stx x_add

  ; the eight frames start at $10, $12, ..., $1E
  ; 0: still; 1-7: scooting
  lda player_frame
  asl a
  ora #$10
  sta row_first_tile
  
  ; frame 7 is special: the player needs to be drawn 1 unit forward
  ; because of how far he's leaned forward
  lda player_frame
  cmp #7
  bcc not_frame_7
  
  ; here, carry is set, so anything you add will get another 1
  ; added to it, so subtract 1 when constructing the value to add
  ; to the player's X position
  lda #1 - 1  ; facing right: move forward by 1
  bit player_facing
  bvc f7_not_flipped
  lda #<(-1 - 1)  ; facing left: move left by 1
f7_not_flipped:
  adc draw_x_left
  sta draw_x_left
not_frame_7:

  ldx oam_used
rowloop:
  ldy #2              ; Y: remaining width on this row in 8px units
  lda row_first_tile
  sta cur_tile
  lda draw_x_left
  sta draw_x
tileloop:

  ; draw an 8x8 pixel chunk of the character using one entry in the
  ; display list
  lda draw_y
  sta OAM,x
  lda cur_tile
  inc cur_tile
  sta OAM+1,x
  lda player_facing
  sta OAM+2,x
  lda draw_x
  sta OAM+3,x
  clc
  adc x_add
  sta draw_x
  
  ; move to the next entry of the display list
  inx
  inx
  inx
  inx
  dey
  bne tileloop

  ; move to the next row, which is 8 scanlines down and on the next
  ; row of tiles in the pattern table
  lda draw_y
  clc
  adc #8
  sta draw_y
  lda row_first_tile
  clc
  adc #16
  sta row_first_tile
  dec rows_left
  bne rowloop

  stx oam_used
  rts
.endproc

.proc draw_scaled_sprite
xwhole = $03
xfrac = $04
dxwhole = $05
dxfrac = $06
colno = $07

  lda #$80
  sta xfrac
  asl a  ; A is 0 and carry is set
  sta colno
  
  ; how close are the columns?
  rol a  ; A is 1
  sta dxwhole
  lda #$FF
  eor shrink_to_show
  asl a
  rol dxwhole
  asl a
  rol dxwhole
  sta dxfrac
  ldx #112
  stx xwhole
loop:
  lda nmis
  and #$04
  ora colno
  asl a
  asl a
  asl a
  asl a
  ora #$80
  ldy #95
  jsr draw_scaled_col_3y
  clc
  lda xfrac
  adc dxfrac
  sta xfrac
  lda xwhole
  adc dxwhole
  sta xwhole
  inc colno
  lda colno
  cmp #4
  bcc loop
  rts
.endproc

.proc draw_scaled_col
  stx $03
.endproc
.proc draw_scaled_col_3y
sy = $00
tileno = $01
rowsleft = $02
sx = $03

  sta tileno
  sty sy
  lda #6
  sta rowsleft

  ldx oam_used
loop:
  lda sy
  sta OAM,x
  inx
  clc
  adc #8
  sta sy
  lda tileno
  inc tileno
  sta OAM,x
  inx
  lda #0
  sta OAM,x
  inx
  lda sx
  sta OAM,x
  inx
  dec rowsleft
  bne loop
  stx oam_used
  rts
.endproc

; Include data to be copied to CHR RAM
.segment "RODATA"
bggfx:
  .incbin "obj/nes/bggfx.chr"
bggfx_end:
spritegfx:
  .incbin "obj/nes/spritegfx.chr"
spritegfx_end:
tiles_to_scale:
  .incbin "obj/nes/swinging2x2g48.chr"

