SQRWAV1_CHN             = 0
SQRWAV2_CHN             = 1
TRIWAV_CHN              = 2
NOSWAV_CHN              = 3
DPCM_CHN                = 4

NED_HDR_VERSION         = $00
NED_HDR_HEADERSIZE      = $01
NED_HDR_FLAGS           = $02
NED_HDR_INITTEMPO       = $03
NED_HDR_RESTARTPOS      = $04
NED_HDR_NUMINSTS        = $05
NED_HDR_NUMINSTS_DPCM   = $06
NED_HDR_SONGLENGTH      = $07
NED_HDR_NUMPATS         = $08
NED_HDR_NUMPATS_SQ1     = $08
NED_HDR_NUMPATS_SQ2     = $09
NED_HDR_NUMPATS_TRI     = $0A
NED_HDR_NUMPATS_NOISE   = $0B
NED_HDR_NUMPATS_DPCM    = $0C
NED_HDR_SIZEOF          = $10


NED_EffPortaUp          = $01
NED_EffPortaDown        = $02
NED_EffTonePorta        = $03
NED_EffVibrato          = $04
NED_EffTremolo          = $07
NED_EffArpeggio         = $08
NED_EffVolSlide         = $0A
NED_EffSetVol           = $0C
NED_EffBrkPat           = $0D
NED_EffSetSpeed         = $0F

NED_PERIODLIMIT = $0A
NED_CHANNELS    = $04

;NED_TEMP_BASE   = $00
;NED_STATIC_BASE = $10

NED_ZTRAM_BASE  = $80
NED_ZRAM_BASE   = $90
NED_RAM_BASE    = $300

        ; Temporary data, may be used by other routines


NED_TempWord    = NED_ZTRAM_BASE + $08
NED_TempWordLo  = NED_ZTRAM_BASE + $08
NED_TempWordHi  = NED_ZTRAM_BASE + $09

NED_CurrChn     = NED_ZTRAM_BASE + $0A
NED_Temp1       = NED_ZTRAM_BASE + $0B
NED_Temp2       = NED_ZTRAM_BASE + $0C
NED_Temp3       = NED_ZTRAM_BASE + $0D
NED_Temp4       = NED_ZTRAM_BASE + $0E
NED_Temp5       = NED_ZTRAM_BASE + $0F
NED_TempWord2   = NED_ZTRAM_BASE + $0E
NED_TempWord2Lo = NED_ZTRAM_BASE + $0E
NED_TempWord2Hi = NED_ZTRAM_BASE + $0F



        ; Static data, must NOT be used by other routines!



NED_NedAddr             = NED_ZRAM_BASE + $00
NED_CurrTick            = NED_ZRAM_BASE + $02
NED_Speed               = NED_ZRAM_BASE + $03
NED_CurrRow             = NED_ZRAM_BASE + $04
NED_CurrOrder           = NED_ZRAM_BASE + $05
NED_SongLength          = NED_ZRAM_BASE + $06
NED_RestartPos          = NED_ZRAM_BASE + $07
NED_OrderAddr           = NED_ZRAM_BASE + $08
NED_InstAddr            = NED_ZRAM_BASE + $0A


NED_ChnPeriodLo         = NED_ZRAM_BASE + $0C
NED_ChnPatOffs          = NED_ZRAM_BASE + $10
NED_ChnVBlanksLeft      = NED_ZRAM_BASE + $15
NED_ChnLastTone         = NED_ZRAM_BASE + $19

NED_Reg4015             = NED_ZRAM_BASE + $1F



NED_ChnVolume           = NED_RAM_BASE + $00
NED_ChnPattern          = NED_RAM_BASE + $04
NED_ChnPeriodHi         = NED_RAM_BASE + $08
NED_ChnLastInst         = NED_RAM_BASE + $10
NED_ChnPortaTone        = NED_RAM_BASE + $14
NED_ChnPortaSpeed       = NED_RAM_BASE + $18


NED_ChnPeriodHiLast     = NED_RAM_BASE + $AC
NED_ChnTotalVBlanks     = NED_RAM_BASE + $1C

NED_ChnAutoVolumeSlide  = NED_RAM_BASE + $20
NED_ChnVolumeSlide      = NED_RAM_BASE + $24

NED_ChnReg0             = NED_RAM_BASE + $94
NED_ChnArpeggio         = NED_RAM_BASE + $98

NED_ChnBigTick          = NED_RAM_BASE + $9C
NED_ChnAutoPorta        = NED_RAM_BASE + $A0


;NED_ChnAutoArpXY        = NED_STATIC_BASE + $28
NED_ChnAutoArpX         = NED_RAM_BASE + $28

NED_ChnAutoArpY         = NED_RAM_BASE + $A4
NED_ChnAutoArpNL        = NED_RAM_BASE + $A8


NED_ChnAutoArpZ         = NED_RAM_BASE + $2C
NED_ChnVibratoPos       = NED_RAM_BASE + $30
NED_ChnVibrato          = NED_RAM_BASE + $34
NED_ChnAutoVibrato      = NED_RAM_BASE + $38
NED_ChnTremoloPos       = NED_RAM_BASE + $3C
NED_ChnTremolo          = NED_RAM_BASE + $40
NED_ChnAutoTremolo      = NED_RAM_BASE + $44
NED_ChnLoopedNoise      = NED_RAM_BASE + $4C

NED_ChnTone             = NED_RAM_BASE + $50 
NED_ChnInst             = NED_RAM_BASE + $55
NED_ChnEff              = NED_RAM_BASE + $5A
NED_ChnEffParm          = NED_RAM_BASE + $5F

NED_ChnTotalPats        = NED_RAM_BASE + $E0

NED_ChnPatPtrsAddrLo    = NED_RAM_BASE + $64
NED_ChnPatPtrsAddrHi    = NED_RAM_BASE + $69
NED_ChnPatAddrLo        = NED_RAM_BASE + $6E
NED_ChnPatAddrHi        = NED_RAM_BASE + $73
NED_ChnNibAddrOdd       = NED_RAM_BASE + $78


NED_ChnLastVolume       = NED_RAM_BASE + $B4

;NED_LoopStart           = NED_STATIC_BASE + $3D
;NED_LoopLength          = NED_STATIC_BASE + $3E
;NED_SampleNote          = NED_STATIC_BASE + $3F
;NED_SampleInst          = NED_STATIC_BASE + $40
;NED_SmpNum              = NED_STATIC_BASE + $41
;NED_Length              = NED_STATIC_BASE + $42

NED_TotalPatsDPCM       = NED_RAM_BASE + $E4

NED_ChnPatRowsToSkip    = NED_RAM_BASE + $8A
NED_ChnPatRowsTotal     = NED_RAM_BASE + $8F

NED_PAL_Counter = $7C

joy1 = $7F
joy1old = $7E
curr_song = $7D

a_button = 128          ; joystick stuff
b_button = 64
select_button = 32
start_button = 16
up_button = 8
down_button = 4
left_button = 2
right_button = 1

;incbin "temp.dmc"
;.PAD    $00C300


