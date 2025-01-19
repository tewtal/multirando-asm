sa1rom 7,0,0,0

;
; Super metroid transition data
; Gets temporary mapped into the C00000-CF0000 range during transitions
;

; SM data
org $C00000
sm_wram:
    incbin "../../data/sm-wram-lo-1.bin"
    incbin "../../data/sm-wram-lo-2.bin"
org $C10000
    incbin "../../data/sm-wram-hi-1.bin"
    incbin "../../data/sm-wram-hi-2.bin"
org $C20000
sm_wram_right:
    incbin "../../data/sm-wram-right-lo-1.bin"
    incbin "../../data/sm-wram-right-lo-2.bin"
org $C30000
    incbin "../../data/sm-wram-right-hi-1.bin"
    incbin "../../data/sm-wram-right-hi-2.bin"
org $C40000
sm_vram:
    incbin "../../data/sm-vram-1.bin"
    incbin "../../data/sm-vram-2.bin"
org $C50000
sm_vram_right:
    incbin "../../data/sm-vram-right-1.bin"
    incbin "../../data/sm-vram-right-2.bin"

; Z3 data
org $C60000
zelda_wram:
    incbin "../../data/z3-newwram.bin":0000-10000
org $C70000
    incbin "../../data/z3-newwram.bin":10000-20000

org $C80000
zelda_vram:
    incbin "../../data/zelda-vram-1.bin"
    incbin "../../data/zelda-vram-2.bin"

sa1rom 0,0,0,7

org $F90000
m1_initram:
    incbin "../../data/m1-initram.bin"
m1_initsram:
    incbin "../../data/m1-initsram.bin"
z1_initram:
    incbin "../../data/z1-initram.bin"
z1_initsram:
    incbin "../../data/z1-initsram.bin"
print "Alttp init sram = ", pc
alttp_initsram:
    incbin "../../data/z3-initsram.bin"
sm_initsram:
    incbin "../../data/sm-initsram.bin"

