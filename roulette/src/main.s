;
; Russian Roulette game for NES
; Copyright 2014 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty
; provided the copyright notice and this notice are preserved.
; This file is offered as-is, without any warranty.
;
.include "nes.inc"
.include "global.inc"
.p02

NUM_CHAMBERS = 6
LF = 10

.segment "ZEROPAGE"
nmis: .res 1
cur_keys: .res 3  ; 0: player 1; 1: player 2; 2: zapper trigger
new_keys: .res 3
num_players: .res 1
cur_turn: .res 1
alive_players: .res 1
nametable_pos: .res 2

.segment "INESHDR"
  .byt "NES",$1A
  .byt 1  ; 16 KiB PRG ROM
  .byt 1  ; 8 KiB CHR ROM
  .byt 1  ; vertical mirroring; low mapper nibble: 0
  .byt 0  ; high mapper nibble: 0

.segment "VECTORS"
  .addr nmi, reset, irq

.segment "CODE"

; we don't use irqs yet
.proc irq
  rti
.endproc

; NMI handler just notifies the main thread that an NMI happened
; (see vsync)
.proc nmi
  inc nmis
  rti
.endproc

.proc reset
  sei

  ; Acknowledge and disable interrupt sources during bootup
  ldx #0
  stx PPUCTRL    ; disable vblank NMI
  stx PPUMASK    ; disable rendering (and rendering-triggered mapper IRQ)
  lda #$40
  sta $4017      ; disable frame IRQ
  stx $4010      ; disable DPCM IRQ
  bit PPUSTATUS  ; ack vblank NMI
  bit $4015      ; ack DPCM IRQ
  cld            ; disable decimal mode to help generic 6502 debuggers
                 ; http://magweasel.com/2009/08/29/hidden-messagin/
  dex            ; set up the stack
  txs
  
  ; Wait for the PPU to warm up (part 1 of 2)
vwait1:
  bit PPUSTATUS
  bpl vwait1

  ; While waiting for the PPU to finish warming up, we have about
  ; 29000 cycles to burn without touching the PPU.  So we have time
  ; to initialize zero page to known values for predictability.
  ldx #$00
  txa
clear_zp:
  sta $00,x
  inx
  bne clear_zp

  ; the most basic sound engine possible:
  ; rely on HW envelopes and length counter
  lda #$0F
  sta $4015
  
  lda #2
  sta num_players
  
  ; Wait for the PPU to warm up (part 2 of 2)
vwait2:
  bit PPUSTATUS
  bpl vwait2

startOver:
  jsr getNumberOfPlayers

gameLoop:
  jsr takeTurn
  jsr findNextAlivePlayer

  ; If A & (A - 1) is not zero, at least 2 bits are set in A.
  ; Use this to terminate the loop when only 1 player is left.
  ldx alive_players
  dex
  txa
  and alive_players
  bne gameLoop

  ; Draw win message
  jsr cls
  lda #$1A
  jsr setbgcolor
  lda #$20
  sta nametable_pos+1
  lda #$62
  sta nametable_pos+0
  lda #>winText
  ldy #<winText
  jsr printMsg
  
  ; position after "Player"
  lda #$20
  ldy #$69
  jsr writePlayerNumber

waitForStartOver:
  jsr read_pads
  jsr vsync
  clc
  jsr screen_on
  lda new_keys
  and #KEY_A|KEY_START
  beq waitForStartOver
  jmp startOver
.endproc

.proc drawIntroText
  jsr cls

  ; set all 8 palettes (4 background, 4 sprite)
  ldx #$3F
  stx PPUADDR
  inx
  stx PPUADDR
  ldx #8
  lda #$17
  ldy #$38
setpalloop:
  sta PPUDATA
  sty PPUDATA
  sty PPUDATA
  sty PPUDATA
  dex
  bne setpalloop

  ; Show title screen message
  lda #$20
  sta nametable_pos+1
  lda #$62
  sta nametable_pos+0
  lda #>introText
  ldy #<introText
  ; fall through to printMsg
.endproc

;;
; @param A Source text pointer high byte
; @param Y Source text pointer low byte
; @param nametable_pos Destination PPU address
.proc printMsg  
src = $00
  sta src+1
  sty src
  ldy #0
lineloop:
  lda nametable_pos+1
  sta PPUADDR
  lda nametable_pos+0
  sta PPUADDR