;.DB 'N','E','S','M',$1A
;.DB $01
;.DB 255
;.DB 1
;.DW $8080
;.DW NSF_InitSong
;.DW NSF_Play
;.DB "0123456789ABCDEF0123456789ABCDE",0
;.DB "0123456789ABCDEF0123456789ABCDE",0
;.DB "0123456789ABCDEF0123456789ABCDE",0
;.DW $411A
;;.DW $4E20
;.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;.pad $00D000

jmp NSF_Play            ; for NTSC speed
;jmp NED_PlayNed         ; for PAL speed
jmp NSF_InitSong


ProgramEntry    sei
                cld
                LDX     #$FF
                TXS

                inx
                stx $2000
                stx $2001

Again           ;lda     #$9E
                ;sta     $2001
@WaitVblank     lda     $2002
                bpl     @WaitVblank

@WaitVblankB 
                lda     $2002
                bpl     @WaitVblankB

                lda #0
                tax
@clear:
                sta $00, x
                sta $200, x
                sta $300, x
                sta $400, x
                sta $500, x
                sta $600, x
                sta $700, x
                inx
                bne @clear

                LDA     #<NED_SONGS
                LDX     #>NED_SONGS
                JSR     NED_SetupNED
                lda #%00011111
                sta $4015

                ;lda     #$1E
                ;sta     $2001
                ;lda     #$80
                ;sta     $2000

                lda #%10000000
                sta $2000
                lda #0
                sta $2001

DumLoop
        lda $2002
        bpl DumLoop
        
        lda #a_button
        and joy1
        beq labl
        and joy1old
        bne labl
        inc curr_song
        lda curr_song
        jsr NSF_InitSong
labl:
        lda $2002
        bmi labl
        jmp     DumLoop



NED_SetupNED
                STA     NED_NedAddr
                STX     NED_NedAddr+1

                LDA     #NED_HDR_SIZEOF
                CLC
                ADC     NED_NedAddr
                STA     NED_InstAddr
                LDA     NED_NedAddr+1
                ADC     #0
                STA     NED_InstAddr+1

                LDY     #NED_HDR_INITTEMPO
                LDA     (NED_NedAddr),Y
                STA     NED_Speed
                INY
                LDA     (NED_NedAddr),Y
                STA     NED_RestartPos
                INY
                INY
                INY
                LDA     (NED_NedAddr),Y
                STA     NED_SongLength
                INY

; Load total patterns indicator for every synth channel
                LDA     (NED_NedAddr),Y
                STA     NED_ChnTotalPats
                INY
                LDA     (NED_NedAddr),Y
                STA     NED_ChnTotalPats+1
                INY
                LDA     (NED_NedAddr),Y
                STA     NED_ChnTotalPats+2
                INY
                LDA     (NED_NedAddr),Y
                STA     NED_ChnTotalPats+3
                INY
                LDA     (NED_NedAddr),Y
                STA     NED_TotalPatsDPCM
                INY

                iny
                iny
                iny


                TYA
                CLC
                ADC     #128
                STA     NED_Temp1

                LDA     NED_NedAddr     ; Calc Order Address
                ADC     NED_Temp1
                STA     NED_OrderAddr
                LDA     NED_NedAddr+1
                ADC     #0
                STA     NED_OrderAddr+1

                LDA     NED_SongLength
                ASL

                asl
                ;ADC     NED_SongLength

                ADC     NED_Temp1
                STA     NED_Temp1

                LDA     NED_NedAddr     ; Calc pattern pointers pointers
                ADC     NED_Temp1
                STA     NED_ChnPatPtrsAddrLo
                LDA     NED_NedAddr+1
                ADC     #0
                STA     NED_ChnPatPtrsAddrHi
                
                ; Make it calc the rest too...

                lda     NED_ChnTotalPats
                asl
                adc     NED_ChnPatPtrsAddrLo
                sta     NED_ChnPatPtrsAddrLo+1
                lda     #0
                adc     NED_ChnPatPtrsAddrHi
                sta     NED_ChnPatPtrsAddrHi+1

                lda     NED_ChnTotalPats+1
                asl
                adc     NED_ChnPatPtrsAddrLo+1
                sta     NED_ChnPatPtrsAddrLo+2
                lda     #0
                adc     NED_ChnPatPtrsAddrHi+1
                sta     NED_ChnPatPtrsAddrHi+2

                lda     NED_ChnTotalPats+2
                asl
                adc     NED_ChnPatPtrsAddrLo+2
                sta     NED_ChnPatPtrsAddrLo+3
                lda     #0
                adc     NED_ChnPatPtrsAddrHi+2
                sta     NED_ChnPatPtrsAddrHi+3

                lda     NED_ChnTotalPats+3
                asl
                adc     NED_ChnPatPtrsAddrLo+3
                sta     NED_ChnPatPtrsAddrLo+4
                lda     #0
                adc     NED_ChnPatPtrsAddrHi+3
                sta     NED_ChnPatPtrsAddrHi+4



                LDA     #0
                LDX     #3
@ClearChnLoop
                STA     NED_ChnVolume,X
                STA     NED_ChnPeriodLo,X
                STA     NED_ChnPeriodHi,X
                STA     NED_ChnLastTone,X
                STA     NED_ChnLastInst,X
                STA     NED_ChnPortaTone,X
                STA     NED_ChnPortaSpeed,X
                STA     NED_ChnReg0,X
                STA     NED_ChnVolumeSlide,X
                STA     NED_ChnAutoVolumeSlide,X
                STA     NED_ChnArpeggio,X
                STA     NED_ChnAutoArpX,X
                STA     NED_ChnAutoArpY,X
                STA     NED_ChnAutoArpZ,X
                STA     NED_ChnVibratoPos,X
                STA     NED_ChnVibrato,X
                STA     NED_ChnAutoVibrato,X
                STA     NED_ChnTremoloPos,X
                STA     NED_ChnTremolo,X
                STA     NED_ChnAutoTremolo,X
                STA     NED_ChnVBlanksLeft,X
                STA     NED_ChnLoopedNoise,X
                STA     NED_ChnTone,X
                STA     NED_ChnInst,X
                STA     NED_ChnEff,X
                STA     NED_ChnEffParm,X
                STA     NED_ChnBigTick,X

                DEX
                BPL     @ClearChnLoop

                STA     NED_CurrRow
                STA     NED_CurrOrder

                sta     NED_Reg4015
                sta     $4015

                LDA     #$05
                STA     NED_PAL_Counter

                LDX     NED_Speed
                inx
                STX     NED_CurrTick

                RTS
                


NED_SetVolume
                cmp     #0
                BPL     @VolumeAbove0
                LDA     #0
@VolumeAbove0   
                CMP     #63
                BCC     @VolumeBelow64
                LDA     #63
@VolumeBelow64
                LSR
                LSR
                ORA     NED_ChnReg0,X

                LDY     NED_Chn2RegIndex,X

                STA     $4000,Y
                RTS

NED_SetPeriod
                CPX     #NOSWAV_CHN
                BEQ     SetPeriodNoise
                cpx     #TRIWAV_CHN
                beq     SetPeriodTri


                LDY     NED_Chn2RegIndex,X

                STA     $4002,Y

                lda     #$08    ; Compensates for the bug Matt found
                sta     $4001,Y

                LDA     NED_Temp1

                cmp     NED_ChnPeriodHiLast,X
                beq     +       ; No update needed
                sta     NED_ChnPeriodHiLast,X
                ORA     #8
                STA     $4003,Y
