;
; sprites.asm
;



gnomesprr1
                .db 12
                .db   8,$49,$00, 0
                .db   8,$4a,$00, 8
                .db   8,$4b,$00,16
                .db   0,$59,$00, 0
                .db   0,$5a,$00, 8
                .db   0,$5b,$00,16
                .db 248,$69,$01, 0
                .db 248,$6a,$01, 8
                .db 248,$6b,$01,16
                .db 240,$79,$01, 0
                .db 240,$7a,$01, 8
                .db 240,$7b,$01,16

gnomesprr2
                .db 12
                .db   8,$48,$40, 0
                .db   8,$47,$40, 8
                .db   8,$46,$40,16
                .db   0,$58,$40, 0
                .db   0,$57,$40, 8
                .db   0,$56,$40,16
                .db 248,$68,$41, 0
                .db 248,$67,$41, 8
                .db 248,$66,$41,16
                .db 240,$78,$41, 0
                .db 240,$77,$41, 8
                .db 240,$76,$41,16

gnomespru1
                .db 12
                .db   8,$40,$00, 0
                .db   8,$41,$00, 8
                .db   8,$42,$00,16
                .db   0,$50,$00, 0
                .db   0,$51,$00, 8
                .db   0,$52,$00,16
                .db 248,$60,$01, 0
                .db 248,$61,$01, 8
                .db 248,$62,$01,16
                .db 240,$70,$01, 0
                .db 240,$71,$01, 8
                .db 240,$72,$01,16

gnomespru2
                .db 12
                .db   8,$42,$40, 0
                .db   8,$41,$40, 8
                .db   8,$40,$40,16
                .db   0,$52,$40, 0
                .db   0,$51,$40, 8
                .db   0,$50,$40,16
                .db 248,$62,$41, 0
                .db 248,$61,$41, 8
                .db 248,$60,$41,16
                .db 240,$72,$41, 0
                .db 240,$71,$41, 8
                .db 240,$70,$41,16

gnomesprdata
                .dw gnomesprr1, gnomesprr2
                .dw gnomespru1, gnomespru2
                .dw gnomesprl1, gnomesprl2
                .dw gnomesprd1, gnomesprd2

                .dsb 8          ;pad so that the table doesn't cross
                                ;a page boundary

gnomesprl1
                .db 12
                .db   8,$46,$00, 0
                .db   8,$47,$00, 8
                .db   8,$48,$00,16
                .db   0,$56,$00, 0
                .db   0,$57,$00, 8
                .db   0,$58,$00,16
                .db 248,$66,$01, 0
                .db 248,$67,$01, 8
                .db 248,$68,$01,16
                .db 240,$76,$01, 0
                .db 240,$77,$01, 8
                .db 240,$78,$01,16

gnomesprl2
                .db 12
                .db   8,$4b,$40, 0
                .db   8,$4a,$40, 8
                .db   8,$49,$40,16
                .db   0,$5b,$40, 0
                .db   0,$5a,$40, 8
                .db   0,$59,$40,16
                .db 248,$6b,$41, 0
                .db 248,$6a,$41, 8
                .db 248,$69,$41,16
                .db 240,$7b,$41, 0
                .db 240,$7a,$41, 8
                .db 240,$79,$41,16

gnomesprd1
                .db 12
                .db   8,$43,$00, 0
                .db   8,$44,$00, 8
                .db   8,$45,$00,16
                .db   0,$53,$00, 0
                .db   0,$54,$00, 8
                .db   0,$55,$00,16
                .db 248,$63,$01, 0
                .db 248,$64,$01, 8
                .db 248,$65,$01,16
                .db 240,$73,$01, 0
                .db 240,$74,$01, 8
                .db 240,$75,$01,16

gnomesprd2
                .db 12
                .db   8,$45,$40, 0
                .db   8,$44,$40, 8
                .db   8,$43,$40,16
                .db   0,$55,$40, 0
                .db   0,$54,$40, 8
                .db   0,$53,$40,16
                .db 248,$65,$41, 0
                .db 248,$64,$41, 8
                .db 248,$63,$41,16
                .db 240,$75,$41, 0
                .db 240,$74,$41, 8
                .db 240,$73,$41,16

;               .pad $??00

kdesprr1
                .db 12
                .db   8,$c9,$03, 0
                .db   8,$ca,$03, 8
                .db   8,$cb,$03,16
                .db   0,$d9,$03, 0
                .db   0,$da,$03, 8
                .db   0,$db,$03,16
                .db 248,$e9,$03, 0
                .db 248,$ea,$03, 8
                .db 248,$eb,$03,16
                .db 240,$f9,$03, 0
                .db 240,$fa,$03, 8
                .db 240,$fb,$03,16

