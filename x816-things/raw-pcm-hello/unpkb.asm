PKB_data        = ppudata       ;NES PPU data register

;
; PKB_unpackblk
; Unpack PackBits() encoded data from memory at ($00) to a character
; device such as the NES PPU data register.
;

; This entry point assumes a 16-bit length word before the data.
PKB_unpackblk
                ldy #0
                lda (0),y
                inc 0
                bne +
                inc 1
+
                sta 3
                lda (0),y
                inc 0
                bne +
                inc 1
+
                sta 2

; This entry point assumes a 16-bit length word in memory $0002.
PKB_unpack
                lda 2
                beq +
                inc 3           ;trick to allow easier 16-bit decrement
+
                ldy #0
PKB_loop
                lda (0),y
                bmi PKB_run

                                ;got a string
                inc 0
                bne +
                inc 1
+
                tax
                inx
                txa
-
                lda (0),y
                inc 0
                bne +
                inc 1
+
                sta PKB_data
                dec 2
                bne +
                dec 3
                beq PKB_rts
+
                dex
                bne -
                beq PKB_loop

PKB_run                         ;got a run
                inc 0
                bne +
                inc 1
+
                tax
                dex
                lda (0),y
                inc 0
                bne +
                inc 1
+
-
                sta PKB_data
                dec 2
                bne +
                dec 3
                beq PKB_rts
+
                inx
                bne -
                beq PKB_loop
PKB_rts
                rts
