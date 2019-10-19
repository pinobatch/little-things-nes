; Names are based on
; http://nesdevwiki.org/index.php/NES_PPU
; http://nesdevwiki.org/index.php/2A03

; PPU registers
PPUCTRL    = $2000
NT_2000    = $00
NT_2400    = $01
NT_2800    = $02
NT_2C00    = $03
VRAM_DOWN  = $04
OBJ_0000   = $00
OBJ_1000   = $08
OBJ_8X16   = $20
BG_0000    = $00
BG_1000    = $10
VBLANK_NMI = $80

PPUMASK   = $2001
LIGHTGRAY = $01
BG_OFF    = $00
BG_CLIP   = $08
BG_ON     = $0A
OBJ_OFF   = $00
OBJ_CLIP  = $10
OBJ_ON    = $14

PPUSTATUS = $2002
OAMADDR   = $2003
OAMDATA   = $2004
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007

; Pulse channel registers
SQ1_VOL   = $4000
SQ1_SWEEP = $4001
SQ1_LO    = $4002
SQ1_HI    = $4003
SQ2_VOL   = $4004
SQ2_SWEEP = $4005
SQ2_LO    = $4006
SQ2_HI    = $4007

SQ_1_8      = $00  ; 1/8 duty (sounds sharp)
SQ_1_4      = $40  ; 1/4 duty (sounds rich)
SQ_1_2      = $80  ; 1/2 duty (sounds hollow)
SQ_3_4      = $C0  ; 3/4 duty (sounds like 1/4)
SQ_HOLD     = $20  ; halt length counter
SQ_CONSTVOL = $10  ; 0: envelope decays from 15 to 0; 1: constant volume
SWEEP_OFF   = $08

; Triangle channel registers
TRI_LINEAR = $4008
TRI_LO     = $400A
TRI_HI     = $400B

TRI_HOLD = $80

; Noise channel registers
NOISE_VOL = $400C
NOISE_LO  = $400E
NOISE_HI  = $400F

NOISE_HOLD = SQ_HOLD
NOISE_CONSTVOL = SQ_CONSTVOL
NOISE_LOOP = $80

; DPCM registers
DMC_FREQ  = $4010
DMC_RAW   = $4011
DMC_START = $4012
DMC_LEN   = $4013

; OAM DMA unit register
; Writing $xx here causes 256 bytes to be copied from $xx00-$xxFF
; to OAMDATA
OAM_DMA = $4014

; Sound channel control and status register
SND_CHN       = $4015
CH_SQ1   = %00000001
CH_SQ2   = %00000010
CH_TRI   = %00000100
CH_NOISE = %00001000
CH_ALL   = %00001111  ; all tone generators, not dpcm
CH_DPCM  = %00010000

JOY1 = $4016
JOY2 = $4017
APUCTRL       = $4017
APUCTRL_5STEP = $80
APUCTRL_NOIRQ = $40