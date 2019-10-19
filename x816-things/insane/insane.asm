;
; insane.asm
; NES Insane source code
; Copyright 2000 Damian Yerrick
; compile with x816 assembler available from
; http://www.zophar.net/
;
; If you are planning on using this code in a Real NES, put it
; in an NROM (e.g. Super Mario Bros.) cartridge.  The iNES
; board number for NROM is 0.
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
; To do yet:
;  multiply
;  divide
;  bin2dec
;  UpdateScore (writes player's five-digit score to sprites 3-7)
;  makemfall
;  makemshift
;
;
; 0000 direct page
; 0080 NT2 replay code direct page area
; 00C0 direct page
; 0100 stack
; 0200 sprite DMA area
; 0300 NT2 replay code main ram area
; 0400 field
; 0480 second field, used for redraw manager
; 0500 unused
; 0800 ---
; 8000 replay code
; 9000
; e000 nametables and other data tables
; f000
; fffa interrupt vectors
;
    .incbin "neshead.bin"
;                .opt on
;                .mem 8
;                .index 8
                .org $8000
;                .list

;PPU regs
spraddr = $2003
sprdma = $4014
ppuaddr = $2006
ppudata = $2007

;
; global variables.
; All 16-bit variables are little endian.
;

; 0 to 3 are temporary storage.

control1 = 4            ; controller 1 data
control2 = 5            ; controller 2 data
control3 = 6            ; controller 3 data
control4 = 7            ; controller 4 data
gameType = 8            ; 0: puzzle; 1: action

randSeed        = 10    ; (16 bits) random number seed
delayMaker      = 12    ; (16 bits) the time until next cycle
gameSpeed       = 14    ; (16 bits) current speed of the game
xcurs           = 16    ; cursor distance from left side in blocks
ycurs           = 17    ; cursor distance from top in blocks
lcursflip       = 18    ; the attribute of the left half of the cursor
rcursflip       = 19    ; the attribute of the right half of the cursor
filled          = 20    ; number of blocks cleared in flood fill

score           = 24    ; (8 bytes)

repeats = $f0           ; (8 bytes) used for key autorepeating
rdmgrline = $f8         ; the lowest line of blocks that's dirty
retraces = $fa          ; (16 bits) the number of retraces

sprbuf = $200		; sprite area
field = $400            ; main playfield
field2 = $480           ; 



GAMETYPEACTION = 1
GAMETYPEPUZZLE = 0

                .incsrc "replay22.inc" ;Bananmos's NerdTracker II replay code

                .db 13, 10, "music code by bananmos", 13, 10
                .db "everything else copyright 2000 damian yerrick", 13, 10

;
; main()
;
; Nintendo wrote the first part of the init code in _Duck_Hunt_.
; Kevin Horton and Chris Covell played with it before I put it in.
;

resetpoint      cld
                sei
                jsr wait4vbl

                ldx #$00  ;turn off screen display
                stx $2000
                stx $2001
                txa       ;a zero will rest in A for most of the init code
                dex       ;move top of stack to $1ff
                txs

;clear the NES's CPURAM
                ldy #7    ;from 0 to $7ff
                sty 1
                sta 0
                tay

-               sta ($00),y     ;Clear $100 bytes
                dey
                bne -
                dec 1           ;Decrement high byte of pointer
                bpl -           ;keep going if still positive

;clear out sprites
                sta spraddr
                tax
-               lda #$ef
		sta sprbuf,x   ;Y = 241
		inx
		lda #$b6
                sta sprbuf,x   ;index = blank
		inx
                lda #0
		sta sprbuf,x   ;no flip, front, color 0
		inx
                sta sprbuf,x   ;X = 0
		inx
                bne -
		lda #>sprbuf
		sta $4014	;start sprite DMA
		lda #0

;clear out 4K of nametables
                ldy #$20
                sty ppuaddr
                sta ppuaddr ;still got the zero... (ppuram address)
                tax
                ldy #4      ;each pass through the x loop will clear 1K
-               sta ppudata
                sta ppudata
                sta ppudata
                sta ppudata
                dex
                bne -
                dey
                bne -

;initialize palette
                ldx #$3F
                stx ppuaddr
                sta ppuaddr
                tax
                ldy #$20
-               lda titlepal,x
                sta ppudata
                inx
                dey
                bne -
                tya             ;put that zero back in A

                lda #<p8swdata
                sta 0
                lda #>p8swdata
                sta 1
                jsr copynametable

                lda #0
                sta ppuaddr
                sta ppuaddr

                lda #2          ;start pin eight music
                jsr $8003

wait4copy       jsr wait4endvbl
                lda retraces
                cmp #192
                bcs +
                jsr $8000
                jmp ++
+
                cmp #214
                bne +
                lda #((sanedata >> 6) & $00ff) + 9
                sta $4012
                lda #20
                sta $4013
                lda #$0d
                sta $4010
                lda #$40
                sta $4011
                lda #$10
                sta $4015
+
                cmp #224
                bne ++
                lda #0
                sta $4013
                sta $4015
                lda #((sanedata >> 6) & $00ff)
                sta $4012
                lda #56
                sta $4013
                lda #$0d
                sta $4010
                lda #$40
                sta $4011
                lda #$10
                sta $4015

++
                jsr wait4vbl

                jsr ReadJPad
                lda retraces+1
                beq wait4copy

                lda #0
                jsr $8003

; Copy the title screen.

title		lda #0

                jsr wait4endvbl
                jsr $8000
                jsr wait4vbl
                jsr ReadJPad
                lda control1
                bne title
                lda #<titledata
                sta 0
                lda #>titledata
                sta 1
                jsr copynametable

                lda #$5f
                sta sprbuf
		sta sprbuf+4
                lda #$90
                sta sprbuf+1
                lda #0
                sta sprbuf+2
                lda #$78
                sta sprbuf+3
                lda #$90
                sta sprbuf+5
                lda #%11000000
                sta sprbuf+6
                lda #$80
                sta sprbuf+7

                lda #0
                sta spraddr
		lda #>sprbuf
		sta sprdma

titlewait       jsr wait4endvbl
                jsr $8000
                jsr wait4vbl
                jsr ReadJPad
                lda control1
                beq titlewait
                asl a
                bcs action
                asl a
                bcs puzzle
                asl a
                bcs titleselect
                asl a
                bcs titlestart
                asl a
                bcs trumpet
                asl a
                bcs titledown
                asl a
                bcs titleleft
                asl a
                bcs titleright
                bcc titlewait


;
; Menu jumptable
;

puzzle
                lda #GAMETYPEPUZZLE
                sta gameType
                jmp NewGame

action
                lda #GAMETYPEACTION
                sta gameType
                jmp NewGame

titleselect     jmp credit

titlestart
titledown
titleleft
titleright
                jmp titlewait


;
; trumpet
;

trumpet
                lda #76
                sta $70

-               lda #0
                sta $4015

trumpetloop     lda control1
                sta $74
                lda #0
                sta ppuaddr
                sta ppuaddr
                jsr wait4endvbl
                jsr wait4vbl

                jsr ReadJPad
                lda $74
                eor control1
                beq trumpetloop

                lda control1
                sta 3
                and #%1111
                tax
                lda trumpetoctaves,x
                beq -

                ldx #0
-               asl 3
                bcc +
                sbc trumpetkeys,x
+               inx
                cpx #4
                bne -

                pha

                lda #1
                sta $4015                
                lda #%00111010
                sta $4000
                lda #0
                sta $4001

                pla
                jsr midi2freq
                sta $4002
                lda 1
                sta $4003
                jmp trumpetloop

trumpetoctaves  .db 0,82,70, 0, 58, 0,65, 0, 77,80,74, 0,  0, 0, 0, 0
trumpetkeys     .db 5, 3, 2, 1


credit          
                lda #<creditdata
                sta 0
                lda #>creditdata
                sta 1
                jsr $8000
                jsr copynametable
-
                jsr wait4endvbl
                jsr $8000
                jsr wait4vbl
                jsr ReadJPad
                lda control1
                bne -
-
                jsr wait4endvbl
                jsr $8000
                jsr wait4vbl
                jsr ReadJPad
                lda control1
                beq -
                jsr $8000
                jmp title




;
; NewGame
; Set up a new game.
;

NewGame
                lda #<gamebgdata
                sta 0
                lda #>gamebgdata
                sta 1
                jsr copynametable

                lda retraces
                sta randSeed
                lda retraces+1
                sta randSeed+1
                ldx #0
                lda gameType
                beq +
                ldx #48
+               stx delayMaker
                lda #2
                ldx #95
-               jsr rand5
                sta field,x
                dex
                bmi +
                cpx delayMaker
                bcs -
                lda #0
-               sta field,x
                dex
                bpl -
+
                lda #6
                sta xcurs
                lda #4
                sta ycurs
                lda #%00000000
                sta lcursflip
                lda #%11000000
                sta rcursflip
                jsr putcurs
                lda #7
                sta rdmgrline
		tax

                lda #1
-		sta repeats,x
		dex
		bpl -

		lda #1		;chopin.ned
                jsr $8003

gameloop
                jsr wait4endvbl
                jsr putcurs
                jsr $8000
                jsr ReadJPad
                jsr MakeRepeats

                lda repeats+4
                and #$0f
                cmp #1
                bne no_up
                ldy ycurs
                dey
                bpl +
                ldy #7
+               sty ycurs
no_up

                lda repeats+5
                and #$0f
                cmp #1
                bne no_down
                ldy ycurs
                iny
                cpy #8
                bcc +
                ldy #0
+               sty ycurs
no_down

                lda repeats+6
                and #$0f
                cmp #1
                bne no_left
                ldy xcurs
                dey
                bpl +
                ldy #11
+               sty xcurs
no_left

                lda repeats+7
                and #$0f
                cmp #1
                bne no_right
                ldy xcurs
                iny
                cpy #12
                bcc +
                ldy #0
+               sty xcurs
no_right

                lda repeats
                cmp #1
                bne +
                jsr HandleClick
+
                jsr wait4vbl

.if 0
                lda #$20
                sta ppuaddr
                lda #$e8
                sta ppuaddr
                ldy #0
-
                lda repeats,y
                jsr puthex
                iny
                cpy #8
                bcc -
.endif
                jsr Redraw2row
                jmp gameloop    ;endless loop


;
; HandleClick
;

HandleClick
                jsr HasNeighbor
                cmp #0
                beq +

                lda #7
                sta rdmgrline

                jsr FloodFill
.if 0
                lda twelves,y
                clc
                adc xcurs
                tax
                lda #0
                sta field,x
.endif
+
                rts

















;
; ===============================
;   END OF MAIN BODY OF PROGRAM
; ===============================
;

;
; MakeRepeats
; Translates controller 1 into autorepeats.
; Trashes: A X Y

MakeRepeats     lda control1
                ldx #7
-
                lsr a
                bcs +
                ldy #0
                beq MakeRepeats_loop
+
                ldy repeats,x
                iny
                cpy #18
                bcc MakeRepeats_loop
                ldy #16
MakeRepeats_loop
                sty repeats,x
                dex
                bpl -
                rts


;
; HasNeighbor
; Return zero in A if the piece under the cursor has no neighbors
; or nonzero if the piece under the cursor has a neighbor.
; Trashes: A X
;

HasNeighbor     ldx ycurs
                lda twelves,x
                clc
                adc xcurs
                tax
                lda field,x
                bne +           ;If the block is empty, it has no neighbors.
                rts
+               tay
                lda xcurs       ;Check to the left.
                beq +
                tya
                cmp field-1,x
                bne +
                rts
+               lda xcurs       ;Check to the right.
                cmp #11
                beq +
                tya
                cmp field+1,x
                bne +
                rts
+               sta 3
                lda ycurs       ;Check up.
                beq +
                tya
                cmp field-12,x
                bne +
                rts
+               lda ycurs       ;Check down.
                cmp #7
                beq +
                tya
                cmp field+12,x
                bne +
                rts
+               lda #0
                rts

;
; FloodFill
; Fills the area at (xcurs, ycurs) with 0.
; Trashes a, x, y, 3.
;

FloodFill       ldx ycurs
                lda #0
                sta filled
                lda twelves,x
                clc
                adc xcurs
                tay
                ldx xcurs
                lda field,y
                sta 3
                bne +
                rts
+
FloodFill_loop                  ;check left side
                lda 3
                dey
                dex
                bmi +
                cmp field,y
                beq FloodFill_loop
+
                inx
                stx 0
                iny
                sty 1
-                               ;check right side
                lda #0
                sta field,y
                inc filled
                inx
                iny
                cpx #12
                beq +
                lda 3
                cmp field,y
                beq -
+
                stx 2
                ldx 0
                lda 1           ;check up
                sec
                sbc #12
                bcc ++
                tay
                lda 3
-
                cmp field,y
                bne +
                lda 0
                pha
                lda 1
                pha
                lda 2
                pha
                txa
                pha
                tya
                pha
                jsr FloodFill_loop
                pla
                tay
                pla
                tax
                pla
                sta 2
                pla
                sta 1
                pla
                sta 0
+
                iny
                inx
                cpx 2
                bne -
++
                ldx 0
                lda 1           ;check up
                cmp #84
                bcs ++
                adc #12
                tay
                lda 3
-
                cmp field,y
                bne +
                lda 0
                pha
                lda 1
                pha
                lda 2
                pha
                txa
                pha
                tya
                pha
                jsr FloodFill_loop
                pla
                tay
                pla
                tax
                pla
                sta 2
                pla
                sta 1
                pla
                sta 0
+
                iny
                inx
                cpx 2
                bne -
++
                rts


;
; MakemFall
;

MakemFall
                rts


;
; MakemShift
;

MakemShift
                rts


;
; Redraw2
; 

Redraw2row      ldx rdmgrline
                bpl +
                rts

+               ; drop top half of tiles
                lda tileshigh,x
                sta ppuaddr
                lda tileslow,x
                sta ppuaddr
                lda twelves,x
                sta 1
                tax
                lda #12
                sta 2
-               lda field,x
                tay
                lda tltileindex,y
                sta ppudata
                lda field,x
                tay
                lda trtileindex,y
                sta ppudata
                inx
                dec 2
                bne -

                lda retraces
                sta ppudata

                ldx rdmgrline
                lda tileshigh,x
                sta ppuaddr
                lda tileslow,x
                clc
                adc #$20
                sta ppuaddr
                ldx 1
                lda #12
                sta 2

-               lda field,x
                tay
                lda bltileindex,y
                sta ppudata
                lda field,x
                tay
                lda brtileindex,y
                sta ppudata
                inx
                dec 2
                bne -

                dec rdmgrline
                lda rdmgrline
                and #1
                beq +

                lda rdmgrline
                tax
                inx
                lda twelves,x
                tay
                lda #$23
                sta ppuaddr
                txa
                lsr a
                tax
                lda attrindex,x
                sta ppuaddr
                lda #6
                sta 2

-               ldx field,y
                lda tlattrs,x
                ldx field+1,y
                ora trattrs,x
                ldx field+12,y
                ora blattrs,x
                ldx field+13,y
                ora brattrs,x
                sta ppudata
                iny
                iny
                dec 2
                bne -
+
                lda #0
                sta ppuaddr
                sta ppuaddr
                rts


;
; putcurs
; Puts the Insane box cursor at (xcurs, ycurs).
; Trashes all regs.
; 

putcurs
                lda xcurs
                asl a
                asl a
                asl a
                asl a
                adc #32
		sta sprbuf+3
		adc #8
		sta sprbuf+7
                lda ycurs
                asl a
                asl a
                asl a
                asl a
                adc #63
                sta sprbuf
		sta sprbuf+4
                ldx #$90
                stx sprbuf+1
		stx sprbuf+5
                lda lcursflip
                sta sprbuf+2
                eor #%10000000  ;vertical flip
                sta lcursflip
                lda rcursflip
                sta sprbuf+6
                eor #%10000000  ;vertical flip
		sta rcursflip
		lda #0
		sta spraddr
                lda #>sprbuf
                sta sprdma
                rts


;
; rand5
; Generates a pseudorandom number from 2 to 6.
;

rand5           sty rand5save
                ldy randSeed
                inc randSeed
                lda randdata,y
                ldy rand5save
                rts
rand5save       .db 0

;
; wait4vbl
; waits for vertical blank
;

wait4vbl        bit $2002
                bpl wait4vbl
                rts


;
; wait4endvbl
; waits for end of vertical blank
;

wait4endvbl     bit $2002
                bmi wait4endvbl
                rts


;
; puts
; There is a C-style string in (AAYY). Print it to wherever ppuaddr points.
; Trashes: 0 1
; output: A = 0, Y = string length
;

puts
                sty 0
                sta 1
                ldy #0
-               lda (0),y
                beq +
                sta ppudata
                iny
                bne -
+               rts


;
; puthex
; Writes the number in A to ppudata.
;

puthex          pha
                pha
                lsr a
                lsr a
                lsr a
                lsr a
                tax
                lda hexdigits,x
                sta ppudata
                pla
                and #$0f
                tax
                lda hexdigits,x
                sta ppudata
                pla
                rts
hexdigits       .db "0123456789ABCDEF"


;
; midi2freq
; Converts a MIDI note to a frequency.
; Preserves X, Y, trashes 0. Returns freq in $01:A.
;

midi2freq
                stx 0
                ldx #0
                cmp #72
                bcc midi2freq_less
                sbc #72
                cmp #12
                bcs midi2freq_more
                tax
                lda pitches,x
                ldx #0
                stx 1
                ldx $fe
                rts

midi2freq_less
                ldx #0
                stx 1
-
                inc 1
                adc #12
                cmp #72
                bcc -
                sbc #72
                tax
                lda pitches,x
                pha
                ldx 1
                lda #0
                sta 1
                pla
-               asl
                rol 1
                dex
                bne -
                ldx 0
                rts

pitches         .db 215, 203, 192, 181, 171, 161, 152, 144, 136, 128, 121, 114

midi2freq_more
                ldx #0
                stx 1
-
                inc 1
                sbc #12
                cmp #12
                bcs -
                tax
                lda pitches,x
-               lsr
                dec 1
                bne -
                ldx 0
                rts


;
; copynametable
; Copy a name table from CPUROM (0) to PPURAM $2000.
;

copynametable
                ldy #0
                sty $2000
                sty $2001
                jsr wait4vbl
                lda #$20
                sta ppuaddr
                lda #0
                sta ppuaddr
                ldx #4

-               lda (0),y
                sta ppudata
                iny
                lda (0),y
                sta ppudata
                iny
                lda (0),y
                sta ppudata
                iny
                lda (0),y
                sta ppudata
                iny
                bne -
                inc 1
                dex
                bne -
                jsr wait4endvbl
                jsr wait4vbl
                sty ppuaddr
                sty ppuaddr

                lda #%10100000  ;NMI on VBL; 8x16 sprites; bg patterns 0;
                                ;sprite patterns 0; ppu += 1; nametable $2000
                sta $2000
                lda #%00011110  ;black bg; sprites on fullscreen;
                                ;bg on fullscreen; color display
                sta $2001
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
; nmipoint
; Increment retrace.
;

nmipoint
                pha             ;Save all regs.
                txa
                pha
                tya
                pha


;Handle the retrace counter.
                inc retraces
                bne +
                inc retraces+1
+

                pla             ;Restore all regs and exit.
                tay
                pla
                tax
                pla
                rti

;
; DATA TABLES
;

                .pad $e800      ; enough for four name tables and
                                ; a few other data tables

p8swdata        .incbin "p8sw.nam"      ;made with nsa
titledata       .incbin "title.nam"     ;made with nsa
gamebgdata      .incbin "gamebg.nam"    ;made with nsa
creditdata      .incbin "credits.nam"   ;made with nsa
sanedata	.incbin "sane.dmc"      ;made with 81
randdata        .incbin "randnos.bin"   ;made with randnos.c (256 b)

;f900

squareds        .db 0,0,0,1, 0,0,0,4, 0,0,0,9, 0,0,1,6
                .db 0,0,2,5, 0,0,3,6, 0,0,4,9, 0,0,6,4
                .db 0,0,8,1, 0,1,0,0, 0,1,2,1, 0,1,4,4
                .db 0,1,6,9, 0,1,9,6, 0,2,2,5, 0,2,5,6
                .db 0,2,8,9, 0,3,2,4, 0,3,6,1, 0,4,0,0
                .db 0,4,4,1, 0,4,8,4, 0,5,2,9, 0,5,7,6
                .db 0,6,2,5, 0,6,7,6, 0,7,2,9, 0,7,8,4
                .db 0,8,4,1, 0,9,0,0, 0,9,6,1, 1,0,2,4  ;FIXME
                .db 1,0,8,9, 1,1,5,6, 1,2,2,5, 1,2,9,6  ;FIXME
                .db 1,3,6,9, 1,4,4,4, 1,5,2,1, 1,6,0,0  ;FIXME
                .db 1,6,8,1, 1,7,6,4, 1,8,4,9, 1,9,3,6  ;FIXME
                .db 2,0,2,5, 2,1,1,6, 2,2,0,9, 2,3,0,4  ;FIXME
                .db 2,4,0,1, 2,5,0,0, 2,6,0,1, 2,7,0,4  ;FIXME
                .db 2,8,0,9, 2,9,1,6, 3,0,2,5, 3,1,3,6  ;FIXME
                .db 3,2,4,9, 3,3,6,4, 3,4,8,1, 3,6,0,0  ;FIXME
                .db 3,7,2,1, 3,8,4,4, 3,9,6,9, 4,0,9,6  ;FIXME

; palette for title screen and game
titlepal        .db $0f,$00,$10,$30,$0f,$16,$28,$30,$0f,$1a,$2c,$30,$0f,$12,$14,$30
                .db $0f,$00,$10,$30,$0f,$16,$28,$30,$0f,$1a,$2c,$30,$0f,$12,$14,$30

; locations of tiles in patterntable
tltileindex     .db $80,$82,$84,$86,$88,$8a,$8c,$8e
trtileindex     .db $81,$83,$85,$87,$89,$8b,$8d,$8f
bltileindex     .db $81,$92,$94,$96,$98,$9a,$9c,$9e
brtileindex     .db $80,$93,$95,$97,$99,$9b,$9d,$9f

; colors for tiles
tlattrs         .db 0, 0, $01, $01, $02, $02, $03, $03
trattrs         .db 0, 0, $04, $04, $08, $08, $0c, $0c
blattrs         .db 0, 0, $10, $10, $20, $20, $30, $30
brattrs         .db 0, 0, $40, $40, $80, $80, $c0, $c0

; y locations of tiles in nametable
tileslow        .db $04,$44,$84,$c4,$04,$44,$84,$c4
tileshigh       .db $21,$21,$21,$21,$22,$22,$22,$22

; multiples of twelve
twelves         .db 0, 12, 24, 36, 48, 60, 72, 84

; y locations of attributes in PPU-space
attrindex       .db $d1,$d9,$e1,$e9

irqpoint        rti

;interrupt table
                .pad $fffa
                .dw nmipoint
                .dw resetpoint
                .dw irqpoint

                .incbin "insane.chr"    ;made with tlayer
