AS65 := ca65
LD65 := ld65
EMU := fceux
CC := gcc
ifdef COMSPEC
PY:=py -3
else
PY:=python3
endif
CFLAGS := -std=gnu99 -Wall -DNDEBUG -O
CFLAGS65 := 
objdir := obj/nes
srcdir := src
imgdir := tilesets

objlist := main
objlistntsc := $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run dist zip all clean

run: boing2k7.nes
	$(EMU) $<

all: boing2k7.nes

# Actually this depends on every single file in zip.in, but currently
# we use changes to boing2k7.nes as a heuristic for when something was
# changed.  Limitation: it won't see changes to docs or tools.
dist: zip
zip: boing2k7.zip
boing2k7.zip: zip.in boing2k7.nes makefile
	zip -9 -u $@ -@ < $<

clean:
	-rm $(objdir)/*.o $(objdir)/*.chr

map.txt boing2k7.nes: nes.ini $(objlistntsc)
	$(LD65) -m map.txt -o boing2k7.nes -C $^

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.chr: tilesets/%.png
	$(PY) ../common/tools/pilbmp2nes.py $< $@

$(objdir)/main.o: $(objdir)/ball.chr
