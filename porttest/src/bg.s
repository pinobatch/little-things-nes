.include "nes.inc"
.include "global.inc"

; header:
; FEDCBA98 76543210
; |||||||| |||+++++- X
; ||||||++-+++------ Y
; ++++++------------ number of runs (0: end)
; 
; data:
; 76543210
; |||+++++- Starting tile number
; +++------ Number of tiles minus 1

.macro RUNH xt, yt, nruns
  .dbyt (xt) | ((yt) << 5) | ((nruns) << 10)
.endmacro

.macro RUN starttile, ntiles
.local starttileor
  .ifnblank ntiles
    starttileor = (ntiles - 1) << 5
  .else
    starttileor = 0
  .endif
  .byte starttile|starttileor
.endmacro

TILE_SPACE = $00
TILE_D = $01
TILE_P = $02
TILE_401 = $08
TILE_8 = $0D
TILE_0 = $10
TILE_1 = $11
TILE_2 = $12
TILE_3 = $13
TILE_4 = $14
TILE_A = $15
TILE_B = $16
TILE_DOWN = $1D
TILE_LEFT = $1E
TILE_RIGHT = $1F
TILE_LIGHT = $20
TILE_IRQ = $03

.rodata
title_data:
RUNH 6,6,17
RUN TILE_A
RUN TILE_SPACE
RUN TILE_B, 7
RUN TILE_SPACE
RUN TILE_DOWN
RUN TILE_SPACE
RUN TILE_LEFT
RUN TILE_SPACE
RUN TILE_RIGHT
RUN TILE_SPACE, 2
RUN TILE_4
RUN TILE_D
RUN TILE_3
RUN TILE_D
RUN TILE_2
RUN TILE_D
RUN TILE_1

RUNH 3,8,2
RUN TILE_1
RUN TILE_P

RUNH 3,10,2
RUN TILE_2
RUN TILE_P

RUNH 3,12,2
RUN TILE_3
RUN TILE_P

RUNH 3,14,2
RUN TILE_4
RUN TILE_P

RUNH 10,18,6
RUN TILE_D
RUN TILE_2
RUN TILE_D
RUN TILE_1
RUN TILE_D
RUN TILE_0

RUNH 3,20,1
RUN TILE_401,5

RUNH 3,22,2
RUN TILE_401,2
RUN TILE_8,3

RUNH 20,20,1
RUN TILE_IRQ,2

.byte $00

.code
.proc draw_bg
srclo = $00
srchi = $01
runsleft = $02
tilenum = $03

  lda #VBLANK_NMI
  sta PPUCTRL
  lda #0
  tay
  ldx #$20
  jsr ppu_clear_nt

  lda #<title_data
  sta srclo
  lda #>title_data
  sta srchi

  runsetloop:
    ldy #0
    lda (srclo),y
    lsr a
    lsr a
    beq done
    sta runsleft
    lda (srclo),y
    iny
    and #$03
    ora #$20
    sta PPUADDR
    lda (srclo),y
    iny
    sta PPUADDR
    runloop:
      lda (srclo),y
      iny
      sec
      byteloop:
        sta tilenum
        and #$1F
        sta PPUDATA
        lda tilenum
        sbc #$1F
        beq rundone
        bcs byteloop
    rundone:
      dec runsleft
      bne runloop
    tya
    clc
    adc srclo
    sta srclo
    bcc runsetloop
    inc srchi
    bcs runsetloop
  done:

  rts
.endproc

.define NTXY(xt,yt) ($2000 | (xt) | ((yt) << 5))

NTDST_1P = NTXY(6, 8)
NTDST_2P = NTXY(6, 10)
NTDST_3P = NTXY(6, 12)
NTDST_4P = NTXY(6, 14)
NTDST_4016 = NTXY(10, 20)
NTDST_4018 = NTXY(10, 22)
NTDST_IRQ = NTXY(24, 20)  ; to confirm

.proc update_pins
  lda #>NTDST_1P
  sta PPUADDR
  lda #<NTDST_1P
  sta PPUADDR
  lda cur_keys+0
  ldx #8
  jsr dosomebits
  lda cur_401x+0
  asl a
  asl a
  asl a
  ldx #4
  jsr dosomebits
  
  lda #>NTDST_2P
  sta PPUADDR
  lda #<NTDST_2P
  sta PPUADDR
  lda cur_keys+1
  ldx #8
  jsr dosomebits
  lda cur_401x+1
  asl a
  asl a
  asl a
  ldx #4
  jsr dosomebits
  
  lda #>NTDST_3P
  sta PPUADDR
  lda #<NTDST_3P
  sta PPUADDR
  lda cur_keys+2
  ldx #8
  jsr dosomebits
  
  lda #>NTDST_4P
  sta PPUADDR
  lda #<NTDST_4P
  sta PPUADDR
  lda cur_keys+3
  ldx #8
  jsr dosomebits

  lda #>NTDST_4018
  sta PPUADDR
  lda #<NTDST_4018
  sta PPUADDR
  lda $4018
  lsr a
  ror a
  ror a
  ror a
  ldx #3
  jsr dosomebits
  
  lda #>NTDST_4016
  sta PPUADDR
  lda #<NTDST_4016
  sta PPUADDR
  lda out4016value
  lsr a
  ror a
  ror a
  ror a
  ldx #3
  jsr dosomebits
  
  lda #>NTDST_IRQ
  sta PPUADDR
  lda #<NTDST_IRQ
  sta PPUADDR
  lda time_since_irq
  beq :+
    lda #$80
  :
  ldx #1

dosomebits:
  asl a
  tay
  lda #TILE_LIGHT>>1
  rol a
  sta PPUDATA
  bit PPUDATA
  tya
  dex
  bne dosomebits
  rts
.endproc
