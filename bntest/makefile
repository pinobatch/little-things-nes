AS65 = ca65
LD65 = ld65
CC = gcc

# Things that differ on Windows vs. *n?x
ifdef COMSPEC
EMU := start
PY := py -3
else
EMU := fceux
PY := python3
endif

CFLAGS65 := 
objdir := obj/nes
srcdir := src
imgdir := tilesets

objlist = main 
objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run dist clean all

run: bntest-aorom.nes
	$(EMU) $<

all: bntest-aorom.nes bntest-h.nes bntest-v.nes

# Actually this depends on every single file in zip.in, but currently
# we use changes to bntest.nes as a heuristic for when something was
# changed.  Limitation: it won't see changes to docs or tools.
dist: bntest.zip
bntest.zip: zip.in bntest.nes makefile
	zip -9 -u $@ -@ < $<

clean:
	-rm $(objdir)/*.chr $(objdir)/*.o

bntest-%.nes: nes.ini $(objlistntsc) $(objdir)/header-%.o
	$(LD65) -C $^ -o $@

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/main.o: $(objdir)/font16.chr

$(objdir)/%16.chr: tilesets/%16.png
	$(PY) ../common/tools/pilbmp2nes.py -H 16 $< $@

$(objdir)/%.chr: tilesets/%.png
	$(PY)../common/ tools/pilbmp2nes.py $< $@