loop:
  lda (src),y
  beq done
  iny
  bne :+
  inc src+1
:
  cmp #LF
  beq newline
  sta PPUDATA
  bne loop
newline:
  lda #32
  clc
  adc nametable_pos+0
  sta nametable_pos+0
  bcc lineloop
  inc nametable_pos+1
  bcs lineloop
done:
  rts
.endproc

.proc getNumberOfPlayers
  jsr drawIntroText
  
  ; clear all other sprites
  lda #$F0
  ldx #4
:
  sta OAM,x
  inx
  bne :-

  ; and set up the position of the cursor sprite
  lda #23*8-1
  sta OAM    ; Y position
  lda #'>'
  sta OAM+1  ; Tile number
  lda #0
  sta OAM+2  ; Palette, background priority, and flip

loop:
  jsr read_pads

  ; Every time the number of players changes, mix the current time
  ; into the random number seed.
  lda new_keys
  and #KEY_RIGHT|KEY_SELECT
  beq notInc
  inc num_players
  lda nmis
  jsr crc16_update
notInc:

  lda new_keys
  and #KEY_LEFT
  beq notDec
  dec num_players
  lda nmis
  jsr crc16_update
notDec:

  ; Wrap number of players within 2-6
  lda num_players
  cmp #2
  bcs :+
  lda #6
:
  cmp #7
  bcc :+
  lda #2
:
  sta num_players

  ; Check for exit
  lda new_keys
  and #KEY_A|KEY_START
  bne have_numPlayers

  ; Move the cursor
  lda num_players
  asl a
  adc num_players
  asl a
  asl a
  asl a
  sbc #31
  sta OAM+3

  jsr vsync
  lda #>OAM
  sta OAM_DMA
  sec
  jsr screen_on
  jmp loop

have_numPlayers:
  lda nmis
  jsr crc16_update  ; again mix the current time into the seed

  ; Determine the initial alive players and the starting player
  ldy num_players
  ldx le_bits,y  ; le_bits is 1 << y
  dex          ; (1 << y) - 1 has the low-order y bits 1 and others 0
  stx alive_players
  jsr roll
  sta cur_turn
  rts
.endproc


.proc takeTurn
cylOffset = $00
cylSpeed = $01

  ; Display whose turn it is
  jsr cls
  lda #$20
  sta nametable_pos+1
  lda #$62
  sta nametable_pos+0
  lda #>turnText1
  ldy #<turnText1
  jsr printMsg
  lda #$20
  ldy #$69
  jsr writePlayerNumber

  ; Slowly spin the cylinder down
  lda #120
  sta cylOffset
  sta cylSpeed

spinCylLoop:
  ; cyl spinning sound
  lda cylSpeed
  clc
  adc cylOffset
  sta cylOffset
  bcc noTurnSound
  
  ; play cylinder click out the speaker
  lda #1
  sta $400C
  lda #4
  sta $400E
  lda #$18
  sta $400F
noTurnSound:

  jsr vsync  
  lda #$02  ; dark blue
  jsr setbgcolor
  clc
  jsr screen_on
  dec cylSpeed
  bne spinCylLoop

waitButtonLoop:
  jsr read_pads
  jsr read_trigger
  jsr vsync
  lda new_keys
  and #KEY_A
  ora new_keys+2
  beq waitButtonLoop

  ldy #NUM_CHAMBERS
  jsr roll
  cmp #0
  beq died

  ; still alive so display a message
  jsr vsync
  lda #$20
  sta nametable_pos+1
  lda #$C2
  sta nametable_pos+0
  lda #>turnTextSafe
  ldy #<turnTextSafe
  jsr printMsg
  clc
  jsr screen_on

  ; play another click
  lda #1
  sta $400C
  lda #4
  sta $400E
  lda #$18
  sta $400F
  
  ; wait two seconds
  ldx #120
  jmp waitXFrames
  
died:
  ; set player's alive bit to 0
  ldx cur_turn
  lda le_bits,x
  eor #$FF
  and alive_players
  sta alive_players
  
  ; play "bang" sound effect
  lda #$0F
  sta $400C
  lda #$0C
  sta $400E
  lda #$08
  sta $400F

  ; turn the screen red and display eliminated message
  jsr vsync
  lda #$16
  jsr setbgcolor
  lda #$20
  sta nametable_pos+1
  lda #$C2
  sta nametable_pos+0
  lda #>turnTextDied
  ldy #<turnTextDied
  jsr printMsg
  ldx #180
  ; fall through to waitXFrames
