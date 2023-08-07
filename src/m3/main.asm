namespace m3
sa1rom 2,3,0,1
incsrc "rom.asm"
incsrc "sa1rom.asm"

incsrc "randomizer/newgame.asm"
incsrc "randomizer/transition_out.asm"
incsrc "randomizer/transition_in.asm"
incsrc "randomizer/transition_tables.asm"


org $d10000
sm_wram:
    incbin "../data/sm-wram-lo-1.bin"
org $d20000
    incbin "../data/sm-wram-lo-2.bin"
org $d30000
    incbin "../data/sm-wram-hi-1.bin"
org $d40000
    incbin "../data/sm-wram-hi-2.bin"

org $d50000
sm_wram_right:
    incbin "../data/sm-wram-right-lo-1.bin"
org $d60000
    incbin "../data/sm-wram-right-lo-2.bin"
org $d70000
    incbin "../data/sm-wram-right-hi-1.bin"
org $d80000
    incbin "../data/sm-wram-right-hi-2.bin"

org $d90000
sm_vram:
    incbin "../data/sm-vram-1.bin"
org $da0000
    incbin "../data/sm-vram-2.bin"

org $db0000
sm_vram_right:
    incbin "../data/sm-vram-right-1.bin"
org $dc0000
    incbin "../data/sm-vram-right-2.bin"

namespace off