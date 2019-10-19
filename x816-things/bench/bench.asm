;
; bench.asm
; test nes emulator compatibility
; copyright 2001 damian yerrick
;
; ported to asm6 in 2019
;

; future tests: 
; sprite 0 hit only when overlapping
; 8 sprites per scanline (both dropout and $2002.d5)
; 


.incbin "header.hdr"
.org $c000

FAIL_TILE       = 4
PASS_TILE       = 8
LED_TILE        = 12
BRICKS_TILE     = 14


; dp ram

pads = $f0

rampal = $3e0


ppuctrl = $2000
ppumask = $2001
ppustatus = $2002
spraddr = $2003
ppuscroll = $2005
ppuaddr = $2006
ppudata = $2007

dmcfreq = $4010
sndraw = $4011
dmcaddr = $4012
dmclen = $4013
sprdma = $4014
sndchn = $4015
joypad1 = $4016
joypad2 = $4017

mainpal
  .dcb $0f,$06,$16,$30, $0f,$06,$16,$30, $0f,$06,$16,$30, $0f,$06,$16,$30
  .dcb $0f,$06,$16,$30, $0f,$1c,$2c,$3c, $0f,$06,$16,$30, $0f,$06,$16,$30

punchthru_window
  ;first a bg window in front of the brick wall
  ;then a bg window in front of a 'fail'
  ;    y   n    ac x     y   n    ac x     y   n    ac x     y   n    ac x
  .dcb 160,  1,$21,119,  160,  1,$21,129,  170,  1,$21,119,  170,  1,$21,129
  .dcb 135,  3,$20,112,  135,  3,$20,120,  135,  3,$20,128,  135,  3,$20,136
  .dcb 135,  4,$00,112,  135,  5,$00,120,  135,  6,$00,128,  135,  7,$00,136

padlines_hi
  .dcb $22,$22,$22,$22,$22,$23,$23,$23
padlines_lo
  .dcb $70,$90,$b0,$d0,$f0,$10,$30,$50

nmipoint
irqpoint
  rti

; Data for load_bgimage

image_directory
  .dcw test_2007d7_data
  .dcw punchthru_data
  .dcw samples_bg_data
  .dcw padtest_bg_data

test_2007d7     = 0
punchthru_bg    = 2
samples_bg      = 4
padtest_bg      = 6



test_2007d7_data
  .incbin "nestc.pkb"
punchthru_data
  .incbin "punch.pkb"
samples_bg_data
  .incbin "samples.pkb"
padtest_bg_data
  .incbin "padtest.pkb"



.dcb 13,10,"=main=",13,10
crt0_startup
  sei
  cld
  lda #$c0      ;initialize interrupt controller
  sta joypad2

  ldx #0        ;initialize PPU
  stx ppumask
  stx ppuctrl
  dex           ;initialize stack
  txs

-               ;wait for vbl
  bit ppustatus
  bpl -

  lda #1        ;initialize 2A03 PSG
  sta sndchn
  ldx #0
  stx sndchn

  ;clear RAM
-
  lda #$ef      ;clear sprite DMA buffer to "hidden"
  sta $200,x
  lda #0        ;clear all other CPU RAM to 0
  sta 0,x
  sta $100,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  inx
  bne -

-               ; copy palette into RAM
  lda mainpal,x
  sta rampal,x
  inx
  cpx #32
  bne -

-               ;after 2 vbls, the ppu should be stable
  bit ppustatus
  bpl -


  ; load initial palette
  jsr copypal

  ;erase sprites
  lda #0
  sta spraddr
  lda #2
  sta sprdma

  ;clear second nametable
  lda #$2c
  sta ppuaddr
  ldx #0
  stx ppuaddr
  lda #32
  ldy #0
  jsr clear_scanlines


  ; NESTICLE detection! ;;;;;;;;;;;;;;;;

  lda #$20
  ldx #test_2007d7
  jsr load_bgimage
  jsr readpads
-
  bit ppustatus         ;wait for a vblank
  bpl -
  bit ppustatus         ;NES clears vblank flag on a read.
  bmi +                 ;NESticle doesn't.
  ldy #PASS_TILE
  jmp nestc_test_result
+
  ldy #FAIL_TILE

