@echo off
del build\main_z1.sfc
resources\asar.exe --symbols=wla --symbols-path=build\main_z1.sym src\z1\standalone.asm build\main_z1.sfc