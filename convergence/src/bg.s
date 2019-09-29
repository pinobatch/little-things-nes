;
; Convergence test tool
; Copyright 2018 Damian Yerrick
; 
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;


.import getTVSystem

PPUCTRL = $2000
  VBLANK_NMI = $80
  VRAM_DOWN = $04
PPUMASK = $2001
  BG_ON = $0A
  OBJ_ON = $14
PPUSTATUS = $2002
OAMADDR = $2003
OAM_DMA = $4014
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007

P1 = $4016
KEY_START = $10

.zeropage
nmis: .res 1
tvSystem: .res 1
cur_keys: .res 1
new_keys: .res 1
help_on: .res 1
center_dot_on: .res 1
bg_is_solid: .res 1
solid_bg_color: .res 1

cur_bgcolors: .res 2
cur_objcolor: .res 1

BGCOLOR_A = $20
BGCOLOR_B = $16

OAM = $0200

.macro OBJSTRIP left, top, width, starttile
.local top_
top_ = top
  .byte width
  .byte left
  .byte (top) - 1
  .byte starttile
.endmacro

.segment "INESHDR"
.byte "NES",$1A
.byte 1, 0, 0, 0

.segment "VECTORS"
.addr nmi_handler, reset_handler, reset_handler

.rodata
tiles_chr:
  .incbin "obj/nes/tiles.ch1"
tiles_chr_count = (* - tiles_chr) / 8

help_strips:
  OBJSTRIP  18,152,7,$10  ; Convergence
  OBJSTRIP  18,160,3,$18  ; Test
  OBJSTRIP  18,172,4,$04  ; Copr. 20xx
  OBJSTRIP  16,180,8,$08  ; Damian Yerrick
  OBJSTRIP  18,192,3,$1C  ; <- Grid
  OBJSTRIP  18,200,1,$1F  ; ->
  OBJSTRIP  26,200,1,$10  ; Co
  OBJSTRIP  34,200,2,$26  ; lor
  OBJSTRIP  18,208,6,$20  ; Start: Help
  .byte $00
center_dot_strips:
  OBJSTRIP 124,116,1,$01  ; center dot
  .byte $00

.code
.proc nmi_handler
  inc nmis
  rti
.endproc

.proc reset_handler
  ; Hardware initialization
  sei
  ldx #0
  stx PPUCTRL  ; no NMI
  stx PPUMASK  ; no rendering
  stx $4015    ; no audio
  dex
  txs
  lda #$40
  sta $4017    ; no APU Frame IRQ
  jsr getTVSystem
  sta tvSystem

  ; Enable NMI and load graphics
  lda tvSystem
  beq :+
    jsr draw_pal_bg
    jmp have_tilemap
  :
    jsr draw_ntsc_bg
  have_tilemap:
  jsr unpack_tiles
  
  ; Load sprite palette
  lda nmis
  :
    cmp nmis
    beq :-

  ; Sprite color 1: White
  lda #$3F
  ldx #$11
  sta PPUADDR
  stx PPUADDR
  ldx #$20
  stx PPUDATA
  
  ; Initialize state
  lda #1
  sta help_on
  sta center_dot_on
  lsr a
  sta bg_is_solid
  lda #BGCOLOR_A
  sta solid_bg_color

forever:
  ; Handle input
  jsr read_pad0
  lda new_keys
  lsr a
  bcc notRight
    ; Right while grid on: Turn grid off
    ; Right while grid off: Toggle color
    lda bg_is_solid
    bne isRightRight
      inc bg_is_solid
      jmp notLR
    isRightRight:
      lda solid_bg_color
      eor #BGCOLOR_A ^ BGCOLOR_B
      sta solid_bg_color
      jmp notLR
  notRight:

  lsr a
  bcc notLeft
    ; Left while grid off: Turn grid on
    ; Left while grid on: Toggle center dot
    lda bg_is_solid
    beq isLeftLeft
      lda #0
      sta bg_is_solid
      jmp notLR
    isLeftLeft:
      lda center_dot_on
      eor #1
      sta center_dot_on
  notLeft:
  notLR:

  lda new_keys
  and #KEY_START
  beq notStart
    lda #1
    eor help_on
    sta help_on
  notStart:

  ; Calculate what graphics shall be shown
  jsr build_display_list
  
  lda bg_is_solid
  bne colorcalc_is_grid
    ldy #$0F
    lda #$10
    bne colorcalc_have
  colorcalc_is_grid:
    ldy solid_bg_color
    tya
  colorcalc_have:
  sty cur_bgcolors+0
  sta cur_bgcolors+1

  ldy #$20
  cpy cur_bgcolors+1
  bne have_objcolor
    ldy #$00
  have_objcolor:
  sty cur_objcolor

  lda nmis
  :
    cmp nmis
    beq :-
  
  ; Copy display list to OAM
  lda #$80
  sta PPUCTRL
  ldx #$00
  stx OAMADDR
  ldy #>OAM
  sty OAM_DMA

  ; Copy palette
  ldy #$3F
  sty PPUADDR
  stx PPUADDR
  ldy cur_bgcolors+0
  sty PPUDATA
  ldy cur_bgcolors+1
  sty PPUDATA
  ldy #$3F
  sty PPUADDR
  ldy #$11
  sty PPUADDR
  ldy cur_objcolor
  sty PPUDATA

  ; Set up rendering
  stx PPUSCROLL
  stx PPUSCROLL
  sta PPUCTRL
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  
  jmp forever
