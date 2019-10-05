@echo off

rem 'ca65' assembles the .s file into relocatable machine code (.o)
ca65 ding2.s -o ding2.o

rem 'ld65' links one or more .o files into an executable .nes file
rem The -C command tells ld65 which memory layout to use
ld65 -C ../common/nrom128.x ding2.o -o ding2.nes
pause