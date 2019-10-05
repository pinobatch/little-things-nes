@echo off

rem 'ca65' assembles the .s file into relocatable machine code (.o)
ca65 ding3.s -o ding3.o

rem 'ld65' links one or more .o files into an executable .nes file
rem The -C command tells ld65 which memory layout to use
ld65 -C ../common/nrom128.x ding3.o -o ding3.nes
pause