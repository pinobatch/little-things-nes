#!/usr/bin/env python3
"""
Sinusoid generator compensating for DAC nonlinearity

Copyright 2017 Damian Yerrick

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
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
from math import cos, pi
import bisect

tablesize = 256
angfreq = pi * 2 / tablesize
per_row = 16

def spit_table(values):
    for i in range(0, tablesize, per_row):
        print(".byte "+",".join(str(x) for x in values[i:i + per_row]))

def log2(i):
    if i < 1: return -1
    out = 0
    while i > 0x10:
        i >>= 4
        out += 4
    while i > 1:
        i >>= 1
        out += 1
    return out

# Calculate the effective output levels for each sum of the triangle,
# noise, and DMC DAC, using the "Lookup Table" method described here
# https://wiki.nesdev.com/w/index.php/APU_Mixer
tnd_table = [163.67 / (24329.0 / n + 100.0) if n else 0 for n in range(203)]
tnd_thresholds = [(a + b) / 2.0 for a, b in zip(tnd_table, tnd_table[1:])]

# Generate a sinusoid period scaled to the DMC's usable levels
lowidx = int(7.5 * 3 + 0 * 2)
highidx = lowidx + 127
tnd_negrail = tnd_table[lowidx]
tnd_raildist = tnd_table[highidx] - tnd_negrail
sintable = [
    (1.0 - cos(x * angfreq)) / 2.0 * tnd_raildist + tnd_negrail
    for x in range(tablesize)
]

# Round each value to the closest member
sinidxtable = [
    bisect.bisect(tnd_thresholds, level) - lowidx
    for level in sintable
]
    
print(""".export sine4011, ctzindex
.rodata
.align 256
sine4011:""")
spit_table(sinidxtable)
print("ctzindex:")
spit_table([
    max(0, log2(x & (-x)))
    for x in range(tablesize)
])
