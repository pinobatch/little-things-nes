zipfilename := "little-things-nes.zip"
binaries := \
  convergence/convergence.nes \
  dacnonlinear/dacnonlinear.nes \
  mmc3bigchrram/mmc3bigchrram.nes \
  parallax/parallax.nes \
  spectralencode/spectral.nes \
  tellinglys/tellinglys.nes \
  test78/test78-submapper3.nes \
  vaus-test/vaus-test.nes \
  vwfterm/vwfterm.nes

# dacnonlinear, spectral, and test78 have additional binaries to
# include, but I have yet to figure out how to serialize their
# multiple make targets.  Maybe by appending all to $(sort) results?

# TODO: separate repos for coveryourown, fizzbuzz, and striker

.PHONY: all clean dist zip zip.in $(binaries)

all: $(binaries)

$(binaries):
	$(MAKE) -C $(dir $@) $(notdir $@)

clean:
	for d in $(foreach o,$(binaries),$(dir $(o))); do \
	  $(MAKE) -C $$d clean; \
	done

dist: $(zipfilename)

$(zipfilename): $(binaries) zip.in
	zip -9u $@ -@ < zip.in

zip.in:
	git ls-files | grep -e "^[^\.]" > zip.in
	echo zip.in >> zip.in
	for d in $(binaries); do echo $$d >> zip.in; done
