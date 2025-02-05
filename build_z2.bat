@echo off
del build\main_z2.sfc
resources\asar.exe -DSTANDALONE=1 --symbols=wla --symbols-path=build\main_z2.sym src\z2\standalone.asm build\main_z2.sfc