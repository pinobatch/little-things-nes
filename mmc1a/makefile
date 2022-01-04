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
title = mmc1atest
version = wip

# Space-separated list of assembly language files that make up the
# PRG ROM.  If it gets too long for one line, you can add a backslash
# (the \ character) at the end of the line and continue on the next.
objlist = main init pads ppuclear mmc1 chrram

AS65 = ca65
LD65 = ld65
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

#EMU := "/C/Program Files/Nintendulator/Nintendulator.exe"
EMU := fceux
DEBUGEMU := ~/.wine/drive_c/Program\ Files\ \(x86\)/FCEUX/fceux.exe
# other options for EMU are start (Windows) or xdg--open (Linux)

# Windows needs .exe suffixed to the names of executables; UNIX does
# not.  COMSPEC will be set to the name of the shell on Windows and
# not defined on UNIX.  Also the Windows Python installer puts
# py.exe in the path, but not python3.exe, which confuses MSYS Make.
ifeq ($(OS), Windows_NT)
DOTEXE:=.exe
PY:=py
else
DOTEXE:=
PY:=python3
endif

PILBMP2NES := $(PY) ../common/tools/pilbmp2nes.py

# Pseudo-targets
.PHONY: run runalt debug debugalt dist zip clean

run: $(title).nes
	$(EMU) $<
runalt: $(title)-sn.nes
	$(EMU) $<
all: $(title).nes $(title)-sn.nes

# Rule to create or update the distribution zipfile.  Use changes to
# the finished program, makefile, and README as a heuristic for when
# something was changed.
dist: zip
zip: $(title)-$(version).zip
$(title)-$(version).zip: $(title).nes $(title)-sn.nes \
  zip.in README.md CHANGES.txt $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

# Build zip.in from the list of files in the Git tree
zip.in:
	git ls-files | grep -e "^[^.]" > $@
	echo zip.in >> $@

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here, but caulk goes where? > $@

clean:
	-rm $(objdir)/*.o $(objdir)/*.s $(objdir)/*.chr

# Rules for PRG ROM

objlisto = $(foreach o,$(objlist),$(objdir)/$(o).o)

$(title).nes: tools/build_test.py $(title).prg $(objdir)/bggfx.chr
	$(PY) $^ -o $@ -t "MMC1A TEST"

$(title)-sn.nes: tools/build_test.py $(title).prg
	$(PY) $^ -o $@ -t "MMC1A TEST"

map.txt $(title).prg: snrom128kbit.cfg $(objlisto)
	$(LD65) -o $(title).prg -m map.txt -C $^

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# Files that depend on .incbin'd files
$(objdir)/chrram.o: $(objdir)/bggfx1.chr

# Rules for CHR data

$(objdir)/%.chr: $(imgdir)/%.png
	$(PILBMP2NES) $< $@

$(objdir)/%1.chr: $(imgdir)/%.png
	$(PILBMP2NES) -1 $< $@