nestc_test_result       ;write test result to screen
  lda #$22              ;$228e is 2/3 of the way down the screen
  sta ppuaddr
  lda #$8e
  sta ppuaddr
  sty ppudata
  iny
  sty ppudata
  iny
  sty ppudata
  iny
  sty ppudata

  lda #0
  sta 0         ;x scroll
  sta 1         ;y scroll
  sta 2         ;ctrl
  jsr wait_for_press_a



  ; SPRITE priority: Punchthru ;;;;;;;;;
  lda #0
  sta ppumask

  ;load punchthru bg into first nametable
  lda #$20
  ldx #punchthru_bg
  jsr load_bgimage

  ;load sprites
  ldx #0
-
  lda punchthru_window,x
  sta $200,x
  inx
  cpx #48
  bcc -

  ;make sprite wall
  lda #239
  sta 3

sprwall_loop
  bit ppustatus
  bpl sprwall_loop

  jsr make_spritewall

  lda #0                ;and copy the sprites
  sta spraddr
  lda #2
  sta sprdma

  lda #0
  sta ppuscroll
  sta ppuscroll
  sta ppuctrl
  lda #%10011110
  sta ppumask

  dec 3
  lda 3
  cmp #151
  bcs sprwall_loop

-
  bit ppustatus
  bpl -


  lda #0
  sta 0
  sta 1
  sta 2
  jsr wait_for_press_a

  lda #$ef      ;clear sprite table
  ldx #0
-
  sta $200,x
  inx
  bne -


  ; DIGITAL sample playback ;;;;;;;;;;;;
  lda #0
  sta ppumask

  ;load samples bg into first nametable
  lda #$20
  ldx #samples_bg
  jsr load_bgimage

  lda #0        ;index
  sta 16
  lda #$3e      ; '>'
  sta $201
  lda #$00      ;no flip, front, pal 0
  sta $202
  lda #16       ;x coord
  sta $203

  lda #119
  jsr between_sounds

  ;
  ; Play DMC sound
  ;
  lda #%00000
  sta sndchn
  lda #$0f
  sta dmcfreq
  lda #<(hello_dmc>>6)
  sta dmcaddr
  lda #$7f
  sta dmclen
  lda #$40
  sta sndraw
  lda #%10000
  sta sndchn

  ldy #30
-
  bit ppustatus
  bpl -
  dey
  bne -

  lda #127
  jsr between_sounds

  lda #<hello_nib
  sta 0
  lda #>hello_nib
  sta 1
  lda #8
  sta 2
  jsr play_raw

  lda #135
  jsr between_sounds

  lda #%00001   ;initialize square wave channel $4000
  sta sndchn
  lda #%10111000
  sta $4000
  lda #%00001000
  sta $4001
  lda #10
  sta $4002
  lda #0
  sta $4003

  lda #<hello_nib
  sta 0
  lda #>hello_nib
  sta 1
  lda #8
  sta 2
  lda #$00
  jsr play_am

  lda #143
  jsr between_sounds

  lda #<hello_nib
  sta 0
  lda #>hello_nib
  sta 1
  lda #8
  sta 2
  lda #$40
  jsr play_am

  lda #151
  jsr between_sounds

  lda #<hello_nib
  sta 0
  lda #>hello_nib
  sta 1
  lda #8
  sta 2
  lda #$80
  jsr play_am

  lda #159
  jsr between_sounds

  lda #<hello_nib
  sta 0
  lda #>hello_nib
  sta 1
  lda #8
  sta 2
  lda #$c0
  jsr play_am

  lda #167
  jsr between_sounds

  lda #<hello_nib
  sta 0
  lda #>hello_nib
  sta 1
  lda #8
  sta 2
  jsr play_pwm
 
  lda #$ef
  jsr between_sounds


  ; CONTROLLER test: all eight! ;;;;;;;;
  lda #0
  sta ppumask

  ;load samples bg into first nametable
  lda #$20
  ldx #padtest_bg
  jsr load_bgimage

padtest_loop
  bit ppustatus
  bpl padtest_loop
  ldx #0
-
  lda padlines_hi,x
  sta ppuaddr
  lda padlines_lo,x
  sta ppuaddr
  lda 8,x
  jsr ppuwritebits
  inx
  cpx #8
  bcc -

  lda #0
  sta ppuscroll
  sta ppuscroll
  sta ppuctrl
  lda #%00011110
  sta ppumask

  jsr readallpads
  lda 8
  cmp #$f0
  bne padtest_loop


  jsr readpads          ;prime the A button so wait_for_a_press isn't confused











  ;next test ;;;;;;;;;;;;;;;;;;;;;;;;;;;








  ;end with infinite loop of "blinking toaster"

  lda #0
  sta ppumask
  sta 0

