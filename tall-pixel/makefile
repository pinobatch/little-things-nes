objlist = main

AS65 := ca65
LD65 := ld65
EMU := fceux
CC = gcc
ifdef COMSPEC
PY:=py -3
else
PY:=python3
endif
CFLAGS = -std=gnu99 -Wall -DNDEBUG -O
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run all clean

run: tall_pixel.nes
	$(EMU) $<

all: tall_pixel.nes

clean:
	-rm $(objdir)/*.o $(objdir)/*.chr

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

map.txt tall_pixel.nes: nes.ini $(objlistntsc)
	$(LD65) -C $^ -m map.txt -o tall_pixel.nes

$(objdir)/main.o: $(objdir)/ac16.chr

$(objdir)/ac16.chr: $(imgdir)/ac16.png
	$(PY) ../common/tools/pilbmp2nes.py -H 16 $< $@
