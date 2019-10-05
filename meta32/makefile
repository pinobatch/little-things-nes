title := meta32
objlist := hello pokecol sprite upd

objdir := obj/nes
srcdir := src
imgdir := tilesets

.PHONY: all run clean

run: $(title).nes
	fceux $<

all: $(title).nes

clean:
	-rm $(objdir)/*.o

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc
	ca65 -o $@ $<

map.txt $(title).nes: nes.ini $(foreach o,$(objlist),$(objdir)/$(o).o)
	ld65 -o $(title).nes -C $^ 

$(objdir)/hello.o: $(imgdir)/hello.chr $(imgdir)/spr.chr
