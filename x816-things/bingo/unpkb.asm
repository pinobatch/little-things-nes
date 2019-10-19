;
; unpkb.asm
; RLE unpacking
;
;
; Copyright 2000 Damian Yerrick
;
; Relicensed to zlib license as of 2019-10-05


;
; Set PKB_data to whatever data port you want PackBits to use.
; (Slightly more modification is necessary for memory-to-memory
; unpacking.)
;
PKB_data        = $2007         ;NES PPU data register

;
; Set PKB_source to the address in direct page (i.e. zero page)
; where the pointer to packed data is stored.
;
PKB_source      = $00
PKB_len         = $02

;
; PKB_unpackblk
; Unpack PackBits() encoded data from memory at (PKB_source)
; to a character device such as the NES PPU data register.
;
; This entry point assumes a 16-bit length word in network
; byte order before the data.
PKB_unpackblk
                ldy #0
                lda (PKB_source),y
                inc PKB_source
                bne +
                inc PKB_source+1
+
                sta PKB_len+1
                lda (PKB_source),y
                inc PKB_source
                bne +
                inc PKB_source+1
+
                sta PKB_len

; This entry point assumes a 16-bit length word in host byte order
; at PKB_len.
PKB_unpack
                lda PKB_len
                beq +
                inc PKB_len+1   ;trick to allow easier 16-bit decrement
+
                ldy #0
PKB_loop
                lda (PKB_source),y
                bmi PKB_run

                                ;got a string
                inc PKB_source
                bne +
                inc PKB_source+1
+
                tax
                inx
                txa
-
                lda (PKB_source),y
                inc PKB_source
                bne +
                inc PKB_source+1
+
                sta PKB_data
                dec PKB_len
                bne +
                dec PKB_len+1
                beq PKB_rts
+
                dex
                bne -
                beq PKB_loop

PKB_run                         ;got a run
                inc PKB_source
                bne +
                inc PKB_source+1
+
                tax
                dex
                lda (PKB_source),y
                inc PKB_source
                bne +
                inc PKB_source+1
+
-
                sta PKB_data
                dec PKB_len
                bne +
                dec PKB_len+1
                beq PKB_rts
+
                inx
                bne -
                beq PKB_loop
PKB_rts
                rts
