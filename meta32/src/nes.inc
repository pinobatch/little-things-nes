.p02

OAM       = $0200

PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
SPRADDR   = $2003  ; always write 0 here and use DMA from OAM
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007

SPRDMA    = $4014
SNDCHN    = $4015
JOY1      = $4016
JOY2      = $4017

PPUCTRL_NMI      = $80
PPUCTRL_8X8      = $00
PPUCTRL_8X16     = $20
PPUCTRL_BGHIPAT  = $10
PPUCTRL_SPRHIPAT = $08
PPUCTRL_WRDOWN   = $04  ; when set, PPU address increments by 32

PPUMASK_RED      = $80  ; when set, slightly darkens other colors
PPUMASK_GREEN    = $40
PPUMASK_BLUE     = $20
PPUMASK_SPR      = $14  ; SPR: show sprites in x=0-255
PPUMASK_SPRCLIP  = $10  ; SPRCLIP: show sprites in x=8-255
PPUMASK_BG0      = $0A  ; BG0: similarly
PPUMASK_BG0CLIP  = $08
PPUMASK_MONO     = $01  ; when set, zeroes the low nibble of palette values

PPUSTATUS_VBL  = $80  ; the PPU has entered a vblank since last $2002 read
PPUSTATUS_SPR0 = $40  ; sprite 0 has overlapped BG since ???
PPUSTATUS_OVER = $20  ; More than 64 sprite pixels on a scanline since ???

