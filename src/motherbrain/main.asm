namespace mb

sa1rom 0,0,0,7      ; Set boot configuration
incsrc "boot.asm"

sa1rom 0,0,0,7      ; Set main configuration
org $F00000
incsrc "randomizer/data.asm" ; Up to 12 banks of randomizer specific data
; Uses up banks F0-F8 right now, so F9-FA remains free
print "Randomizer data ends = ", pc

; Bank FB - Used by NES games common data

org $FC0000
namespace menu
incsrc "menu/main.asm"
namespace mb
incsrc "randomizer/init.asm"
warnpc $FC8000
namespace off

org $FC8000
namespace data
incsrc "data.asm"
warnpc $FD0000
namespace off

; FD0000 - FDFFFF
; SPC data for credits

org $FE0000
namespace credits
incsrc "credits.asm"
incsrc "spc_play.asm"
namespace mb
warnpc $FF0000

org $FF0000
namespace off
incsrc "../nes-spc/spc.asm"
namespace mb
; free space for more code here
warnpc $FFE000


org $FFE000
base $40E000
incsrc "snes.asm"
incsrc "sa1.asm"
incsrc "transition.asm"
incsrc "randomizer/main.asm"
print "MotherBrain ends = ", pc
namespace off

incsrc "config.asm"

