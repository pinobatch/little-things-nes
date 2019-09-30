zipfilename := "little-things-nes.zip"
binaries := \
  a53bigchrram/a53bigchrram.nes \
  bntest/bntest.nes \
  convergence/convergence.nes \
  dacnonlinear/dacnonlinear.nes \
  dacnonlinear/dacnonlinear.nsf \
  dpcm-split/dpcmletterbox.nes \
  eighty/eighty.nes \
  eq/eq.nes \
  mmc3bigchrram/mmc3bigchrram.nes \
  parallax/parallax.nes \
  password-save/pwtest.nes \
  spectralencode/spectral.nes \
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
  vwfterm/vwfterm.nes

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

