#!/usr/bin/make -f
#
# Makefile for gmewav, a wave renderer for Game_Music_Emu and DUMB
# Copyright 2017 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

title := gmewav
version = 0.03
objlist := gmewav gmesrcs canonwav

CC := gcc
CFLAGS := -std=c99 -Wall -Wextra -Os
LD := gcc
LDFLAGS := -Wall -Wextra -s
LDLIBS := -lgme -ldumb
objdir := obj
srcdir := src

ifdef COMSPEC
DOTEXE:=.exe
else
DOTEXE:=
endif

# Nicknames

.PHONY: all dist clean

all: $(title)$(DOTEXE)
dist: $(title)-$(version).zip

# The main executable

EXE := $(title)$(DOTEXE)
objlisto := $(foreach o,$(objlist),$(objdir)/$(o).o)

$(EXE): $(objlisto)
	$(LD) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(objdir)/%.o: $(srcdir)/%.c
	mkdir -p $(objdir)
	$(CC) $(CFLAGS) -c -o $@ $<

$(objdir)/gmewav.c: $(srcdir)/gmesrcs.h $(srcdir)/canonwav.h
$(objdir)/gmesrcs.c: $(srcdir)/gmesrcs.h
$(objdir)/canonwav.c: $(srcdir)/canonwav.h

# Installation

install: $(EXE) scripts/gmeplay.sh
	$(if $(PREFIX),,$(error variable 'PREFIX' must be set))
	mkdir -p $(PREFIX)/bin
	cp $(EXE) $(PREFIX)/bin/
	cp scripts/gmeplay.sh $(PREFIX)/bin/gmeplay
	chmod +x $(PREFIX)/bin/gmeplay

# Cleanup

clean:
	-rm $(objdir)/*.o

# Distribution

$(title)-$(version).zip: zip.in README.md CHANGES.txt makefile \
  $(EXE) scripts/gmeplay.sh
	zip -9 -u $@ -@ < $<

