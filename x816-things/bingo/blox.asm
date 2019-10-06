;
;
; 
;
;  0 no block
;  1  1
;  2  2
;  3  3
;  4  4
; ......
; 24 24
; 25 25
; 26 mole
; 27 B
; 28 I
; 29 N
; 30 G
; 31 O
; 32 1p hit
; 33 2p hit
; 34 block
; 35 landmine
; 36 [unused]
; 37 [unused]
; 38 [unused]
; 39 [unused]
;


;
; Check4Bingo
; Checks for a bingo state.
; in: tile # in x; player # in y
; out: 
;


Check4Bingo

                ldx #11
                lda #0
                sta totalBingo
-
                sta bingoes,x
                dex
                bpl -

                ldx #4

                ; check for | match
-
                lda field,x
                cmp field+5,x
                bne +
                cmp field+10,x
                bne +
                cmp field+15,x
                bne +
                cmp field+20,x
                bne +
                inc bingoes+5,x
                inc totalBingo
+
                ; check for \ match
                dex
                bpl -

                lda field+12
                cmp field
                bne +
                cmp field+6
                bne +
                cmp field+18
                bne +
                cmp field+24
                bne +
                inc bingoes+11
                inc totalBingo
+                
                ; check for / match
                cmp field+4
                bne +
                cmp field+8
                bne +
                cmp field+16
                bne +
                cmp field+20
                bne +
                inc bingoes+10
                inc totalBingo
+
                ldy #20
                ldx #4
-
                ; check for - match
                lda field,y
                cmp field+1,y
                bne +
                cmp field+2,y
                bne +
                cmp field+3,y
                bne +
                cmp field+4,y
                bne +
                inc bingoes,x
                inc totalBingo
+
                tya
                sec
                sbc #5
                tay
                dex
                bpl -

                lda totalBingo
                rts


;
; BingoDebrief
; Clears the screen and draws bingo.
;

BingoDebrief
                lda #0
                sta $4015
                jsr PlayBingoWav
                jsr SetupScroll
                ldx #15
                stx 5
-
                jsr wait4endvbl
                jsr $8000
                jsr wait4vbl
                dec 5
                bne -

                ldx #11
-

                lda bingoes,x
                beq +
                stx 5

                jsr SetupScroll

                ldx 5
                lda bingo1table,x
                tax
                ldy #27
                jsr WriteBlock
                ldx 5
                lda bingo2table,x
                tax
                ldy #28
                jsr WriteBlock
                ldx 5
                lda bingo3table,x
                tax
                ldy #29
                jsr WriteBlock
                ldx 5
                lda bingo4table,x
                tax
                ldy #30
                jsr WriteBlock
                ldx 5
                lda bingo5table,x
                tax
                ldy #31
                jsr WriteBlock
                ldx 5
+
                dex
                bpl -

                jsr SetupScroll
                ldx #60
                stx 5
-
                jsr wait4endvbl
                jsr $8000
                jsr wait4vbl
                dec 5
                bne -
                rts

SetupScroll
                lda #0
                sta ppuaddr
                sta ppuaddr

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
                jsr wait4endvbl
                jsr $8000
                jsr wait4vbl
                rts


;
; WriteBlock
; Writes block y to tile #x; leaves addr pointed to attr table.
; (158 bytes; 203 cycles; trashes a)
;

WriteBlock
                clc
                lda ppuaddrhitable,x
                sta ppuaddr
                lda ppuaddrlotable,x
                sta ppuaddr
                lda tile0table,y
                sta ppudata
                lda tile1table,y
                sta ppudata
                lda tile2table,y
                sta ppudata
                lda tile3table,y
                sta ppudata
                lda ppuaddrhitable,x
                sta ppuaddr
                lda ppuaddrlotable,x
                adc #32
                sta ppuaddr
                lda tile4table,y
                sta ppudata
                lda tile5table,y
                sta ppudata
                lda tile6table,y
                sta ppudata
                lda tile7table,y
                sta ppudata
                lda ppuaddrhitable,x
                sta ppuaddr
                lda ppuaddrlotable,x
                adc #64
                sta ppuaddr
                lda tile8table,y
                sta ppudata
                lda tile9table,y
                sta ppudata
                lda tileatable,y
                sta ppudata
                lda tilebtable,y
                sta ppudata
                lda ppuaddrhitable,x
                sta ppuaddr
                lda ppuaddrlotable,x
                adc #96
                sta ppuaddr
                lda tilectable,y
                sta ppudata
                lda tiledtable,y
                sta ppudata
                lda tileetable,y
                sta ppudata
                lda tileftable,y
                sta ppudata
                lda #$23
                sta ppuaddr
                lda attraddrlotable,x
                sta ppuaddr
                rts
                


                .pad $ac00
