;
; bingo
; NES Panel Action Bingo source code
; Copyright 2000 Damian Yerrick
; compile with x816 assembler available from
; http://www.zophar.net/
;
; If you are planning on using this code in a Real NES, put it
; in an NROM cartridge with horizontal mirroring (_not_ Super
; Mario Bros.).  The iNES board number for NROM is 0.
;
; I chose horizontal mirroring because
;  o it's similar to how VGA mode X tiling works
;  o it makes vertical scrolling (credit screens) easier
;  o it lets me
;  o unlike Rare-style one-screen mirroring (which is what I wanted
;    to use), it's available in NROM carts.
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
; 0000 direct page
; 0080 NT2 replay code direct page area
; 00C0 direct page
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

dx = 14
dy = 15
level = 16
nextTarget = 17
targetTile = 18
targetHit = 19
bingoes = 20

facing1 = 32
facing2 = 33
px1 = 34
px2 = 35
py1 = 36
py2 = 37
dx1 = 38
dx2 = 39
dy1 = 40
dy2 = 41
totalBingo = 63


repeats1 = $c0
repeats2 = $c8
field = $d0

sprbufptr = $f0

randseed = $f8
retraces = $fa          ; (16 bits) the number of retraces
control1 = $fc          ; data read from controllers
control2 = $fd
control3 = $fe
control4 = $ff


sprbuf = $200           ; sprite dma communication area


                .incsrc "replay22.asm" ;Bananmos's NerdTracker II replay code



;
; main()
;
; Nintendo wrote the first part of the init code in _Duck_Hunt_.
; Kevin Horton and Chris Covell played with it before I put it in.
;

resetcode
  cld
  sei
  
  ldx #1          ;initialize sound chip
  stx $4015
  dex             ;0 -> A
  stx $2000
  stx $2001
  txa             ;(A will contain 0 for most of init)
  dex             ;255 -> S
  stx $4003
  txs

  ; wait for warmup (1/2)
  bit $2002
  -
    bit $2002
    bpl -

  ; wait for warmup (2/2)
  -
    bit $2002
    bpl -
  

;clear work RAM (other than sprites)
  tax
  -
    sta $00,x
    sta $100,x
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x
    dex
    bne -

; ======================================
; == PRERELEASE NOTICE:               ==
; == remove this when game is done    ==
; ======================================

                lda #$80
                sta $2000
                lda #$00
                sta $2001
                lda #<readmedata
                sta 0
                lda #>readmedata
                sta 1
                lda #$20
                jsr NT_decode
                ldx #0
                stx 0
                ldx #titlepal-pals
                jsr putpal
                jsr wait4vbl
                lda #0
                sta ppuaddr
                sta ppuaddr
                lda #%10011000  ;NMI on VBL; 8x8 sprites; bg patterns 1;
                                ;sprite patterns 1; ppu += 1; nametable $2800
                sta $2000
                lda #%00011110  ;black bg; sprites on fullscreen;
                                ;bg on fullscreen; color display
                sta $2001
-
                jsr wait4vbl
                jsr ReadJPad
                lda control1
                and #$80
                beq -

; === END OF NOTICE ===

title           lda #0

                jsr wait4vbl
                jsr ReadJPad
                lda control1
                bne title

                lda #$80
                sta $2000
                lda #$00
                sta $2001
                lda #<coprdata
                sta 0
                lda #>coprdata
                sta 1
                lda #$28
                jsr NT_decode
                lda #<ctitledata
                sta 0
                lda #>ctitledata
                sta 1
                lda #$20
                jsr NT_decode
                ldx #0
                stx 0
                ldx #titlepal-pals
                jsr putpal

                jsr wait4vbl

                lda #0
                jsr $8003

                ; Scroll the title screen up.
                lda #0
                sta $2005
                sta $2005
                sta 0
                sta 1
                sta 2
                sta 3
                lda #$f0
                lda #%10011010  ;NMI on VBL; 8x8 sprites; bg patterns 1;
                                ;sprite patterns 1; ppu += 1; nametable $2800
                sta $2000
                lda #%00011110  ;black bg; sprites on fullscreen;
                                ;bg on fullscreen; color display
                sta $2001
;                ldx #250
                ldx #1  ; frames to wait

-
                jsr wait4vbl
                dex
                bne -