+
                RTS

SetPeriodNoise
                AND     #$0F
                ORA     NED_ChnLoopedNoise,X
                STA     $400E
                LDA     #8
                STA     $400F
                RTS


SetPeriodTri
                LDY     NED_Chn2RegIndex,X

                STA     $4002,Y
                LDA     NED_Temp1
                ORA     #8
                STA     $4003,Y
                RTS



NED_PlayNED
                
                        LDA     NED_Speed
                        BEQ     Halted
                        INC     NED_CurrTick
                        CMP     NED_CurrTick
                        beq     +
                        bpl     UpdateTx
+
                                LDA     #0
                                STA     NED_CurrTick
                                LDA     NED_CurrRow
                                CMP     #64
                                BCC     @DontIncOrder
                                        LDA     #0
                                        STA     NED_CurrRow
                                        LDX     NED_CurrOrder
                                        INX
                                        CPX     NED_SongLength
                                        BCC     @DontRestartSong
                                                LDX     NED_RestartPos
                                        @DontRestartSong
                                        STX     NED_CurrOrder
                                @DontIncOrder
                        jmp     NED_UpdateT0

UpdateTx
                                ;lda     #6
                                ;sta     $2001
                

                LDX     #3
                

-
                        lda     NED_ChnVBlanksLeft,X
                        bmi     @HoldNoteOnTx
                        sec
                        sbc     #1
                        bpl     @DontSetNoteOffTx
                                lda     NED_ChnBitIndexInv,X
                                and     NED_Reg4015
                                sta     NED_Reg4015
                                lda     #0

@DontSetNoteOffTx
                        sta     NED_ChnVBlanksLeft,X

@HoldNoteOnTx
                        cpx     #TRIWAV_CHN
                        bne     +
                        lda     #$FF
                        sta     $4008
+


                dex
                bpl     -


.if 0
                lda #<finishedoffsamplespr
                sta 0
                lda #>finishedoffsamplespr
                sta 1
                lda #128
                sta 2
                lda #128
                sta 3
                jsr putsprite
.endif

                lda     $4015
                and     #$10
                bne     +
                lda     NED_Reg4015
                and     #$0F
                sta     NED_Reg4015
+
                LDA     NED_Reg4015
                sta     $4015


                LDX     #3
UpdateChannels
                CPX     #TRIWAV_CHN
                BEQ     +
                jsr     DoVolEffsTx
+
                jsr     DoPitchEffsTx
@DontSetPeriod
                DEX
                BPL     UpdateChannels


Halted
                INC     NED_ChnBigTick
                INC     NED_ChnBigTick+1
                INC     NED_ChnBigTick+2
                INC     NED_ChnBigTick+3

                RTS

DoVolEffsTx
                lda     NED_ChnEff,X
                cmp     #NED_EffVolSlide
                bne     NoEffVolSlideTx
                        LDA     NED_ChnEffParm,X
                        BEQ     +
                                STA     NED_ChnVolumeSlide,X
                        +
                        lda     NED_ChnVolumeSlide,X
                        tay
                        and     #$F0
                        beq     +
                        lsr
                        lsr
                        lsr
                        lsr
                        ;adc     NED_Temp1
                        adc     NED_ChnVolume,X
                        sta     NED_ChnVolume,X
                        jmp     EffVolSlideDone
+
                        tya
                        and     #$0F            ; remove!
                        eor     #$FF
                        sec
                        adc     NED_ChnVolume,X
                        sta     NED_ChnVolume,X
                        ;sta     NED_Temp1
                        ;lda     NED_ChnVolume,X
                        ;sec
                        ;sbc     NED_Temp1
                        ;sta     NED_Temp1

EffVolSlideDone
                        jmp     +

NoEffVolSlideTx
                lda     NED_ChnAutoVolumeSlide,X
                beq     +
                        clc
                        adc     NED_ChnVolume,X
                        sta     NED_ChnVolume,X
+

                ldy     NED_ChnEff,X
                ;lda     NED_ChnTremolo,X
                cpy     #NED_EffTremolo
                bne     ++
                LDA     NED_ChnEffParm,X
                BEQ     +
                STA     NED_ChnTremolo,X
+               LDA     NED_ChnTremolo,X
                bNE     DoTremolo
++
                lda     NED_ChnAutoTremolo,X
                bne     DoTremolo

                LDA     NED_ChnVolume,X
                BPL     +
                LDA     #0
+
                CMP     #63
                BCC     +
                LDA     #63
+
                STA     NED_ChnVolume,X
                Jmp     NED_SetVolume
                



DoTremolo

                PHA
                and     #$0F

                ldy     NED_ChnTremoloPos,X
                jsr     ReadSineTab

                bmi     @NegativeTremDelta

                clc
                adc     NED_ChnVolume,X
                jsr     NED_SetVolume

                PLA

                lsr
                lsr
                lsr
                lsr
                clc
                adc     NED_ChnTremoloPos,X
                cmp     #32
                bpl     @ResetTremPos
                sta     NED_ChnTremoloPos,X

                rts

@NegativeTremDelta
                clc
                adc     NED_ChnVolume,X
                jsr     NED_SetVolume

                PLA

                lsr
                lsr
                lsr
                lsr
                clc
                adc     NED_ChnTremoloPos,X
                cmp     #32
                bpl     @ResetTremPos
                sta     NED_ChnTremoloPos,X

                rts

@ResetTremPos
                cmp #$80 ;sec     ; prolly' not needed
                sbc     #64
                sta     NED_ChnTremoloPos,X

                rts



; In: A = Depth (in lower nibble), Y = Position

ReadSineTab
                bmi     @PositionNegative
                dey
                bmi     @PositionZero
                ora     Pos2TabPos,Y
                tay
                lda     VibAndTremTab,Y

                clc

                rts

@PositionNegative
                PHA
                tya
                eor     #$FF
                and     #31
                tay

                DEY

                PLA
                ora     Pos2TabPos,Y
                tay
                lda     VibAndTremTab,Y

                eor     #$FF
                clc
                adc     #1

                ;sec
                cmp #$80        ; bug
                rts

@PositionZero
                lda     #0
                clc
                rts





DoVibrato
                PHA
                and     #$0F

                ldy     NED_ChnVibratoPos,X
                jsr     ReadSineTab

                ROR
                bmi     @NegativeVibDelta

                clc
                adc     NED_ChnPeriodLo,X
                tay
                lda     NED_ChnPeriodHi,X
                adc     #0
                sta     NED_Temp1
                tya
                jsr     NED_SetPeriod

                PLA

                lsr
                lsr
                lsr
                lsr
                clc
                adc     NED_ChnVibratoPos,X
                cmp     #32
                bpl     @ResetVibPos
                sta     NED_ChnVibratoPos,X

                rts

@NegativeVibDelta
                clc
                adc     NED_ChnPeriodLo,X
                tay
                lda     NED_ChnPeriodHi,X
                adc     #$FF
                sta     NED_Temp1
                tya
                jsr     NED_SetPeriod

                PLA

                lsr
                lsr
                lsr
                lsr
                clc
                adc     NED_ChnVibratoPos,X
                cmp     #32
                bpl     @ResetVibPos
                sta     NED_ChnVibratoPos,X

                rts

