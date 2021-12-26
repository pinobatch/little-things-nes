.export setup_selfmodarea, selfmodarea

ASL_ABS = $0E
ROL_ABS = $2E
LSR_ABS = $4E
ROR_ABS = $6E
DEC_ABS = $CE
INC_ABS = $EE
DEC_X   = $CA
DEC_Y   = $88
BNE_REL = $D0
POP_PC  = $60

SPAMINC_WRITES_PER_ITERATION = 26

.bss
.align 128
selfmodarea:
  .res SPAMINC_WRITES_PER_ITERATION * 3 + 4
selfmodarea_end:

.code
.proc setup_selfmodarea
  ; Fetch the instruction
  lda selfmod_instruction,x
  sta selfmodarea+0
  lda selfmod_addrlo,x
  sta selfmodarea+1
  lda selfmod_addrhi,x
  sta selfmodarea+2

  ; Repeat it
  ldx #(SPAMINC_WRITES_PER_ITERATION - 1) * 3
  loop:
    lda selfmodarea+0
    sta selfmodarea+0,x
    lda selfmodarea+1
    sta selfmodarea+1,x
    lda selfmodarea+2
    sta selfmodarea+2,x
    dex
    dex
    dex
    bne loop

  ; And set up the jump
  lda #DEC_Y
  sta selfmodarea_end-4
  lda #BNE_REL
  sta selfmodarea_end-3
  lda #<(selfmodarea - (selfmodarea_end - 1))
  sta selfmodarea_end-2
  lda #POP_PC
  sta selfmodarea_end-1
  rts
.endproc

.rodata

; 0: inc $8001 -- controls CHR page in PPU $0000-$07FF
; 1: asl $8000 -- swaps CHR at PPU $0000-$0FFF and $1000-$1FFF
; 2: lsr $A000 -- swaps tilemaps at PPU $2400-$27FF and $2800-$2BFF
; 3: dec $8001 -- writes 3 then 2 as a control

selfmod_instruction:  .byte INC_ABS, ASL_ABS, LSR_ABS, DEC_ABS
selfmod_addrlo:       .byte $01,     $00,     $00,     $01
selfmod_addrhi:       .byte $80,     $80,     $A0,     $80

.segment "ROM8000"
.assert * = $8000, error, "pattern not at $8000"
.byte $80, $03

.segment "ROMA000"
.assert * = $A000, error, "pattern not at $A000"
.byte $01