.endproc
.proc waitXFrames
  jsr vsync
  clc
  jsr screen_on
  dex
  bne waitXFrames
  rts
.endproc

;;
; Finds which player after the current player is still alive.
.proc findNextAlivePlayer
  ldx cur_turn
  ldy #8  ; Iterations left; if it hits 0 something's seriously wrong
loop:
  inx
  cpx num_players
  bcc notTooMany
  ldx #0
notTooMany:
  lda alive_players
  and le_bits,x
  bne foundOne
  dey
  bne loop
foundOne:
  stx cur_turn
  rts
.endproc

;;
; Writes the player number (1 to 6) to the nametable
; @param A high byte of VRAM address (usually $20 to $23)
; @param Y low byte of VRAM address
.proc writePlayerNumber
  sta PPUADDR
  sty PPUADDR
  lda cur_turn
  clc
  adc #'1'
  sta PPUDATA
  rts
.endproc

; PPU utility subroutines ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
; Clears the screen by filling it with 960 space ($20) characters
; followed by 64 attribute bytes of $00.
.proc cls
  lda #VBLANK_NMI
  sta PPUCTRL  ; make sure the address increment is 1, not 32
  lda #$20
  ldx #$00
  stx PPUMASK  ; disable rendering
  sta PPUADDR  ; high byte: $20  (which is also the space character)
  stx PPUADDR  ; low byte: $00
  ldx #240     ; clear 960 bytes, unrolled to 4 bytes each iteration
tileloop:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  dex
  bne tileloop
  txa          ; by this point X = $00 and we also want to clear to $00
  ldx #64
attrloop:
  sta PPUDATA
  dex
  bne attrloop
  rts
.endproc

;;
; Sets the background color to the color in A and leaves the VRAM
; pointer at entry $01 of the palette.
; Works only during vertical blanking.
.proc setbgcolor
  ldx #$3F  ; Set to $3F40, which mirrors $3F00
  stx PPUADDR
  inx
  stx PPUADDR
  sta PPUDATA
  rts
.endproc

;;
; Waits for the start of vertical blanking.
.proc vsync
  lda nmis
:
  cmp nmis
  beq :-
  rts
.endproc

;;
; Sets the scroll to the start of the first nametable and turns on
; the background.  Also turns on sprites if carry is set.
.proc screen_on
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #VBLANK_NMI|BG_1000|OBJ_1000
  sta PPUCTRL
  lda #BG_ON
  bcc nobg
  lda #BG_ON|OBJ_ON
nobg:
  sta PPUMASK
  rts
.endproc

.segment "RODATA"
le_bits:
  .byt $01,$02,$04,$08,$10,$20,$40,$80
introText:
  .byt "Russian Roulette 0.02",LF
  .byt "Copr. 2014 Damian Yerrick",LF
  .byt "(Share this freely!)",LF
  .byt LF
  .byt "In this game, roulette",LF
  .byt "plays YOU.  Here's how:",LF
  .byt LF
  .byt "One of a revolver's six",LF
  .byt "chambers holds a paint",LF
  .byt "capsule.  Each player in",LF
  .byt "turn spins the cylinder",LF
  .byt "and pulls the trigger.",LF
  .byt "(No Zapper? Press A on",LF
  .byt "controller 1.) If it doesn't",LF
  .byt "fire, pass it to the next",LF
  .byt "player.  Get splattered",LF
  .byt "and you're out!",LF
  .byt LF
  .byt "How many players?",LF
  .byt LF
  .byt " 2  3  4  5  6",0

turnText1:
  .byt "Player   grabs the marker",LF
  .byt "and spins the cylinder.",0
turnTextSafe:
  .byt "(click)",0
turnTextDied:
  .byt "BANG!",LF
  .byt "Player eliminated.",0
winText:
  .byt "Player   wins the game!",LF
  .byt LF
  .byt "Press Start to play again",0

.segment "CHR"
  .incbin "obj/nes/titlegfx.chr"  ; blank page
  .incbin "obj/nes/gamegfx.chr"   ; ascii font
