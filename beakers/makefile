objlist := crt0 main readpad display

AS65 = ca65
LD65 = ld65
EMU := fceux

srcdir := src
objdir := obj/nes

OBJS:= $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run all clean

run: beakers.nes
	$(EMU) $<

all: beakers.nes

$(OBJS): $(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc
	$(AS65) $(CFLAGS) $< -o $@

beakers.nes: nes.ini $(OBJS)
	$(LD65) -C $^ -m map.txt -o $@

$(objdir)/display.o: data/bgopt.nam data/bgopt.chr data/8x16.chr

clean:
	-rm $(objdir)/*.o
