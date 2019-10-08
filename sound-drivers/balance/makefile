AS = ca65
LD = ld65
EMU = fceux

ifdef COMSPEC
DOTEXE:=.exe
else
DOTEXE:=
endif

objlist := initcode main freqtable

OBJS = $(foreach o,$(objlist),obj/nes/$(o).o)

.PHONY: run all clean

run: ../balance.nes
	$(EMU) $<

all: ../balance.nes

clean:
	-rm obj/nes/*.o obj/nes/*.dmc tools/freqtable$(DOTEXE)

obj/nes/%.o: src/%.s src/nes.inc
	$(AS) $(CFLAGS) $< -o $@

obj/nes/%.o: obj/nes/%.s
	$(AS) $(CFLAGS) $< -o $@

obj/nes/freqtable.s: tools/freqtable$(DOTEXE)
	tools/freqtable$(DOTEXE) > $@

tools/%$(DOTEXE): tools/%.c
	gcc -Wall -Wextra -Os $< -lm -o $@

obj/nes/%.dmc: tools/81%$(DOTEXE) %.wav
	$^ $@ 100 32

map.txt ../balance.nes: nes.ini $(OBJS)
	$(LD) -o ../balance.nes -m map.txt -C $^
