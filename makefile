version := 20.10
binzipfilename := little-things-nes-$(version).zip
srczipfilename := little-things-nes-src-$(version).zip
binaries := \
  768/768.nes \
  a53bigchrram/a53bigchrram.nes \
  beakers/beakers.nes \
  bntest/bntest-aorom.nes \
  bntest/bntest-h.nes \
  bntest/bntest-v.nes \
  boing2k7/boing2k7.nes \
  bunny250/zapperlag.nes \
  bunny250/a-white.nes \
  chrpress/chrpress.nes \
  convergence/convergence.nes \
  croom-try2/emblem.nes \
  dacnonlinear/dacnonlinear.nes \
  dacnonlinear/dacnonlinear.nsf \
  dpcm-split/dpcmletterbox.nes \
  eighty/eighty.nes \
  eq/eq.nes \
  fded/cout02.nes \
  fme7acktest/fme7acktest.nes \
  fme7ramtest/fme7ramtest.nes \
  gridfloor/gridfloor.nes \
  hello-world-ca65/hello.nes \
  iretiny/iretiny.nes \
  iretiny/iretiny218.nes \
  mathlib/mathlib.prg \
  meece/meece.nes \
  meta32/meta32.nes \
  mmc1a/mmc1atest.nes \
  mmc1a/mmc1atest-sn.nes \
  mmc3bigchrram/mmc3bigchrram.nes \
  mmc3save/mmc3save.nes \
  mmc3spaminc/mmc3spaminc.nes \
  oam-reset/oam_reset.nes \
  palphase/palphase.nes \
  parallax/parallax.nes \
  password-save/pwtest.nes \
  porttest/porttest.nes \
  powerpadgesture/powerpadgesture.nes \
  pretendo/pretendo.nes \
  rgb121/rgb121.nes \
  roulette/roulette.nes \
  scaling/scaling.nes \
  sound-drivers/p8mus/pl.nes \
  sound-drivers/5/5.nes \
  sound-drivers/balance/balance.nes \
  spectralencode/spectral.nes \
  sprite-cans/spritecans.nes \
  tall-pixel/tall_pixel.nes \
  tellinglys/tellinglys.nes \
  test28/test28.nes \
  test28/test28-8Mbit.nes \
  test78/test78-0h.nes \
  test78/test78-0v.nes \
  test78/test78-78ines.nes \
  test78/test78-submapper0.nes \
  test78/test78-submapper1.nes \
  test78/test78-submapper2.nes \
  test78/test78-submapper3.nes \
  twobitclones/twobit.nes \
  vaus-test/vaus-test.nes \
  volumes/volumes.nes \
  vwfterm/vwfterm.nes \
  x816-things/bench.nes \
  x816-things/bingo.nes \
  x816-things/insane.nes \
  x816-things/nibbles.nes \
  x816-things/s0.nes \
  x816-things/sndtest.nes

# See MISSING.md for other things that could be added

# All elements of binaries must be produced by a makefile in the
# same directory that supports the `all` phony target.
alls := $(sort $(foreach o,$(binaries),$(dir $(o))all))

.PHONY: all clean dist $(alls)

all: $(alls)

$(alls):
	$(MAKE) -C $(dir $@) $(notdir $@)

clean:
	for d in $(foreach o,$(alls),$(dir $(o))); do \
	  $(MAKE) -C $$d clean; \
	done
	-rm bin-files.in src-files.in

dist: $(binzipfilename) $(srczipfilename)

$(binzipfilename): bin-files.in $(alls)
	zip -9u $@ -@ < $<
	-advzip -z3 $@

$(srczipfilename): src-files.in $(alls)
	zip -9u $@ -@ < $<
	-advzip -z3 $@

bin-files.in: makefile
	git ls-files | grep -e "README.md" > $@
	echo $@ >> $@
	for d in $(binaries); do echo $$d >> $@; done

src-files.in: makefile
	git ls-files | grep -e "^[^\.]" > $@
	echo $@ >> $@
