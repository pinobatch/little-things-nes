zipfilename := "little-things-nes.zip"
binaries := \
  tellinglys/tellinglys.nes \
  parallax/parallax.nes \
  convergence/convergence.nes \
  dacnonlinear/dacnonlinear.nes \
  test78/test78-submapper3.nes

# dacnonlinear and test78 have additional binaries to include,
# but I have yet to figure out how to serialize their multiple makes.
# Maybe by appending all to $(sort) results?

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
