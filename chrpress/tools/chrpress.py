#!/usr/bin/env python3
"""

This codec incorporates the following techniques:

* Run-length encoding of identical pixels
http://en.wikipedia.org/wiki/Run-length_encoding
* Gamma coding of run lengths
http://en.wikipedia.org/wiki/Elias_gamma_coding
* Move-to-front transform used to save space when one pixel value is
returned to more often
http://en.wikipedia.org/wiki/Move-to-front_transform

The "Codemasters Markov" codec maintained by tokumaru uses similar
techniques, except it uses a separate table of next colors for each
current color and unary coding for run lengths.

denied: 4488 bits
gamegfx: 20080 bits
smb1bg: 13992 bits
titlegfx: 12112 bits

"""
assert str is not bytes
from PIL import Image
import sys

tilesPerBlock = 4
printRatioPerTile = False

def log2(i):
    return int(i).bit_length() - 1

class BitBuilder(object):

    def __init__(self):
        self.data = bytearray()
        self.nbits = 0  # number of bits left in the last byte

    def append(self, value, length=1):
        """Append a bit string."""
        assert(value < 1 << length)
        while length > 0:
            if self.nbits == 0:
                self.nbits = 8
                self.data.append(0)
            lToAdd = min(length, self.nbits)
            bitsToAdd = (value >> (length - lToAdd))
            length -= lToAdd
            self.nbits -= lToAdd
            bitsToAdd = (bitsToAdd << self.nbits) & 0xFF
            self.data[-1] = self.data[-1] | bitsToAdd

    def appendRemainder(self, value, divisor):
        """Append a number from 0 to divisor - 1.

This writes small numbers with floor(log2(divisor)) bits and large
numbers with ceil(log2(divisor)) bits.

"""
        nBits = log2(divisor)
        # 2 to the power of (1 + nBits)
        cutoff = (2 << nBits) - divisor
        if value >= cutoff:
            nBits += 1
            value += cutoff
        self.append(value, nBits)

    def appendGamma(self, value, divisor=1):
        """Add a nonnegative integer in the exp-Golomb code.

Universal codes are a class of prefix codes over the integers that
are optimal for variables with a power-law distribution.  Peter Elias
developed the "gamma code" in 1975, and it has become commonly used
in data compression.  First write one fewer 0 bits than there are
binary digits in the number, then write the number.  For example:

1 -> 1
2 -> 010
3 -> 011
4 -> 00100
...
21 -> 000010101

This function modifies the gamma code slightly by encoding value + 1
so that zero has a code.

The exp-Golomb code is a generalization of Peter Elias' gamma code to
support flatter power law distributions.  The code for n with divisor
M is the gamma code for (n // M) + 1 followed by the remainder code
for n % M.  To write plain gamma codes, use M = 1.

"""
        if divisor > 1:
            remainder = value % divisor
            value = value // divisor
        value += 1
        length = log2(value)
        self.append(0, length)
        self.append(value, length + 1)
        if divisor > 1:
            self.appendRemainder(remainder, divisor)

    def appendGolomb(self, value, divisor=1):
        """Add a nonnegative integer in the Golomb code.

The Golomb code is intended for a geometric distribution, such as
run-length encoding a Bernoulli random variable.  It has a parameter
M related to the variable's expected value.  The Golomb code for n
with divisor M is the unary code for n // M followed by the remainder
code for n % M.

Rice codes are Golomb codes where the divisor is a power of 2, and
the unary code is the Golomb code with a divisor of 1.

"""
        if divisor > 1:
            remainder = value % divisor
            value = value // divisor
        self.append(1, value + 1)
        if divisor > 1:
            self.appendRemainder(remainder, divisor)

    def __bytes__(self):
        return bytes(self.data)

    def __len__(self):
        return len(self.data) * 8 - self.nbits

    @classmethod
    def test(cls):
        testcases = [
            (cls.append, 0, 0, b''),
            (cls.append, 123456789, 0, None),
            (cls.append, 1, 1, b'\x80'),
            (cls.append, 1, 2, b'\xA0'),
            (cls.append, 3, 4, b'\xA6'),
            (cls.append, 513, 10, b'\xA7\x00\x80'),  # with 7 bits left
            (cls.appendRemainder, 5, 10, b'\xA7\x00\xD0'),
            (cls.appendRemainder, 6, 10, b'\xA7\x00\xDC'),  # with 0 bits left
            
            (cls.appendGolomb, 14, 9, b'\xA7\x00\xDC\x68'),
        ]
        bits = BitBuilder()
        if bytes(bits) != b'':
            print("fail create")
        for (i, testcase) in zip(range(len(testcases)), testcases):
            (appendFunc, value, length, result) = testcase
            try:
                appendFunc(bits, value, length)
                should = bytes(bits)
            except AssertionError:
                should = None
            if should != result:
                print("BitBuilder.test: line", i, "failed.")
                print(''.join("%02x" % x for x in bits.data))
                return False
        return True