rowidstable     .db 0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4
colidstable     .db 0,1,2,3,4,0,1,2,3,4,0,1,2,3,4,0,1,2,3,4,0,1,2,3,4
ppuaddrhitable  .db $20,$20,$20,$20,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22
ppuaddrlotable  .db $84,$88,$8c,$90,$94,$04,$08,$0c,$10,$14,$84,$88,$8c,$90,$94,$04,$08,$0c,$10,$14,$84,$88,$8c,$90,$94
;attraddrhitable would be all $23.
attraddrlotable .db $c9,$ca,$cb,$cc,$cd,$d1,$d2,$d3,$d4,$d5,$d9,$da,$db,$dc,$dd,$e1,$e2,$e3,$e4,$e5,$e9,$ea,$eb,$ec,$ed
unused25table1
unused25table2
unused25table3
unused25table4

bingo1table     .db 0, 5, 10, 15, 20,  0,  1,  2,  3,  4, 20,  0
bingo2table     .db 1, 6, 11, 16, 21,  5,  6,  7,  8,  9, 16,  6
                .pad $ad04
bingo3table     .db 2, 7, 12, 17, 22, 10, 11, 12, 13, 14, 12, 12
;                     0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19
tile0table      .db $10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10
                .db $10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$18,$01,$10,$10,$10,$10
tile1table      .db $01,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
                .db $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$19,$00,$11,$11,$11,$11
tile2table      .db $01,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
                .db $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$19,$00,$11,$11,$11,$11
tile3table      .db $01,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12
                .db $12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$1a,$01,$12,$12,$12,$12
tile4table      .db $01,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13
                .db $13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$1b,$00,$13,$13,$13,$13
tile5table      .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81
                .db $82,$82,$82,$82,$82,$82,$01,$20,$22,$24,$26,$8a,$8c,$8e,$01,$00,$01,$01,$01,$01
;should be ae00
tile6table      .db $01,$81,$82,$83,$84,$85,$86,$87,$88,$89,$80,$81,$82,$83,$84,$85,$86,$87,$88,$89
                .db $80,$81,$82,$83,$84,$85,$01,$21,$23,$25,$27,$8b,$8d,$8f,$01,$00,$01,$01,$01,$01
tile7table      .db $01,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14
                .db $14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$1c,$00,$14,$14,$14,$14
tile8table      .db $01,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13
                .db $13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$1b,$00,$13,$13,$13,$13
tile9table      .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$91,$91,$91,$91,$91,$91,$91,$91,$91,$91
                .db $92,$92,$92,$92,$92,$92,$01,$30,$32,$34,$36,$9a,$9c,$9e,$01,$00,$01,$01,$01,$01
tileatable      .db $01,$91,$92,$93,$94,$95,$96,$97,$98,$99,$90,$91,$92,$93,$94,$95,$96,$97,$98,$99
                .db $90,$91,$92,$93,$94,$95,$01,$31,$33,$35,$37,$9b,$9d,$9f,$01,$00,$01,$01,$01,$01
tilebtable      .db $01,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14
                .db $14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$14,$1c,$00,$14,$14,$14,$14
;should be aef0

;with creative table location, I can store 32 bytes of stuff here
;and not cross page boundaries
                .dsb 4
bingo4table     .db 3, 8, 13, 18, 23, 15, 16, 17, 18, 19,  8, 18
bingo5table     .db 4, 9, 14, 19, 24, 20, 21, 22, 23, 24,  4, 24
                .dsb 4

;should be af10 here
tilectable      .db $01,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15
                .db $15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$15,$1d,$01,$15,$15,$15,$15
tiledtable      .db $01,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16
                .db $16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$1e,$00,$16,$16,$16,$16
tileetable      .db $01,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16
                .db $16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$16,$1e,$00,$16,$16,$16,$16
tileftable      .db $01,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17
                .db $17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$1f,$01,$17,$17,$17,$17
tileattrtable   .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$aa,$00,$00,$00,$00,$00,$00
unused40table   .db $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
                .db $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
