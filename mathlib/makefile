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
title = mathlib
version = 0.01pre

# Space-separated list of assembly language files that make up the
# PRG ROM.  If it gets too long for one line, you can add a backslash
# (the \ character) at the end of the line and continue on the next.
objlist = importer \
  math bcd bpmmath count_ones

AS65 = ca65
LD65 = ld65
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

#EMU := "/C/Program Files/Nintendulator/Nintendulator.exe"
EMU := fceux
# other options for EMU are start (Windows) or gnome-open (GNOME)

# Compiler options for C build tools if needed
CC = gcc
CFLAGS = -std=gnu99 -Wall -DNDEBUG -O

# Windows needs .exe (and has COMSPEC); UNIX does not.
ifdef COMSPEC
DOTEXE=.exe
else
DOTEXE=
endif

.PHONY: test dist zip clean all

test: $(title).prg
	cd sim && ./tests.py

all: $(title).prg

# To guess when to update the distribution zipfile, we use
# changes to the compiled program, makefile, and README.
dist: zip
zip: $(title)-$(version).zip
$(title)-$(version).zip: zip.in $(title).prg README.md $(objdir)/index.txt sim/tests.py
	zip -9 -u $@ -@ < $<

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here > $@

clean:
	-rm $(objdir)/*.o

# Rules for PRG ROM

objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

map.txt $(title).prg: plainprg.x $(objlistntsc)
	$(LD65) -o $(title).prg -C $^ -m map.txt

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@