@ResetVibPos
                ;cmp #$80 ;sec     ; prolly' not needed
                sec
                sbc     #64
                sta     NED_ChnVibratoPos,X

                rts


DoPitchEffsTx   jsr     DoArpEffsTx
                ;jsr     DoPortaEffsTx
                Jmp     DoPortaEffsTx
-
                ldy     NED_ChnEff,X
                ;lda     NED_ChnVibrato,X
                cpy     #NED_EffVibrato
                BNE     ++
                LDA     NED_ChnEffParm,X
                BEQ     +
                STA     NED_ChnVibrato,X
                +
                LDA     NED_ChnVibrato,X
                bNE     DoVibrato
++

                lda     NED_ChnAutoVibrato,X
                bne     DoVibrato

                LDA     NED_ChnPeriodHi,X
                STA     NED_Temp1
                LDA     NED_ChnPeriodLo,X
                Jmp     NED_SetPeriod




DoPortaEffsTx
                lda     NED_ChnEff,X
                cmp     #NED_EffTonePorta
                beq     DoTonePorta

                cmp     #NED_EffPortaUp
                beq     DoPortaUp
                cmp     #NED_EffPortaDown
                beq     DoPortaDown
                lda     NED_ChnAutoPorta,X
                bne     DoAutoPorta
                jmp     -


DoAutoPorta
                lda     NED_ChnAutoPorta,X
                bmi     DoAutoPortaUp
                clc
                adc     NED_ChnPeriodLo,X
                sta     NED_ChnPeriodLo,X
                lda     NED_ChnPeriodHi,X
                adc     #0
                sta     NED_ChnPeriodHi,X
                jmp     -

DoAutoPortaUp
                clc
                adc     NED_ChnPeriodLo,X
                sta     NED_ChnPeriodLo,X
                lda     NED_ChnPeriodHi,X
                adc     #$FF
                sta     NED_ChnPeriodHi,X
                jmp     -

DoPortaUp
                LDA     NED_ChnEffParm,X
                BEQ     +
                        STA     NED_ChnPortaSpeed,X
                +

                lda     NED_ChnPeriodLo,X
                sec
                sbc     NED_ChnPortaSpeed,X
                sta     NED_ChnPeriodLo,X
                lda     NED_ChnPeriodHi,X
                sbc     #0
                sta     NED_ChnPeriodHi,X
                jmp     -

DoPortaDown
                LDA     NED_ChnEffParm,X
                BEQ     +
                        STA     NED_ChnPortaSpeed,X
                +

                lda     NED_ChnPeriodLo,X
                clc
                adc     NED_ChnPortaSpeed,X
                sta     NED_ChnPeriodLo,X
                lda     NED_ChnPeriodHi,X
                adc     #0
                sta     NED_ChnPeriodHi,X
                jmp     -

DoTonePorta
                LDA     NED_ChnTone,X
                BEQ     +
                STA     NED_ChnPortaTone,X
+
                LDA     NED_ChnEffParm,X
                BEQ     +
                        STA     NED_ChnPortaSpeed,X
                +

                ldy     NED_ChnPortaTone,X

                lda     Tone2PeriodLoTab-1,Y
                sta     NED_TempWordLo
                lda     Tone2PeriodHiTab-1,Y
                sta     NED_TempWordHi

                sec
                lda     NED_ChnPeriodLo,X
                sbc     NED_TempWordLo
                lda     NED_ChnPeriodHi,X
                sbc     NED_TempWordHi
                bmi     @TonePortaDown
                bPL     @TonePortaUp

                jmp     -

@TonePortaDown
                lda     NED_ChnPeriodLo,X

                clc     ; prolly' not needed

                adc     NED_ChnPortaSpeed,X
                sta     NED_ChnPeriodLo,X
                lda     NED_ChnPeriodHi,X
                adc     #0
                sta     NED_ChnPeriodHi,X

                sec
                lda     NED_ChnPeriodLo,X
                sbc     NED_TempWordLo
                lda     NED_ChnPeriodHi,X
                sbc     NED_TempWordHi
                bpl     @StopTonePorta

                jmp     -

@TonePortaUp
                lda     NED_ChnPeriodLo,X

                sec     ; prolly' not needed

                sbc     NED_ChnPortaSpeed,X
                sta     NED_ChnPeriodLo,X
                lda     NED_ChnPeriodHi,X
                sbc     #0
                sta     NED_ChnPeriodHi,X

                sec
                lda     NED_ChnPeriodLo,X
                sbc     NED_TempWordLo
                lda     NED_ChnPeriodHi,X
                sbc     NED_TempWordHi
                bmi     @StopTonePorta

                jmp     -

@StopTonePorta
                lda     NED_TempWordLo
                sta     NED_ChnPeriodLo,X
                lda     NED_TempWordHi
                sta     NED_ChnPeriodHi,X

                jmp     -



DoArpEffsTx
                lda     NED_ChnEff,X
                cmp     #NED_EffArpeggio
                beq     @DoArpeggioTx
                lda     NED_ChnAutoArpX,X
                bne     DoAutoArpeggio
                lda     NED_ChnAutoArpY,X
                bne     DoAutoArpeggio
                lda     NED_ChnAutoArpZ,X
                bne     DoAutoArpeggio
                rts

@DoArpeggioTx
                jMP     DoArpeggio

;@DoAutoArpeggioTx
;                JMP      DoAutoArpeggio

DoAutoArpeggio

                lda     NED_ChnBigTick,X
                ldy     NED_ChnAutoArpNL,X
                bne     @DoNonLoopedArpeggio
                and     #3
@DoNonLoopedArpeggio
                cmp     #0
                beq     @DoAutoArp0
                cmp     #1
                beq     @DoAutoArpX
                cmp     #2
                beq     @DoAutoArpY
                cmp     #3
                beq     @DoAutoArpZ
                rts


@DoAutoArp0
                ldy     NED_ChnLastTone,X
                lda     Tone2PeriodHiTab-1,Y
                sta     NED_ChnPeriodHi,X
                STA     NED_Temp1
                lda     Tone2PeriodLoTab-1,Y
                sta     NED_ChnPeriodLo,X

                Jmp     NED_SetPeriod


@DoAutoArpX

                lda     NED_ChnLastTone,X
                clc     ; Optimize!
                adc     NED_ChnAutoArpX,X
                tay


                lda     Tone2PeriodHiTab-1,Y
                sta     NED_ChnPeriodHi,X
                STA     NED_Temp1
                lda     Tone2PeriodLoTab-1,Y
                sta     NED_ChnPeriodLo,X

                Jmp     NED_SetPeriod


@DoAutoArpY
                lda     NED_ChnLastTone,X
                clc     ; Optimize!
                adc     NED_ChnAutoArpY,X

                tay


                lda     Tone2PeriodHiTab-1,Y
                sta     NED_ChnPeriodHi,X
                STA     NED_Temp1
                lda     Tone2PeriodLoTab-1,Y
                sta     NED_ChnPeriodLo,X

                Jmp     NED_SetPeriod



