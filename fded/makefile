# the following might differ per installation
EMU := fceux
LALLEG := $(shell allegro-config --libs)
#DOTEXE :=
DOTEXE := .exe

ifdef COMSPEC
DOTEXE:=.exe
PY:=py -3
else
DOTEXE:=
PY:=python3
endif

CC := gcc
CFLAGS := -Wall -O -std=gnu99
LD := gcc
LDFLAGS := -Wall
AS65 := ca65
LD65 := ld65
NESROM := cout02
NESOBJS := cout02.o

.PHONY: all

all: fded$(DOTEXE) $(NESROM).nes

clean:
	-rm *.prg *.o

# PC side stuff

fded$(DOTEXE): fded.o
	$(LD) $(LDFLAGS) $^ $(LALLEG) -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# NES side stuff

run: $(NESROM).nes
	$(EMU) $<

%.nes: %.hdr %.prg %.chr
	cat $^ > $@

cout02.o: drawing.cout

map.txt $(NESROM).prg: nes.ini $(NESOBJS)
	$(LD65) -o $(NESROM).prg -m map.txt -C $^

$(NESOBJS): %.o: %.s
	$(AS65) $< -o $@
