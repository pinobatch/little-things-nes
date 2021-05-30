#!/usr/bin/env python3
"""
Wave to DPCM converter
Copyright 2012, 2019, 2021 Damian Yerrick

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
"""
assert str is not bytes
import sys
from contextlib import closing
from optparse import OptionParser

def load_wave_as_mono_s16(filename):
    import wave
    from array import array
    little = array('H', b'\x01\x00')[0] == 1
    with closing(wave.open(filename, "rb")) as infp:
        bytedepth = infp.getsampwidth()
        if bytedepth not in (1, 2):
            raise ValueError("unsupported sampwidth")
        n_ch = infp.getnchannels()
        datatype = 'h' if bytedepth == 2 else 'B'
        freq = infp.getframerate()
        length = infp.getnframes()
        data = array('h', infp.readframes(length))
    if datatype == 'B':
        # Expand 8 to 16 bit
        data = array('h', ((c - 128) << 8 for c in data))
    elif not little:
        # 16-bit data is little-endian in the wave file; it needs to
        # be byteswapped for big-endian platforms
        data.byteswap()
    if n_ch > 1:
        # average all channels
        data = array('h', (int(round(sum(data[i:i + n_ch]) / n_ch))
                           for i in xrange(0, len(data), n_ch)))
    return (freq, data)

def save_wave_as_mono_u8(filename, freq, data):
    import wave
    from array import array
    data = bytearray(min(255, (s + 32896) // 256) for s in data)
    with closing(wave.open(filename, "wb")) as outfp:
        outfp.setnchannels(1)
        outfp.setsampwidth(1)
        outfp.setframerate(freq)
        outfp.writeframes(data)

def parse_argv(argv):
    parser = OptionParser(version="81 0.02wip")
    parser.add_option("-i", "--infile",
                      dest="infilename")
    parser.add_option("-o", "--outfile",
                      dest="outfilename")
    parser.add_option("-d", "--decompfile",
                      dest="decompfilename",
                      help="write a wave of the decompressed output here")
    parser.add_option("-r", "--rate",
                      type="int", dest="rate",
                      help="resample to this frequency")
    parser.add_option("-a", "--volume",
                      type="float", dest="volume", default=100.0,
                      help="amplify by this percentage (default 100.0)")
    out, filenames = parser.parse_args(argv[1:])
    filenames = iter(filenames)
    try:
        infilename = out.infilename or next(filenames)
        outfilename = out.outfilename or next(filenames)
    except StopIteration:
        parser.error("not enough filenames")
    decompfilename = out.decompfilename
    rate = out.rate
    volume = out.volume / 100.0
    try:
        next(filenames)
    except StopIteration:
        pass
    else:
        parser.error("too many filenames")

    return infilename, outfilename, decompfilename, rate, volume

def upsample_data(data, infreq, outfreq, volume):
    from array import array
    out = array('h')
    i = 0
    isub = 0
    while i < len(data):
        first = data[i]
        try:
            second = data[i + 1]
        except IndexError:
            second = first
        first += (second - first) * isub // outfreq
        out.append(min(32767, max(-32767, int(round(first * volume)))))
        isub += infreq
        i += isub // outfreq
        isub = isub % outfreq
    return out

def encode_dpcm(data):
    """Encode a 16-bit signed wave to 64-level DPCM."""
    from array import array
    out = bytearray()
    level = 0
    curbyte = 0
    curbit = 1
    for s in data:
        s = min(31744, max(-32768, s))
        if level < -31744 or level < s:
            level += 1024
            curbyte |= curbit
        else:
            level -= 1024
        curbit = curbit << 1
        if curbit >= 256:
            out.append(curbyte)
            curbit = 1
            curbyte = 0
    return out

def decode_dpcm(data):
    """Decode 64-level DPCM to a 16-bit signed wave."""
    from array import array
    out = array('h')
    level = 0
    curbyte = 0
    for curbyte in data:
        for i in range(8):
            offset = 1024 if curbyte & 1 else -1024
            level = min(31744, max(-32768, offset + level))
            out.append(level)
            curbyte = curbyte >> 1
    return out

def main(argv=None):
    import sys
    argv = argv or sys.argv
    parsed = parse_argv(argv)
    infilename, outfilename, decompfilename, outfreq, volume = parsed
    infreq, data = load_wave_as_mono_s16(infilename)
    outfreq = outfreq or infreq
    resampled = upsample_data(data, infreq, outfreq, volume)
    print("freq: %d to %d; length: %d to %d"
          % (infreq, outfreq, len(data), len(resampled)))
    encoded = encode_dpcm(resampled)
    with open(outfilename, 'wb') as outfp:
        outfp.write(encoded)
    if decompfilename:
        decoded = decode_dpcm(encoded)
        save_wave_as_mono_u8(decompfilename, outfreq, decoded)

if __name__=='__main__':
    if 'idlelib' in sys.modules:
        main(['./81.py', 'DF.wav', 'out.dmc', '-r', '33488', '-d', 'decomp.wav'])
    else:
        main()
