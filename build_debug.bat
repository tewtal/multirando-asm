@echo off
del build\main.sfc
cd resources
asar.exe -DDEBUG=1 --fix-checksum=off --symbols=wla --symbols-path=../build/main.sym ../src/main.asm ../build/main.sfc
cd ..

cd build
del merged.sfc
del quad.bps
copy /b ..\resources\sm.sfc+..\resources\zelda3.sfc+..\resources\metroid.nes+..\resources\zelda1prg0.nes merged.sfc
..\resources\flips.exe --create --exact --ignore-checksum --bps-delta merged.sfc main.sfc quad.bps
cd ..