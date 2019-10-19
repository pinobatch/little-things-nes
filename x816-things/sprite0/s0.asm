;Copyright 2000 Damian Yerrick
;
;Redistribution and use in source and binary forms, with or without
;modification, are permitted provided that the following conditions
;are met: 
;
;1. Redistributions of source code must retain the above copyright
;   notice, this list of conditions and the following disclaimer.
;2. Redistributions in binary form must reproduce the above copyright
;   notice, this list of conditions and the following disclaimer in
;   the documentation and/or other materials provided with the
;   distribution. 
;THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY
;EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
;PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
;BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
;OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
;OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
;BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
;OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
;EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

;
; s0
; sprite 0 demo
; Copyright 2000 Damian Yerrick
; assemble awith ASM6
;
; If you are planning on using this code in a Real NES, put it
; in an NROM cartridge.  The iNES board number for NROM is 0.
;
; 0000 direct page
; 0100 stack
; 0200 sprite DMA area
; 0300 NT2 replay code main ram area
; 0400 the map
; 0480 second field, used for redraw manager
; 0500 unused
; 0800 ---
; 8000 replay code
; 9000
; e000 nametables and other data tables
; f000
; fffa interrupt vectors
;

.incbin "nromhead.bin"

                .org $c000

;PPU regs
spraddr = $2003
sprdma = $4014
ppuaddr = $2006
ppudata = $2007

nametableid = 16

repeats1 = $c0
repeats2 = $c8

randseed = $f8
retraces = $fa          ; (16 bits) the number of retraces
control1 = $fc          ; data read from controllers
control2 = $fd
control3 = $fe
control4 = $ff


sprbuf = $200           ; sprite dma communication area




;
; main()
;
; Nintendo wrote the first part of the init code in _Duck_Hunt_.
; Kevin Horton and Chris Covell played with it before I put it in.
;

resetcode       cld
                sei

                ldx #$00  ;turn off screen display
                stx $2000
                stx $2001
                stx ppuaddr
                stx ppuaddr
                txa       ;a zero will rest in A for most of the init code
                dex       ;move top of stack to $1ff
                txs
                jsr bootwait4vbl

;clear the NES's CPURAM
                tay

-               sta 0,y
                sta $100,y
                sta $300,y
                sta $400,y
                sta $500,y
                sta $600,y
                sta $700,y
                dey
                bne -
                jsr bootwait4vbl

;clear out sprites
                tax
-               lda #$ef
		sta sprbuf,x   ;Y = 241
		inx
		inx
		inx
		inx
		inx
                bne -
                lda #128        ;set initial sprite
                sta $200
                lda #$69        ; medium brightness, not biggest
                sta $201
                lda #0
                sta $202
                lda #128
                sta $203

                lda #$24
                sta ppuaddr
                ldx #0
                stx ppuaddr
                lda #$78
                ldy #240
-                
                sta ppudata
                stx ppudata
                sta ppudata
                stx ppudata
                dey
                bne -
                ldy #16
-                
                stx ppudata
                stx ppudata
                stx ppudata
                stx ppudata
                dey
                bne -
                lda #$79
                ldy #240
-                
                sta ppudata
                stx ppudata
                sta ppudata
                sta ppudata
                dey
                bne -
                ldy #16
-                
                stx ppudata
                stx ppudata
                stx ppudata
                stx ppudata
                dey
                bne -
                ldx #titlepal-pals
                jsr putpal

                lda #%10011000
                sta nametableid
                sta $2000
                jsr wait4vbl
                lda #0
                sta spraddr
                sta $2002
                sta $2002
		lda #>sprbuf
                sta sprdma      ;start sprite DMA
                lda #%00011110
                sta $2001

mainloop
                bit $2002
                bmi gotvbl
                bvs gotspr0
                bvc mainloop

gotspr0
                lda #%00010100
                sta $2001
                ldy #0
                lda #%00011110
-
                dey
                bne -
                sta $2001


                jsr wait4vbl

gotvbl
                lda nametableid
                sta $2000
                lda #%00011110
                sta $2001
                jsr ReadJPad
                jsr MakeRepeats

                lda repeats1
                and #%00001111
                cmp #1
                bne +
                inc $201
                lda $201
                cmp #$78
                bcc +
                lda #$60
                sta $201
+
                lda repeats1+1
                and #%00001111
                cmp #1
                bne +
                dec $201
                lda $201
                cmp #$60
                bcs +
                lda #$77
                sta $201
+
                lda repeats1+2
                cmp #1
                bne +
                lda nametableid
                eor #%00000011
                sta nametableid
+
                lda repeats1+4
                and #%00001111
                cmp #1
                bne +
                dec $200
+
                lda repeats1+5
                and #%00001111
                cmp #1
                bne +
                inc $200
+
                lda repeats1+6
                and #%00001111
                cmp #1
                bne +
                dec $203
+
                lda repeats1+7
                and #%00001111
                cmp #1
                bne +
                inc $203
+
                lda #0
                sta $2005
                sta $2005
                sta spraddr
                lda #>sprbuf
                sta sprdma
                ldy #0
-
                dey
                bne -
                jmp mainloop

                
                


;
; ===============================
;   END OF MAIN BODY OF PROGRAM
; ===============================
;















;
; MakeRepeats
; Translates controllers into autorepeats.
; Trashes: A X Y

MakeRepeats     lda control1
                ldx #7
-
                lsr a
                bcs +
                ldy #0
                beq ++
+
                ldy repeats1,x
                iny
                cpy #18
                bcc ++
                ldy #16
++
                sty repeats1,x
                dex
                bpl -

                lda control2
                ldx #7
-
                lsr a
                bcs +
                ldy #0
                beq ++
+
                ldy repeats2,x
                iny
                cpy #18
                bcc ++
                ldy #16
++
                sty repeats2,x
                dex
                bpl -

                rts




;
; wait4vbl
; waits for vertical blank
;

wait4vbl
  lda retraces
  -
    cmp retraces
    beq -
  rts

bootwait4vbl    bit $2002
                bpl bootwait4vbl
                rts

;
; putpal
; Copies 32 bytes from (pals,x) to the palette.  Call during VBL.
;

putpal
                lda #$3F
                sta ppuaddr
                lda #0
                sta ppuaddr
                
                ldy #$20
-               lda pals,x
                sta ppudata
                inx
                dey
                bne -
                rts


;
; ReadJPad
; Poll the controllers.
;

ReadJPad
; Read controllers 1 and 3.
                lda #1
                sta $4016
                lda #0
                sta $4016
                ldx #8
-               lda $4016
                lsr a
                rol control1
                dex
                bne -
                ldx #8
-               lda $4016
                lsr a
                rol control3
                dex
                bne -

; Read controllers 2 and 4.
                lda #1
                sta $4017
                lda #0
                sta $4017
                ldx #8
-               lda $4017
                lsr a
                rol control2
                dex
                bne -
                ldx #8
-               lda $4017
                lsr a
                rol control4
                dex
                bne -
                rts

;
; DATA TABLES
;

                .pad $fe00      ; enough for a few compressed name
                                ; tables and a few other data tables


; palette
pals

; palette for title screen and game
titlepal        .db $0f,$10,$00,$30,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
                .db $0f,$04,$14,$24,$30,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f

                .pad $ff00


;
; nmipoint
; Increment retrace.
;

nmipoint
                inc retraces
irqpoint
                rti

resetpoint
                 ;set up mapper to bring in first bank
                 jmp resetcode

;interrupt table
                .pad $fffa
                .dw nmipoint
                .dw resetpoint
                .dw irqpoint

                .incbin "s0.chr"    ;made with tlayer
