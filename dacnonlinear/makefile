#!/usr/bin/make -f
#
# Makefile for Pently music engine
# Copyright 2012-2015 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

# These are used in the title of the NES program and the zip file.
title = dacnonlinear
version = 0.01

# Space-separated list of asm files that make up the ROM,
# whether source code or generated
objlist := onekpulse nrom init main
objlistnsf := onekpulse nsfshell

AS65 = ca65
LD65 = ld65
CFLAGS65 := 
objdir = obj/nes
srcdir = src
imgdir = tilesets

#EMU := "/C/Program Files/Nintendulator/Nintendulator.exe"
EMU := fceux --input1 GamePad.0
DEBUGEMU := ~/.wine/drive_c/Program\ Files\ \(x86\)/FCEUX/fceux.exe
# other options for EMU are start (Windows) or gnome-open (GNOME)

# Work around a quirk of how the Python 3 for Windows installer
# sets up the PATH
ifdef COMSPEC
PY:=py
else
PY:=
endif


.PHONY: run debug clean dist zip all 

run: $(title).nes
	$(EMU) $<
debug: $(title).nes
	$(DEBUGEMU) $<
clean:
	-rm $(objdir)/*.o $(objdir)/*.s $(objdir)/*.chr

# Rule to create or update the distribution zipfile by adding all
# files listed in zip.in.  Actually the zipfile depends on every
# single file in zip.in, but currently we use changes to the compiled
# program, makefile, and README as a heuristic for when something was
# changed.  It won't see changes to docs or tools, but usually when
# docs changes, README also changes, and when tools changes, the
# makefile changes.
dist: zip
zip: $(title)-$(version).zip
$(title)-$(version).zip: zip.in all \
  README.md $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

$(objdir)/index.txt: makefile
	echo "This file forces the creation of the folder for object files. You may delete it." > $@

# Rules for PRG ROM

objlistntsc := $(foreach o,$(objlist),$(objdir)/$(o).o)
objlistnsf := $(foreach o,$(objlistnsf),$(objdir)/$(o).o)

all: $(title).nes $(title).nsf

map.txt $(title).nes: nrom128.cfg $(objlistntsc)
	$(LD65) -o $(title).nes -C $^ -m map.txt

nsfmap.txt $(title).nsf: nsf.cfg $(objlistnsf)
	$(LD65) -o $(title).nsf -C $^ -m nsfmap.txt

$(objdir)/%.o: \
  $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# Rules for CHR ROM

$(objdir)/%.chr: $(imgdir)/%.png
	$(PY) tools/pilbmp2nes.py $< $@
