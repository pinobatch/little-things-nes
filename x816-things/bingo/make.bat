@echo off
mode,50
cls
echo ============================================
echo compressing nametables
echo ============================================
echo.
ntenc copr.nam
ntenc readme.nam
ntenc title.nam
cls
echo ============================================
echo compiling
echo ============================================
x816 bingo.asm
pause
copy /b neshead.bin+bingo.bin bingo.nes
cd \personal\nes
nesticle \personal\develop\bingo\bingo.nes
cd \personal\develop\bingo
mode,50
echo if it worked, type L to try it in a better emulator
