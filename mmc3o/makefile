title:=mmc3o
specialized:=$(title)_1M_CR32
version:=0.01
objlist:=mmc3 init pads main
EMU:=Mesen

# Allow building either in or out of little things
# test by holms <https://stackoverflow.com/a/20566812/2738262>
COMMON_PILBMP2NES:=../common/tools/pilbmp2nes.py
LOCAL_PILBMP2NES:=tools/pilbmp2nes.py
ifneq ("$(wildcard $(COMMON_PILBMP2NES))","")
  PILBMP2NES:=$(COMMON_PILBMP2NES)
else
  PILBMP2NES:=$(LOCAL_PILBMP2NES)
endif
ifeq ($(OS),Windows_NT)
  PY:=py -3
else
  PY:=python3
endif

.PHONY: run default clean dist
default: $(title).nes

# And when building the zipfile, include the test
$(LOCAL_PILBMP2NES): $(COMMON_PILBMP2NES)
	cp $< $@

obj/nes/%.chr: tilesets/*.png
	mkdir -p $(dir $@)
	$(PY) $(PILBMP2NES) -p "0;1" $< $@

obj/nes/%.o: src/%.s 
	mkdir -p $(dir $@)
	ca65 -g -o $@ $<

obj/nes/main.o: obj/nes/font8x5.chr

$(title).nes: tgrom128.cfg $(foreach o,$(objlist),obj/nes/$(o).o)
	ld65 -o $(title).nes -m map.txt --dbgfile $(title).dbg -C $^

$(specialized).nes: tools/makerom.py $(title).nes
	$(PY) $^ $@ -P1024 -RC32

run: $(title)_1M_CR32.nes
	$(EMU) $<

clean:
	$(RM) map.txt $(title).dbg obj/nes/*.o obj/nes/*.chr

dist: $(title)-$(version).zip

zip.in: makefile README.md $(specialized).nes $(LOCAL_PILBMP2NES)
	git ls-files > $@
	echo zip.in >> $@
	echo $(title).nes >> $@
	echo $(title)_1M_CR32.nes >> $@
	echo $(LOCAL_PILBMP2NES) >> $@

$(title)-$(version).zip: zip.in makefile
	zip -9u $@ -@ < $<
