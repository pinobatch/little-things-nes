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
.include "mmc1.inc"
.include "global.inc"
.include "cigetbit.inc"

.import ppu_clear_nt, ppu_clear_oam, ppu_screen_on
.import setPRGBank, setMMC1BankMode
.import read_pads

.import chnaddrs, chnbanks
.importzp NUM_PICS, MAX_IM_HEIGHT
.import decodechn
.importzp drawchn_x, drawchn_y, drawchn_2000, drawchn_tilebase
.import drawchn_namwidth, drawchn_namheight, drawchn_namtiles

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

.export nmi, reset, irq

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

  ; NES's 6502 has no BCD, but some post-patent famiclones have it
  cld

  ; Clear OAM and the zero page here.
  ; We don't copy the cleared OAM to the PPU until later.
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
  ; Set up your sound engine
  
  lda #%01110
  ;        ^^ Vertical mirroring (horizontal arrangement of nametables)
  ;      ^^   Fixed $C000
  ;     ^     8 KiB CHR banks
  jsr setMMC1BankMode

vwait2:
  bit PPUSTATUS  ; After the second vblank, we know the PPU has
  bpl vwait2     ; fully stabilized.

  lda #0
  sta player_xlo
  sta player_xhi

next_pic:
  ldx #$20
  lda #$00
  sta PPUMASK
  ldy #$AA
  jsr ppu_clear_nt
  ldx #$24
  lda #$00
  ldy #$FF
  jsr ppu_clear_nt

  ldx player_xhi
  lda chnbanks,x
  jsr setPRGBank
  txa
  asl a
  tax
  lda chnaddrs+0,x
  sta ciSrc
  lda chnaddrs+1,x
  sta ciSrc+1

  ; Decode the nametable
  lda #4
  sta drawchn_y
  sta drawchn_x
  lsr a
  sta drawchn_tilebase
  lda #0
  sta drawchn_2000
  jsr decodechn
  lda #$20
  sta PPUADDR
  lda #$62
  sta PPUADDR
  lda #1
  sta PPUDATA
  
  ; Load sprite 0
  lda #24-1
  sta OAM+0
  lda #1
  sta OAM+1
  lda #0
  sta OAM+2
  lda #20
  sta OAM+3
  ldx #4
  jsr ppu_clear_oam
  
  ; Copy the tiles
  lda #$00
  sta PPUADDR
  sta PPUADDR
  jsr set_blanktiles
  jsr copy_namtiles
  lda #$10
  sta PPUADDR
  lda #$00
  sta PPUADDR
  jsr set_blanktiles
  jsr copy_namtiles

  jsr load_main_palette
  lda #VBLANK_NMI
  sta PPUCTRL

loop:
  lda nmis
vw3:
  cmp nmis
  beq vw3
  
  ldx #0
  stx OAMADDR
  lda #>OAM
  sta OAM_DMA
  ldy #0
  lda #VBLANK_NMI|OBJ_1000
  sec
  jsr ppu_screen_on
  jsr do_s0

  lda nmis
  bne loop
  inc player_xlo
  lda player_xlo
  cmp #2
  bcc loop
  lda #0
  sta player_xlo

  inc player_xhi
  lda player_xhi
  cmp #NUM_PICS
  bcc :+
  lda #0
  sta player_xhi
:
  jmp next_pic
.endproc
  
  
.align 256
.proc do_s0

  ; If we arrived during vblank (sprite 0 hit already set),
  ; try to trigger the 3-phase colorburst sequence so that the
  ; diagonal lines will move down the screen instead of staying
  ; in place.  Otherwise, skip colorburst manipulation.
  bit PPUSTATUS
  bvc s0wait1

  ; First wait for the end of vblank
s0wait0:
  bit PPUSTATUS
  bvs s0wait0
  lda #$00
  sta PPUMASK
  sta PPUADDR
  sta PPUADDR
  ldy #20
:
  dey
  bne :-
  lda #BG_ON|OBJ_ON
  sta PPUMASK

s0wait1:
  bit PPUSTATUS
  bmi nos0
  bvc s0wait1

ctrlbits = 0
cyclepart = 1

  lda #0
  sta cyclepart
  lda nmis
  and #$01
  beq :+
  ora #BG_1000
:
  ora #VBLANK_NMI|OBJ_1000
  sta ctrlbits
  ldx #MAX_IM_HEIGHT
  jsr waste_12
  jsr waste_12
  jsr waste_12
  
s0loop:
  ; 12
  lda ctrlbits
  sta PPUCTRL
  eor #$01|BG_1000
  sta ctrlbits
  ; 10.67
  lda cyclepart
  adc #$AA
  sta cyclepart
  bcs :+
:
  
  jsr waste_12
  jsr waste_12
  jsr waste_12
  jsr waste_12
  jsr waste_12
  jsr waste_12
  jsr waste_12
  nop
  
  ; 5
  dex
  bne s0loop
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  sta PPUCTRL
nos0:
waste_12:
  rts
.endproc

.segment "CODE"
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
  .byt $0F,$08,$19,$2A,$0F,$18,$28,$38,$0F,$0A,$1A,$2A,$0F,$12,$16,$24
  .byt $0F,$08,$15,$27,$0F,$06,$16,$26,$0F,$0A,$1A,$2A,$0F,$02,$12,$22

.segment "CODE"
.proc set_blanktiles
  ldx #31
  lda #0
loop:
  sta PPUDATA
  dex
  bne loop
  lda #$FF
  sta PPUDATA
  rts
.endproc

.proc copy_namtiles
  lda #$0F
  sta 1
  lda drawchn_namtiles
  eor #$FF
  asl a
  rol 1
  asl a
  rol 1
  asl a
  rol 1
  asl a
  rol 1
  adc #16
  bcc :+
  inc 1
:
  tax
  ldy #0
byteloop:
  lda (ciSrc),y
  sta PPUDATA
  iny
  bne :+
  inc ciSrc+1
:
  inx
  bne byteloop
  inc 1
  bne byteloop
  tya
  clc
  adc ciSrc
  sta ciSrc
  bcc :+
  inc ciSrc+1
:
  rts
.endproc

