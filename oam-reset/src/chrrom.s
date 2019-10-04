.segment "CHRROM"
bgtiles:
  .incbin "obj/nes/txt.chr"
  .res bgtiles+$1000-*
objtiles:
  .incbin "obj/nes/spritegfx16.chr"
  .res objtiles+$1000-*
