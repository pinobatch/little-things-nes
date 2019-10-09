# This makefile was newly created for little things in October 2019.
# It was not part of the original project template from October 2003.

%.o: %.s
	ca65 $< -o $@
hello.prg: nes.ini hello.o
	ld65 -o $@ -C $^
hello.nes: hello.prg hello.chr
	cat $^ > $@
all: hello.nes
clean:
	-rm *.o *.prg