def getRunLengths(pxdata):
    runLengths = []
    thisRunLength = 1
    lastPixel = pxdata[0]
    for pixel in pxdata[1:]:
        if pixel != lastPixel:
            runLengths.append((thisRunLength, lastPixel))
            lastPixel = pixel
            thisRunLength = 1
        else:
            thisRunLength += 1

    runLengths.append((thisRunLength, lastPixel))
    assert(sum(row[0] for row in runLengths) == len(pxdata))
    return runLengths

def getMode(values, weightFunc=None):
    """Find the value that occurs the most times.

Ties are broken in favor of the lowest value.

Optional weightFunc is a function from (value, count) to a weight,
and the function will look for the value with the highest weight.

"""
    # Collect histogram
    histo = {}
    for r in values:
        histo[r] = histo.get(r, 0) + 1
    histo = list(histo.items())

    # Add weights
    if weightFunc is not None:
        histo = [(r, weightFunc(r, count))
                 for (r, count) in histo]

    # Find the with the highest weight
    histo.sort()  # prefer lower most common lengths
    (modeValue, modeCount) = histo[0]
    for (r, count) in histo[1:]:
        if count > modeCount:
            modeCount = count
            modeValue = r
    return (modeValue, modeCount)

encode1BitTilePalettes = {
    (0, 1): 2,
    (0, 2): 3,
    (0, 3): 4,
    (1, 2): 5,
    (1, 3): 6,
    (2, 3): 7
}
def encode1BitTile(bits, pxdata, seenColors):
    """Encode a string of pixel data with 1bpp format.

3 bits: the palette (see encode1BitTilePalettes)
Gamma: the most common run length (1 represents this and this represents 1)
1 bit: The first color value
Gamma: run lengths until their sum equals the length of pixel data

"""

    # convert pixels to bits
    assert(len(seenColors) == 2)

    startLen = len(bits)
    seenColorsSorted = tuple(sorted(seenColors))
    palette = encode1BitTilePalettes[seenColorsSorted]
    indices = [None for i in range(4)]
    for i in range(2):
        indices[seenColorsSorted[i]] = i
    pxdata = bytearray(indices[x] for x in pxdata)
    bits.append(palette, 3)

    # convert bits to run lengths
    runLengths = getRunLengths(pxdata)

    # The mode (most common run length) will be encoded with a
    # shorter code.  Encoding the mode with 1 bit can't be any
    # worse than unary (not RLEing at all).
    rlsOnly = [r for (r, pixel) in runLengths]
    countOnes = len([r for r in rlsOnly if r == 1])

    # The weight is the number of bits saved by swapping this with 1.
    # = (length of this code - length of code for 1)
    #   * (occurrences of this - occurrences of code for 1)
    weightFunc = (lambda r, count:
                  log2(r) * (count - countOnes))
    (modeRL, modeRLC) = getMode(rlsOnly, weightFunc)
    if modeRL is None:
        modeRL = 1
    bits.appendGamma(modeRL - 1)
    (oldModeRL, oldModeRLC) = getMode(rlsOnly)
    if oldModeRL != modeRL:
        print("Run length mode mismatch!",
              modeRL, modeRLC, oldModeRL, oldModeRLC)

    # Now encode, swapping lengths 1 and modeRL
    bits.append(pxdata[0], 1)
    for (r, pixel) in runLengths:
        if r == modeRL:
            r = 1
        elif r == 1:
            r = modeRL
        bits.appendGamma(r - 1)
    writtenBits = len(bits) - startLen
    if len(pxdata) <= writtenBits:
        print("This 1-bit tile doesn't save!")
        pxdatas = ''.join('%' if x else '.' for x in pxdata)
        pxdatas = [pxdatas[i:i + len(pxdata) // 8]
                   for i in range(0, len(pxdata), len(pxdata) // 8)]
        print("\n".join(pxdatas))
        print("Run lengths: mode is", modeRL, "with savings", modeRLC, "out of", len(runLengths))
        print(' '.join(str(r[0]) for r in sorted(runLengths)))
    if printRatioPerTile:
        print('1-bit tile: %d/%d (saved %d%%; 1=%d saves %d bits)'
              % (writtenBits, len(pxdata),
                 (len(pxdata) - writtenBits) * 100 // len(pxdata),
                 modeRL, modeRLC * 2))

def encode2BitTile(bits, pxdata):
    """Encode a string of pixel data with 1bpp format.

2 bits: 00 (so it isn't seen as 1-bit)
Remainder3: Xor value
Gamma: Common run length
2 bits: The first color value
Gamma: The first run length

Then write out MTF values and run lengths until the sum of run lengths
reaches the length of pixel data.

For 2-bit tiles, we don't swap the codes for run length 1 and the
code for the most common run length because it's usually 1 anyway
for a 2-bit tile.

"""
    runLengths = getRunLengths(pxdata)
    # print "pixels:", ''.join(str(row[1]) for row in runLengths)

    rlsOnly = [r for (r, pixel) in runLengths]
    countOnes = len([r for r in rlsOnly if r == 1])
    weightFunc = (lambda r, count:
                  log2(r) * (count - countOnes))
    (modeRL, modeRLC) = getMode(rlsOnly, weightFunc)

    # write header: 00, then first pixel, then first run length
    startLen = len(bits)
    
    xorFiltered = [(runLengths[i + 1][0],
                    runLengths[i + 1][1] ^ runLengths[i][1])
                   for i in range(len(runLengths) - 1)]
    (modeXor, modeXorC) = getMode(row[1] for row in xorFiltered)

    bits.append(0, 2)
    bits.appendRemainder(modeXor - 1, 3)
    bits.appendGamma(modeRL - 1)
    (r, pixel) = runLengths[0]
    if r == modeRL:
        r = 1
    elif r == 1:
        r = modeRL
    bits.append(pixel, 2)
    bits.appendGamma(r - 1)
        
    for (r, xorValue) in xorFiltered:
        if xorValue == modeXor:
            xorValue = 1
        elif xorValue == 1:
            xorValue = modeXor
        bits.appendRemainder(xorValue - 1, 3)

        if r == modeRL:
            r = 1
        elif r == 1:
            r = modeRL
        bits.appendGamma(r - 1)
        
    writtenBits = len(bits) - startLen
    if len(pxdata) * 2 <= writtenBits:
        print("This 2-bit tile doesn't save!")
        pxdatas = ''.join(str(x) if x else '.' for x in pxdata)
        pxdatas = [pxdatas[i:i + len(pxdata) // 8]
                   for i in range(0, len(pxdata), len(pxdata) // 8)]
        print("\n".join(pxdatas))
        #print("Run lengths: mode is", modeRL, "with savings", modeRLC, "out of", len(runLengths))
        #print(' '.join(repr(r[0]) for r in sorted(runLengths)))
    if printRatioPerTile:
        print('2-bit tile: %d/%d (saved %d%%; 1=%d saves %d bits)'
              % (writtenBits, len(pxdata) * 2,
                 (len(pxdata) * 2 - writtenBits) * 100 // (len(pxdata) * 2),
                 modeRL, modeRLC * 2))

def encodeTile(bits, pixels, xtile, ytile):
    pxdata = bytearray()
    for y in range(ytile, ytile + 8):
        for x in range(xtile, xtile + 8 * tilesPerBlock):
            pxdata.append(pixels[x, y])
    seenColors = set(iter(pxdata))
    return (encode2BitTile(bits, pxdata)
            if len(seenColors) > 2
            else encode1BitTile(bits, pxdata, seenColors))
            
def doFile(filename):
    im = Image.open(filename)
    print(filename, "is", im.size[1] * im.size[0] * 2, "bits uncompressed")
    pixels = im.load()

    runLengths = [0] * 256
    mtfTotal = 0
    bits = BitBuilder()
    srcBits = 0
    for ytile in range(0, im.size[1], 8):
        for xtile in range(0, im.size[0], 8 * tilesPerBlock):
            tiledata = encodeTile(bits, pixels, xtile, ytile)
            srcBits += 128 * tilesPerBlock
    saved = 100 * (srcBits - len(bits)) // srcBits
    print("compressed %d bits to %d saving %d%%"
          % (srcBits, len(bits), saved))
    return bytes(bits)

def main(argv=None):
    argv = argv or sys.argv
    if len(argv) != 3:
        print("usage: chrpress INFILE.png OUTFILE.2bt", file=sys.stderr)
        return
    data = doFile(argv[1])
    with open(argv[2], 'wb') as outfp:
        outfp.write(data)

if __name__ == '__main__':
    main()