kdesprr2
                .db 12
                .db   8,$c8,$43, 0
                .db   8,$c7,$43, 8
                .db   8,$c6,$43,16
                .db   0,$d8,$43, 0
                .db   0,$d7,$43, 8
                .db   0,$d6,$43,16
                .db 248,$e8,$43, 0
                .db 248,$e7,$43, 8
                .db 248,$e6,$43,16
                .db 240,$f8,$43, 0
                .db 240,$f7,$43, 8
                .db 240,$f6,$43,16

kdespru1
                .db 12
                .db   8,$c0,$03, 0
                .db   8,$c1,$03, 8
                .db   8,$c2,$03,16
                .db   0,$d0,$03, 0
                .db   0,$d1,$03, 8
                .db   0,$d2,$03,16
                .db 248,$e0,$03, 0
                .db 248,$e1,$03, 8
                .db 248,$e2,$03,16
                .db 240,$f0,$03, 0
                .db 240,$f1,$03, 8
                .db 240,$f2,$03,16

kdespru2
                .db 12
                .db   8,$c2,$43, 0
                .db   8,$c1,$43, 8
                .db   8,$c0,$43,16
                .db   0,$d2,$43, 0
                .db   0,$d1,$43, 8
                .db   0,$d0,$43,16
                .db 248,$e2,$43, 0
                .db 248,$e1,$43, 8
                .db 248,$e0,$43,16
                .db 240,$f2,$43, 0
                .db 240,$f1,$43, 8
                .db 240,$f0,$43,16

kdesprdata
                .dw kdesprr1, kdesprr2
                .dw kdespru1, kdespru2
                .dw kdesprl1, kdesprl2
                .dw kdesprd1, kdesprd2

                .dsb 8          ;pad so that the table doesn't cross
                                ;a page boundary

kdesprl1
                .db 12
                .db   8,$c6,$03, 0
                .db   8,$c7,$03, 8
                .db   8,$c8,$03,16
                .db   0,$d6,$03, 0
                .db   0,$d7,$03, 8
                .db   0,$d8,$03,16
                .db 248,$e6,$03, 0
                .db 248,$e7,$03, 8
                .db 248,$e8,$03,16
                .db 240,$f6,$03, 0
                .db 240,$f7,$03, 8
                .db 240,$f8,$03,16

kdesprl2
                .db 12
                .db   8,$cb,$43, 0
                .db   8,$ca,$43, 8
                .db   8,$c9,$43,16
                .db   0,$db,$43, 0
                .db   0,$da,$43, 8
                .db   0,$d9,$43,16
                .db 248,$eb,$43, 0
                .db 248,$ea,$43, 8
                .db 248,$e9,$43,16
                .db 240,$fb,$43, 0
                .db 240,$fa,$43, 8
                .db 240,$f9,$43,16

kdesprd1
                .db 12
                .db   8,$c3,$03, 0
                .db   8,$c4,$03, 8
                .db   8,$c5,$03,16
                .db   0,$d3,$03, 0
                .db   0,$d4,$03, 8
                .db   0,$d5,$03,16
                .db 248,$e3,$03, 0
                .db 248,$e4,$03, 8
                .db 248,$e5,$03,16
                .db 240,$f3,$03, 0
                .db 240,$f4,$03, 8
                .db 240,$f5,$03,16

kdesprd2
                .db 12
                .db   8,$c5,$43, 0
                .db   8,$c4,$43, 8
                .db   8,$c3,$43,16
                .db   0,$d5,$43, 0
                .db   0,$d4,$43, 8
                .db   0,$d3,$43,16
                .db 248,$e5,$43, 0
                .db 248,$e4,$43, 8
                .db 248,$e3,$43,16
                .db 240,$f5,$43, 0
                .db 240,$f4,$43, 8
                .db 240,$f3,$43,16


;
; startsprite
; Initializes the sprite table.
;

startsprite
                lda #0
                sta sprbufptr
                rts


;
; endsprite
; Clears the rest of the sprite table and blits it.
;

endsprite
                lda #0
                ldx sprbufptr
-
                sta sprbuf,x
                inx
                bne -
                sta spraddr
                lda #>sprbuf
                sta sprdma
                nop
                nop
                rts


;
; putsprite
; Input: (0) points to sprite data; x in 2, y in 3
; trashes: all regs, 2, 3, 4
;

putsprite
                ldy #0
                lda (0),y
                sta 4
                ldx sprbufptr
-
                lda 3
                sec
                iny
                sbc (0),y
                sta sprbuf,x
                iny
                inx
                lda (0),y
                sta sprbuf,x
                iny
                inx
                lda (0),y
                sta sprbuf,x
                iny
                inx
                lda (0),y
                clc
                adc 2
                sta sprbuf,x
                inx
                dec 4
                bne -

                stx sprbufptr
                rts
