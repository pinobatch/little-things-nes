#!/usr/bin/make -f
#
# Makefile for DPCM Letterbox demo
# Copyright 2010 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#
AS65 = ca65
LD65 = ld65
EMU := fceux
CC = gcc
ifdef COMSPEC
DOTEXE=.exe
PY := py -3
else
DOTEXE=
PY := python3
endif
CFLAGS = -std=gnu99 -Wall -DNDEBUG -O
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

objlist = main
objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run all clean

run: dpcmletterbox.nes
	$(EMU) $<

all: dpcmletterbox.nes

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

map.txt dpcmletterbox.nes: NROM.ini $(objlistntsc)
	$(LD65) -m map.txt -o dpcmletterbox.nes -C $^

$(objdir)/main.o: $(objdir)/ac16.chr

$(objdir)/ac16.chr: $(imgdir)/ac16.png
	$(PY) ../common/tools/pilbmp2nes.py -H 16 $< $@

clean:
	-rm $(objdir)/*.o $(objdir)/*.chr
