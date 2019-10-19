objdir := obj/nes
srcdir := src

objlist := \
  main editor chr unpkb sel sprcels \
  studio osk colorpicker login savedata dialog wram

CHR := \
  tools.chr ascii.chr studio.chr $(objdir)/studio.pkb \
  $(objdir)/keyboardFrame.pkb $(objdir)/copr.pkb \
  screens/colorPicker.nam screens/thingOrTeam.nam \
  $(objdir)/numbers16.chr $(objdir)/tableau.chr

CHR0 := $(srcdir)/presetNames.bin $(objdir)/presetsB16.chr $(objdir)/presetsA16.chr


CC := gcc
CFLAGS := -Wall -O -std=gnu99
LD := gcc
LDFLAGS := -Wall
AS65 := ca65
LD65 := ld65
EMU := fceux

NESROM := emblem
MAPPER := snrom

NESOBJS := $(foreach o,$(objlist),$(objdir)/$(o).o)


ifdef COMSPEC
PY:=py -3
DOTEXE:=.exe
else
py:=python3
DOTEXE:=
endif

.PHONY: run all clean

# NES side stuff

run: $(NESROM).nes
	$(EMU) $<

all: $(NESROM).nes

clean:
	-rm $(objdir)/*.o $(objdir)/*.pkb $(objdir)/*.chr

map.txt $(NESROM).nes: nes.ini $(NESOBJS)
	$(LD65) -m map.txt -o $(NESROM).nes -C $^

$(objdir)/chr.o: $(CHR) $(CHR0)
$(objdir)/sprcels.o: tools/sprcelsOut.chr

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/global.inc
	$(AS65) $< -o $@

$(objdir)/%.pkb: screens/%.nam
	$(PY) tools/packbits3.py $< $@

$(objdir)/%.chr: bmps/%.bmp
	$(PY) ../common/tools/pilbmp2nes.py $< $@

$(objdir)/%16.chr: bmps/%.bmp
	$(PY) ../common/tools/pilbmp2nes.py -H 16 $< $@
