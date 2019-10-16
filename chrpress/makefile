AS65 = ca65
LD65 = ld65
EMU := fceux
ifdef COMSPEC
PY:=py -3
else
PY:=python3
endif
CFLAGS = -std=gnu99 -Wall -DNDEBUG -O
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

objlist = reset pads decompress
objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run dist zip all clean

run: chrpress.nes
	$(EMU) $<

all: chrpress.nes

clean:
	-rm $(objdir)/*.2bt $(objdir)/*.o

# Actually this depends on every single file in zip.in, but currently
# we use changes to chrpress.nes as a heuristic for when something was
# changed.  Limitation: it won't see changes to docs or tools.
dist: zip
zip: chrpress.zip
chrpress.zip: zip.in chrpress.nes makefile
	zip -9 -u $@ -@ < $<

map.txt chrpress.nes: nes.ini $(objlistntsc)
	$(LD65) -m map.txt -o chrpress.nes -C $^

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/decompress.o: $(objdir)/lj65chr.2bt

$(objdir)/%.2bt: tilesets/%.png
	$(PY) tools/chrpress.py $< $@

$(objdir)/%.chr: tilesets/%.png
	$(PY) ../common/tools/pilbmp2nes.py $< $@