@DoAutoArpZ

                lda     NED_ChnLastTone,X
                clc     ; Optimize!
                adc     NED_ChnAutoArpZ,X

                tay

                lda     Tone2PeriodHiTab-1,Y
                sta     NED_ChnPeriodHi,X
                STA     NED_Temp1
                lda     Tone2PeriodLoTab-1,Y
                sta     NED_ChnPeriodLo,X

                Jmp     NED_SetPeriod




ChangeVolume
                sta     NED_ChnVolume,X
                jmp     DoneExEffsT0

SetSpeed        sta     NED_Speed
                jmp     DoneExEffsT0

BreakPattern    sec
                sbc     #1
                sta     NED_CurrRow
                lda     NED_CurrOrder
                clc
                adc     #1
                cmp     NED_SongLength
                bcc     +
                        lda     NED_RestartPos
+
                sta     NED_CurrOrder
                jmp     DoneExEffsT0


DoEffsT0
                ldy     NED_ChnEff,X
                BEQ     +
                LDA     NED_ChnEffParm,X
                cpy     #NED_EffSetVol
                beq     ChangeVolume
                cpy     #NED_EffSetSpeed
                beq     SetSpeed
                cpy     #NED_EffBrkPat
                beq     BreakPattern
+
DoneExEffsT0

                lda     NED_ChnEffParm,X
                cpy     #NED_EffArpeggio
                beq     DoArpeggioT0
                lda     NED_ChnAutoArpX,X
                bne     DoAutoArpeggioT0
                lda     NED_ChnAutoArpY,X
                bne     DoAutoArpeggioT0
                lda     NED_ChnAutoArpZ,X
                bne     DoAutoArpeggioT0


                lda     NED_ChnTone,X
                beq     +
                lda     NED_ChnEff,X
                cmp     #NED_EffTonePorta
                BEQ     +

                LDA     NED_ChnPeriodHi,X
                STA     NED_Temp1
                LDA     NED_ChnPeriodLo,X
                Jmp     NED_SetPeriod

+
                rts



DoArpeggioT0
                jsr     DoArpeggio

                LDA     NED_ChnPeriodHi,X
                STA     NED_Temp1
                LDA     NED_ChnPeriodLo,X
                Jmp     NED_SetPeriod

DoAutoArpeggioT0
                JMP     DoAutoArpeggio




DoArpeggio
                lda     NED_ChnEffParm,X
                beq     @NoArpParm
                        sta     NED_ChnArpeggio,X
@NoArpParm
                sec
                lda     NED_CurrTick
                beq     @DoArp0
@DoArpLoop      cmp     #1
                beq     @DoArpX
                cmp     #2
                beq     @DoArpY
                sbc     #3
                bne     @DoArpLoop

@DoArp0
                ldy     NED_ChnLastTone,X

                lda     Tone2PeriodLoTab-1,Y
                sta     NED_ChnPeriodLo,X
                lda     Tone2PeriodHiTab-1,Y
                sta     NED_ChnPeriodHi,X
                rts

@DoArpX
                lda     NED_ChnArpeggio,X
                lsr
                lsr
                lsr
                lsr
                clc
                adc     NED_ChnLastTone,X

                tay

                lda     Tone2PeriodLoTab-1,Y
                sta     NED_ChnPeriodLo,X
                lda     Tone2PeriodHiTab-1,Y
                sta     NED_ChnPeriodHi,X
                rts

@DoArpY
                lda     NED_ChnArpeggio,X
                and     #$0F
                clc
                adc     NED_ChnLastTone,X
                
                tay

                lda     Tone2PeriodLoTab-1,Y
                sta     NED_ChnPeriodLo,X
                lda     Tone2PeriodHiTab-1,Y
                sta     NED_ChnPeriodHi,X
                rts

; If instrument has not changed, just reset (& reload) volume and 
; reset misc things

SameInstrument
                LDA     NED_ChnTotalVBlanks,X   ; 4
                STA     NED_ChnVBlanksLeft,X    ; 4
                LDA     NED_ChnLastVolume,X     ; 4
                STA     NED_ChnVolume,X         ; 4
                LDA     NED_ChnBitIndex,X       ; 4
                ORA     NED_Reg4015             ; 3/4
                STA     NED_Reg4015             ; 3/4
                JMP     NoInst                  ; 3

NED_UpdateT0

                                ;lda     #6
                                ;sta     $2001

                JSR     GetSNotes

                ;INC     NED_CurrRow
                ;RTS

                LDX     #3
ChnLoop

                LDA     NED_ChnInst,X
                Bne     @YesInst
                jmp     NoInst

@YesInst
                        CMP     NED_ChnLastInst,X
                        BEQ     SameInstrument

                        sta     NED_ChnLastInst,X       ; 4
                        asl                             ; 2
                        asl                             ; 2
                        asl                             ; 2
                        adc     #(256-8)                ; 2
                        tay                             ; 2

                        lda     (NED_InstAddr),Y        ; 5
                        iny                             ; 2

                        sta     NED_ChnReg0,X           ; 4
                        lda     (NED_InstAddr),Y        ; 5
                        iny                             ; 2
                        sta     NED_ChnAutoPorta,X      ; 4
                        lda     (NED_InstAddr),Y        ; 5
                        iny                             ; 2
                        sta     NED_ChnAutoVibrato,X    ; 4
                        lda     (NED_InstAddr),Y        ; 5
                        iny                             ; 2
                        sta     NED_ChnAutoTremolo,X    ; 4     
                        lda     (NED_InstAddr),Y        ; 5     63


                        bmi     @@VolumeSlideGoesUp     ; 2/3

                        iny                             ; 2
                        and     #$7F                    ; 2
                        ;sta     NED_ChnVBlanksLeft,X
                        sta     NED_Temp1               ; 3
                        lda     NED_ChnReg0,X           ; 4
                        asl                             ; 2
                        asl                             ; 2
                        and     #$80                    ; 2
                        ora     NED_Temp1               ; 3
                        sta     NED_ChnVBlanksLeft,X    ; 4
                        sta     NED_ChnTotalVBlanks,X   ; 4
                        lda     (NED_InstAddr),Y        ; 5
                        sta     NED_Temp1               ; 3
                        and     #$F0                    ; 2
                        lsr                             ; 2
                        lsr                             ; 2
                        sta     NED_ChnVolume,X         ; 4

                        STA     NED_ChnLastVolume,X     ; 4

                        lda     NED_Temp1               ; 3
                        and     #$0F                    ; 2
                        eor     #$FF                    ; 2
                        clc                             ; 2
                        adc     #1                      ; 2
                        sta     NED_ChnAutoVolumeSlide,X        ; 61

                        jmp     +
@@VolumeSlideGoesUp
                        iny                             ; 2
                        and     #$7F                    ; 2
                        ;sta     NED_ChnVBlanksLeft,X

                        sta     NED_Temp1               ; 3

                        lda     NED_ChnReg0,X           ; 4
                        asl                             ; 2
                        asl                             ; 2
                        and     #$80                    ; 2
                        ora     NED_Temp1               ; 3
                        sta     NED_ChnVBlanksLeft,X    ; 4
                        sta     NED_ChnTotalVBlanks,X   ; 4

                        lda     (NED_InstAddr),Y        ; 5
                        sta     NED_Temp1               ; 3
                        and     #$F0                    ; 2
                        lsr                             ; 2
                        lsr                             ; 2
                        sta     NED_ChnVolume,X         ; 4
                        lda     NED_Temp1               ; 3
                        and     #$0F                    ; 2

                        sta     NED_ChnAutoVolumeSlide,X        ; 4
