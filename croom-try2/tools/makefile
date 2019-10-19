CC := gcc
CFLAGS := -Wall -O -std=gnu99
LIBALLEG := -lalleg
LD := gcc
LDFLAGS := -Wall -s

.PHONY: run clean

run: sprcels.exe
	start $<

clean:
	-rm *.o

sprcels.exe: sprcels.o
	$(LD) $(LDFLAGS) $^ $(LIBALLEG) -o $@

packbits.exe: packbits.o
	$(LD) $(LDFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
