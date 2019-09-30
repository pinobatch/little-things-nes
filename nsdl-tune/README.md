# NSD.Lib tuner

NSD.Lib, an NES audio player library by S.W., hardcodes its five
pitch lookup tables for A = 442 Hz.  Some users may prefer A = 440 Hz
(concert pitch) or other tunings.  In addition, thresholds for the
most significant byte of some tables are hardcoded elsewhere in the
library's code.  This Python program takes an A frequency, generates
a replacement for each of these tables, and outputs instructions on
how to patch the hardcoded high bytes.

Copyright 2017 Damian Yerrick  
License: zlib