+
                        iny                             ; 2
                        lda     (NED_InstAddr),Y        ; 5
                        iny                             ; 2
                        sta     NED_Temp1               ; 3
                        asl                             ; 2
                        and     #$80                    ; 2
                        sta     NED_ChnLoopedNoise,X    ; 4
                        lda     NED_Temp1               ; 3
                        and     #$20                    ; 2
                        sta     NED_ChnAutoArpNL,X      ; 4
                        lda     (NED_InstAddr),Y        ; 5
                        tay                             ; 2
                        and     #$0F                    ; 2     38

                        bcs     @@ReversedArpeggio      ; 2/3

                        sta     NED_ChnAutoArpX,X       ; 4
                        tya                             ; 2
                        lsr                             ; 2
                        lsr                             ; 2
                        lsr                             ; 2
                        lsr                             ; 2
                        sta     NED_ChnAutoArpY,X       ; 4
                        lda     NED_Temp1               ; 3
                        and     #$0F                    ; 2
                        sta     NED_ChnAutoArpZ,X       ; 4     27
                        jmp     +
@@ReversedArpeggio
                        eor     #$FF                    ; 2
                        clc                             ; 2
                        adc     #1                      ; 2
                        sta     NED_ChnAutoArpX,X       ; 4
                        tya                             ; 2
                        lsr                             ; 2
                        lsr                             ; 2
                        lsr                             ; 2
                        lsr                             ; 2
                        eor     #$FF                    ; 2
                        clc                             ; 2
                        adc     #1                      ; 2
                        sta     NED_ChnAutoArpY,X       ; 4
                        lda     NED_Temp1               ; 3
                        and     #$0F                    ; 2
                        eor     #$FF                    ; 2
                        clc                             ; 2
                        adc     #1                      ; 2
                        sta     NED_ChnAutoArpZ,X       ; 4
+


                        LDA     NED_ChnBitIndex,X       ; 4
                        ORA     NED_Reg4015             ; 3/4
                        STA     NED_Reg4015             ; 3/4
NoInst

                ;LDA     NED_ChnTone,X
                LDy     NED_ChnTone,X
                BEQ     NoTone
                        ;cmp     #97
                        cPY     #97
                        beq     NoteOff

                        ;STA     NED_ChnLastTone,X
                        STy     NED_ChnLastTone,X


                        lda     #0
                        sta     NED_ChnBigTick,X
                        STA     NED_ChnTremoloPos,X

                        lda     NED_ChnTotalVBlanks,X
                        sta     NED_ChnVBlanksLeft,X

                        LDA     NED_ChnBitIndex,X
                        ORA     NED_Reg4015
                        STA     NED_Reg4015

                        lda     NED_ChnEff,X
                        cmp     #NED_EffTonePorta
                        beq     SkipPeriodSetToneRead

                        ;should make sure period is only updated when needed
                        lda     #$FF
                        sta     NED_ChnPeriodHiLast,X


                        LDA     #0
                        STA     NED_ChnVibratoPos,X


                        ;ldY     NED_ChnLastTone,X

                        CPX     #NOSWAV_CHN
                        BEQ     ChnIsNoise


                        LDA     Tone2PeriodLoTab-1,Y
                        STA     NED_ChnPeriodLo,X
                        LDA     Tone2PeriodHiTab-1,Y
-
                        STA     NED_ChnPeriodHi,X


                        LDA     NED_ChnBitIndex,X
                        ORA     NED_Reg4015
                        STA     NED_Reg4015

SkipPeriodSetToneRead

NoTone

                        DEX
                        bmi     @ExitChnLoop
                        jmp     ChnLoop
@ExitChnLoop

;                        INC     NED_CurrRow
;                        RTS

;                        jsr     UpdateDPCMT0

                        jmp     UpdateChannelsT0


NoteOff         LDA     NED_ChnBitIndexInv,X
                AND     NED_Reg4015
                STA     NED_Reg4015
                jmp     NoTone

ChnIsNoise
                        dey
                        STy     NED_ChnPeriodLo,X
                        ;DEC     NED_ChnPeriodLo,X
                        LDA     #0
                        jmp     -



UpdateDPCMT0    ldx     #DPCM_CHN
                lda     NED_ChnTone,X
                beq     @NoSampleTone
                        ;sta     NED_ChnLastTone,X
@NoSampleTone
                lda     NED_ChnInst,X
                beq     @NoSampleInst
                        ;sta     NED_ChnLastInst,X
@NoSampleInst
                lda     NED_ChnTone,X
                cmp     #97
                beq     @SetSampleToneOff
                cmp     #0
                bne     @PlaySample
                lda     NED_ChnInst,X
                bne     @PlaySample

                rts

@SetSampleToneOff


                lda     NED_Reg4015
                and     #$0F
                sta     $4015
                rts

@PlaySample
                lda     NED_Reg4015
                and     #$0f
                sta     $4015

                ldy     NED_ChnTone,X
                dey
                lda     NED_ChnInst,X
                sec
                sbc     #1

                jsr     GetDPCMRegs
                

                sty     $4010
                sta     $4011
                stx     $4012
                lda     NED_Temp1
                sta     $4013

                lda     NED_Reg4015
                ora     #$10
                sta     NED_Reg4015
                sta     $4015

                rts


PatternIsEmpty  lda     #0
                STA     NED_ChnPatRowsTotal,X
                jmp     BackFromPatternIsEmpty


GetSNotes       LDA     #$40
                STA     NED_Temp3
                LDA     #0

                LDX     #4      ; This now includes DPCM!!!

@ClearLoop      STA     NED_ChnTone,X
                STA     NED_ChnInst,X
                STA     NED_ChnEff,X
                STA     NED_ChnEffParm,X
                DEX
                BPL     @ClearLoop
                
                
                LDA     NED_CurrRow
                BNE     DontRecalcPtrs0
                LDA     NED_CurrTick
                BNE     DontRecalcPtrs0
                jmp     +
DontRecalcPtrs0 jmp     DontRecalcPtrs
+


                        LDA     NED_CurrOrder
                        ASL
                        asl
                        TAY
                        LDA     (NED_OrderAddr),Y
                        iny

                        tax
                        and     #$1F
                        asl
                        sta     NED_ChnPattern+0
                        LDA     (NED_OrderAddr),Y
                        sta     NED_Temp1
                        lsr
                        sty     NED_Temp2
                        tay
                        and     #$3E
                        sta     NED_ChnPattern+2
                        txa
                        ror
                        tax
                        tya
                        lsr
                        txa
                        ror
                        ror
                        ror
                        and     #$3E
                        sta     NED_ChnPattern+1
                        asl     NED_Temp1

                        ldy     NED_Temp2
                        iny
                        LDA     (NED_OrderAddr),Y
                        tax
                        rol
                        asl
                        and     #$3E

                        sta     NED_ChnPattern+3
                        txa
                        lsr
                        lsr
                        lsr
                        and     #$3E
                        sta     NED_ChnPattern+4

                        ldx     #4      ; includes DPCM
