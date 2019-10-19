# the following might differ per installation
EMU := fceux
LALLEG := -lalleg
#DOTEXE :=
DOTEXE := .exe

CC := gcc
CFLAGS := -Wall -O -std=gnu99
LD := gcc
LDFLAGS := -Wall
AS65 := ca65
LD65 := ld65
title := 768

srcdir := src
objdir := obj/nes
imgdir := tilesets

NESOBJS := $(objdir)/768.o

.PHONY: all run clean

run: $(title).nes
	$(EMU) $<

all: $(title).nes

clean:
	-rm $(objdir)/*.o

map.txt $(title).nes: $(NESOBJS)
	$(LD65) $^ -C nes.ini -m map.txt -o $(title).nes

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc
	$(AS65) $< -o $@

$(objdir)/768.o: $(imgdir)/768.chr
