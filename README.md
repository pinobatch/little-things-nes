# little things
One-off tech demos and test ROMs for NES

This repository will contain several tech demos for Nintendo
Entertainment System that I've produced over more than a decade
prior to 2019.

- [Action 53 (mapper 28) big CHR RAM](https://forums.nesdev.com/viewtopic.php?p=190851#p190851)
- [Action 53 (mapper 28) comprehensive test](https://forums.nesdev.com/viewtopic.php?p=102693#p102693)
- [BNROM and AOROM size and mirroring test](https://forums.nesdev.com/viewtopic.php?p=79826#p79826)
- [Boing 2007](https://forums.nesdev.com/viewtopic.php?p=62806#p62806):
  squashing the background using mistimed VRAM reads
- [ca65 macros reimplementing 6502 mnemonics](https://forums.nesdev.com/viewtopic.php?f=2&t=10701)
- [Convergence](https://forums.nesdev.com/viewtopic.php?p=215229#p215229)
- [DAC nonlinear volume](https://forums.nesdev.com/viewtopic.php?f=6&t=16726)
- [DPCM Split](https://forums.nesdev.com/viewtopic.php?p=65871#p65871):
  generate a stable raster split without external timer hardware
- [EQ test](https://forums.nesdev.com/viewtopic.php?p=208506#p208506):
  pink noise and sine sweep generators
- [Eighty](https://forums.nesdev.com/viewtopic.php?p=95153#p95153):
  read buttons on the NES Four Score accessory
- FamiTracker module to video renderer
- File extractor for Family Computer Disk System (FDS) images
- [FME-7 big PRG RAM](https://forums.nesdev.com/viewtopic.php?p=142573#p142573)
- [FME-7 IRQ acknowledgment](https://forums.nesdev.com/viewtopic.php?p=142243#p142243)
- [IRE tiny](https://forums.nesdev.com/viewtopic.php?p=159262#p159262):
  port of the IRE (brightness level) test of 240p Test Suite to run
  on a minimalist devcart
- [Mapper 78 submappers](https://forums.nesdev.com/viewtopic.php?p=208395#p208395):
  test for handling of nametable mirroring in ROMs intended to run
  on the _Uchuusen_ and _Holy Diver_ cartridge boards
- Meece:
  first NES program to use a Super NES Mouse
- [MMC3 big CHR RAM](https://forums.nesdev.com/viewtopic.php?f=3&t=13890)
- MMC3 save data viewer
- [Password save](https://forums.nesdev.com/viewtopic.php?p=64656#p64656)
- [PAL chroma phase](https://forums.nesdev.com/viewtopic.php?p=133629#p133629):
  investigate how a TV comb filter combines scanlines in the video
  from various NES and famiclone models
- [Pretendo and other fake logos](https://forums.nesdev.com/viewtopic.php?p=116405#p116405):
  generate entropy without a button press to randomly choose a parody
  logo to drop into the Game Boy boot ROM intro
- [RGB121](https://forums.nesdev.com/viewtopic.php?p=94658#p94658):
  display 16-color images on an NES using pseudo-interlacing
- [Software parallax](https://forums.nesdev.com/viewtopic.php?f=22&t=16419):
  use bit shifting to rotate background tiles horizontally
- [Sprite scaling](https://forums.nesdev.com/viewtopic.php?f=22&t=12055):
  real-time shrinking is possible using lookup tables
- [Telling LYs?](https://forums.nesdev.com/viewtopic.php?f=22&t=18998):
  sub-frame input timing test
- Text to spectrogram
- Tuning table generator for NSD.Lib
- [Vaus Test](https://forums.nesdev.com/viewtopic.php?f=22&t=10662):
  read the _Arkanoid_ controller
- [VWF terminal](https://forums.nesdev.com/viewtopic.php?f=2&t=12436)
- [Zapper lag tests](https://forums.nesdev.com/viewtopic.php?f=9&t=10198)
- Projects that never proceeded past pixel art prototypes

Many of them have patches to their build system to help them build
under Python 3 and late-2010s versions of cc65.

Most should be under the zlib license or an equivalent GNU
all-permissive license, though this merits an audit.
