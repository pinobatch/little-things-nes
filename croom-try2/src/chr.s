.p02
.include "global.inc"

.segment "CODE"

; y: source and destination address
; x: 
.proc loadCHR
  src = 0
  nTiles = 2
  
  ; set mapper bank 1
  ldx #1
  stx $E000
  dex
  stx $E000
  stx $E000
  stx $E000
  stx $E000
  
  tya
  asl a
  asl a
  tax
  lda lastPPUCTRL
  sta PPUCTRL
  lda loadCHRTable+1,x
  sta src+1
  lda loadCHRTable+2,x
  sta PPUADDR
  bmi isCompressed
  lda loadCHRTable+3,x
  sta PPUADDR
  lda loadCHRTable+0,x
  sta nTiles
  lda #0
  sta src

copyloop:
  ldx #4
  ldy #0
subloop:
  lda (src),y
  sta PPUDATA
  iny
  lda (src),y
  sta PPUDATA
  iny
  lda (src),y
  sta PPUDATA
  iny
  lda (src),y
  sta PPUDATA
  iny
  dex
  bne subloop
  tya
  clc
  adc src
  sta src
  bcc :+
  inc src+1
:
  dec nTiles
  bne copyloop
  rts

isCompressed:
  lda loadCHRTable+3,x
  sta PPUADDR
  lda loadCHRTable,x
  sta src
  jmp PKB_unpackblk  
.endproc

.proc loadFont
  src = 0
  nTiles = 2
  asciiTemp = 2  ; 3 to 10

  lda #<ascii_chr
  sta src
  lda #>ascii_chr
  sta src+1
  lda lastPPUCTRL
  sta PPUCTRL
  lda #$02
  sta PPUADDR
  ldy #0
  sty PPUADDR

  ; set mapper bank 0
  sty $E000
  sty $E000
  sty $E000
  sty $E000
  sty $E000

  lda #112
  sta nTiles
  copyloop:
    ldx #8
    chrCopy1:
      lda (src),y
      sta PPUDATA
      sta asciiTemp,x
      iny
      dex
      bne chrCopy1
    ldx #8
    chrCopy2:
      lda asciiTemp,x
      sta PPUDATA
      dex
      bne chrCopy2
    cpy #0
    bne :+
    inc src+1
  :
    dec nTiles
    bne copyloop
  rts
.endproc

; bank 0
.segment "RODATA0"
presetsBnames: .incbin "src/presetNames.bin"
presetsAnames = presetsBnames + 80*32
presetsB16: .incbin "obj/nes/presetsB16.chr"
presetsA16: .incbin "obj/nes/presetsA16.chr"
ascii_chr: .incbin "ascii.chr"

.segment "RODATA1"

; if byte 2 is 80-FF, data is rle compressed:
; 0-1: start of compressed data (length then packbits bitstream)
; 2: high byte of vram dst addr
; 3: low byte of vram dst addr
; if byte 2 is 00-7F, data is uncompressed:
; 0: length of data in 16-bit units
; 1: high byte of src addr (MUST be page aligned)
; 2: high byte of vram dst addr
; 3: low byte of vram dst addr
loadCHRTable:
  ; 0: editor tiles
  .byt 28, >tools_chr
  .dbyt $0000
  ; 1: keyboard background
  .addr keyboardFrame_pkb
  .dbyt $A000
  ; 2: studio tiles
  .byt 48, >studio_chr
  .dbyt $0D00
  ; 3: studio background
  .addr studio_pkb
  .dbyt $A000
  ; 4: copyright screen background
  .addr copr_pkb
  .dbyt $A000
  ; 5: tableau tiles 00-2F
  .addr tableau_chr
  ; 6: tableau tiles 80-BF
  .addr numbers16_chr

keyboardFrame_pkb:
  .incbin "obj/nes/keyboardFrame.pkb"
studio_pkb:
  .incbin "obj/nes/studio.pkb"
copr_pkb:
  .incbin "obj/nes/copr.pkb"
.align 256
tools_chr:
  .incbin "tools.chr"
studio_chr:
  .incbin "studio.chr"
tableau_chr:
  .incbin "obj/nes/tableau.chr"
numbers16_chr:
  .incbin "obj/nes/numbers16.chr"
