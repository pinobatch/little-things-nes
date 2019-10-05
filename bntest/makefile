AS65 = ca65
LD65 = ld65
CC = gcc

# Things that differ on Windows vs. *n?x
ifdef COMSPEC
EMU := start
DOTEXE=.exe
PY := py -3
else
EMU := fceux
DOTEXE=
PY := python3
endif

CFLAGS = -std=gnu99 -Wall -DNDEBUG -O
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

objlist = main 
objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run dist zip clean all

run: bntest.nes
	$(EMU) $<

all: bntest.nes
# TODO: Figure out how to recreate these
# bntest_aorom.nes  bntest_h.nes  bntest_v.nes

# Actually this depends on every single file in zip.in, but currently
# we use changes to bntest.nes as a heuristic for when something was
# changed.  Limitation: it won't see changes to docs or tools.
dist: zip
zip: bntest.zip
bntest.zip: zip.in bntest.nes makefile
	zip -9 -u $@ -@ < $<

clean:
	-rm $(objdir)/*.chr $(objdir)/*.o

map.txt bntest.nes: nes.ini $(objlistntsc)
	$(LD65) -C $^ -m map.txt -o bntest.nes

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/main.o: $(objdir)/font16.chr

$(objdir)/%16.chr: tilesets/%16.png
	$(PY) ../common/tools/pilbmp2nes.py -H 16 $< $@

$(objdir)/%.chr: tilesets/%.png
	$(PY)../common/ tools/pilbmp2nes.py $< $@