blinking_toaster
  lda #$3f      ;clear out palette
  sta ppuaddr
  lda #0
  sta ppuaddr
  lda 0
  eor #$0d
  sta 0
  ldy #32
-
  sta ppudata
  dey
  bne -

  ldy #60
-
  bit ppustatus
  bpl -
  dey
  bpl -
  bne blinking_toaster

  















; make_spritewall ;;;;;;;;;;;;;;;;;;;;;;
; make a wall of sprites reaching from ([3]+1, 104) to ([3]+48, 151)

make_spritewall
  ;construct sprite wall
  lda 3
  sta 1

  clc           ;48 pixels tall, clipped to the bottom of the screen
  adc #48
  bcc +
  lda #240
+
  sta 2
  ldx #112      ;(64 - 36)*8

spritewall_yloop
  lda #104      ;x position
  sta 0
spritewall_xloop
  lda 1         ;y location
  sta $200,x
  inx
  lda #BRICKS_TILE
  sta $200,x
  inx
  lda #0        ;no flip, front, pal 0
  sta $200,x
  inx
  lda 0         ;x location
  sta $200,x
  inx
  clc
  adc #8
  sta 0
  cmp #152
  bcc spritewall_xloop
  lda 1
  clc
  adc #8
  sta 1
  cmp 2
  bcc spritewall_yloop
  rts



; wait_for_press_a ;;;;;;;;;;;;;;;;;;;;;
; Display "PRESS <A> BUTTON" and wait for an A button press.
; To be called during vblank.
; in: (0, 1) scroll; 2: ctrl

wait_for_press_a
  lda #$23              ;display message
  sta ppuaddr
  lda #$68
  sta ppuaddr
  ldx #15
-
  lda press_a_str,x
  sta ppudata
  dex
  bpl -

  lda 0
  sta ppuscroll
  lda 1
  sta ppuscroll
  lda 2
  sta ppuctrl
  lda #%00011110
  sta ppumask
-                       ;loop: wait for A
  bit ppustatus
  bpl -

  jsr readpads
  lda pads+0            ;player 1 A button
  cmp #1
  bne -
  rts

press_a_str
  .dcb "NOTTUB >A< SSERP"       ;backwards for easier copying



; clear_press_a ;;;;;;;;;;;;;;;;;;;;;;;;
; Hide "PRESS <A> BUTTON" message.
; To be called during vblank.
clear_press_a
  lda #$23              ;location where message was
  sta ppuaddr
  lda #$68
  sta ppuaddr
  ldx #8
  lda #0
-                       ;write blank spaces over it
  sta ppudata
  sta ppudata
  dex
  bne -
  rts



; between_sounds ;;;;;;;;;;;;;;;;;;;;;;;
; Display and then hide 'press a button' between phases of one test.

between_sounds
  bit ppustatus         ;wait for vbl
  bpl between_sounds
-
  bit ppustatus         ;need 2 vbls because it's likely we'll
                        ;catch the very end of one
  bpl -
  sta $200              ;move cursor
  lda #0
  sta ppumask
  sta 0
  sta 1
  sta 2
  sta spraddr
  lda #2
  sta sprdma
  jsr wait_for_press_a
-
  bit ppustatus         ;wait for vbl
  bpl -
  lda #0
  sta ppumask
  jsr clear_press_a
  lda #0                ;fix up screen
  sta ppuctrl
  sta ppuscroll
  sta ppuscroll
  lda #%01011110
  sta ppumask
  rts



; readallpads ;;;;;;;;;;;;;;;;;;;;;;;;;;
; Read ALL EIGHT pads the NES and Famicom can address.

readallpads
  ldx #0
  jsr readallpads_01
  ldx #1
readallpads_01
  ldy #1
  sty joypad1
  dey
  sty joypad1
  ldy #8
-
  lda joypad1,x
  lsr a
  rol 8,x
  lsr a
  rol 12,x
  dey
  bne -
  ldy #8
-
  lda joypad1,x
  lsr a
  rol 10,x
  lsr a
  rol 14,x
  dey
  bne -
  rts


ppuwritebits
  sta 0
  ldy #4
-
  lda #LED_TILE>>1
  asl 0
  rol a
  sta ppudata
  lda #LED_TILE>>1
  asl 0
  rol a
  sta ppudata
  dey
  bne -
  rts
  




.pad $d000
  .dcb "d000"

.pad $d400
  .dcb "d400"

.pad $d800
  .dcb "d800"

.pad $dc00
  .dcb "dc00"

.pad $e000
hello_dmc
  .incbin "hello.dmc"

