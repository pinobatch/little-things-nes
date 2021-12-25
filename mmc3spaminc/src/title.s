.include "nes.inc"
.include "global.inc"

.code
.proc show_title_screen
srcptr = $00
dstlo = $01
dsthi = $02
dsttile = $03
rowwidth = $04

  ; Draw the title screen!
  lda #VBLANK_NMI
  sta PPUCTRL
  asl a
  sta PPUMASK
  ;lda #0
  sta $A000  ; vertical mirroring
  sta $E000  ; disable MMC3 PIT IRQ
  tay
  ldx #$20
  jsr ppu_clear_nt

  ;ldy #0
  rowloop:
    ; 76543210 76543210 76543210
    ;  ||||||| |||||||| ++++++++- tile number
    ;  ||||||| |||+++++---------- X
    ;  |||||++-+++--------------- Y
    ;  +++++--------------------- Length
    lda title_layout,y
    beq tilemap_done  ; NUL terminator
    lsr a
    lsr a
    sta rowwidth
    lda title_layout,y
    and #$03
    ora #$20
    sta dsthi
    lda title_layout+1,y
    sta dstlo
    lda title_layout+2,y
    sta dsttile
    jsr do_half_map_row
    inc dsttile
    jsr do_half_map_row
    iny
    iny
    iny
    bne rowloop
  tilemap_done:
  
  lda #$23
  sta PPUADDR
  lda #$C0
  sta PPUADDR
  ldy #4
  attrrowloop:
    lda #$55
    ldx #5
    attrbyteloop1:
      sta PPUDATA
      dex
      bne attrbyteloop1
    asl a
    ldx #3
    attrbyteloop2:
      sta PPUDATA
      dex
      bne attrbyteloop2
    dey
    bne attrrowloop

  ldx #0
  initoamloop:
    lda press_A_oam,x
    sta OAM,x
    inx
    cpx #press_A_oam_end-press_A_oam
    bcc initoamloop
  jsr ppu_clear_oam  ; Clear the rest of OAM

  ldx #0
  stx $8000  ; PPU window $0000-$07FF
  stx $8001  ; to banks 0 and 1
  inx
  stx $8000  ; PPU window $0800-$0FFF
  inx
  stx $8001  ; to banks 2 and 3
  stx $8000  ; PPU window $1000-$13FF
  ldx #0
  stx $8001  ; to bank 0

  ; Copy the palette (must be done in real vblank to hide a rainbow)
  jsr ppu_vsync
  lda #$3F
  sta PPUADDR
  stx PPUADDR
  palloop:
    lda title_palette,x
    sta PPUDATA
    inx
    cpx #title_palette_end-title_palette
    bcc palloop

  wait_press_loop:
    ldx #$FF
    lda nmis
    and #%00011000
    beq :+
      ldx #192-1
    :
    stx OAM+0
    stx OAM+4
    jsr ppu_vsync
    lda #>OAM
    sta OAM_DMA
    ldx #0
    ldy #0
    lda #VBLANK_NMI|BG_0000|OBJ_8X16
    sec
    jsr ppu_screen_on
    jsr read_pads
    lda new_keys
    and #KEY_A|KEY_START
    beq wait_press_loop
  rts

do_half_map_row:
  lda dsthi
  sta PPUADDR
  lda dstlo
  sta PPUADDR
  clc
  adc #32
  sta dstlo
  bcc :+
    inc dsthi
    clc
  :
  lda dsttile
  ldx rowwidth
  tileloop:
    sta PPUDATA
    adc #2
    dex
    bne tileloop
  rts
.endproc

.macro TILEROW left, top, right, tilenum
  .dbyt (right - left) << 7 | top << 2 | left >> 3
  .byte tilenum
.endmacro

.rodata
title_layout:
  TILEROW  24, 64,152, $40  ; spam
  TILEROW  24, 80,152, $60
  TILEROW  48, 96, 64, $2A  ; p descender
  TILEROW 160, 64,232, $0E  ; inc
  TILEROW 160, 80,232, $2E
  TILEROW 160, 48,176, $0A  ; Dot on i
  TILEROW  40,128, 80, $20  ; test...
  TILEROW  80,128,208, $A0  ;   how mmc3 handles
  TILEROW  16,144,136, $82  ; read, modify, writ...
  TILEROW 136,144,144, $C8  ;   e...
  TILEROW 144,144,240, $C0  ;   on registers
  TILEROW  16,192,176, $D8  ; Copr. 202x Damian Yerrick
  .byte 0

title_palette:
  .byte $02,$12,$22,$20  ; BG: blue ramp
  .byte $02,$0F,$18,$28  ; blue, black to olive
  .byte $02,$0F,$00,$10  ; blue, black to gray
  .byte $02,$FF,$FF,$FF  ; blue, black to gray
  .byte $02,$0F,$16,$26  ; SPRITE: blue, black to red
title_palette_end:

press_A_oam:
  .byte $FF,$09,$00,224  ; Left half of A
  .byte $FF,$09,$40,232  ; Right half of A
press_A_oam_end:
