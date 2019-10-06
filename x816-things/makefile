# makefile for using ASM6 to build x816-things

ifdef COMSPEC
DOTEXE:=.exe
PY:=py -3
else
DOTEXE:=
PY:=python3
endif

.PHONY: all clean

all: nibbles.nes sndtest.nes insane.nes bingo.nes

clean:
	-rm nibbles/*.pkb raw-pcm-hello/*.pkb bingo/*.pkb insane/*.pkb
	-rm nibbles/*tab.bin
	-rm nibbles/packbits$(DOTEXE) nibbles/mkpowers$(DOTEXE) asm6$(DOTEXE)

nibbles.nes: nibbles/nibbles.asm nibbles/title.pkb nibbles/copr.pkb nibbles/nibb_tab.bin asm6$(DOTEXE)
	( cd nibbles && ../asm6 nibbles.asm ../nibbles.nes )

sndtest.nes: raw-pcm-hello/sndtest.asm raw-pcm-hello/title.pkb asm6$(DOTEXE)
	( cd raw-pcm-hello && ../asm6 sndtest.asm ../sndtest.nes )

insane.nes: insane/insane.asm asm6$(DOTEXE)
	( cd insane && ../asm6 insane.asm ../insane.nes )

bingo.nes: bingo/bingo.asm bingo/title.pkb bingo/copr.pkb bingo/readme.pkb asm6$(DOTEXE)
	( cd bingo && ../asm6 bingo.asm ../bingo.nes )

# Lookup tables

nibbles/nibb_tab.bin: nibbles/mkpowers$(DOTEXE)
	( cd nibbles && ./mkpowers )

# Nametable RLE compression

%.pkb: %.nam nibbles/packbits$(DOTEXE)
	nibbles/packbits $< $@

# Building native tools

asm6$(DOTEXE): asm6.c
	gcc -Wall -Os -std=c99 -s $< -o $@

nibbles/packbits$(DOTEXE): nibbles/packbits.c
	gcc -Wall -Os -s nibbles/packbits.c -o $@

nibbles/mkpowers$(DOTEXE): nibbles/mkpowers.c
	gcc -Wall -Os -s nibbles/mkpowers.c -o $@
