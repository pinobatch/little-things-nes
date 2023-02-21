#!/usr/bin/env python3
"""


"""
from __future__ import with_statement, print_function

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
        for i, testcase in enumerate(testcases):
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

def remainderlen(value, divisor):
    nBits = log2(divisor)
    cutoff = (2 << nBits) - divisor
    if value >= cutoff:
        nBits += 1
    return nBits

def gammalen(value, divisor=1):
    return 1 + 2*log2((value // divisor) + 1) + remainderlen(value % divisor, divisor)

def golomblen(value, divisor=1):
    return 1 + value // divisor + remainderlen(value % divisor, divisor)

def biterator(data):
    """Return an iterator over the bits in a sequence of 8-bit integers."""
    for byte in data:
        for bit in range(8):
            byte = (byte << 1)
            yield (byte >> 8) & 1
            byte = byte & 0xFF

class Biterator(object):
    def __init__(self, data):
        self.data = iter(data)
        self.bitsLeft = 0

    def __iter__(self):
        return self

    def read(self, count=1):
        accum = 0
        while count > 0:
            if self.bitsLeft == 0:
                self.bits = next(self.data)
                self.bitsLeft = 8
            bitsToAdd = min(self.bitsLeft, count)
            self.bits <<= bitsToAdd
            accum = (accum << bitsToAdd) | (self.bits >> 8)
            self.bits &= 0x00FF
            self.bitsLeft -= bitsToAdd
            count -= bitsToAdd
        return accum

    __next__ = read

    @classmethod
    def test(cls):
        src = Biterator([0xBA,0xDA,0x55,0x52,0xA9,0x0E])
        print("%x" % src.read(12),)
        print("%x mother shut your mouth" % src.read(12))
        print("zero is", next(src))
        print("%x is donkey" % src.read(12))
        print("one thirty five is", src.read(10))
        print("zero is", next(src))
        try:
            next(src)
        except StopIteration:
            print("stopped as expected")
        else:
            print("didn't stop.")

if __name__=='__main__':
    print("Testing BitBuilder")
    BitBuilder.test()
    print("Testing Biterator")
    Biterator.test()