-
                        LDA     NED_ChnPatPtrsAddrLo,X
                        STA     NED_TempWordLo
                        LDA     NED_ChnPatPtrsAddrHi,X
                        STA     NED_TempWordHi


                        ldy     NED_ChnPattern,X
                        LDA     (NED_TempWord),Y
                        INY
                        CMP     #0
                        bNE     +
                        STA     NED_Temp1
                        LDA     (NED_TempWord),Y
                        bne     Buggar
                        ;beq     PatternIsEmpty
                        jmp     PatternIsEmpty
Buggar
                        lda     NED_Temp1
+

                        clc

                        ADC     NED_NedAddr
                        STA     NED_ChnPatAddrLo,X
                        STA     NED_TempWord2Lo
                        ;INY
                        LDA     (NED_TempWord),Y
                        ADC     NED_NedAddr+1
                        STA     NED_ChnPatAddrHi,X
                        STA     NED_TempWord2Hi

                        LDY     #0              ; Read StartRow & EndRow vars
                        LDA     (NED_TempWord2),Y
                        STA     NED_ChnPatRowsToSkip,X
                        INY
                        LDA     (NED_TempWord2),Y
                        ;clc     ; remove! probably not needed
                        ADC     #1
                        STA     NED_ChnPatRowsTotal,X

                        ADC     #1
                        ;adc     #5
                        LSR
                        clc
                        ADC     #2
                        STA     NED_ChnPatOffs,x
                        lda     #0
                        sta     NED_ChnNibAddrOdd,x

BackFromPatternIsEmpty
                        dex
                        bpl     -

DontRecalcPtrs

                LDX     #4      ; This now includes DPCM!!!
DecodeChnLoop
                DEC     NED_ChnPatRowsTotal,X
                BMI     DoneDecoding0
                DEC     NED_ChnPatRowsToSkip,X
                BPL     DoneDecoding0

                jmp     +
DoneDecoding0
                JMP     DoneDecoding
+

                LDA     NED_ChnPatAddrLo,X
                STA     NED_TempWord
                LDA     NED_ChnPatAddrHi,X
                STA     NED_TempWord+1

@DecodeChn0     LDA     NED_CurrRow                             ; 3
                LSR                                             ; 2
                TAY                                             ; 2
                INY
                INY
                LDA     (NED_TempWord),Y                        ; 5
                BCC     @LowerNib                               ; 2
                        LSR                                     ; 2
                        LSR                                     ; 2
                        LSR                                     ; 2
                        LSR                                     ; 2
@LowerNib
                ldy     NED_ChnNibAddrOdd,x
                sty     NED_Temp1
                bit     NED_Temp1
                LDY     NED_ChnPatOffs,x                        ; 3
                LSR                                             ; 2
                STA     NED_Temp1                               ; 3

                BCC     @ToneNotPresent                         ; 2
;                beq     +
;                .db $FF
;+

                        cpx     #NOSWAV_CHN
                        beq     @NoiseTone
                        bvs   @ToneAddrOdd
                                LDA     (NED_TempWord),Y        ; 5
                                INY                             ; 2
                                ;clv
                                JMP     @ToneDecoded            ; 3
@ToneAddrOdd
                        LDA     (NED_TempWord),Y                ; 5
                        AND     #$F0                            ; 2

                        STA     NED_Temp2                       ; 3
                        INY                                     ; 2
                        LDA     (NED_TempWord),Y                ; 5
                        AND     #$0F                            ; 2

                        ORA     NED_Temp2                       ; 3
                        ;bit     NED_Temp3
                        jmp     @ToneDecoded

@NoiseTone
                        bvs     @NosToneAddrOdd
                                lda     (NED_TempWord),Y
                                and     #$0F
                                ;clc
                                ;adc     #1
                                SBC     #$FF
                                bit     NED_Temp3
                                jmp     @ToneDecoded

@NosToneAddrOdd         lda     (NED_TempWord),Y
                        lsr
                        lsr
                        lsr
                        lsr
                        clc
                        adc     #1
                        ;SBC     #$FF
                        iny
                        clv

@ToneDecoded
                STA     NED_ChnTone,x                           ; 3


@ToneNotPresent
                LSR     NED_Temp1                               ; 5
                BCC     @InstNotPresent                         ; 2
                        bvs     @InstAddrOdd
                                LDA     (NED_TempWord),Y        ; 5
                                AND     #$0F                    ; 2

                                ADC     #0
                                STA     NED_ChnInst,x                           ; 3

                                bit     NED_Temp3
                                JMP     @InstDecoded            ; 3

@InstAddrOdd
                        LDA     (NED_TempWord),Y                ; 5
                        LSR                                     ; 2
                        LSR                                     ; 2
                        LSR                                     ; 2
                        LSR                                     ; 2
                        INY                                     ; 2

                        CLC
                        ADC     #1
                        STA     NED_ChnInst,x                           ; 3
                        clv     ; will work now?...
                        
@InstDecoded                                                    ; 2
                ;STA     NED_ChnInst,x                           ; 3
                ;inc     NED_ChnInst,x                           ; 5-6
@InstNotPresent
                LSR     NED_Temp1                               ; 5
                BCC     @EffectNotPresent
                        bvs     @EffectAddrOdd
                                LDA     (NED_TempWord),Y        ; 5
                                AND     #$0F                    ; 2
                                bit     NED_Temp3
                                JMP     @EffectDecoded          ; 3
@EffectAddrOdd
                        LDA     (NED_TempWord),Y                ; 5
                        LSR                                     ; 2
                        LSR                                     ; 2
                        LSR                                     ; 2
                        LSR                                     ; 2
                        INY                                     ; 2
                        clv     ; will work now?...

@EffectDecoded
                STA     NED_ChnEff,x                            ; 3
@EffectNotPresent
                LSR     NED_Temp1                               ; 5
                BCC     @EffParmNotPresent                      ; 2
                        bvs     @EffParmAddrOdd
                                LDA     (NED_TempWord),Y        ; 5
                                INY                             ; 2
                                ;clv
                                JMP     @EffParmDecoded         ; 3
@EffParmAddrOdd
                        LDA     (NED_TempWord),Y                ; 5
                        AND     #$F0                            ; 2

                        STA     NED_Temp2                       ; 3
                        INY                                     ; 2
                        LDA     (NED_TempWord),Y                ; 5
                        AND     #$0F                            ; 2

                        ORA     NED_Temp2                       ; 3
                        ;bit     NED_Temp3

@EffParmDecoded
                STA     NED_ChnEffParm,x                        ; 3
@EffParmNotPresent

                STY     NED_ChnPatOffs,x

                LDA     #$40
                BVS     @DontClearV
                        LDA     #0
@DontClearV
                STa     NED_ChnNibAddrOdd,x                     ; 3 =~= 180 c
                                                ; (180*4)/114=6-7 rasterlines
DoneDecoding
                dex
                bmi     +
                jmp     DecodeChnLoop
+


                RTS





UpdateChannelsT0
                        ldx     #3
-
                        ;lda     NED_ChnVBlanksLeft,X
                        ldy     NED_ChnVBlanksLeft,X
                        bmi     @HoldNoteOnT0
                        ;sec
                        ;sbc     #1
                        dey
                        bpl     @DontSetNoteOffT0
                                lda     NED_ChnBitIndexInv,X
                                and     NED_Reg4015
                                sta     NED_Reg4015
                                lda     #0
                                ldy     #0

