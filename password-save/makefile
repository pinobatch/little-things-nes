#!/usr/bin/make -f
#
# Makefile for Concentration Room
# Copyright 2010 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#
version = 0.01wip
objlist = main pw pads

CC65 = /usr/local/bin
AS65 = ca65
LD65 = ld65
CC = gcc
ifdef COMSPEC
DOTEXE=.exe
EMU := start
PY := py -3
else
DOTEXE=
EMU := fceux
PY := python3
endif
CFLAGS = -std=gnu99 -Wall -DNDEBUG -O
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

# -f while debugging code; -r while adding shuffle markup;
# neither once a module has stabilized
shufflemode = -r

objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run clean dist zip all

run: pwtest.nes
	$(EMU) $<
all: pwtest.nes

# Actually this depends on every single file in zip.in, but currently
# we use changes to pwtest.nes, makefile, and README as a heuristic
# for when something was changed.  Limitation: it won't see changes
# to docs or tools.
dist: zip
zip: pwtest-$(version).zip
pwtest-$(version).zip: zip.in pwtest.nes README.html $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here > $@

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

map.txt pwtest.nes: NROM.ini $(objlistntsc)
	$(LD65) -m map.txt -o pwtest.nes -C $^

$(objdir)/main.o: $(objdir)/titlegfx.chr $(objdir)/gamegfx.chr

$(objdir)/%.chr: $(imgdir)/%.png
	$(PY) ../common/tools/pilbmp2nes.py $< $@

clean:
	rm -r $(objdir)/*.chr $(objdir)/*.o

