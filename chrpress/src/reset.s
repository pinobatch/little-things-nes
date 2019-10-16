.include "nes.inc"
.include "global.inc"
.p02

.exportzp psg_sfx_state

.segment "ZEROPAGE"
nmis: .res 1
cur_keys: .res 2
new_keys: .res 2
psg_sfx_state: .res 32

.segment "INESHDR"
  .byt "NES",$1A
  .byt 1  ; 16 KiB PRG ROM
  .byt 0  ; 8 KiB CHR RAM
  .byt 1  ; vertical mirroring; low mapper nibble: 0
  .byt 0  ; high mapper nibble: 0

.segment "VECTORS"
  .addr nmi, reset, irq

.segment "CODE"
.proc irq
  rti
.endproc

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
  lda $4015      ; ack DPCM IRQ
  ; Set up the stack
  dex
  txs
  
  ; Wait for the PPU to warm up (part 1 of 2)
vwait1:
  bit PPUSTATUS
  bpl vwait1

  ; While waiting for the PPU to finish warming up, we have about
  ; 29000 cycles to burn without touching the PPU.  So we have time
  ; to initialize some of RAM to known values.
  ; Ordinarily the "new game" initializes everything that the game
  ; itself needs, so we'll just do zero page and shadow OAM.
  
  ldy #$00
  lda #$F0
  ldx #$00
clear_zp:
  sty $00,x
  sta OAM,x
  inx
  bne clear_zp
  
  ; Wait for the PPU to warm up (part 2 of 2)
vwait2:
  bit PPUSTATUS
  bpl vwait2

; step 1: load a palette while we're still solidly in blanking
  lda #$3F
  sta PPUADDR
  ldy #$00
  sty PPUADDR
  sty PPUCTRL
palloop:
  lda testpal,y
  sta PPUDATA
  iny
  cpy #$20
  bcc palloop

; step 2: clear the nametable and open up an area to show all tiles
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  ldx #$F0
  lda #$10
clear_vram_loop:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  dex
  bne clear_vram_loop
  txa
  ldx #64
clear_attr_loop:
  sta PPUDATA
  dex
  bne clear_attr_loop  

  lda #$21
  sta PPUADDR
  lda #$08
  sta PPUADDR
  stx PPUADDR
  bgdebug_rowloop:
    ldy #$10
    bgdebug_tileloop1:
      stx PPUDATA
      inx
      dey
      bne bgdebug_tileloop1
    ldy #$10
    tya
    bgdebug_tileloop2:
      sta PPUDATA
      dey
      bne bgdebug_tileloop2
    txa
    bne bgdebug_rowloop

  ; step 3: test decompression
  lda #$80
  sta PPUCTRL
  jsr testLoadCHR

  ; step 4: turn on the screen
  lda #$80
  sta PPUCTRL

  lda nmis
:
  cmp nmis
  beq :-
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #%00001010
  sta PPUMASK
:
  jmp :-
.endproc

.import testCompression
.proc testLoadCHR
  jsr testCompression
  rts
.endproc

.segment "RODATA"
testpal:
  .byt $0F,$12,$27,$2A,$0F,$00,$00,$00,$0F,$00,$00,$00,$0F,$00,$00,$00
  .byt $0F,$12,$27,$2A,$0F,$00,$00,$00,$0F,$00,$00,$00,$0F,$00,$00,$00

