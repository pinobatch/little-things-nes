#!/usr/bin/env python3
"""
empty space compression

"""
import os, sys, argparse

def pack_autocommon(blo):
    """Packs an iterable of byte values using autocommon RLE.

Each compressed packet represents 8 source bytes.  Each bit in a
packet's first byte controls the decoding of each byte, most
significant first.  0 means copy a literal byte, and 1 means repeat
the current common value.  The common value begins at $00 and changes
to two successive identical source values.

Return an iterator over bytes objects representing output packets.
"""
    out = bytearray(1)
    packet = None
    common_value = last_value = 0
    for value in blo:
        if packet is None:
            packet, packetbits = bytearray(1), 0
        packet[0] <<= 1
        packetbits += 1
        if value == common_value:
            packet[0] |= 1
        else:
            packet.append(value)
        if packetbits >= 8:
            yield bytes(packet)
            packet = None
        if value == last_value:
            common_value = value
        last_value = value
    if packet:
        # Pad last packet with repeats
        while packetbits < 8:
            packet[0] <<= 1
            packetbits += 1
        yield packet

def parse_argv(argv):
    p = argparse.ArgumentParser()
    p.add_argument("in_nam")
    p.add_argument("out_nam")
    return p.parse_args(argv[1:])

def main(argv=None):
    args = parse_argv(argv or sys.argv)
    with open(args.in_nam, "rb") as infp:
        source_data = infp.read()
    packets = pack_autocommon(source_data)
    with open(args.out_nam, "wb") as outfp:
        outfp.writelines(packets)

if __name__=='__main__':
    if 'idlelib' in sys.modules:
        main("""
./ac8.py ../obj/nes/grid.nam ../obj/nes/grid.nam.ac8
""".split())
    else:
        main()
