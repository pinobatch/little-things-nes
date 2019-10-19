
  .incbin "plhead.hdr"
.org $c000
nmis            = $10
p8m_zrambase    = $60
p8m_rambase     = p8m_zrambase + $0c

p8m_songaddr    = p8m_zrambase
p8m_instaddr    = p8m_zrambase+2
p8m_orderaddr   = p8m_zrambase+4
p8m_patptraddr  = p8m_zrambase+6
p8m_curtempo    = p8m_zrambase+8
p8m_tempocd     = p8m_zrambase+9
p8m_curchn      = p8m_zrambase+10
p8m_chpatlo     = p8m_rambase+$00
p8m_chpathi     = p8m_rambase+$04
p8m_chxpose     = p8m_rambase+$08
p8m_chcurorder  = p8m_rambase+$0c
p8m_chrest      = p8m_rambase+$10
p8m_chbasenote  = p8m_rambase+$14
p8m_chinst1     = p8m_rambase+$18
p8m_chadsr      = p8m_rambase+$20
p8m_chfreqlo    = p8m_rambase+$24
p8m_chfreqhi    = p8m_rambase+$28
p8m_lastfreqhi  = p8m_rambase+$2c
p8m_chvolume    = p8m_rambase+$30

p8m_chfmphase   = p8m_rambase+$38
p8m_chfmrate    = p8m_rambase+$3c
p8m_ch4000      = p8m_rambase+$40
p8m_tuneoff     = p8m_rambase+$44
p8m_chbend      = p8m_rambase+$48
p8m_charp       = p8m_rambase+$4c
p8m_chattack    = p8m_rambase+$50
p8m_chdecay     = p8m_rambase+$54


ppuctrl         = $2000
ppumask         = $2001
ppustatus       = $2002
spraddr         = $2003
ppuscroll       = $2005
ppuaddr         = $2006
ppudata         = $2007

sprdma          = $4014
sndchn          = $4015
joy1read        = $4016
joy2read        = $4017



p8mh_header_size = 1
p8mh_initspeed   = 3
p8mh_ninsts      = 4
p8mh_norders     = 5
p8mh_npats       = 6
p8mh_initorder   = 8

P8M_ATTACK      = 1
P8M_DECAY       = 2
P8M_SUSTAIN     = 3
P8M_RELEASE     = 4

P8M_NCHANNELS   = 2



  jmp p8m_play
  jmp p8m_init

freqstab_lo
  .incbin "freqstab.bin"
freqstab_hi = freqstab_lo + 64


p8m_init
  lda #<p8m_thesong
  sta p8m_songaddr
  lda #>p8m_thesong
  sta p8m_songaddr+1

  ldy #p8mh_header_size
  lda (p8m_songaddr),y
  clc
  adc p8m_songaddr
  sta p8m_instaddr
  lda p8m_songaddr+1
  adc #0
  sta p8m_instaddr+1

  lda #0
  sta 0
  sta p8m_tempocd
  ldy #p8mh_ninsts
  lda (p8m_songaddr),y
  asl a
  rol 0
  asl a
  rol 0
  asl a
  rol 0
  adc p8m_instaddr
  sta p8m_orderaddr
  lda p8m_instaddr+1
  adc 0
  sta p8m_orderaddr+1

  ldy #p8mh_norders
  lda #0
  sta 0
  lda (p8m_songaddr),y
  asl a
  rol 0
  adc p8m_orderaddr
  sta p8m_patptraddr
  lda p8m_orderaddr+1
  adc #0
  sta p8m_patptraddr+1

  ldy #p8mh_initspeed
  lda (p8m_songaddr),y
  sta p8m_curtempo

  lda #$01
  sta sndchn

  ldx #0
-
  lda #4
  sta p8m_chrest,x

  txa
  ora #8
  tay
  lda (p8m_songaddr),y
  sta p8m_chcurorder,x
  jsr p8m_ordertableload

  inx
  cpx #P8M_NCHANNELS
  bne -
  rts

p8m_ordertableload

  ; first compute orders[curorder]
  ldy #0                ;indexing
  sty 1
  lda p8m_chcurorder,x
  asl a
  rol 1
  adc p8m_orderaddr
  sta 0
  lda 1
  adc p8m_orderaddr+1
  sta 1
  lda (0),y
  iny
  sta 2
  lda (0),y
  sta 3

  ;now interpret it

  lda 2
  cmp #$ff
  bne p8m_notorderjump
  lda 3
  sta p8m_chcurorder,x
  jmp p8m_ordertableload
p8m_notorderjump
  sta p8m_chxpose,x
  ;find patptr[a]+songaddr
  lda 3
  ldy #0
  sty 1
  asl a
  rol 1
  adc p8m_patptraddr
  sta 0
  lda 1
  adc p8m_patptraddr+1
  sta 1
  clc
  lda (0),y
  iny
  adc p8m_songaddr
  sta p8m_chpatlo,x
  lda (0),y
  adc p8m_songaddr+1
  sta p8m_chpathi,x

  rts

