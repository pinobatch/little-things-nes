#!/usr/bin/make -f
#
# Makefile for NES game
# Copyright 2011-2025 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

# These are used in the title of the NES program and the zip file.
title := twobit
version := 0.01

# Translation units to be linked
objlist :=  play2b pads init main bg ppuclear

# Things differing between Windows and POSIX (Linux, BSD, macOS)
# environments
ifeq ($(OS), Windows_NT)
  PY := py -3
else
  PY := python3
endif

# Allow building either in or out of little things
# test by holms <https://stackoverflow.com/a/20566812/2738262>
COMMON_PILBMP2NES:=../common/tools/pilbmp2nes.py
LOCAL_PILBMP2NES:=tools/pilbmp2nes.py
ifneq ("$(wildcard $(COMMON_PILBMP2NES))","")
  PILBMP2NES:=$(COMMON_PILBMP2NES)
else
  PILBMP2NES:=$(LOCAL_PILBMP2NES)
endif

# Use cc65 conventions for variable names where practicable
CA65FLAGS := -g
CA65 := $(if $(wildcard $(CC65_HOME)/bin/ca65*),$(CC65_HOME)/bin/ca65,ca65)
LD65 := $(if $(wildcard $(CC65_HOME)/bin/ld65*),$(CC65_HOME)/bin/ld65,ld65)

objdir := obj/nes
srcdir := src
imgdir := tilesets

EMU := fceux
DEBUGEMU := Mesen
# other options for EMU are start "" (Windows) or xdg-open (UNIX)

.PHONY: run debug all dist zip clean

# Running `make` without arguments builds the target of the first
# rule in a makefile.  Because some editors bind F5 to `make`,
# some people prefer to have `make` behave as `make run`.
# Rules after the first may appear in any order.

run: $(title).nes
	$(EMU) $<
debug: $(title).nes
	$(DEBUGEMU) $<

# Rules to convert audio

obj/nes/%.w2b: tools/w2bencode.py audio/%.wav
	$(PY) $^ $@ --gain 6.0 --bias 0

# Rules to convert graphics from PNG to the NES's 2bpp format, or
# convert or generate other data

$(objdir)/%.chr: $(imgdir)/%.png
	$(PY) $(PILBMP2NES) $< $@

# Generic rules for assembling, or converting assembly language
# source code to object code

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(CA65) $(CA65FLAGS) $< -o $@

# List files that include other files.  This instructs Make to
# ensure other files are built first and to rebuild this file
# when the other files change.

$(objdir)/main.o: \
  $(objdir)/bggfx.chr \
  $(objdir)/intro.w2b $(objdir)/swapped.w2b $(objdir)/authentic.w2b

# Rules for linking TUs together

all: $(title).nes

objlisto := $(foreach o,nrom $(objlist),$(objdir)/$(o).o)

map.txt $(title).nes: nrom128.cfg $(objlisto)
	$(LD65) -o $(title).nes --dbgfile $(title).dbg -m map.txt -C $^

# Rule to create or update the distribution zipfile by adding all
# files listed in zip.in.  Use changes to the ROM, makefile, and
# README as a heuristic for when something was changed.
dist: zip
zip: $(title)-$(version).zip
$(title)-$(version).zip: \
  zip.in all README.md $(objdir)/index.txt # CHANGES.txt
	zip -9 -u $@ -@ < $<

# Build zip.in from the list of files in the Git tree.
zip.in: makefile README.md $(title).nes $(LOCAL_PILBMP2NES)
	git ls-files | grep -e "^[^.]" > $@
	echo $(title).nes >> $@
	echo zip.in >> $@
	echo $(LOCAL_PILBMP2NES) >> $@

# When building the zipfile, include common scripts from little things
$(LOCAL_PILBMP2NES): $(COMMON_PILBMP2NES)
	cp $< $@

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here > $@

# When troubleshooting a build process or cleaning up a full drive,
# you can remove intermediate files.
clean:
	$(RM) $(objdir)/*.o $(objdir)/*.s $(objdir)/*.chr
	$(RM) $(objdir)/*.w2b
