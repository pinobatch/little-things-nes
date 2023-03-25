#!/usr/bin/make -f
#
# Makefile for NES game
# Copyright 2011-2014 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

# These are used in the title of the NES program and the zip file.
title = rgbdetect
version = wip

# Space-separated list of assembly language files that make up the
# PRG ROM.  If it gets too long for one line, you can add a backslash
# (the \ character) at the end of the line and continue on the next.
objlist = nrom init main bg \
pads ppuclear


AS65 = ca65
LD65 = ld65
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

EMU := fceux
DEBUGEMU := Mesen

# The Windows Python installer puts py.exe in the path, but
# not python3.exe, which confuses MSYS Make.
ifdef COMSPEC
PY:=py
else
PY:=python3
endif
PNGTOCHR := $(PY) ../common/tools/pilbmp2nes.py

# Virtual targets ###################################################

.PHONY: run debug all dist zip clean

run: $(title).nes
	$(EMU) $<
debug: $(title).nes
	$(DEBUGEMU) $<

all: $(title).nes

dist: zip
zip: $(title)-$(version).zip
$(title)-$(version).zip: zip.in $(title).nes README.md CHANGES.txt $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

# Build zip.in from the list of files in the Git tree
zip.in:
	git ls-files | grep -e "^[^.]" > $@
	echo zip.in >> $@

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here, but caulk goes where? > $@

clean:
	-rm $(objdir)/*.o $(objdir)/*.s $(objdir)/*.nam $(objdir)/*.chr

# Rules for PRG ROM

objlisto = $(foreach o,$(objlist),$(objdir)/$(o).o)

map.txt $(title).nes: nrom128.cfg $(objlisto)
	$(LD65) -o $(title).nes -m map.txt -C $^

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# Files that depend on .incbin'd files
$(objdir)/bg.o: $(objdir)/logo.u.chr $(objdir)/logo.nam \
  $(objdir)/fizzter16.chr 

# Graphics conversion

$(objdir)/%.chr: $(imgdir)/%.png
	$(PNGTOCHR) $< $@

$(objdir)/%16.chr: $(imgdir)/%.png
	$(PNGTOCHR) -H 16 $< $@

$(objdir)/%.u.chr $(objdir)/%.nam: $(objdir)/%.chr
	$(PY) tools/uniq.py $< $(patsubst %.chr,%.u.chr,$<) $(patsubst %.chr,%.nam,$<)
