#!/usr/bin/make -f
#
# Makefile for codename spritecans
# Copyright 2010 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#
version = 2011
objlist = sprite sound music musicseq paldetect ntscPeriods

AS65 = ca65
LD65 = ld65
#EMU := "/C/Program Files/nintendulator/Nintendulator.exe"
EMU := fceux
CC = gcc
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

objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run dist zip all clean

run: spritecans.nes
	$(EMU) $<

all: spritecans.nes

clean:
	-rm $(objdir)/*.o $(objdir)/*.s $(objdir)/*.chr

# Actually this depends on every single file in zip.in, but currently
# we use changes to spritecans.nes, makefile, and README as a heuristic
# for when something was changed.  Limitation: it won't see changes
# to docs or tools.
dist: zip
zip: spritecans-$(version).zip
spritecans-$(version).zip: zip.in spritecans.nes \
  README.md CHANGES.txt $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here > $@

$(objdir)/%.o: $(srcdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

map.txt spritecans.nes: nes.ini $(objlistntsc)
	$(LD65) -m map.txt -o spritecans.nes -C $^

$(objdir)/sprite.o: $(objdir)/spritecans.chr

$(objdir)/spritecans.chr: $(imgdir)/main.png
	$(PY) ../common/tools/pilbmp2nes.py $< $@

$(objdir)/ntscPeriods.s: tools/mktables.py
	$(PY) $< period $@
