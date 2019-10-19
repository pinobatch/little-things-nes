; iNES header
.segment "INESHDR"
  .byt "NES",$1A
  .byt 32  ; PRG ROM is sixteen banks, each 2 * 16384 bytes
  .byt 0   ; no CHR ROM; uses 8 KiB CHR RAM instead (if we used
           ; CHR ROM we'd be on the NINA board instead of BxROM)
  .byt $21 ; v mirroring, no battery, no trainer; mapper $x2
  .byt $20 ; classic header format; mapper $2x

