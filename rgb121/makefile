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
title = rgb121
version = 0.01

# Space-separated list of assembly language files that make up the
# PRG ROM.  If it gets too long for one line, you can add a backslash
# (the \ character) at the end of the line and continue on the next.
objlist := \
  main pads ppuclear mmc1 bankcalltable \
  bitstream drawchn pics

photolist := \
  su1 im_3figs eloi_1 top_half \
  071031_14 071031_16 im_front_yard im_diwheel \
  im_discipline logo

AS65 = ca65
LD65 = ld65
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets
photodir = converted

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

.PHONY: run dist zip all clean

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
	echo Files produced by build tools go here > $@

clean:
	-rm $(objdir)/*.o $(objdir)/*.121

# Rules for PRG ROM

objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

map.txt $(title).nes: nes.ini $(objlistntsc)
	$(LD65) -C $^ -m map.txt -o $(title).nes

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# incbins

$(objdir)/pics.o: $(foreach o,$(photolist),$(objdir)/$(o).121)

# Rules for CHR ROM

$(objdir)/%.121: $(photodir)/%.png
	$(PY) tools/pngto121.py $< $@