+
                jsr PlayBingoWav

-
                jsr wait4vbl
                clc
                lda 0
                adc #4
                sta 0
                lda 1
                adc #0
                sta 1
                lda 0
                adc 2
                sta 2
                lda #0
                sta $2005
                lda 3
                sta $2005
                adc 1
                sta 3
                cmp #240
                bcc -

                lda #%10011000  ;NMI on VBL; 8x8 sprites; bg patterns 1;
                                ;sprite patterns 1; ppu += 1; nametable $2c00
                sta $2000
                lda #0
                sta $2005
                sta $2005
-
                jsr $8000
                jsr wait4vbl
                jsr ReadJPad
                lda control1
                beq -
                asl a
                bcs NewGame
                bcc -

;
; Menu jumptable
;

NewGame
                lda retraces
                sta randseed
                lda retraces+1
                sta randseed+1

                lda #0
                sta level
                lda #1
                jsr $8003


NewLevel
;                jsr $8000
                lda #<gamebgdata
                sta 0
                lda #>gamebgdata
                sta 1
                lda #$20
                jsr copynametable

                ; Also copy the data to the bottom nametable so that
                ; graphics wrap around vertically.  This would not be
                ; necessary if NROM supported one-screen mirroring.
                ; Only MMC1, Rare AOROM, and Jaleco boards seem to
                ; support it.

                jsr $8000
                lda #<gamebgdata
                sta 0
                lda #>gamebgdata
                sta 1
                lda #$2c
                jsr copynametable

                ldx #0          ;rehide the display
                stx $2001
                ldx #0
                stx 0
                ldx ingamepal-pals
                jsr putpal

                ; Construct and blit the level.

                lda #0
                ldx #24
-
                sta field,x
                dex
                bpl -

                lda #25
                sta 1

                lda level
                and #%00000011  ;look for extra stuff
                beq ++
                cmp #2
                bne +

                jsr rand        ;place landmine
                and #%00000111
                clc
                adc #4
                tax
                ldy #35
                sty field,x
                jsr WriteBlock
                lda #0
                sta ppudata
                dec 1
+
                jsr rand        ;place block
                and #%00000111
                tax
                clc
                adc #13
                tax
                ldy #34
                sty field,x
                jsr WriteBlock
                lda #0
                sta ppudata
                dec 1
++
                ldx #0
--
                jsr rand
                and #%00011111
                tay
                iny
-
                dex
                bpl +
                ldx #24
+
                lda field,x
                bne -
                dey
                bne -
                lda 1
                sta field,x
                tay
                jsr WriteBlock
                lda #0
                sta ppudata
                dec 1
                bne --

                lda #1
                sta nextTarget
                jsr FindNextTarget
                sty targetTile
                lda #$23
                sta ppuaddr
                lda attraddrlotable,y
                sta ppuaddr
                lda #$55
                sta ppudata

                jsr wait4vbl

                lda #0
                sta targetHit

                lda #%10000011  ;NMI on VBL; 8x8 sprites; bg patterns 0;
                                ;sprite patterns 0; ppu += 1; nametable $2c00
                sta $2000
                lda #%00011110  ;black bg; sprites on fullscreen;
                                ;bg on fullscreen; color display
                sta $2001

                lda #$f0
                sta $2005
                lda #$d8
                sta $2005

                lda #0
                sta px1
                sta py1
                lda #136
                sta px2
                sta py2

gameloop
                jsr startsprite
                jsr $8000
                jsr ReadJPad

                ldx #1
-
                lda #0
                sta dx
                sta dy

                lda control1,x
                lsr a
                sta 6
                bcc +
                lda #0
                sta facing1,x
                lda #2
                sta dx
                bcs ++
+
                lsr 6
                bcc +
                lda #8
                sta facing1,x
                lda #$fe
                sta dx
                bcs ++
+
                lsr 6
                bcc +
                lda #12
                sta facing1,x
                lda #2
                sta dy
                bcs ++
+
                lsr 6
                bcc ++
                lda #4
                sta facing1,x
                lda #$fe
                sta dy
++
                jsr inbounds

                lda px1,x
                clc
                adc #12
                sta 0
                lda py1,x
                adc #12
                sta 1
                jsr Pos2Block
                cmp targetTile
                bne +
                txa
                ora #$20
                sta targetHit
