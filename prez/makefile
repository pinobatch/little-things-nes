title := prez
objlist := vectors tilesets main camera coldecode coldecode2vram pads \
  sprites
tilesets := tileset sprtileset

AS65 := ca65
LD65 := ld65
EMU := Mesen
srcdir := src
objdir := obj/nes
objs := $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run

run: $(title).nes
	$(EMU) $<

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS) $< -o $@

$(objdir)/tilesets.o: $(foreach o,$(tilesets),$(objdir)/$(o).chr)

map.txt $(title).nes &: unrom1mbit.cfg $(objs)
	$(LD65) -C $^ -m map.txt -o $@

$(objdir)/%.chr: tilesets/%.png
	$(PY) ../common/tools/pilbmp2nes.py $< $@