.endproc

.proc unpack_tiles
src = $00
count_cd = $02
  lda #VBLANK_NMI
  sta PPUCTRL
  asl a
  sta PPUMASK
  sta PPUADDR
  sta PPUADDR
  lda #<tiles_chr
  sta src+0
  lda #>tiles_chr
  sta src+1
  lda #tiles_chr_count
  sta count_cd
  ldy #0
  tileloop:
    plane_0_byteloop:
      lda (src),y
      sta PPUDATA
      iny
      cpy #8
      bcc plane_0_byteloop
    lda #8-1
    adc src
    sta src
    bcc :+
      inc src+1
    :
    lda #0
    plane_1_byteloop:
      sta PPUDATA
      dey
      bne plane_1_byteloop
    dec count_cd
    bne tileloop
  rts
.endproc

.proc draw_helpobj
src = $00
xcoord = $02
ycoord = $03
tilenum = $04
width_cd = $05
  sta src+1
  sty src+0
  ldy #0
  striploop:
    lda (src),y 
    beq done
    sta width_cd
    iny
    lda (src),y 
    sta xcoord
    iny
    lda (src),y 
    sta ycoord
    iny
    lda (src),y
    sta tilenum
    clc
    tileloop:
      lda ycoord
      sta OAM,x
      inx
      lda tilenum
      inc tilenum
      sta OAM,x
      inx
      lda #0
      sta OAM,x
      inx
      lda xcoord
      sta OAM,x
      inx
      adc #8
      bcs stripdone
      sta xcoord
      dec width_cd
      bne tileloop
    stripdone:
    iny
    bne striploop
  done:
  rts
.endproc

.proc read_pad0
padreadtmp = $00
  lda #1
  sta $4016
  sta padreadtmp
  lsr a
  sta $4016
  loop:
    lda $4016
    and #$03  ; D0: NES plugin or FC hardwired pad; D1: FC plugin pad
    cmp #$01
    rol padreadtmp
    bcc loop
  lda cur_keys
  eor #$FF
  and padreadtmp
  sta new_keys
  lda padreadtmp
  sta cur_keys
  rts
.endproc

.proc build_display_list
  ldx #0

  lda bg_is_solid
  bne no_center_dot
  lda center_dot_on
  beq no_center_dot
    lda #>center_dot_strips
    ldy #<center_dot_strips
    jsr draw_helpobj
  no_center_dot:

  lda help_on
  beq no_help
    lda #>help_strips
    ldy #<help_strips
    jsr draw_helpobj
  no_help:

  lda #$FF
  xendloop:
    sta OAM,x
    inx
    bne xendloop
  rts
.endproc

.proc draw_ntsc_bg
tilenum = $00

  lda #VBLANK_NMI|VRAM_DOWN
  sta PPUCTRL
  bit PPUSTATUS
  lda #$2A
  sta tilenum
  ldx #$1F
  colloop:
    lda #$20
    sta PPUADDR
    stx PPUADDR
    dec tilenum
    lda tilenum
    cmp #$28
    bcs :+
      lda #$2E
      sta tilenum
    :
    ldy #30
    :
      sta PPUDATA
      dey
      bne :-
    dex
    bpl colloop
  jmp clear_attrs
.endproc

.proc draw_pal_bg
tilenum = $00

  lda #VBLANK_NMI
  sta PPUCTRL
  bit PPUSTATUS
  lda #$37
  sta tilenum
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  ldx #29
  colloop:
    lda tilenum
    clc
    adc #3
    cmp #$3B
    bcc :+
      sbc #11
    :
    sta tilenum
    cmp #$38
    bcc :+
      lda #$2F
    :
    ldy #32
    :
      sta PPUDATA
      dey
      bne :-
    dex
    bne colloop
  ; fall through
.endproc
.proc clear_attrs
  lda #VBLANK_NMI
  sta PPUCTRL
  asl a
  ldx #$23
  ldy #$C0
  stx PPUADDR
  sty PPUADDR
  :
    sta PPUDATA
    iny
    bne :-
  rts
.endproc