p8m_play
  lda p8m_tempocd
  clc
  adc p8m_curtempo
  sta p8m_tempocd
  bcs +
  ldx #0
  jsr p8m_chwrite
  rts
+
  ldx #0
  stx p8m_curchn
p8m_chloop              ;Interpret a row
  lda p8m_chrest,x
  beq +
  dec p8m_chrest,x
p8m_restonerow
  jsr p8m_chwrite
  inx
  cpx #P8M_NCHANNELS
  bcc p8m_chloop
  rts
+
  lda p8m_chpatlo,x
  sta 0
  lda p8m_chpathi,x
  sta 1
  ldy #0
  lda (0),y
  bne p8m_notpatbrk     ;0: pattern break
  inc p8m_chcurorder,x
  jsr p8m_ordertableload
  jmp p8m_chloop
p8m_notpatbrk
  cmp #$40
  bcs p8m_notrest       ;00cLLLLL: rest
  pha
  and #$1f
  sta p8m_chrest,x
  pla
  and #$20
  beq p8m_incpat1

  lda #P8M_RELEASE
  sta p8m_chadsr

p8m_incpat1
  inc p8m_chpatlo,x
  bne +
  inc p8m_chpathi,x
+
  jmp p8m_chloop

p8m_notrest
  cmp #$60
  bcs p8m_notnote       ;010LLLLL rsnnnnnn: note
  and #%00011111
  sta p8m_chrest,x
  iny
  lda (0),y
  sta 2
  and #$3f
  sta p8m_chbasenote,x
  tay
  lda freqstab_lo,y
  sta p8m_chfreqlo,x
  lda freqstab_hi,y
  sta p8m_chfreqhi,x

  inc p8m_chpatlo,x
  bne +
  inc p8m_chpathi,x
+
  inc p8m_chpatlo,x
  bne +
  inc p8m_chpathi,x
+
  lda 2
  bpl +
  lda p8m_chinst1,x
  jsr p8m_retrig
+
  jmp p8m_restonerow

p8m_notnote
  cmp #$80              ; 011aiiii
  bcs p8m_noteffect
  jmp p8m_incpat1

p8m_retrig
  asl a
  asl a
  asl a
  clc
  adc p8m_instaddr
  sta 0
  lda #0
  tay
  adc p8m_instaddr+1
  sta 1
  lda (0),y
  sta p8m_ch4000,x
  and #$0f
  asl a
  asl a
  sta p8m_chvolume,x
  iny
  lda (0),y
  sta p8m_chbend,x
  iny
  lda (0),y
  sta p8m_charp,x
  iny
  iny
  iny
  lda (0),y
  sta p8m_chfmrate,x
  iny
  lda (0),y
  sta p8m_chattack,x
  iny
  lda (0),y
  sta p8m_chdecay,x
  lda #P8M_ATTACK
  sta p8m_chadsr,x

  rts

p8m_noteffect
  sta 2
  and #$1f
  sta p8m_chinst1,x

  lda 2
  and #$20
  beq +
  lda p8m_chinst1,x
  jsr p8m_retrig
+
  jmp p8m_incpat1


p8m_chan_enable_bit
  .dcb $01,$02,$04,$08
p8m_chan_disable_bit
  .dcb $fe,$fd,$fb,$f7


p8m_chwrite
  lda p8m_chvolume,x
  cmp #4
  bcs +
  lda p8m_chan_disable_bit,x
  and sndchn
  sta sndchn
  lda #$ff
  sta p8m_lastfreqhi
  rts
+
  lda p8m_chan_enable_bit,x
  ora sndchn
  sta sndchn

  txa
  asl a
  asl a
  tay

  lda p8m_ch4000,x
  and #$c0
  ora #$30
  sta 2
  lda p8m_chvolume
  lsr a
  lsr a
  ora 2

  sta $4000,y

  lda p8m_chfreqhi,x
  cmp p8m_lastfreqhi,x
  beq +
  sta p8m_lastfreqhi,x
  sta $4003,y
+
  lda p8m_chfreqlo,x
  sta $4002,y

  lda p8m_chadsr,x
  cmp #P8M_ATTACK
  bne p8m_notattack
  lda #$0f
  and p8m_chattack,x
  beq p8m_settodecay
  dec p8m_chattack,x
  lda p8m_chattack,x
  lsr a
  lsr a
  lsr a
  lsr a
  clc
  adc p8m_chvolume,x
  cmp #63
  bcc +
  lda #63
+
  sta p8m_chvolume,x
  rts
p8m_settodecay
  lda #P8M_DECAY
  sta p8m_chadsr,x