@DontSetNoteOffT0
                        ;sta     NED_ChnVBlanksLeft,X
                        sty     NED_ChnVBlanksLeft,X
                        ;beq     @NotTriChn
@HoldNoteOnT0

                dex
                bpl     -


.if 0
                lda #<finishedoffsamplespr
                sta 0
                lda #>finishedoffsamplespr
                sta 1
                lda #128
                sta 2
                lda #128
                sta 3
                jsr putsprite
.endif
                lda     $4015
                and     #$10
                bne     +
                lda     NED_Reg4015
                and     #$0F
                sta     NED_Reg4015
+

                        LDA     NED_Reg4015
                        sta     $4015


                        ldx     #3
@UpdateLoop
                        jsr     DoEffsT0
                        CPX     #TRIWAV_CHN
                        BEQ     @SkipSetVolume
                        lda     NED_ChnInst,X
                        bne     @SetVolume
                        lda     NED_ChnEff,X
                        cmp     #NED_EffSetVol
                        beq     @SetVolume
                        jmp     @SkipSetVolume

@SetVolume
                        LDA     NED_ChnVolume,X
                        LSR
                        LSR
                        ORA     NED_ChnReg0,X
                        LDY     NED_Chn2RegIndex,X
                        STA     $4000,Y
@SkipSetVolume

                        dex
                        bpl     @UpdateLoop

                        INC     NED_ChnBigTick
                        INC     NED_ChnBigTick+1
                        INC     NED_ChnBigTick+2
                        INC     NED_ChnBigTick+3

                        INC     NED_CurrRow


                        RTS


NSF_Play


                dec     NED_PAL_Counter
                bpl @@DontSkip
                ;JMP     @@DontSkip
                lda     #$05
                sta     NED_PAL_Counter
                jmp     @@Skip

@@DontSkip      Jmp     NED_PlayNED
@@Skip:

                rts

NSF_InitSong
                ;LDA     #<NED_SONG
                ;LDX     #>NED_SONG
                
                ;AND     #$7
                ASL
                TAY
                lda     NED_SongPtrs,Y
                INY
                ldx     NED_SongPtrs,Y

                JSR     NED_SetupNED

                lda     #$05
                sta     NED_PAL_Counter

                lda #$1F
                sta $4015       ; ***
                rts
                
NED_SEV_Emulator        .DB     $C0

NED_NibbleNegationTab   .DB     $00,$FF,$FE,$FD,$FC,$FB,$FA,$F9
                        .DB     $F8,$F7,$F6,$F5,$F4,$F3,$F2,$F1

NED_Chn2RegIndex        .DB     $00,$04,$08,$0C

NED_ChnBitIndex         .DB     $01,$02,$04,$08
NED_ChnBitIndexInv      .DB     $FE,$FD,$FB,$F7



Pos2TabPos      .DB $00,$10,$20,$30,$40,$50,$60,$70
                .DB $80,$90,$A0,$B0,$C0,$D0,$E0,$F0
                .DB $E0,$D0,$C0,$B0,$A0,$90,$80,$70
                .DB $60,$50,$40,$30,$20,$10,$00

VibAndTremTab   .DB 0, 0, 0, 1, 1, 1, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5
                .DB 0, 0, 1, 2, 3, 3, 4, 5, 6, 6, 7, 8, 9, 9, 10, 11
                ;.DB 0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 15, 16, 17
                .DB 0, 1, 3, 4, 6, 7, 9, 10, 12, 13, 15, 16, 18, 19, 21, 22
                .DB 0, 1, 3, 5, 7, 9, 11, 13, 15, 16, 18, 20, 22, 24, 26, 28
                .DB 0, 2, 4, 6, 8, 11, 13, 15, 17, 19, 22, 24, 26, 28, 30, 33
                .DB 0, 2, 5, 7, 10, 12, 15, 17, 20, 22, 25, 27, 30, 32, 35, 37
                .DB 0, 2, 5, 8, 11, 14, 16, 19, 22, 25, 28, 30, 33, 36, 39, 42
                .DB 0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 40, 43, 46
                .DB 0, 3, 6, 9, 13, 16, 19, 23, 26, 29, 33, 36, 39, 43, 46, 49
                .DB 0, 3, 7, 10, 14, 17, 21, 24, 28, 31, 35, 38, 42, 45, 49, 52
                .DB 0, 3, 7, 11, 14, 18, 22, 25, 29, 33, 36, 40, 44, 47, 51, 55
                .DB 0, 3, 7, 11, 15, 19, 22, 26, 30, 34, 38, 41, 45, 49, 53, 57
                .DB 0, 3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 42, 46, 50, 54, 58
                .DB 0, 3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47, 51, 55, 59
                .DB 0, 3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47, 51, 55, 59


Tone2PeriodLoTab .DB $5C, $9C, $E8, $3C, $9C, $2F, $72, $EC, $FF, $F2, $80, $14
                 .DB $AE, $4E, $F4, $9E, $4E, $1,  $B9, $76, $35, $F9, $C0, $8A 
                 .DB $57, $27, $FA, $CF, $A7, $81, $5D, $3B, $1B, $FD, $E0, $C5 
                 .DB $AC, $94, $7D, $68, $53, $40, $2E, $1D, $D,  $FE, $F0, $E3 
                 .DB $D6, $CA, $BE, $B4, $AA, $A0, $97, $8F, $87, $7F, $78, $71
                 .DB $6B, $65, $5F, $5A, $55, $50, $4C, $47, $43, $40, $3C, $39 
                 .DB $35, $32, $30, $2D, $2A, $28, $26, $24, $22, $20, $1E, $1C 
                 .DB $1B, $19, $18, $16, $15, $14, $13, $12, $11, $10, $F,  $E

Tone2PeriodHiTab .DB $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7
                 .DB $6, $6, $5, $5, $5, $5, $4, $4, $4, $3, $3, $3 
                 .DB $3, $3, $2, $2, $2, $2, $2, $2, $2, $1, $1, $1 
                 .DB $1, $1, $1, $1, $1, $1, $1, $1, $1, $0, $0, $0 
                 .DB $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0 
                 .DB $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0 
                 .DB $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0 
                 .DB $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0 

NED_SongPtrs    .DW     ned1
                .DW     ned2
                .DW     ned3
                .DW     ned4
                .DW     ned5
                .DW     ned6
                .DW     ned7
                .DW     ned8
                .dw ned9
                .dw ned10
                .dw ned11
                .dw ned12
                .dw ned13
                .dw ned14
                .dw ned15
                .dw ned16
                .dw ned17


;.PAD    $009000

;NED_ChnPeriodLo         = NED_ZRAM_BASE + $0C
;NED_ChnPeriodHi         = NED_RAM_BASE + $08


NED_SONGS = $
.incsrc "1.asm"

GetDPCMRegs     lda #0
                tax
                tay
                sta NED_Temp1
                rts



                                                                                     
                .db 13,10,"for now, i'm putting in a sprite that tells me"
                .db 13,10,"when a Bingo is done playing",13,10
                .incsrc "finished.asm"
                
