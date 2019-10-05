@echo off

echo Compiling support programs...

gcc -Wall -O3 -s packbits.c -o packbits.exe
if errorlevel 1 goto end
gcc -Wall -O3 -s mkpowers.c -o mkpowers.exe
if errorlevel 1 goto end

echo Building binary components...
mkpowers
if errorlevel 1 goto end
packbits title.nam title.pkb
if errorlevel 1 goto end
packbits copr.nam copr.pkb
if errorlevel 1 goto end

echo Compiling Nibbles...
x816 nibbles.asm
echo Linking to iNES format...
copy /b header.nes+nibbles.bin nibbles.nes
goto end

:fail
Build failed.

:end
