AS = ca65
LD = ld65
EMU = fceux

ifdef COMSPEC
DOTEXE:=.exe
else
DOTEXE:=
endif

objlist := freqs 5

OBJS = $(foreach o,$(objlist),obj/nes/$(o).o)

.PHONY: run all clean

run: 5.nes
	$(EMU) 5.nes

all: 5.nes

clean:
	-rm obj/nes/*.s obj/nes/*.o tools/mkpowers$(DOTEXE)

obj/nes/%.o: src/%.s
	$(AS) $(CFLAGS) $< -o $@

obj/nes/freqs.s: tools/mkpowers$(DOTEXE)
	$< > $@

tools/%$(DOTEXE): tools/%.c
	gcc -Wall -Wextra -Os $< -lm -o $@

map.txt 5.nes: nes.ini $(OBJS)
	$(LD) -m map.txt -o 5.nes -C $^
