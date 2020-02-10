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
title = fme7acktest
version = r1

# Space-separated list of assembly language files that make up the
# PRG ROM.  If it gets too long for one line, you can add a backslash
# (the \ character) at the end of the line and continue on the next.
objlist = fme7 init main bg \
pads ppuclear


AS65 = ca65
LD65 = ld65
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets
commonimgdir = ../common/tilesets

#EMU := "/C/Program Files/Nintendulator/Nintendulator.exe"
EMU := fceux
# other options for EMU are start (Windows) or gnome-open (GNOME)

# Windows needs .exe suffixed to the names of executables; UNIX does
# not.  COMSPEC will be set to the name of the shell on Windows and
# not defined on UNIX.
ifdef COMSPEC
PY := py -3
else
PY := python3
endif

.PHONY: run dist zip clean all

run: $(title).nes
	$(EMU) $<

all: $(title).nes

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
	echo Files produced by build tools go here, but caulk goes where? > $@

clean:
	-rm $(objdir)/*.o $(objdir)/*.s $(objdir)/*.chr

# Rules for PRG ROM

objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

map.txt $(title).nes: jsrom256.x $(objlistntsc)
	$(LD65) -o $(title).nes -m map.txt -C $^

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# Files that depend on .incbin'd files
$(objdir)/main.o: $(objdir)/fizzter16.chr

# This is an example of how to call a lookup table generator at
# build time.  mktables.py itself is not included because the demo
# has no music engine, but it's available online at
# http://wiki.nesdev.com/w/index.php/APU_period_table
$(objdir)/ntscPeriods.s: tools/mktables.py
	$< period $@

# Rules for CHR ROM

$(title).chr: $(objdir)/bggfx.chr $(objdir)/spritegfx.chr
	cat $^ > $@

$(objdir)/%.chr: $(imgdir)/%.png
	$(PY) ../common/tools/pilbmp2nes.py $< $@

$(objdir)/%16.chr: $(imgdir)/%.png
	$(PY) ../common/tools/pilbmp2nes.py -H 16 $< $@

$(objdir)/%16.chr: $(commonimgdir)/%.png
	$(PY) ../common/tools/pilbmp2nes.py -H 16 $< $@


