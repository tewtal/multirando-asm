@echo off
del build\main_z1.sfc
resources\asar.exe -DSTANDALONE=1 --symbols=wla --symbols-path=build\main_z1.sym src\z1\standalone.asm build\main_z1.sfc