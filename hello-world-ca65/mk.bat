\nesdev\cc65\bin\ca65 hello.s
if errorlevel 1 goto End
\nesdev\cc65\bin\ld65 hello.o -C nes.ini -o hello.prg
if errorlevel 1 goto End
copy /b hello.prg+hello.chr hello.nes
hello.nes
:End