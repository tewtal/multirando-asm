namespace m3
sa1rom 2,3,0,1
incsrc "rom.asm"
incsrc "sa1rom.asm"

incsrc "randomizer/main.asm"

org $d10000
sm_wram:
    incbin "../data/sm-wram-lo-1.bin"
    incbin "../data/sm-wram-lo-2.bin"

org $d20000
    incbin "../data/sm-wram-hi-1.bin"
    incbin "../data/sm-wram-hi-2.bin"

org $d30000
sm_wram_right:
    incbin "../data/sm-wram-right-lo-1.bin"
    incbin "../data/sm-wram-right-lo-2.bin"
org $d40000
    incbin "../data/sm-wram-right-hi-1.bin"
    incbin "../data/sm-wram-right-hi-2.bin"

org $d50000
sm_vram:
    incbin "../data/sm-vram-1.bin"
    incbin "../data/sm-vram-2.bin"

org $d60000
sm_vram_right:
    incbin "../data/sm-vram-right-1.bin"
    incbin "../data/sm-vram-right-2.bin"

org $d80000
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
warnpc $d90000


namespace off