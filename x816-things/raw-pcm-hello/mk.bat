@echo off
packbits sndtest.nam title.pkb
x816 sndtest.asm
if errorlevel 1 goto End
copy /b nrom128.hdr+sndtest.bin sndtest.nes
:End