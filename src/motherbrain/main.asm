namespace mb

sa1rom 0,0,0,7      ; Set boot configuration
incsrc "boot.asm"

sa1rom 0,0,0,7      ; Set main configuration
org $FC0000
namespace menu
incsrc "menu/main.asm"
warnpc $FC8000
namespace off

org $FC8000
namespace data
incsrc "data.asm"
warnpc $FD0000
namespace off

org $FE0000
namespace credits
incsrc "credits.asm"
incsrc "spc_play.asm"       ; Bank $FD is used for the SPC to play here
namespace mb

org $FF8000
namespace off
incsrc "../nes-spc/spc.asm"

namespace mb
org $FFE000
base $40E000
incsrc "snes.asm"
incsrc "sa1.asm"
incsrc "transition.asm"
incsrc "randomizer/main.asm"
print "MotherBrain ends = ", pc
namespace off

incsrc "config.asm"

