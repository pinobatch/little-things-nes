;
; Simple sprite demo for NES
; Copyright 2011 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in any source
; code copies.  This file is offered as-is, without any warranty.
;

.include "nes.inc"
.include "global.inc"

.exportzp cur_keys, new_keys

.segment "ZEROPAGE"
nmis:          .res 1
oam_used:      .res 1  ; starts at 0
cur_keys:      .res 2
new_keys:      .res 2

; Game variables
player_xlo:       .res 1  ; horizontal position is xhi + xlo/256 px
player_xhi:       .res 1
player_dxlo:      .res 1  ; speed in pixels per 256 s
player_yhi:       .res 1
player_facing:    .res 1
player_frame:     .res 1
player_frame_sub: .res 1
mouse_x:          .res 1
mouse_y:          .res 1

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
  lda #16
  sta mouse_x
  sta mouse_y

forever:

  ; Game logic
  jsr move_player
  ; The first entry in OAM (indices 0-3) is "sprite 0".  In games
  ; with a scrolling playfield and a still status bar, it's used to
  ; help split the screen.  This demo doesn't use scrolling, but
  ; yours might, so I'm marking the first entry used anyway.  
  ldx #4
  stx oam_used
  ; adds to oam_used
  jsr draw_player_sprite
  jsr draw_mouse_pointer
  ldx oam_used
  jsr ppu_clear_oam



  jsr read_pads

  ldx #1
  jsr read_mouse
  lda 2
  bpl :+
  eor #$7F
  clc
  adc #1
:
  clc
  adc mouse_y
  sta mouse_y
  lda 3
  bpl :+
  eor #$7F
  clc
  adc #1
:
  clc
  adc mouse_x
  sta mouse_x
  
  lda new_keys
  and #KEY_B
  beq :+
  ldx #1
  jsr mouse_change_sensitivity
:

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
  lda #$21
  sta PPUADDR
  lda #$08
  sta PPUADDR
  lda #VBLANK_NMI
  sta PPUCTRL
  jsr puthex03
  
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
  .byt $22,$08,$15,$27,$0F,$0F,$0F,$20,$0F,$0A,$1A,$2A,$0F,$02,$12,$22

.segment "CODE"

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
WALK_SPD = 105  ; speed limit in 1/256 px/frame
WALK_ACCEL = 4  ; movement acceleration in 1/256 px/frame^2
WALK_BRAKE = 8  ; stopping acceleration in 1/256 px/frame^2

LEFT_WALL = 32
RIGHT_WALL = 224

;;
; Moves the player character in response to controller 1.
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
  notRight:

    ; Right is not pressed.  Brake if headed right.
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
  beq isLeft
    bpl notLeft
  isLeft:

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
  cmp #LEFT_WALL-4
  bcs notHitLeft
    lda #LEFT_WALL-4
    sta player_xhi
    lda #0
    sta player_dxlo
    beq doneWallCollision
  notHitLeft:

  cmp #RIGHT_WALL-12
  bcc notHitRight
    lda #RIGHT_WALL-13
    sta player_xhi
    lda #0
    sta player_dxlo
  notHitRight:

  ; Additional checks for collision, if needed, would go here.
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

  lsr a  ; Multiply abs(velocity) by 5/16 cels per pixel
  lsr a
  sta 0
  lsr a
  lsr a
  adc 0

  ; And 16-bit add it to player_frame, modulo $700 (7 cels per cycle)
  adc player_frame_sub
  sta player_frame_sub
  lda player_frame
  adc #0  ; add only the carry

  ; Wrap from $800 (after last frame of walk cycle)
  ; to $100 (first frame of walk cycle)
  cmp #8  ; frame 0: still; 1-7: scooting
  bcc have_player_frame
    lda #1
  have_player_frame:

  sta player_frame
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
  tay
  asl a
  ora #$10
  sta row_first_tile

  ; Correct for each cel's horizontal hotspot offset
  bit player_facing
  lda player_frame_to_xoffset,y
  ; clc  ; set by previous ASL A
  bvc xoffset_not_flipped
    eor #$FF
    sec
  xoffset_not_flipped:
  adc draw_x_left
  sta draw_x_left

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

.pushseg
.rodata
; In frame 7, the player needs to be drawn 1 pixel forward
; because of how far he's leaned forward
player_frame_to_xoffset:
  .byte 0, 0, 0, 0, 0, 0, 0, 1
.popseg
.endproc

;;
; Draws the mouse pointer.
.proc draw_mouse_pointer
draw_x = 3
draw_y = 0

  lda mouse_y
  sec
  sbc #2
  sta draw_y
  lda mouse_x
  sec
  sbc #1
  sta draw_x

  ldx oam_used
  ; set Y coord
  lda mouse_y
  sec
  sbc #2
  sta OAM+0,x
  sta OAM+4,x
  clc
  adc #8
  sta OAM+8,x
  sta OAM+12,x

  ; set X coord
  lda mouse_x
  sec
  sbc #1
  sta OAM+3,x
  sta OAM+11,x
  clc
  adc #8
  sta OAM+7,x
  sta OAM+15,x

  ; set shape  
  lda #$0C
  sta OAM+1,x
  lda #$0D
  sta OAM+5,x
  lda #$0E
  sta OAM+9,x
  lda #$0F
  sta OAM+13,x
  
  ; set attr
  lda #$01
  sta OAM+2,x
  sta OAM+6,x
  sta OAM+10,x
  sta OAM+14,x
  
  txa
  clc
  adc #16
  sta oam_used
  rts
.endproc

.proc puthex03
  ldx #0
byteloop:
  lda 0,x
  lsr a
  lsr a
  lsr a
  lsr a
  jsr xdigit
  lda 0,x
  and #$0F
  jsr xdigit
  inx
  cpx #4
  bcc byteloop
  rts
xdigit:
  cmp #10
  bcc notletter
  adc #'A'-'9'-2
notletter:
  adc #'0'
  sta PPUDATA
  rts
.endproc

.segment "CHR"
.incbin "obj/nes/bggfx.chr"
.incbin "obj/nes/spritegfx.chr"
