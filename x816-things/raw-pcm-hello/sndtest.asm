  .incbin "nrom128.hdr"
;  .opt on
;  .index 8
;  .mem 8
  .org $c000
;  .list
;  .symbol

ppuctrl   = $2000
ppumask   = $2001
ppustatus = $2002
spraddr   = $2003
sprdma    = $4014
ppuscroll = $2005
ppuaddr   = $2006
ppudata   = $2007

dmcfreq   = $4010
sndraw    = $4011
dmcaddr   = $4012
dmclen    = $4013
sndchn    = $4015

retrace_cd = 8





.pad $e000
hello_dmc
  .incbin "hello.dmc"

.pad $e800
hello_nib
  .incbin "hello.nib"
.pad $f000

pal
  .db $12,$30,$12,$30,$12,$12,$30,$30,$12,$12,$0f,$0f,$12,$22,$32,$30
  .db $12,$30,$12,$30,$12,$12,$30,$30,$12,$12,$0f,$0f,$12,$22,$32,$30

title_pkb
  .incbin "title.pkb"



;
; THE MAIN CODE STARTS HERE!
;
resetpoint
  sei
  cld
  lda #$c0
  sta $4017     ;init interrupts
  lda #0
  sta ppuctrl   ;init ppu
  sta ppumask
  tax
  stx sndchn    ;init sound
  sta sndchn
  dex
  txs           ;init stack
  jsr wait4vbl
  tax
-               ;clear RAM
  lda #0
  sta 0,x
  sta $100,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  inx
  bne -

  lda #$ef      ;clear sprite table
-
  sta $200,x
  inx
  bne -

  jsr wait4vbl  ;after 2 vbl's, the ppu should be warmed up

  lda #0        ;initialize the pointer sprite
  jsr set_sprite

  lda #0        ;send the sprite table
  sta spraddr
  lda #2
  sta sprdma

  lda #$24      ;clear PPU RAM
  sta ppuaddr
  lda #0
  sta ppuaddr
  tax
-
  sta ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  inx
  bne -

  lda #$3f      ;load palette
  sta ppuaddr
  lda #0
  sta ppuaddr
  tax
-
  lda pal,x
  sta ppudata
  inx
  cpx #32
  bcc -

  lda #$20
  sta ppuaddr
  lda #0
  sta ppuaddr
  lda #<title_pkb
  sta 0
  lda #>title_pkb
  sta 1
  jsr PKB_unpackblk

  ; now that video ram is loaded, turn on the screen
  jsr wait4vbl
  lda #0
  sta ppuscroll
  sta ppuscroll
  sta ppuctrl
  lda #%00011110
  sta ppumask

start_over

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
  jsr wait4vbl
  dey
  bne -

  lda #1
  jsr do_sprite

  lda #<hello_nib
  sta 0
  lda #>hello_nib
  sta 1
  lda #8
  sta 2
  jsr play_raw

  lda #2
  jsr do_sprite

  lda #%00001   ;initialize square wave channel $4000
  sta sndchn
  lda #%10111000
  sta $4000
  lda #%00001000
  sta $4001
  lda #13
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

  lda #3
  jsr do_sprite

  lda #<hello_nib
  sta 0
  lda #>hello_nib
  sta 1
  lda #8
  sta 2
  lda #$40
  jsr play_am

  lda #4
  jsr do_sprite

  lda #<hello_nib
  sta 0
  lda #>hello_nib
  sta 1
  lda #8
  sta 2
  lda #$80
  jsr play_am

  lda #5
  jsr do_sprite

  lda #<hello_nib
  sta 0
  lda #>hello_nib
  sta 1
  lda #8
  sta 2
  lda #$c0
  jsr play_am

  lda #6
  jsr do_sprite

  lda #<hello_nib
  sta 0
  lda #>hello_nib
  sta 1
  lda #8
  sta 2
  jsr play_pwm


  lda #0
  jsr do_sprite
  jmp start_over









.pad $fe00
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
  lda #$10
  sta sndchn
--
  lda (0),y     ; 16 cycles
  sta 3
  and #$c0
  ora #$3f
  sta sndraw
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
; wait4vbl
; does what you think it does
;
wait4vbl
  bit ppustatus
  bpl wait4vbl
  rts


;
; set_sprite
; Moves sprites 0 and 1 to (56, a * 16 + 94)
;
set_sprite
  asl a
  asl a
  asl a
  asl a
  clc
  adc #93       ; y
  sta $200
  clc
  adc #8
  sta $204
  lda #56       ; x
  sta $203
  sta $207
  lda #$e7      ; tile id
  sta $201
  sta $205
  lda #0        ; top tile is not flipped
  sta $202
  lda #$80      ; bottom tile is v flipped
  sta $206
  rts


;
; do_sprite
; Wait for VBL, turn off the screen, move the pointer, blit the
; sprites, and turn the screen back on.
;
do_sprite
  jsr wait4vbl
  jsr set_sprite
  lda #2
  sta sprdma
  rts

.pad $ff00
;
; PKB_unpackblk
; Unpack PackBits() encoded data from memory at ($00) to
; NES PPU data port.
;
  .incsrc "unpkb.asm"


.pad $fff8
nmipoint
irqpoint
  rti

.pad $fffa
  .dw nmipoint
  .dw resetpoint
  .dw irqpoint
  .incbin "sndtest.chr"
