#!/usr/bin/make -f
#
# Makefile for NES game
# Copyright 2011-2022 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

# These are used in the title of the NES program and the zip file.
title = gridfloor
version = 0.02

# Space-separated list of assembly language files that make up the
# PRG ROM.  If it gets too long for one line, you can add a backslash
# (the \ character) at the end of the line and continue on the next.
objlist := \
  kernel init bg player pads ppuclear main nrom
objlistchrram := \
  kernel init bg pads ppuclear main-chrram nrom-chrram


AS65 = ca65
LD65 = ld65
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

#EMU := "/C/Program Files/Nintendulator/Nintendulator.exe"
EMU := fceux
DEBUGEMU := ~/.wine/drive_c/Program\ Files\ \(x86\)/FCEUX/fceux.exe
# other options for EMU are start (Windows) or gnome-open (GNOME)

# Occasionally, you need to make "build tools", or programs that run
# on a PC that convert, compress, or otherwise translate PC data
# files into the format that the NES program expects.  Some people
# write their build tools in C or C++; others prefer to write them in
# Perl, PHP, or Python.  This program doesn't use any C build tools,
# but if yours does, it might include definitions of variables that
# Make uses to call a C compiler.
CC = gcc
CFLAGS = -std=gnu99 -Wall -DNDEBUG -O

# Windows needs .exe suffixed to the names of executables; UNIX does
# not.  COMSPEC will be set to the name of the shell on Windows and
# not defined on UNIX.  Also the Windows Python installer puts
# py.exe in the path, but not python3.exe, which confuses MSYS Make.
ifeq ($(OS), Windows_NT)
DOTEXE:=.exe
PY:=py
else
DOTEXE:=
PY:=
endif

.PHONY: run debug all dist zip clean

run: $(title).nes
	$(EMU) $<
debug: $(title).nes
	$(DEBUGEMU) $<

all: $(title).nes $(title)-chrram.nes

# Rule to create or update the distribution zipfile by adding all
# files listed in zip.in.  Actually the zipfile depends on every
# single file in zip.in, but currently we use changes to the compiled
# program, makefile, and README as a heuristic for when something was
# changed.  It won't see changes to docs or tools, but usually when
# docs changes, README also changes, and when tools changes, the
# makefile changes.
dist: zip
zip: $(title)-$(version).zip
$(title)-$(version).zip: zip.in all README.md CHANGES.txt $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

# Build zip.in from the list of files in the Git tree
zip.in:
	git ls-files | grep -e "^[^.]" > $@
	echo $(title)-chrram.nes >> $@
	echo $(title).nes >> $@
	echo zip.in >> $@

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here > $@

clean:
	-rm $(objdir)/*.o $(objdir)/*.s $(objdir)/*.chr $(objdir)/*.nam
	-rm $(objdir)/*.sentinel $(objdir)/*.pb53 $(objdir)/*.ac8
	-rm map*.txt

# Rules for PRG ROM

map.txt $(title).nes: \
  nrom128.cfg $(foreach o,$(objlist),$(objdir)/$(o).o)
	$(LD65) -o $(title).nes -m map.txt -C $^

map-chrram.txt $(title)-chrram.nes: \
  nrom128-chrram.cfg $(foreach o,$(objlistchrram),$(objdir)/$(o).o)
	$(LD65) -o $(title)-chrram.nes -m map-chrram.txt -C $^

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/main-chrram.o: $(srcdir)/main.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) -DCHRRAM=1 $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# Files that depend on .incbin'd files
$(objdir)/nrom.o: \
  $(objdir)/spritegfx.chr $(objdir)/grid.u.chr
$(objdir)/nrom-chrram.o: \
  $(objdir)/spritegfx-trim5.chr.pb53 $(objdir)/grid.u.chr.pb53
$(objdir)/bg.o: $(objdir)/grid.nam.ac8

# Rules for CHR ROM

$(objdir)/%.chr: $(imgdir)/%.png
	$(PY) tools/pilbmp2nes.py $< $@

$(objdir)/%-trim5.chr: $(objdir)/%.chr
	dd if=$< of=$@ bs=16 count=5

$(objdir)/%.pb53: $(objdir)/%
	$(PY) tools/pb53.py --raw --no-prev $< $@

# Use a sentinel file to trick Make prior to version 4.3 into
# doing grouped targets
$(objdir)/%.nam.sentinel: $(objdir)/%.chr
	$(PY) tools/uniq.py --block-size 16 $< $(basename $<).u.chr $(basename $<).nam
	touch $@

$(objdir)/%.u.chr $(objdir)/%.nam: $(objdir)/%.nam.sentinel
	@test -f $@

$(objdir)/%.ac8: $(objdir)/%
	$(PY) tools/ac8.py $< $@

