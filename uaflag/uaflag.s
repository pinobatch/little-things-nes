.p02
PPUCTRL = $2000
  VBLANK_NMI = $80
PPUMASK = $2001
  BG_ON = $0A
PPUSTATUS = $2002
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007

.segment "INESHDR"
.byte "NES",$1A
.byte 1, 0, 0, 0

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.code
nmi_handler:
irq_handler:
  rti

reset_handler:
  sei
  cld
  ldx #$FF
  txs
  inx
  stx PPUCTRL
  stx PPUMASK
  bit PPUSTATUS
  vw1:
    bit PPUSTATUS
    bpl vw1
  vw2:
    bit PPUSTATUS
    bpl vw2

  lda #$3F
  sta PPUADDR
  stx PPUADDR
  sta PPUDATA  ; bg
  stx PPUDATA  ; unused color
  lda #$11  ; blue
  sta PPUDATA
  lda #$28  ; yellow
  sta PPUDATA

  txa
  sta PPUADDR
  sta PPUADDR
  chrloop:
    ldx #24
    :
      sta PPUDATA
      dex
      bne :-
    eor #$FF
    bmi chrloop

  ; the flag has a proportion of 2 tall by 3 wide, top half blue
  ; and bottom half yellow
  ; Ukraine used 50 Hz video, and 50 Hz NES has a roughly 18:13
  ; pixel aspect ratio
  ; so ideally the height of each half should be 18/13*1/3*252
  ; or 116 pixels
  ; let's just round that up to 120 or half the screen
  lda #$20
  sta PPUADDR
  stx PPUADDR
  lda #1
  jsr write480
  asl a
  jsr write480
  lda #0
  ldx #32
  jsr write2x

  vw3:
    bit PPUSTATUS
    bpl vw3

  lda #VBLANK_NMI
  sta PPUCTRL
  asl a
  sta PPUSCROLL
  sta PPUSCROLL
  lda #BG_ON
  sta PPUMASK

  forever:
    jmp forever

write480:
  ldx #240
  write2x:
    sta PPUDATA
    sta PPUDATA
    dex
    bne write2x
  rts
