#!/usr/bin/make -f
#
# Makefile for Vaus Test
# Copyright 2013 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

# These are used in the title of the NES program and the zip file.
title := vaus-test
version := 0.02

# Space-separated list of asm files
objlist := vauspads main detailed ppuclear bcd

AS65 := ca65
LD65 := ld65
CFLAGS65 := 
objdir := obj/nes
srcdir := src
imgdir := tilesets

EMU := Mesen
# other options for EMU are start "" (Windows) or xdg-open (*n?x)
PY := python3

.PHONY: run dist zip all clean 

run: $(title).nes
	$(EMU) $<

# Rule to create or update the distribution zipfile by adding all
# files listed in zip.in.  Actually the zipfile depends on every
# single file in zip.in, but currently we use changes to the compiled
# program, makefile, and README as a heuristic for when something was
# changed.  It won't see changes to docs or tools, but usually when
# docs changes, README also changes, and when tools changes, the
# makefile changes.
dist: zip
zip: $(title)-$(version).zip
$(title)-$(version).zip: zip.in $(title).nes README.txt $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here > $@

all: $(title).nes

clean:
	-rm $(objdir)/*.chr $(objdir)/*.o

# Rules for PRG ROM

objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

map.txt $(title).nes: nes.ini $(objlistntsc)
	$(LD65) -o $(title).nes -m map.txt -C $^

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.h $(srcdir)/ram.h
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# Files that depend on .incbin'd files
$(objdir)/title.o: todo.txt src/title.pkb
$(objdir)/main.o: $(objdir)/bggfx.chr $(objdir)/spritegfx.chr

# Rules for CHR ROM

$(objdir)/%.chr: $(imgdir)/%.png
	$(PY) ../common/tools/pilbmp2nes.py $< $@

