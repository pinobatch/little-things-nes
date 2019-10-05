GetDPCMRegs
                clc
                adc     #>NED_ToneTableDPCM
                sta     NED_TempWordHi
                lda     #<NED_ToneTableDPCM
                ;adc     #0
                sta     NED_TempWordLo
                tya
                asl
                asl
                tay

                lda     (NED_TempWord),Y
                iny
                sta     NED_temp1
                lda     (NED_TempWord),Y
                iny
                tax
                lda     (NED_TempWord),Y
                iny
                pha
                lda     (NED_TempWord),Y
                iny
                tay
                pla

                RTS

NED_ToneTableDPCM = *
.INCBIN "TEMP.DTT"