+
                dex
                bpl -

                lda retraces
                lsr
                lsr
                lsr
                and #%00000010
                ora facing1
                tax
                lda gnomesprdata+0,x
                sta 0
                lda gnomesprdata+1,x
                sta 1
                lda #48
                clc
                adc px1
                sta 2
                lda #55
                clc
                adc py1
                sta 3
                jsr putsprite
                lda retraces
                lsr
                lsr
                lsr
                and #%00000010
                ora facing2
                tax
                lda kdesprdata+0,x
                sta 0
                lda kdesprdata+1,x
                sta 1
                lda #48
                clc
                adc px2
                sta 2
                lda #55
                clc
                adc py2
                sta 3
                jsr putsprite


                ldx sprbufptr
                lda #128
                sta sprbuf,x
                inx
                lda #1
                sta sprbuf,x
                inx
                lda #0
                sta sprbuf,x
                inx
                lda $4015
                and #$1f
                sta sprbuf,x
                inx
                stx sprbufptr


                jsr endsprite

                jsr wait4vbl
                lda #0
                sta spraddr
                lda #>sprbuf
                sta sprdma


                ; Check for hit.
                ldy targetHit
                beq ++

                ldx targetTile
                sty field,x
                jsr WriteBlock
                lda tileattrtable,y
                sta ppudata

                jsr Check4Bingo
                beq +
                jsr BingoDebrief

                inc level
                jmp NewLevel
+

                inc nextTarget
                lda nextTarget
                jsr FindNextTarget
                sty targetTile
                lda #$23
                sta ppuaddr
                lda attraddrlotable,y
                sta ppuaddr
                lda #$55
                sta ppudata
                lda #0
                sta targetHit

                lda #%10000011  ;NMI on VBL; 8x8 sprites; bg patterns 0;
                                ;sprite patterns 0; ppu += 1; nametable $2c00
                sta $2000
                lda #%00011110  ;black bg; sprites on fullscreen;
                                ;bg on fullscreen; color display
                sta $2001

                lda #$f0
                sta $2005
                lda #$d8
                sta $2005


                lda targetTile
                bpl ++
                inc level
                jmp NewLevel
++
                jmp gameloop


;
; inbounds
; Detect and correct collisions between player x and stuff.
;

inbounds
                lda px1,x
                clc
                adc dx
                sta px1,x
                cmp #192
                bcc +
                sbc dx
                sta px1,x
                bcs ++
+
                cmp #136
                bcc ++
                lda #134
                sta px1,x
++

                lda #0
                sta 2
                sta 3

                lda px1,x
                sta 0
                lda py1,x
                sta 1
                jsr Pos2Block
                tay
                lda field,y
                cmp #34
                bne +

                inc px1,x
                inc px1,x
+                
                lda 0
                clc
                adc #24
                sta 0
                jsr Pos2Block
                tay
                lda field,y
                cmp #34
                bne +
                dec px1,x
                dec px1,x
+                

                lda 1
                clc
                adc #24
                sta 1
                jsr Pos2Block
                tay
                lda field,y
                cmp #34
                bne +
                dec px1,x
                dec px1,x
+                
                lda 0
                sec
                sbc #24
                sta 0
                jsr Pos2Block
                tay
                lda field,y
                cmp #34
                bne +
                inc px1,x
                inc px1,x
+                

                lda py1,x
                clc
                adc dy
                sta py1,x
                cmp #192
                bcc +
                sbc dy
                sta py1,x
                bcs ++
+
                cmp #136
                bcc ++
                sbc dy
                sta py1,x
++

                lda #0
                sta 2
                sta 3

                lda px1,x
                sta 0
                lda py1,x
                sta 1
                jsr Pos2Block
                tay
                lda field,y
                cmp #34
                bne +
                inc py1,x
                inc py1,x
+                
                lda 0
                clc
                adc #24
                sta 0
                jsr Pos2Block
                tay
                lda field,y
                cmp #34
                bne +
                inc py1,x
                inc py1,x
+                

                lda 1
                clc
                adc #24
                sta 1
                jsr Pos2Block
                tay
                lda field,y
                cmp #34
                bne +
                dec py1,x
                dec py1,x
+                
                lda 0
                sec
                sbc #24
                sta 0
                jsr Pos2Block
                tay
                lda field,y
                cmp #34
                bne +
                dec py1,x
                dec py1,x
