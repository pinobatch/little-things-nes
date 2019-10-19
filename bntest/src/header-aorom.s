; iNES header
.segment "INESHDR"
  .byt "NES",$1A
  .byt 32  ; PRG ROM is sixteen banks, each 2 * 16384 bytes
  .byt 0   ; no CHR ROM; uses 8 KiB CHR RAM instead
  .byt $70 ; v mirroring, no battery, no trainer; mapper $x7
  .byt $00 ; classic header format; mapper $0x

