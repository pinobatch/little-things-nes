;
; unpkb.asm
; RLE unpacking
;
;
; Copyright 2000 Damian Yerrick
;
; This library is free software; you can redistribute it and/or
; modify it under the terms of the GNU Lesser General Public
; License as published by the Free Software Foundation; either
; version 2.1 of the License, or (at your option) any later version.
; 
; This library is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; Lesser General Public License for more details.
; 
; You should have received a copy of the GNU Lesser General Public
; License along with this library; if not, write to
;   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;   Boston, MA  02111-1307, USA.
; GNU licenses can be viewed online at http://www.gnu.org/copyleft/
; 
; Visit http://www.pineight.com/ for more information.
;



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
