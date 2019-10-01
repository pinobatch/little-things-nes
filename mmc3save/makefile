#!/usr/bin/make -f
#
# Makefile for codename mmc3save
# Copyright 2010 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#
version = 0.01wip
objlist = hello pads

AS65 = ca65
LD65 = ld65
EMU := fceux
CC = gcc
ifdef COMSPEC
PY:=py -3
else
PY:=python3
endif
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run dist zip all clean

run: mmc3save.nes
	$(EMU) $<

all: mmc3save.nes

# Actually this depends on every single file in zip.in, but currently
# we use changes to mmc3save.nes, makefile, and README as a heuristic
# for when something was changed.  Limitation: it won't see changes
# to docs or tools.
dist: zip
zip: mmc3save-$(version).zip
mmc3save-$(version).zip: zip.in mmc3save.nes README.html $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here > $@

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc $(srcdir)/mmc3.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/hello.o: $(objdir)/titlegfx.chr $(objdir)/gamegfx.chr

map.txt mmc3save.nes: nes.ini $(objlistntsc)
	$(LD65) -C $^ -m map.txt -o mmc3save.nes

$(objdir)/%.chr: $(imgdir)/%.png
	$(PY) tools/pilbmp2nes.py $< $@