+                

                lda #0
                sta dx
                sta dy
                rts


                
;
; FindNextTarget
; Light up the next target.
; input: a = next target
; output: a = tile number for next target or -1 if none
;

FindNextTarget
                ldy #24
-
                cmp field,y
                beq +
                dey
                bpl -
+
                rts


;
; Pos2Block
; Convert (0, 1) position to a block index a.
;

Pos2Block
                lda 1
                and #%11100000
                lsr
                lsr
                lsr
                sta 5
                lsr
                lsr
                adc 5
                sta 5
                lda 0
                lsr
                lsr
                lsr
                lsr
                lsr
                clc
                adc 5
                rts
                





































;
; ===============================
;   END OF MAIN BODY OF PROGRAM
; ===============================
;

;
; PlayBingoWav
; Plays "BINGO" wav.
;

PlayBingoWav
                lda NED_Reg4015
                and #%11101111
                sta $4015
                lda #%00001111  ;no loop; 33 kHz
                sta $4010
                lda #64         ;first sample
                sta $4011
                lda #0          ;$c000
                sta $4012
                lda #128        ;2 KB       
                sta $4013
                lda NED_Reg4015
                ora #%00010000  ;only DMC
                sta NED_Reg4015
                sta $4015
                rts


;
; MakeRepeats
; Translates controller A into autorepeats.
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
; rand
; Generates a pseudorandom number from tons of variables;
; returns it in a
; Trashes y
;

rand
                lda randseed
                inc randseed
                eor randseed+1
                tay
                lda randdata,y
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
; Copy 1 KB from CPUROM (0) to PPURAM $aa00.
;

copynametable
                ldy #$80  ; forward, not down
                sty $2000
                ldy #$00
                sty $2001
                pha
                jsr wait4vbl
                pla
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
                jsr $8000
                jsr wait4vbl
                sty ppuaddr
                sty ppuaddr

                lda #%10000000  ;NMI on VBL; 8x8 sprites; bg patterns 0;
                                ;sprite patterns 0; ppu += 1; nametable $2000
                sta $2000
                lda #%00011110  ;black bg; sprites on fullscreen;
                                ;bg on fullscreen; color display
                sta $2001
                rts


;
; NT_decode
;
NT_decode
                sta     $2006   ; write high byte of PPU address
                lda     #$00
                sta     $2006   ; write low byte of PPU address
                jmp PKB_unpackblk
                .incsrc "unpkb.asm"

;
; putpal
; Copies 32 bytes from (pals,x) to the palette.  Subtracts $000
; for fading.  Call during VBL.
;

putpal
                lda #$3F
                sta ppuaddr
                lda #0
                sta ppuaddr
                
                ldy #$20
-               lda pals,x
                sec
                sbc 0
                bpl +
                lda #0
+
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
                sta $4016
                lda #0
                sta $4016
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

                .pad $a000
                .incsrc "sprites.asm"

                .incsrc "blox.asm"

                .pad $b000      ; enough for a few compressed name
                                ; tables and a few other data tables

randdata        .incbin "randnos.bin"   ;made with randnos.c (included)
gamebgdata      .incbin "ingame.nam"    ;made with SnowBro's nsa
ctitledata      .incbin "title.pkb"     ;compressed with packbits
coprdata        .incbin "copr.pkb"      ;same
readmedata      .incbin "readme.pkb"    ;same

; palette for title screen and game
pals

ingamepal       .db $0f,$00,$10,$30,$0f,$16,$26,$30,$0f,$1a,$2a,$30,$0f,$12,$22,$30
                .db $0f,$27,$16,$08,$0f,$27,$02,$08,$0f,$27,$16,$08,$0f,$27,$0a,$08

; palette for title screen and game
titlepal        .db $30,$10,$00,$0f,$30,$27,$00,$0f,$30,$16,$00,$0f,$30,$10,$00,$0f
                .db $30,$10,$00,$0f,$30,$27,$00,$0f,$30,$10,$00,$0f,$30,$10,$00,$0f

                .pad $c000
bingowav        .incbin "bingo.dmc"     ; 2 KB, 50 sec dmc file

                .pad $ff00


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

                .incbin "bingo.chr"    ;made with SnowBro's tlayer
