.include "nes.inc"
.include "global.inc"
.include "popslide.inc"

.code
.proc draw_bg
  ; Load CHR RAM
  lda #VBLANK_NMI
  sta PPUCTRL
  ldy #$00
  sty PPUMASK
  sty PPUADDR
  sty PPUADDR
  lda #<chr
  sta $00
  lda #>chr
  sta $01
  ldx #5120/256
  chrloop:
    lda ($00),y
    sta PPUDATA
    iny
    bne chrloop
    inc $01
    dex
    bne chrloop

  ; Start by clearing the first nametable
  ldx #$20
  lda #$00
  ldy #$AA
  jsr ppu_clear_nt
  
  jsr popslide_init
  ldx #>bg_stripe
  lda #<bg_stripe
  jsr nstripe_append
  jsr popslide_terminate_blit

  rts
.endproc

.rodata
bg_stripe:
  .dbyt NTXY(0, 24)  ; Floor
  .byte 32+63
  .byte $0B
  
  .dbyt NTXY(0, 25)  ; Solid area under floor
  .byte 32+63  ; (I learned this convention from "Pinobee" for GBA)
  .byte $01
  .dbyt NTXY(0, 26)
  .byte 64+63
  .byte $01
  .dbyt NTXY(0, 28)
  .byte 64+63
  .byte $01

  ; draw two columns of two blocks each, each block being 4 tiles:
  ; 0C 0D
  ; 0E 0F
  .dbyt NTXY(2, 20)
  .byte 4+127
  .byte $0C, $0E, $0C, $0E

  .dbyt NTXY(3, 20)
  .byte 4+127
  .byte $0D, $0F, $0D, $0F

  .dbyt NTXY(28, 20)
  .byte 4+127
  .byte $0C, $0E, $0C, $0E

  .dbyt NTXY(29, 20)
  .byte 4+127
  .byte $0D, $0F, $0D, $0F

  ; Attributes
  .dbyt $23E8
  .byte 1-1
  .byte $00
  
  .dbyt $23EF
  .byte 1-1
  .byte $00

  ; Preview area for parallax tiles
  .dbyt $208E
  .byte 4+127
  .byte $F0,$F4,$F8,$FC

  .dbyt $208F
  .byte 4+127
  .byte $F1,$F5,$F9,$FD

  .dbyt $2090
  .byte 4+127
  .byte $F2,$F6,$FA,$FE

  .dbyt $2091
  .byte 4+127
  .byte $F3,$F7,$FB,$FF

  .byte $FF

chr:
  .incbin "obj/nes/bggfx.chr"
  .incbin "obj/nes/spritegfx.chr", 0, 1024
