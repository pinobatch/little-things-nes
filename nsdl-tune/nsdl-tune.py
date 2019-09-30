#!/usr/bin/env python3
"""
nsdl-tune.py
Frequency table generator for NSD.Lib, an NES audio player library
by S.W.

Copyright 2017 Damian Yerrick

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

from math import ceil

# NSD.Lib comes hardcoded with pitch lookup tables set to A=442 Hz.
# Some users may prefer A=440 (concert pitch) or other tunings.
Afreq = 442.0

M2 = 39375000.0/22
C0freq = Afreq/pow(2, 3.75)

# Name of table, description, .if defined(...),
# timebase, low byte only, units per octave
tables = [
    ('Freq', '2A03, MMC5, VRC6 pulse, and 5B', None,
     M2/16, False, 96),
    ('Freq_FDS', 'Famicom Disk System', 'FDS',
     M2/(1<<27), False, 96),
    ('Freq_SAW', 'VRC6 sawtooth', 'VRC6',
     M2/14, False, 96),
    ('Freq_VRC7', 'VRC7', 'VRC7|OPLL',
     M2/(36<<18), True, 96),
    ('Freq_N163', 'Namco 163', 'N163',
     M2/(15<<29), False, 192)
]

notenames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']

print(""";------------
; nsdl-tune.inc
; Frequency tables for NSD.Lib, an NES audio player library by S.W.
; Generated using nsdtune.py by Damian Yerrick
;
; A few changes to nsd_snd.s are required for any non-A442 tuning
; because NSD.Lib hardcodes the most significant byte breakpoints
; for a few chips.
;
; In .proc _nsd_vrc7_frequency
; Replace cmp #$6C with cmp #2*(Freq_VRC7_BP1 - Freq_VRC7)
;
; In .proc _nsd_OPLL_frequency and its percussion counterparts
; Replace cmp #$6D with cmp #2*(Freq_VRC7_BP1 - Freq_VRC7)
;
; In .proc N163_frequency
; Replace cmp #$50 with cmp #(Freq_N163_BP1 - Freq_N163)/2
; Replace cmp #$9F with cmp #(Freq_N163_BP2 - Freq_N163)/2
; Replace sub #$50 with sub #(Freq_N163_BP1 - Freq_N163)/2
; Replace Freq_N163_50 with Freq_N163_BP1
""")
for row in tables:
    (label, comment, if_defined,
     timebase, byte_sized, units_per_octave) = row
    line2 = "Frequency table for " + comment
    print(";-" + "-" * len(line2))
    print("; " + line2)
    if if_defined:
        if_defined = " || ".join(
            ".defined(%s)" % s for s in if_defined.split("|")
        )
        print(".if" + if_defined)
    print("%s:" % label)

    msb_breakpoints = 0
    lines = []
    pr = lines.append
    for i in range(units_per_octave):
        notenamenum = i * 12
        notecomment = ''
        if notenamenum % units_per_octave == 0:
            notecomment = "  ; %s" % notenames[notenamenum // units_per_octave]

        freq = C0freq * pow(2, i / units_per_octave)
        value = freq / timebase if timebase < 1 else timebase / freq
        value = int(ceil(value)) & (0xFF if byte_sized else 0xFFFF)

        # Write labels for most significant byte breakpoints in
        # that need them (VRC7 and N163)
        if i > 0 and timebase < 1 and value < lastvalue:
            msb_breakpoints += 1
            pr("%s_BP%d:  ; $%X" % (label, msb_breakpoints, i))
        lastvalue = value

        if byte_sized:
            tvalue = "  .byte $%02X" % (value & 0xFF)
        else:
            tvalue = "  .word $%04X" % value
        pr(tvalue + notecomment)
    print("\n".join(lines))
    
    if if_defined:
        print(".endif")

