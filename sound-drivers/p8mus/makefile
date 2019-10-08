
ifdef COMSPEC
DOTEXE:=.exe
else
DOTEXE:=
endif

ASM6 := ../../x816-things/asm6$(DOTEXE)
EMU := fceux

.PHONY: run all clean $(ASM6)

run: pl.nes
	$(EMU) $<

all: pl.nes

pl.nes: pl.asm plhead.hdr pl.chr $(ASM6)
	$(ASM6) $< $@

$(ASM6): ../../x816-things/asm6.c
	make -C ../../x816-things asm6$(DOTEXE)

clean:
	-echo 'no "clean" necessary for p8mus yet'
