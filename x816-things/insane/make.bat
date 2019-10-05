@echo off
x816 insane.asm
pause
copy /b neshead.bin+insane.bin insane.nes
cd \personal\nes
nesticle \personal\develop\insanes\insane.nes
cd \personal\develop\insanes
