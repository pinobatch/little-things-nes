#!/usr/bin/make -f
#
# Makefile for NES game
# Copyright 2011 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

# These are used in the title of the NES program and the zip file.
title = zapperlag
version = 0.01

# Space-separated list of assembly language files that make up the
# PRG ROM.  If it gets too long for one line, you can add a backslash
# (the \ character) at the end of the line and continue on the next.
objlist = measuretime paldetect puts bcd pads ppuclear main 
objlistalt = a-white

AS65 = ca65
LD65 = ld65
CFLAGS65 = -DZAPPER_TO_A_BUTTON=1 -DDPCM_UNSAFE=1
objdir = obj/nes
srcdir = src
imgdir = tilesets

#EMU := "/C/Program Files/Nintendulator/Nintendulator.exe"
EMU := fceux
# other options for EMU are start (Windows) or xdg-open (freedesktop)

# Windows needs .exe suffixed to the names of executables; UNIX does
# not.  COMSPEC will be set to the name of the shell on Windows and
# not defined on UNIX.
ifdef COMSPEC
PY:=py -3
else
PY:=python3
endif

.PHONY: run dist zip all clean

run: $(title).nes
	$(EMU) $<

all: $(title).nes a-white.nes

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

clean:
	rm $(objdir)/*.o $(objdir)/*.chr

# Rules for PRG ROM

objlisto = $(foreach o,$(objlist),$(objdir)/$(o).o)
objlistalto = $(foreach o,$(objlistalt),$(objdir)/$(o).o)

map.txt $(title).nes: nes.ini $(objlisto)
	$(LD65) -C $^ -m map.txt -o $(title).nes

mapalt.txt a-white.nes: nes.ini $(objlistalto)
	$(LD65) -C $^ -m map.txt -o a-white.nes

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# Files that depend on .incbin'd files
$(objdir)/main.o: $(objdir)/font16.chr 

$(objdir)/%.chr: $(imgdir)/%.png
	$(PY) tools/pilbmp2nes.py $< $@

$(objdir)/%16.chr: $(imgdir)/%.png
	$(PY) tools/pilbmp2nes.py -H 16 $< $@


