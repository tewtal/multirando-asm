namespace mb

sa1rom 0,0,0,7      ; Set boot configuration
incsrc "boot.asm"

sa1rom 0,0,3,7      ; Set main configuration
org $F00000
incsrc "randomizer/data.asm" ; Up to 12 banks of randomizer specific data
; Uses up banks F0-F9 right now,
warnpc $FA0000
print "Randomizer data ends = ", pc

; Bank FA - FB - Zelda 2 CHR-ROM
; Bank FC - Free space

; FD0000 - FDFFFF
; SPC data for credits

org $FE0000
namespace credits
incsrc "credits.asm"
incsrc "spc_play.asm"
namespace mb
warnpc $FF0000

org $FF0000
base $CF0000
namespace off
incsrc "../nes-spc/spc.asm"

org $FF4000
namespace menu
incsrc "menu/main.asm"
namespace mb
incsrc "randomizer/init.asm"
warnpc $FF8000

; FF8000 - FFE000
; Nes games common data


org $FFE000
base $40E000
incsrc "snes.asm"
incsrc "sa1.asm"
incsrc "transition.asm"
incsrc "randomizer/main.asm"
print "MotherBrain ends = ", pc
namespace off

incsrc "config.asm"