p8m_notattack
  cmp #P8M_DECAY
  bne p8m_notdecay
  lda #$0f
  and p8m_chdecay,x
  beq p8m_settosustain
  dec p8m_chdecay,x
  lda p8m_chdecay,x
  lsr a
  lsr a
  lsr a
  lsr a
  eor #$ff
  sec
  adc p8m_chvolume,x
  bcs +
  lda #0
+
  sta p8m_chvolume,x
  rts
p8m_settosustain
  lda #P8M_SUSTAIN
  sta p8m_chadsr,x
p8m_notdecay
  cmp #P8M_SUSTAIN
  bne +
  rts
+
  lda p8m_chdecay,x
  lsr a
  lsr a
  lsr a
  lsr a
  eor #$ff
  sec
  adc p8m_chvolume,x
  bcs +
  lda #0
+
  sta p8m_chvolume,x
  rts





.pad $c800
  .dcb 13,10,"This is as big as we want the music code to get.",13,10

p8m_thesong
  .dcb $00,$10,$00,44
  .dcb 2,5,3,0
  .dcb 0,3,0,0
  .dcb 0,0,0,0

  ;instruments
  .dcb $52,0,0,0,0,0,$38,$63
  .dcb $5a,0,0,0,0,0,$18,$37

  ;orders
  .dcb $00,$02, $00,$00, $ff,$01
  .dcb $00,$01, $ff,$03

  ;patterns
  .dcw pat0-p8m_thesong
  .dcw pat1-p8m_thesong
  .dcw pat2-p8m_thesong

pat0:
  .dcb $a0, $43,$a6, $41,$a1, $41,$a2, $43,$a4, $41,$a2, $41,$a1
  .dcb      $43,$9f, $41,$9f, $41,$a2, $43,$a6, $41,$a4, $41,$a2, $00
pat1:
  .dcb $a0, $41,$82, $41,$8e, $41,$82, $41,$8e, $41,$86, $41,$92, $41,$86, $41,$92
  .dcb      $41,$87, $41,$93, $41,$87, $41,$93, $41,$87, $41,$93, $41,$87, $41,$93, $00
pat2:
  .dcb $10,$10,$00















.pad $fe00

main
  sei           ;begin to initialize NES
  cld
  lda #$c0      ;interrupt system
  sta joy2read
  ldx #1
  stx joy1read
  stx sndchn
  dex
  stx joy1read
  stx sndchn
  stx ppuctrl
  stx ppumask
  dex
  txs
  bit ppustatus
-               ;begin to wait for ppu to warm up
  bit ppustatus
  bpl -

  ldx #0        ;clear ram
-
  lda #$ef
  sta $200,x    ;200 is special because it contains the sprite table
  lda #0
  sta 0,x
  sta $100,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  inx
  bne -

-               ;after 2 vbls, the ppu should be warmed up
  bit ppustatus
  bpl -

  ;Assuming a=x=0 from cpuram clear...
  ldy #$80
  sty ppuctrl
  ldy #$20
  sty ppuaddr
  sta ppuaddr
  ldx #120
  lda #16
  ldy #19
-
  sty ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  dex
  bne -
  txa
  ldx #16
-
  sta ppudata
  sta ppudata
  sta ppudata
  sta ppudata
  dex
  bne -

  ldx #0
  stx ppuaddr
  stx ppuaddr
  lda #$3f
  sta ppuaddr
  stx ppuaddr
-
  lda graypal,x
  sta ppudata
  inx
  lda graypal,x
  sta ppudata
  inx
  cpx #32
  bcc -

  jsr p8m_init
-
  jsr wait4vbl
  jsr refresh_daemon
  lda #$80
  sta ppuctrl
  lda #0
  sta ppuscroll
  sta ppuscroll
  lda #%00001010
  sta ppumask
  jsr p8m_play
  jmp -

.pad $ff80
graypal
  .dcb $0f,$00,$10,$30,$0f,$00,$10,$30
  .dcb $0f,$00,$10,$30,$0f,$00,$10,$30
  .dcb $0f,$00,$10,$30,$0f,$00,$10,$30
  .dcb $0f,$00,$10,$30,$0f,$00,$10,$30

refresh_daemon
  ldx #$80
  stx ppuctrl
  ldx #0
  stx ppumask
  lda #$21
  sta ppuaddr
  stx ppuaddr
-
  lda p8m_zrambase,x
  lsr a
  lsr a
  lsr a
  lsr a
  sta ppudata
  lda p8m_zrambase,x
  and #$0f
  sta ppudata
  inx
  cpx #64
  bne -
  rts

wait4vbl
  lda nmis
-
  cmp nmis
  beq -
  rts

nmipoint
  inc nmis
irqpoint
  rti

.pad $fffa
  .dcw nmipoint
  .dcw main
  .dcw irqpoint

  .incbin "pl.chr"
