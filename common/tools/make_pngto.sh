#!/bin/sh
set -e

echo 'Native compile'
gcc -Wall -Wextra -Os -s indexedimage.c lodepng.c musl_getopt.c pngto.c -o pngtochr
echo 'Cross-compile for Wine and Windows'
x86_64-w64-mingw32-gcc -Wall -Wextra -Os -s indexedimage.c lodepng.c musl_getopt.c pngto.c -o pngtochr.exe