# NES Compatibility Benchmarks

In September 2001, gaining access to NES development hardware was
difficult. So may NES software developers wrote and tested their
software exclusively on emulators that run on popular personal
computers.  However, emulators popular at the time (notably Bloodlust
Software's NESticle) showed significant differences in behavior from
that of the NES hardware that negatively impact stability and
compatibility. This software provides test cases for NES emulator
developers to use to test and improve their code.

## Included tests

- NESticle detection: a $2002 read should clear D7 for the
  following read.
- Test for ability to punch the background through a sprite by
  drawing a "behind" priority sprite in front of a "front" one.
  _Super Mario Bros. 3_ uses this for items sprouting from blocks,
  and in 2014, I would go on to use this effect to draw units
  behind furniture in _RHDE: Furniture Fight_.
- Digital sample playback methods test, using code and audio
  samples from one of Damian Yerrick's previous test cases.
  The pulse width modulation differs from raw-pcm-hello.
- Test support for two-, four-, or eight-controller configurations
  using Famicom-style parallel or NES-style serial controller data
  multiplexing.
- "Blinking toaster" animation for end.

## Future tests

I never got a chance to do these, as the allure of Game Boy Advance
homebrew sucked me in:

- Add sprite 0 hit detection (should trigger only if an opaque
  sprite pixel overlaps an opaque bg pixel).
- Add test for proper behavior of the color emphasis and grayscale
  features of the PPU Mask register ($2001).
- Add basic tests of the more useful among 2A03's unofficial opcodes.
- Make sure 2A03's decimal mode is disabled properly (all `adc` and
  `sbc` instructions operate in binary whether or not D flag is
  set, but D flag isn't frozen to one position).
- Test that writes to the PPU VRAM Data register update the
  scrolling position. (NESticle fails this test, and software such
  as Mouser that relies on failing this test fails on a real NES.)
- Test that PPU VRAM Data register ($2007) reads are properly
  delayed by one read, on which _Super Mario Bros._ relies.
- Test that joypad reads from all addressing modes emulate 2A03
  data bus capacitance correctly.
- Document the behavior on real hardware:  Famicom, original NES,
  new NES, Doctor PC Jr., Dendy, other famiclones, etc.
- Document the behavior on the latest versions of popular NES
  emulators available from Zophar's Domain.
- Additional tests pertaining to each class of NES cart boards.
- Other tests you may implement, release under a free software
  license and submit to the NESdev community.
- Other tests you may suggest by writing me at
  pino@pineight.com
                  
## Legal

Copyright 2001 Damian Yerrick  
Relicensed 2019 under zlib license
