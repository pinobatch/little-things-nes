.ifndef HAVE_MMC3_H
.define HAVE_MMC3_H

MMC3SEL      = $8000
MMC3_SWAPCHR = $80
MMC3_FIX80   = $40

MMC3BANK     = $8001

MMC3MIRROR   = $A000
MMC3_H       = $00
MMC3_V       = $01

MMC3WRAM     = $A001
MMC3_RO      = $C0
MMC3_RW      = $80

MMC3IRQ      = $C000
MMC3IRQRESET = $C001
MMC3IRQOFF   = $E000
MMC3IRQON    = $E001

.endif