.pad $e800
hello_nib
  .incbin "hello.nib"

.pad $f000
  .dcb "f000"

.pad $f100
  .dcb "f100"

.pad $f200
  .dcb "f200"

.pad $f300
  .dcb "f300"

.pad $f400
  .dcb "f400"

.pad $f500
  .dcb "f500"

.pad $f600
  .dcb "f600"

.pad $f700
  .dcb "f700"

.pad $f800
  .dcb "f800"

.pad $f900
  .dcb "f900"

.pad $fa00
  .dcb "fa00"

.pad $fb00
  .dcb "fb00"

.pad $fc00
  .dcb "fc00"

.pad $fd00
  .dcb "fd00"

.pad $fe00
  .dcb "fe00"
;
; play_raw
; Play a 4-bit sample out the NES speaker through DMC raw, at 8 kHz.
; 0 sample address
; 2 length in 256-byte pages
; 3 last byte read
;
play_raw
  ldy #0
  lda #$10
  sta sndchn
--
  lda (0),y     ; 16 cycles
  sta 3
  and #$f0
  lsr a
  sta sndraw
  ldx #41
-
  dex
  bne -                                 

  lda 3         ; 16 cycles
  and #$0f
  asl a
  asl a
  asl a
  sta sndraw
  
  ldx #40
-
  dex
  bne -                                 

  iny
  bne --
  inc 1
  dec 2
  bne --
  rts


;
; play_am
; Play a 4-bit sample out the NES speaker through amplitude
; modulation on pulse channel $4000, at 8 kHz.
; 0 sample address
; 2 length in 256-byte pages
; 3 last byte read
;
play_am
  and #$c0
  ora #$30
  sta 4
  ldy #0
  lda #$01
  sta sndchn
--
  lda (0),y
  sta 3
  and #$f0
  lsr a
  lsr a
  lsr a
  lsr a
  ora 4
  sta $4000
  nop
  ldx #42
-
  dex
  bne -                                 

  lda 3         ; 16 cycles
  and #$0f
  ora 4
  sta $4000
  
  ldx #39
-
  dex
  bne -                                 

  iny
  bne --
  inc 1
  dec 2
  bne --
  rts


;
; play_pwm
; Play a 4-bit sample out the NES speaker through pulse width
; modulation on DMC raw, at 8 kHz.
; 0 sample address
; 2 length in 256-byte pages
; 3 last byte read
;
play_pwm
  ldy #0
  lda #$01
  sta sndchn
--
  lda (0),y     ; 16 cycles
  sta 3
  and #$c0
  ora #$3f
  sta $4000
  ldx #40
-
  dex
  bne -                                 

  lda 3         ; 20 cycles
  and #$0c
  asl a
  asl a
  asl a
  asl a
  ora #$3f
  sta $4000
  
  ldx #40
-
  dex
  bne -                                 

  iny
  bne --
  inc 1
  dec 2
  bne --
  lda #$30      ;kill sound
  sta $4000
  rts


.pad $ff00
  .dcb "ff00"


clear_scanlines
  asl a
  asl a
  tax
-
  sty ppudata
  sty ppudata
  sty ppudata
  sty ppudata
  sty ppudata
  sty ppudata
  sty ppudata
  sty ppudata
  dex
  bne -
  rts


readpads
  ldx #1
  stx joypad1
  dex
  stx joypad1
-
  lda joypad1
  jsr readpads_cycle
  lda joypad2
  jsr readpads_cycle
  cpx #16
  bcc -
  rts

readpads_cycle
  lsr a
  bcs +
  lda #0
  sta pads,x
  inx
  rts
+
  inc pads,x
  lda pads,x
  cmp #18
  bcc readpads_skip
  lda #16
  sta pads,x
readpads_skip
  inx
  rts


; load_bgimage ;;;;;;;;;;;;;;;;;;;;;;;;;
; Decompress image #x from ROM to VRAM $aa00.
;
load_bgimage
  sta ppuaddr   ;set to v
  lda #0
  sta ppuaddr
  lda image_directory,x
  sta 0
  lda image_directory+1,x
  sta 1
  jmp PKB_unpackblk

  .incsrc "unpkb.asm"


copypal
  lda #$3f
  sta ppuaddr
  ldx #0
  stx ppuaddr
-
  lda rampal,x
  sta ppudata
  inx
  cpx #32
  bcc -
  rts

.pad $fffa
  .dcw nmipoint, crt0_startup, irqpoint

.incbin "bench.chr"
