#!/usr/bin/make -f
#
# Makefile for NES game
# Copyright 2011-2015 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

# These are used in the title of the NES program and the zip file.
title := iretiny
version := 0.01

# Space-separated list of assembly language files that make up the
# PRG ROM.  If it gets too long for one line, you can add a backslash
# (the \ character) at the end of the line and continue on the next.
objlist = init main pads ppuclear

AS65 := ca65
LD65 := ld65
CFLAGS65 := 
objdir := obj/nes
srcdir := src
imgdir := tilesets

#EMU := "/C/Program Files/Nintendulator/Nintendulator.exe"
EMU := fceux
# other options for EMU are start (Windows) or gnome-open (GNOME)

# Windows needs .exe suffixed to the names of executables; UNIX does
# not.  COMSPEC will be set to the name of the shell on Windows and
# not defined on UNIX.
ifdef COMSPEC
PY:=py -3
else
PY:=python3
endif

.PHONY: run dist zip clean all

run: $(title).nes
	$(EMU) $<

all: $(title).nes $(title)218.nes

# Rule to create or update the distribution zipfile by adding all
# files listed in zip.in.  Actually the zipfile depends on every
# single file in zip.in, but currently we use changes to the compiled
# program, makefile, and README as a heuristic for when something was
# changed.  It won't see changes to docs or tools, but usually when
# docs changes, README also changes, and when tools changes, the
# makefile changes.
dist: zip
zip: $(title)-$(version).zip
$(title)-$(version).zip: zip.in $(title).nes $(title)218.nes README.md $(objdir)/index.txt # CHANGES.txt
	zip -9 -u $@ -@ < $<

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here, but caulk goes where? > $@

clean:
	-rm $(objdir)/*.o $(objdir)/*.1bpp

# Rules for PRG ROM

objlist7 = $(foreach o,aotiny $(objlist),$(objdir)/$(o).o)
objlist218 = $(foreach o,aotiny218 $(objlist),$(objdir)/$(o).o)

map.txt $(title).nes: nrom128.cfg $(objlist7)
	$(LD65) -o $(title).nes -m map.txt -C $^

map218.txt $(title)218.nes: nrom128.cfg $(objlist218)
	$(LD65) -o $(title)218.nes -m map218.txt -C $^

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/aotiny218.o: $(srcdir)/aotiny.s
	$(AS65) $(CFLAGS65) -DUSE_MAPPER_218=1 $< -o $@

# Files that depend on .incbin'd files
$(objdir)/main.o: $(objdir)/digits.1bpp

# Rules for CHR ROM

$(objdir)/%.1bpp: $(imgdir)/%.png
	$(PY) ../common/tools/pilbmp2nes.py -1 $< $@
