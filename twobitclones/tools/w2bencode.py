#!/usr/bin/env python3
import os, sys, argparse, wave, array

helpText = """
Encodes a wave file in w2b format for Pino's 2bpp wave player demo.
""".strip()
helpTextEnd = """
The wave should be 12429 Hz, mono, heavily level compressed, and
linear PCM.  The output (w2b) is 2bpp unsigned big endian.
""".strip()
PREVIEW_NAME = "w2bpreview.wav"
DEFAULT_RATE = 12429

def parse_argv(argv):
    p = argparse.ArgumentParser(description=helpText, epilog=helpTextEnd)
    p.add_argument("input",
                   help="input file (wave if encoding, w2b if decoding)")
    p.add_argument("output",
                   help="output file (w2b if encoding, wave if decoding)")
    p.add_argument("--bias", type=int,
                   help="apply a centering bias (0 to 32)")
    p.add_argument("--scale", type=float, default=1.0,
                   help="when encoding, increase input volume by a factor "
                        "(default: 1.0)")
    p.add_argument("--gain", type=float, default=0.0,
                   help="when encoding, increase input volume by decibels "
                        "(default: 0.0)")
    p.add_argument("--preview", action="store_true",
                   help="when encoding, also decode 2-bit data to %s"
                        % PREVIEW_NAME)
    p.add_argument("-d", "--decode", action="store_true",
                   help="decode 2-bit data instead of encoding")
    p.add_argument("-r", "--rate", type=int, default=DEFAULT_RATE,
                   help="when decoding, write sample rate in Hz"
                        "(default %d)"
                        % DEFAULT_RATE)
    p.add_argument("-v", "--verbose", action="store_true",
                   help="print exception stack traces")
    return p.parse_args(argv[1:])

def encode_main(infile, outfile, bias=0, gain=1.0, write_preview=False):
    with wave.open(infile, "rb") as infp:
        params = infp.getparams()
        if params.nchannels != 1:
            raise ValueError("%s: expected 1 channel (mono); got %d"
                             % (infile, params.nchannels))
        if params.sampwidth not in (1, 2):
            raise ValueError("%s: expected 8- or 16-bit samples; got %d"
                             % (infile, params.sampwidth * 8))

        if params.comptype != 'NONE':
            raise ValueError("%s: expected linear PCM; got %s (%s)"
                             % (infile, params.compname, params.comptype))
        samples = infp.readframes(params.nframes)

    if params.sampwidth == 2:
        # Convert 16-bit signed little-endian input to 8-bit unsigned
        samples = array.array("h", samples)
        little = array.array("h", [1])[0]
        if not little: samples.byteswap()
        samples = bytes(min(255, (x + 0x8080) // 256) for x in samples)

    out = bytearray()
    previewdata = bytearray()
    out_bits, error = 1, 0
    for sample in samples:
        sample = int(round(gain * (sample - 128) + 128 + error))
        quant = min(3, max(0, (sample - bias) // 64))
        rescaled = quant * 64 + bias
        previewdata.append(rescaled)
        error = sample - rescaled
        out_bits = (out_bits << 2) | quant
        if out_bits >= 0x100:
            out.append(out_bits & 0xFF)
            out_bits = 1

    with open(outfile, "wb") as outfp:
        outfp.write(out)
    if write_preview:
        with wave.open(PREVIEW_NAME, "wb") as outfp:
            outfp.setnchannels(1)
            outfp.setsampwidth(1)
            outfp.setframerate(params.framerate)
            outfp.writeframes(previewdata)

def decode_main(infile, outfile, bias=0, rate=DEFAULT_RATE):
    with open(infile, "rb") as infp:
        data = infp.read()
    previewdata = bytearray()
    shifts = 6, 4, 2, 0
    for quad in data:
        for shift in shifts:
            quant = (quad >> shift) & 0x03
            rescaled = quant * 64 + bias
            previewdata.append(rescaled)
    with wave.open(outfile, "wb") as outfp:
        outfp.setnchannels(1)
        outfp.setsampwidth(1)
        outfp.setframerate(rate)
        outfp.writeframes(preview)

def main(argv=None):
    args = parse_argv(argv or sys.argv)
    prog = os.path.basename(sys.argv[0])
    try:
        if not args.decode:
            gain = 10 ** (args.gain / 20) * args.scale
            encode_main(args.input, args.output,
                        bias=args.bias, gain=gain,
                        write_preview=args.preview)
        else:
            decode_main(args.input, args.output, rate=args.rate)
    except Exception as e:
        if args.verbose:
            from traceback import print_exc
            print_exc()
        else:
            print("%s: %s" % (prog, e), file=sys.stderr)
        exit(1)

if __name__=='__main__':
    if 'idlelib' in sys.modules:
        main("""
./w2bencode.py -v --preview --gain 6 ../audio/selnow.wav ../obj/nes/selnow.w2b
""".split())
    else:
        main()
