;
; unpkb.s - RLE unpacking
;
; Copyright 2000-2003 Damian Yerrick
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
; 
; Visit http://www.pineight.com/ for more information.
;

;;; Version history
;
;   2003 Oct: Ported for use with ca65 assembler
;   2000:     Initial release, for x816 assembler


.export PKB_unpackblk, PKB_unpack, PKB_source, PKB_len


;;; Configuration
;
; Set PKB_outport to whatever data port you want PackBits to use.
; (Slightly more modification is necessary for memory-to-memory
; unpacking.)
;
PKB_outport = $2007         ;NES PPU data register

;
; Set PKB_source to the address in direct page (i.e. zero page)
; where the pointer to packed data is stored.
;
PKB_source  = $00
PKB_len     = $02

.segment "CODE"

;
; PKB_unpackblk
; Unpack PackBits() encoded data from memory at (PKB_source)
; to a character device such as the NES PPU data register.
;
; This entry point assumes a 16-bit length word in network
; byte order before the data.
PKB_unpackblk:
  ldy #0
  lda (PKB_source),y
  inc PKB_source
  bne :+
  inc PKB_source+1
:
  sta PKB_len+1
  lda (PKB_source),y
  inc PKB_source
  bne :+
  inc PKB_source+1
:
  sta PKB_len

; This entry point assumes a 16-bit length word in host byte order
; at PKB_len.
PKB_unpack:
  lda PKB_len
  beq :+
  inc PKB_len+1   ;trick to allow easier 16-bit decrement
:
  ldy #0
@PKB_loop:
  lda (PKB_source),y
  bmi @PKB_run

  inc PKB_source  ; got a literal string
  bne :+
  inc PKB_source+1
:
  tax
  inx
@PKB_strloop:
  lda (PKB_source),y
  inc PKB_source
  bne :+
  inc PKB_source+1
:
  sta PKB_outport
  dec PKB_len
  bne :+
  dec PKB_len+1
  beq @PKB_rts
:
  dex
  bne @PKB_strloop
  beq @PKB_loop

@PKB_rts:
  rts

@PKB_run:
  inc PKB_source  ; got a run
  bne :+
  inc PKB_source+1
:
  tax
  dex
  lda (PKB_source),y
  inc PKB_source
  bne @PKB_runloop
  inc PKB_source+1
@PKB_runloop:
  sta PKB_outport
  dec PKB_len
  bne :+
  dec PKB_len+1
  beq @PKB_rts
:
  inx
  bne @PKB_runloop
  beq @PKB_loop
