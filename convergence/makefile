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
title = convergence

version = 0.01

# Assembly language files that make up the PRG ROM
objlist := paldetect bg

AS65 = ca65
LD65 = ld65
CFLAGS65 = -DUSE_DAS=1 -DDPCM_UNSAFE_PADS=1
objdir:=obj/nes
srcdir:=src
imgdir:=tilesets
PENTLY_MASTER:=..

#EMU := "/C/Program Files/Nintendulator/Nintendulator.exe"
EMU := fceux
DEBUGEMU := ~/.wine/drive_c/Program\ Files\ \(x86\)/FCEUX/fceux.exe
# other options for EMU are start (Windows) or gnome-open (GNOME)

# Things differing between UNIX and Windows.  COMSPEC will be set
# to the name of the shell on Windows and not defined on UNIX.
ifdef COMSPEC
  PY:=py
else
  PY:=python3
endif

.PHONY: run debug dist zip clean dep

run: $(title).nes
	$(EMU) $<
debug: $(title).nes
	$(DEBUGEMU) $<

clean:
	-rm $(objdir)/*.o $(objdir)/*.ch1 $(objdir)/*.chr $(objdir)/*.s
	-rm $(pentlyfiles)

# Rule to create or update the distribution zipfile by adding all
# files listed in zip.in.  Actually the zipfile depends on every
# single file in zip.in, but currently we use changes to the compiled
# program, makefile, and README as a heuristic for when something was
# changed.  It won't see changes to docs or tools, but usually when
# docs changes, README also changes, and when tools changes, the
# makefile changes.
dist: zip
zip: $(title)-$(version).zip
$(title)-$(version).zip: zip.in $(title).nes README.md CHANGES.txt $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here, but caulk goes where? > $@

# Rules for PRG ROM

objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

map.txt $(title).nes: nrom128chrram.cfg $(objlistntsc)
	$(LD65) -o $(title).nes -C $^ -m map.txt

$(objdir)/%.o: $(srcdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# Files that depend on included files
$(objdir)/bg.o: $(objdir)/tiles.ch1

# Rules for graphics data conversion

$(objdir)/%.ch1: $(imgdir)/%.png tools/pilbmp2nes.py
	$(PY) tools/pilbmp2nes.py -1 $< $@
