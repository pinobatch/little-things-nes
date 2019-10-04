;
; OAM test for NES
; Copyright 2012 Damian Yerrick
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

.segment "ZEROPAGE"
nmis:          .res 1
oam_used:      .res 1  ; starts at 0
cur_keys:      .res 2
new_keys:      .res 2

; Game variables
siglo:            .res 1
sighi:            .res 1
stagger_amount:   .res 1

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 1          ; PRG ROM size in 16384 byte units
  .byt 1          ; CHR ROM size in 8192 byte units
  .byt $00        ; mirroring type and mapper number lower nibble
  .byt $00        ; mapper number upper nibble

.segment "VECTORS"
.addr nmi, reset, irq

.segment "CODE"
.proc nmi
  inc nmis
  rti
.endproc
.proc irq
  rti
.endproc

; 
.proc reset
  ; Put all interrupt sources into a known state
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

  ; Wait for the PPU to stabilize
vwait1:
  bit PPUSTATUS
  bpl vwait1

  cld
  ; If cold boot, reset signature
  ldx #$F0
  ldy #$1E
  cpx sighi
  bne is_cold_boot
  cpy siglo
  beq is_warm_boot
is_cold_boot:
  stx sighi
  sty siglo
  lda #0
  sta stagger_amount
is_warm_boot:

vwait2:
  bit PPUSTATUS  ; After the second vblank, we know the PPU has
  bpl vwait2     ; fully stabilized.
  
  jsr load_main_palette
  jsr draw_bg
  jsr draw_all_sprites

  ; Wait for NMI to signal vertical blank before turning on display
  ; for the first time.  Thanks rainwarrior for reporting this
  ; https://forums.nesdev.com/viewtopic.php?p=193303#p193303
  lda #VBLANK_NMI
  sta PPUADDR
  lda nmis
vwait3:
  cmp nmis
  beq vwait3
oam_copy:
  lda #>OAM
  sta OAM_DMA
oam_nocopy:
  ; Turn the screen on
  ldx #0
  ldy #0
  lda #VBLANK_NMI|BG_0000|OBJ_8X16
  sec
  jsr ppu_screen_on

  ; Game logic
  jsr read_pads
  jsr move_player
  jsr draw_all_sprites

  ; Wait for a vertical blank and turn on display
  lda nmis
:
  cmp nmis
  beq :-

  ; Copy the display list from main RAM to the PPU
  ; Usually you'd copy it every frame, but this ROM tests
  ; what happens if you don't copy it all the time.
  lda #KEY_SELECT
  and new_keys
  beq oam_nocopy
  bne oam_copy
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
  .byt $0F,$00,$10,$30,$0F,$00,$10,$30,$0F,$00,$10,$30,$0F,$00,$10,$30
  .byt $0F,$06,$16,$26,$0F,$08,$18,$28,$0F,$0A,$1A,$2A,$0F,$02,$12,$22

.segment "CODE"

.proc draw_bg
  ; Start by clearing the first nametable
  ldx #$20
  lda #$00
  ldy #$AA
  jsr ppu_clear_nt


dstlo = 0
  lda #$10
  sta dstlo
  ldx #0
  bit PPUSTATUS
  lda #VBLANK_NMI
  sta PPUCTRL
rowloop:
  lda #$21
  sta PPUADDR
  lda dstlo
  sta PPUADDR
  clc
  adc #64
  sta dstlo
  ldy #16
tileloop:
  stx PPUDATA
  inx
  dey
  bne tileloop
  cpx #48
  bcc rowloop

  rts
.endproc


.proc move_player

  lda new_keys
  and #KEY_SELECT
  beq notSelect
  inc stagger_amount
  lda stagger_amount
  cmp #4
  bcc notSelect
  lda #0
  sta stagger_amount
notSelect:
  rts
.endproc

OBJARRAY_LEFT_SIDE = 24
OBJARRAY_TOP = 20
OBJARRAY_VSTRIDE = 24

.proc draw_all_sprites
row_y = 4
mul12 = 5
  ldx #OBJARRAY_TOP - 1
  stx row_y
  ldx #0
rowloop:
  ldy row_y
objloop:
  tya
  sta OAM,x
  clc
  adc stagger_amount 
  tay
  txa
  lsr a
  ora #$01
  sta OAM+1,x
  lsr a
  and #$03
  sta OAM+2,x
  txa
  and #$1C
  sta mul12
  asl a
  adc mul12
  adc #OBJARRAY_LEFT_SIDE
  sta OAM+3,x
  inx
  inx
  inx
  inx
  beq done
  txa
  and #$1C
  bne objloop
  lda row_y
  clc
  adc #OBJARRAY_VSTRIDE
  sta row_y
  jmp rowloop
done:
  rts
.endproc

