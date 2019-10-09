zipfilename := "little-things-nes.zip"
binaries := \
  768/768.nes \
  a53bigchrram/a53bigchrram.nes \
  beakers/beakers.nes \
  bntest/bntest.nes \
  boing2k7/boing2k7.nes \
  bunny250/zapperlag.nes \
  bunny250/a-white.nes \
  convergence/convergence.nes \
  croom-try2/emblem.nes \
  dacnonlinear/dacnonlinear.nes \
  dacnonlinear/dacnonlinear.nsf \
  dpcm-split/dpcmletterbox.nes \
  eighty/eighty.nes \
  eq/eq.nes \
  fme7acktest/fme7acktest.nes \
  fme7ramtest/fme7ramtest.nes \
  hello-world-ca65/hello.nes \
  iretiny/iretiny.nes \
  iretiny/iretiny218.nes \
  mathlib/mathlib.prg \
  meece/meece.nes \
  meta32/meta32.nes \
  mmc3bigchrram/mmc3bigchrram.nes \
  mmc3save/mmc3save.nes \
  oam-reset/oam_reset.nes \
  palphase/palphase.nes \
  parallax/parallax.nes \
  password-save/pwtest.nes \
  porttest/porttest.nes \
  pretendo/pretendo.nes \
  rgb121/rgb121.nes \
  roulette/roulette.nes \
  scaling/scaling.nes \
  sound-drivers/p8mus/pl.nes \
  sound-drivers/5/5.nes \
  sound-drivers/balance/balance.nes \
  spectralencode/spectral.nes \
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
  vaus-test/vaus-test.nes \
  volumes/volumes.nes \
  vwfterm/vwfterm.nes \
  x816-things/bingo.nes \
  x816-things/insane.nes \
  x816-things/nibbles.nes \
  x816-things/s0.nes \
  x816-things/sndtest.nes

# All recursive makefiles must support the `all` phony target
alls := $(sort $(foreach o,$(binaries),$(dir $(o))all))

# TODO: separate repos for coveryourown, fizzbuzz, and striker

.PHONY: all clean dist zip zip.in $(alls)

all: $(alls)

$(alls):
	$(MAKE) -C $(dir $@) $(notdir $@)

clean:
	for d in $(foreach o,$(alls),$(dir $(o))); do \
	  $(MAKE) -C $$d clean; \
	done

dist: $(zipfilename)

$(zipfilename): $(alls) zip.in
	zip -9u $@ -@ < zip.in

zip.in:
	git ls-files | grep -e "^[^\.]" > zip.in
	echo zip.in >> zip.in
	for d in $(binaries); do echo $$d >> zip.in; done

