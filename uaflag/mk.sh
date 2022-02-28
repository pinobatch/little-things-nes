#!/bin/sh
set -e
ca65 -o uaflag.o uaflag.s
ld65 -o uaflag.nes -C nrom128.cfg uaflag.o
