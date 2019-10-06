
.PHONY: all

all: nibbles/nibbles.nes raw-pcm-hello/sndtest.nes insane/insane.nes bingo/bingo.nes

nibbles/nibbles.nes: nibbles/nibbles.asm nibbles/title.pkb nibbles/copr.pkb nibbles/nibb_tab.bin asm6
	( cd nibbles && ../asm6 nibbles.asm nibbles.nes )

nibbles/title.pkb: nibbles/title.nam nibbles/packbits
	nibbles/packbits nibbles/title.nam nibbles/title.pkb

nibbles/copr.pkb: nibbles/copr.nam nibbles/packbits
	nibbles/packbits nibbles/copr.nam nibbles/copr.pkb

nibbles/nibb_tab.bin: nibbles/mkpowers
	( cd nibbles && ./mkpowers )

nibbles/packbits: nibbles/packbits.c
	gcc -Wall -O3 -s nibbles/packbits.c -o nibbles/packbits

nibbles/mkpowers: nibbles/mkpowers.c
	gcc -Wall -O3 -s nibbles/mkpowers.c -o nibbles/mkpowers

raw-pcm-hello/sndtest.nes: raw-pcm-hello/sndtest.asm asm6
	( cd raw-pcm-hello && ../asm6 sndtest.asm sndtest.nes )

raw-pcm-hello/title.pkb: raw-pcm-hello/title.nam nibbles/packbits
	nibbles/packbits raw-pcm-hello/title.nam raw-pcm-hello/title.pkb

insane/insane.nes: insane/insane.asm asm6
	( cd insane && ../asm6 insane.asm insane.nes )

bingo/bingo.nes: bingo/bingo.asm bingo/title.pkb bingo/copr.pkb bingo/readme.pkb asm6
	( cd bingo && ../asm6 bingo.asm bingo.nes )

bingo/title.pkb: bingo/title.nam nibbles/packbits
	nibbles/packbits bingo/title.nam bingo/title.pkb

bingo/copr.pkb: bingo/copr.nam nibbles/packbits
	nibbles/packbits bingo/copr.nam bingo/copr.pkb

bingo/readme.pkb: bingo/readme.nam nibbles/packbits
	nibbles/packbits bingo/readme.nam bingo/readme.pkb

asm6: asm6.c
	gcc -Wall -O3 -std=c99 -s asm6.c -o asm6
