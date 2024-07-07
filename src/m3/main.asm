namespace m3
sa1rom 2,3,0,1
incsrc "rom.asm"
incsrc "sa1rom.asm"

incsrc "randomizer/main.asm"



org $dd0000
m1_initram:
    incbin "../data/m1-initram.bin"
m1_initsram:
    incbin "../data/m1-initsram.bin"
z1_initram:
    incbin "../data/z1-initram.bin"
z1_initsram:
    incbin "../data/z1-initsram.bin"
sm_alttp_sram:
    incbin "../data/z3-initsram.bin"
warnpc $df0000


namespace off