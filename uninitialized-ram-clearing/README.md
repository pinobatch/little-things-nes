Uninitialized RAM clearing
==========================

This program clears all of the Nintendo Entertainment System's work
RAM.  It triggers 2,046 dummy reads: one for each byte of work RAM
in the Control Deck minus two for a pointer in zero page.

Some NES emulators offer "uninitialized memory read" exceptions to
help a programmer determine whether they inadvertently made a program
read an unspecified value from memory that has not yet been written.
As of April 12, 2023, at least one NES emulator is triggering these
"uninitialized memory read" exceptions for dummy reads performed by
indexed (`STA abs,X`) or indirect indexed (`STA (zp),Y`) instructions
before a write.  These cause fatigue when the programmer must skip
dozens or hundreds of dummy reads during machine initialization to
find those reads that may cause a program to behave unpredictably.

Instructions:

1. If necessary, build the ROM (run `./mk.sh` with [cc65] installed).
2. Open it in Mesen.
3. From the Debug menu, choose Debugger.
4. Under "Break on..." check Uninitialized memory read.
   (In Mesen 1 or Mesen-X, under Options > Break Options,
   check Break on uninitialized memory read.)
5. From the Game menu of the main window, choose Power cycle.
6. Click Continue in the toolbar.  (The button looks like a
   right-pointing triangle.)

If your emulator's uninitialized memory read breakpoint disregards
dummy reads before writes, it will break once at `ldy $0700`.
Click Continue, and it will reach the end of the program, turning
the video output green.  Mesen 1 and Mesen-X behave this way.

If your emulator breaks on dummy reads before writes, it will break
once at `ldy $0700` and then repeatedly at `byteloop: sta ($00),y`.
Mesen 2 (April 12, 2023) behaves this way, as reported in a
[post to NESdev BBS].


By Damian Yerrick, April 2023  
Permission is granted to make use of this file without restriction.  
This file is offered as-is, without any warranty.

[cc65]: https://cc65.github.io/
[post to NESdev BBS]: https://forums.nesdev.org/viewtopic.php?p=287540#p287540
