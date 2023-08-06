#!/bin/bash

rm build/main.sfc
cd resources
./asar --fix-checksum=off --symbols=wla --symbols-path=../build/main.sym ../src/main.asm ../build/main.sfc
cd ..