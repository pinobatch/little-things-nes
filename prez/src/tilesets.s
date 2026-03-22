.segment "RODATA0"
.export demo_tileset
demo_tileset:
  .incbin "obj/nes/tileset.chr"
  .incbin "obj/nes/sprtileset.chr"
