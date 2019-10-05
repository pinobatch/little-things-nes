;
; nibbles.asm
; Main source for Nibbles
;
;
; Copyright 2001 Damian Yerrick
;
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either version 2
; of the License, or (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to 
;   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;   Boston, MA  02111-1307, USA.
; GNU licenses can be viewed online at http://www.gnu.org/copyleft/
; 
; Visit http://www.pineight.com/ for more information.
;






.mem 8
.index 8
.list


.org $c000

ppuctrl = $2000
ppumask = $2001
ppustatus = $2002
spraddr = $2003
ppuscroll = $2005
ppuaddr = $2006
ppudata = $2007


sprdma = $4014
sndchn = $4015
joypads = $4016


tile_apple = 13
tile_wall = 30
tile_star = 42


playfield = $400

STAR_SPACING = 44
STAR_SPEED = 4


rndl = 20
rndh = 21
sound_ptr = 22
sound_delay = 24
apple_value = 25
need_apple = 26
apples_left = 27
cur_level = 28
game_speed = 29
nPlayers = 30
curTurn = 31
pad1 = 32
pad2 = 33
lastpad1 = 34
lastpad2 = 35
pressed1 = 36
pressed2 = 37
pressed_dir = 38
lives = 40
snake_dead = 42
snake_subtile = 44

target_len = 60
snake_len = 62
xes = 64
yes = 128
dirs = 192



DIR_EAST = 0
DIR_NORTH = 1
DIR_WEST = 2
DIR_SOUTH = 3

MAX_SNAKE_LEN = 31
INIT_SNAKE_LEN = 3
APPLES_PER_LEVEL = 8

  




.pad $f000      ;this game uses only 8K! (4K rom 4K vrom)

copr_pkb
  .incbin "copr.pkb"

.dcb "  main  "
crt0_startup
  sei
  cld
  lda #$c0      ;initialize interrupt controller
  sta $4017

  ldx #0        ;initialize PPU
  stx ppumask
  stx ppuctrl
  dex           ;initialize stack
  txs
  jsr wait4vbl

  lda #1        ;initialize 2A03 PSG
  sta sndchn
  ldx #0
  stx sndchn

  ;clear RAM
-
  lda #0
  sta 0,x       ;clear all CPU RAM to 0
  sta $100,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  lda #$ef      ;except for sprite DMA buffer,
  sta $200,x    ;which is cleared to "hide me"
  inx
  bne -

  jsr wait4vbl  ;after two VBLs the PPU should be warmed up
  jsr copy_spr

  ;clear unused 2nd nametable (so its RAM doesn't act up)
  lda #$2c
  sta ppuaddr
  ldx #0
  stx ppuaddr
  lda #$10
-
  sta ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  inx
  bne -

  lda #1
  sta nPlayers

  lda #0
  sta ppumask

  lda #$3f      ;Copy the palette into PPU $3f00.
  sta ppuaddr
  ldx #0
  stx ppuaddr
-
  lda nibpal,x
  sta ppudata
  inx
  lda nibpal,x
  sta ppudata
  inx
  cpx #$20
  bne -

  ; Unpack the copyright screen into PPU $2000.
  lda #0
  sta ppumask
  lda #<copr_pkb
  sta 0
  lda #>copr_pkb
  sta 1
  lda #$20
  sta ppuaddr
  lda #0
  sta ppuaddr
  jsr PKB_unpackblk
  lda #0
  sta ppuctrl
  sta ppuscroll
  sta ppuscroll
  lda #%00001010 ;bg no sprites
  sta ppumask
  jsr wait4start


title_entry
  lda #0
  sta ppumask
  ; Unpack the title screen into PPU $2000.
  lda #<title_pkb
  sta 0
  lda #>title_pkb
  sta 1
  lda #$20
  sta ppuaddr
  lda #0
  sta ppuaddr
  jsr PKB_unpackblk

  lda #8
  sta 2

  lda #1
  sta rndl
  sta rndh

  lda #<boot_snd
  sta sound_ptr
  lda #>boot_snd
  sta sound_ptr+1
  lda #0
  sta sound_delay
  
title_loop
  lda 2
  clc
  adc #STAR_SPEED
  cmp #STAR_SPACING + 8
  bcc +
  sbc #STAR_SPACING
+
  sta 2
  tay
  ldx #4        ;reserve one sprite for arrow

  jsr do_stars
  lda #13
  jsr sound_mgr

  jsr wait4vbl
  lda #0
  sta ppumask
  jsr copy_spr
  lda #0
  sta ppuscroll
  sta ppuscroll
  sta ppuctrl
  lda #%00011110
  sta ppumask
  jsr read_pads
  lda pressed1
  and #%10010000        ;pressed A or Start
  bne +

  jmp title_loop
+
  lda #0
  sta cur_level
  lda #5
  sta lives
  sta lives + 1

play_level
  lda cur_level
  jsr load_level
  jsr sound_mgr
  lda #0
  sta ppumask
  lda #1
  sta need_apple
  sta apple_value
  lda #APPLES_PER_LEVEL
  sta apples_left
  lda #0
  sta curTurn
-
  jsr reset_snake
  inc curTurn
  lda curTurn
  cmp nPlayers
  bcc -

  lda #48
  sta game_speed
  ;overlap subtiles so as not to run both players in one vbl
  lda #128
  sta snake_subtile+1
  lda #0
  sta snake_subtile
  sta curTurn

  jsr game_paused
  lda #<level_snd
  sta sound_ptr
  lda #>level_snd
  sta sound_ptr+1
  lda #0
  sta sound_delay
  
game_loop
  jsr wait4vbl
  lda #0
  sta ppumask
  sta ppuctrl
  lda need_apple
  beq +
  jsr make_apple
+
  sta curTurn
-
  jsr move_snake
  inc curTurn
  lda curTurn
  cmp nPlayers
  bcc -
  lda #0
  sta ppuctrl
  sta ppuscroll
  sta ppuscroll
  sta curTurn
  lda #%00001010
  sta ppumask
  jsr read_pads
  lda pressed1
  and #%00010000
  beq +
  jsr game_paused
+
  jsr sound_mgr
-
  jsr control_snake
  inc curTurn
  lda curTurn
  cmp nPlayers
  bcc -

  lda snake_dead
  ora snake_dead+1
  beq +
  
  lda #<die_snd
  sta sound_ptr
  lda #>die_snd
  sta sound_ptr+1
  lda #0
  sta sound_delay
  
  jmp play_level
+
  lda snake_dead+1
  beq +
  
  lda #<die_snd
  sta sound_ptr
  lda #>die_snd
  sta sound_ptr+1
  lda #0
  sta sound_delay
  
  jmp play_level
+


  lda apples_left
  beq +
  jmp game_loop
+
  inc cur_level
  lda cur_level
  cmp #20
  bcs +
  jmp play_level
+
  lda #0
  sta cur_level
  lda game_speed
  adc #24
  bcs +
  sta game_speed
+
  jmp play_level








game_paused
  ; display "Press Start"
  ldx #0
-
  lda press_start_spr,x
  sta $200,x
  inx
  lda press_start_spr,x
  sta $200,x
  inx
  cpx #32
  bne -
  jsr clr_spr
  jsr copy_spr

  jsr wait4vbl
  lda #0
  sta ppuctrl
  sta ppuscroll
  sta ppuscroll
  lda #%00011110
  sta ppumask

wait4start
-
  jsr wait4vbl
  jsr read_pads
  jsr sound_mgr
  lda pressed1
  and #%10010000
  beq -
  rts

.pad $f700

boot_snd
  .dcb 13,10,0,2
  .dcb 15,10,0,2
  .dcb 17,10,0,2
  .dcb 15,10,0,2
  .dcb 13,10,0,2
  .dcb 15,10,0,2
  .dcb 17,20,0,4
  .dcb 13,20,0,4
  .dcb 13,20,0,4
  .dcb 0,0

level_snd
  .dcb 25, 5,0,1
  .dcb 27, 5,0,1
  .dcb 29, 5,0,1
  .dcb 27, 5,0,1
  .dcb 25, 5,0,1
  .dcb 27, 5,0,1
  .dcb 29,10,0,2
  .dcb 25,10,0,2
  .dcb 25,10,0,2
  .dcb 0,0

apple_snd
  .dcb 13,5,0,1
  .dcb 13,5,0,1
  .dcb 13,5,0,1
  .dcb 17,5,0,1
  .dcb 0,0

die_snd
  .dcb 5,3,6,3,8,3,6,3,5,3,3,3,1,3,0,0



.pad $f800
.dcb "make_apple"
;
; make_apple
; Place an apple at a random unoccupied place on the screen.
; Must be called with screen off.
; Returns: A = 0
;
make_apple
  jsr rand
  and #$1f      ;x coord: 0 to 31
  tay
  jsr rand
  and #$1f      ;y coord: 5 to 27
  cmp #23
  bcc +
  sbc #16
+
  clc
  adc #5
  jsr gototile
  lda ppudata
  lda ppudata
  bne make_apple
  lda 1
  sta ppuaddr
  lda 0
  sta ppuaddr
  lda #tile_apple
  sta ppudata
  lda #0
  dec need_apple
  rts


.pad $f880
freqs_lo
  .incbin "nibb_tab.bin"
freqs_hi = freqs_lo + 64

sound_note
  cmp #0
  bne +
  lda #0
  sta $4015
  rts
+
  tax
  dex
  lda #1
  sta $4015
  lda freqs_lo,x
  sta $4002
  lda freqs_hi,x
  sta $4003
  lda #8
  sta $4001
  lda #$bc
  sta $4000
  lda #1
  sta $4015
  rts


sound_mgr
  lda sound_delay       ;are we even playing a sound?
  bpl +
  rts
+
  bne ++                ;is a note still ringing?
+
  ldy #0
  lda (sound_ptr),y
  inc sound_ptr
  bne +
  inc sound_ptr+1
+
  jsr sound_note
  lda (sound_ptr),y
  inc sound_ptr
  bne +
  inc sound_ptr+1
+
  sta sound_delay
++
  dec sound_delay
  rts


reset_snake
  ldy #2
  ldx curTurn
  beq +
  ldy #29
+
-
  sty xes,x
  lda #0
  sta yes,x
  lda #DIR_SOUTH
  sta dirs,x
  inx
  inx
  cpx #MAX_SNAKE_LEN*2
  bcc -
  ldx curTurn
  lda #0
  sta snake_dead,x
  lda #INIT_SNAKE_LEN
  sta snake_len,x
  sta target_len,x
  lda #5
  sta yes,x
  lda #DIR_SOUTH
  sta pressed_dir,x

  rts


;
; control_snake
; Takes a joypad and maps it to a snake's direction.
;
control_snake
  ldx curTurn
  lda pressed1,x

  ;check for RIGHT arrow
  lsr a
  bcc +
  ldy dirs,x
  cpy #DIR_WEST
  beq +
  ldy #DIR_EAST
  sty pressed_dir,x
  rts
+  
  ;check for LEFT arrow
  lsr a
  bcc +
  ldy dirs,x
  cpy #DIR_EAST
  beq +
  ldy #DIR_WEST
  sty pressed_dir,x
  rts
+  
  ;check for DOWN arrow
  lsr a
  bcc +
  ldy dirs,x
  cpy #DIR_NORTH
  beq +
  ldy #DIR_SOUTH
  sty pressed_dir,x
  rts
+  
  ;check for UP arrow
  lsr a
  bcc +
  ldy dirs,x
  cpy #DIR_SOUTH
  beq +
  ldy #DIR_NORTH
  sty pressed_dir,x
  rts
+  
  rts


;
; rand
; Generates a (not very) random number.
; By Andrew Davie.
;
rand
  lda rndl
  lsr a
  lsr a
  sbc rndl
  lsr a
  ror rndh
  ror rndl
  lda rndl
  rts


.pad $fa00

;
; move_snake
; Move a snake forward a unit.
;
move_snake
  ldx curTurn
  lda snake_dead,x
  beq +
  rts
+
  lda snake_subtile,x   ;do we even have a turn coming?
  clc
  adc game_speed
  sta snake_subtile,x
  bcs +
  rts
+
  ldy xes,x
  lda yes,x
  jsr gototile
  lda dirs,x
  asl a
  asl a
  ora pressed_dir,x
  tay
  lda midsec_tiles,y
  ora curTurn
  sta ppudata

  ;erase the old tail and draw the new tail
  ;but DON'T draw on y=0 as that's a flag meaning
  ;"the snake has just extended itself"

  ;erase the old tail
  lda snake_len,x
  asl a
  ora curTurn
  tax

  lda target_len
  cmp snake_len
  beq +
  inc snake_len
  jmp no_erase_tail
+
  dex
  dex
  ldy xes,x
  lda yes,x
  beq no_erase_tail     ;don't draw on line 0
  jsr gototile
  lda #0
  sta ppudata
+
no_erase_tail
  ;draw the new tail
  dex
  dex
  ldy xes,x
  lda yes,x
  beq +
  jsr gototile
  ldy dirs-2,x
  lda tail_tiles,y
  ora curTurn
  sta ppudata
+
  ;move all snake parts one tile back
-
  lda xes,x
  sta xes+2,x
  lda yes,x
  sta yes+2,x
  lda dirs,x
  sta dirs+2,x
  dex
  dex
  bpl -


  ;move the snake
  ldx curTurn
  lda yes,x
  ldy pressed_dir,x
  clc
  adc dir_sine,y
  sta yes,x

  ldx curTurn
  lda xes,x
  ldy pressed_dir,x
  clc
  adc dir_cosine,y
  sta xes,x
  tay
  lda yes,x
  jsr gototile
  lda ppudata
  lda ppudata
  beq snake_ok

  cmp #tile_apple       ;check for eating an apple
  bne +

  lda #<apple_snd
  sta sound_ptr
  lda #>apple_snd
  sta sound_ptr+1
  lda #0
  sta sound_delay
  
  lda target_len,x
  clc
  adc apple_value
  sta target_len,x
  inc apple_value

  inc need_apple
  dec apples_left
  jmp snake_ok
+
  lda 1
  sta snake_dead,x
  rts
snake_ok
  lda 1
  sta ppuaddr
  lda 0
  sta ppuaddr
  ldy pressed_dir,x
  sty dirs,x
  lda head_tiles,y
  ora curTurn
  sta ppudata

  rts


.pad $fb00
;
; load_level
; Load a level from VROM into RAM and then into VRAM.
; a  Level number minus 1 (0 to 19)
;
; The levels are stored in VROM as 1-bit tiles in this order:
;   0 3 6 9
;   1 4 7 A   This order is easy to read with Pin Eight TilEd by
;   2 5 8 B   setting the Tile Pitch to 3 with the + key.
; The top, left, and right side of levels in VROM is always binary
; 1, meaning wall.  Level 1 is stored starting at location $0880;
; each level takes 96 bytes.
;
; The playfield is stored in RAM $400-$7FF by row.  Row 29 is blank.
; Rows 0 to 3 contain player score information.  Rows 4 and 28 are
; all walls, leaving rows 5 to 27 as the actual playfield.
;
load_level
  and #$1f      ;multiply level number by 3
  sta 0
  asl a
  adc 0
  sta 0
  lda #0
  sta ppumask
  lsr 0         ;multiply by 32
  ror a
  lsr 0
  ror a
  lsr 0
  ror a
  adc #$80
  tax           ;x contains the low byte
  lda 0
  adc #$08      ;and a contains the high byte of ppuaddr
  sta ppuaddr   ;initialize read stream
  stx ppuaddr
  ldx ppudata
  ldx #0        ;first strip is columns 0-7
  stx 4

load_level_strip
  lda 4         ;set up destination address
  ora #$80      ;levels start on row 4
  sta 0
  lda #4
  sta 1
  lda #24       ;2 = number of rows left in this strip
  sta 2
load_level_byte
  ldy #0
  lda ppudata   ;pull a byte from VROM
  sta 3
load_level_bit
  asl 3
  bcc +
  lda #tile_wall
  bne ++
+
  lda #0        ;empty tile
++
  sta (0),y
  iny
  cpy #8
  bcc load_level_bit

  lda 0         ;move to next row within this strip
  adc #31       ;31, plus a Carry (32 bytes per row)
  sta 0
  bcc +
  inc 1
+
  dec 2
  bne load_level_byte

  lda 4         ;advance to next strip
  clc
  adc #8
  sta 4
  cmp #32
  bcc load_level_strip

  ;create the south wall
  ldx #31
  lda #tile_wall
-
  sta $780,x
  dex
  sta $780,x
  dex
  bpl -

  jsr sound_mgr

  ;now copy it into RAM
  ldx #4
  stx 1
  ldy #0
  sty 0
  lda #$20
  sta ppuaddr
  lda #0
  sta ppuaddr
-
  lda (0),y
  sta ppudata
  iny
  lda (0),y
  sta ppudata
  iny
  bne -
  inc 1
  dex
  bne -

  rts


;
; gototile
; set the PPU port address to (Y, A)
; 57 cycles
;
gototile
  sta 1
  lda #0
  lsr 1
  ror a
  lsr 1
  ror a
  lsr 1
  ror a
  sta 0
  lda 1
  ora #$20
  sta 1
  sta ppuaddr
  tya
  ora 0
  sta 0
  sta ppuaddr
  rts


.pad $fbe0
press_start_spr
  .dcb $6f,$78,$03,$70
  .dcb $6f,$7A,$03,$78
  .dcb $6f,$7C,$03,$80
  .dcb $6f,$7E,$03,$88
  .dcb $7f,$79,$03,$70
  .dcb $7f,$7B,$03,$78
  .dcb $7f,$7D,$03,$80
  .dcb $7f,$7F,$03,$88


;
; PKB_unpackblk
; Unpack PackBits() encoded data from memory at ($00) to a character
; device such as the NES PPU data register.
;
.incsrc "unpkb.asm"

;
; The title screen packs down to about 384 to 512 bytes;
; there is little performance gain by page-aligning it.
;
title_pkb
  .incbin "title.pkb"



.pad $fe00

;
; Data tables
;

; Palettes
nibpal
  .dcb $02,$38,$24,$26,$02,$12,$22,$32,$02,$12,$22,$32,$02,$12,$22,$32
  .dcb $02,$38,$24,$26,$02,$12,$22,$32,$02,$12,$22,$32,$02,$12,$22,$32

; Midsection tiles:
midsec_tiles
;to...  E   N   W   S
  .dcb $10,$1A,$01,$16 ;00: eastward to...
  .dcb $14,$12,$16,$01 ;01: northward to...
  .dcb $01,$18,$10,$14 ;10: westward to...
  .dcb $18,$01,$1A,$12 ;11: southward to...
tail_tiles
  .dcb $66,$60,$64,$62
head_tiles
  .dcb $6E,$68,$6C,$6A

; Direction sines and cosines
; How far along each axis is one step in a given direction?
dir_sine
  .dcb 0, $ff, 0, 1
dir_cosine
  .dcb 1, 0, $ff, 0

.pad $fe60
;
; do_stars
; Set up sprites for stars animation in title screen.
; x = offset in sprite table of first star
; y = x-location screen of first star (8 <= y < 8 + STAR_SPACING)
;
do_stars
-
  lda #15       ;starts at y = 16
  sta $200,x
  inx
  lda #tile_star
  sta $200,x
  inx
  lda #0        ;no flip
  sta $200,x
  inx
  tya
  sta $200,x
  inx
  cmp #240-STAR_SPACING
  bcs +
  adc #STAR_SPACING
  tay
  jmp -

+
  sbc #(240-STAR_SPACING-15)
  tay
-
  tya           ;x position
  sta $200,x
  inx
  lda #tile_star
  sta $200,x
  inx
  lda #0        ;no flip
  sta $200,x
  inx
  lda #240      ;x = 240
  sta $200,x
  inx
  tya
  cmp #223-STAR_SPACING
  bcs +
  adc #STAR_SPACING
  tay
  jmp -
+
  eor #$ff
  clc
  adc #(240+224-STAR_SPACING - 256)
  tay
-
  lda #223      ;starts at y = 224
  sta $200,x
  inx
  lda #tile_star
  sta $200,x
  inx
  lda #0        ;no flip
  sta $200,x
  inx
  tya
  sta $200,x
  inx
  cmp #8+STAR_SPACING
  bcc +
  sbc #STAR_SPACING
  tay
  jmp -

+
  adc #(223-8-STAR_SPACING)
  tay
-
  tya           ;y coordinate
  sta $200,x
  inx
  lda #tile_star
  sta $200,x
  inx
  lda #0        ;no flip
  sta $200,x
  inx
  lda #8        ;x = 8
  sta $200,x
  inx
  tya
  cmp #15+STAR_SPACING
  bcc clr_spr
  sbc #STAR_SPACING
  tay
  jmp -


;
; clr_spr
; Clear the rest of the sprite table.
; x = first sprite index * 4 to clear
;
clr_spr
  lda #$ef
-
  sta $200,x
  inx
  bne -
  rts


.pad $ff00

;
; wait4vbl
; Waits for the start of a vertical blank.
;
wait4vbl
  bit ppustatus
  bpl wait4vbl
  rts

;
; copy_spr
; Copies sprites from $200 to OAM
;
copy_spr
  lda #0
  sta spraddr
  lda #2
  sta sprdma
  rts

;
; read_pads
;
;

read_pads
  lda pad1
  sta lastpad1
  lda pad2
  sta lastpad2
  ldx #1        ;Strobe joypads
  stx joypads
  dex
  stx joypads
  ldx #8
-
  lda joypads   ;Read each button
  lsr
  rol pad1
  lda joypads+1
  lsr
  rol pad2
  dex
  bne -

  ; Take which keys have been newly pressed since last read.

  lda lastpad1
  eor #$ff
  and pad1
  sta pressed1

  lda lastpad2
  eor #$ff
  and pad2
  sta pressed2

  rts



nmipoint
irqpoint
  rti

.pad $fffa
  .dw nmipoint
  .dw crt0_startup
  .dw irqpoint

.incbin "nibbles.chr"
