#!/bin/sh
set -e
ca65 -g -o test.o test.s
ld65 -o uninitialized-ram-clearing.nes --dbgfile uninitialized-ram-clearing.dbg -C nrom128.cfg test.o
zip -9 uninitialized-ram-clearing.zip uninitialized-ram-clearing.nes uninitialized-ram-clearing.dbg test.s nrom128.cfg mk.sh README.md
