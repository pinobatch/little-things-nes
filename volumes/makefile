AS65 = ca65
LD65 = ld65
EMU := fceux
CC = gcc
CFLAGS = -std=gnu99 -Wall -DNDEBUG -O
CFLAGS65 = 
objdir = obj/nes
srcdir = src

objlist = hello pads sound
objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run all clean

run: volumes.nes
	$(EMU) $<

all: volumes.nes

clean:
	-rm obj/nes/*.o

$(objdir)/%.o: $(srcdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

map.txt volumes.nes: nes.ini $(objlistntsc)
	$(LD65) -C $^ -m map.txt -o volumes.nes
