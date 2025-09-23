namespace m1
sa1rom 0,0,6,7

!BASE_BANK = $90

; Temp code that incbins the ROM in the right places
incsrc "rom.asm"

; Include hooks
incsrc "hooks.asm"

; Include common code (will be copied to WRAM $1000-$1FFF when switching to M1)
; The reason for this is that the main "common" MMC1 bank at $C000-$FFFF is more or less full
; so instead we use this free space in WRAM for code accessible from all banks
org $978000
base $7E1000
incsrc "common.asm"
incsrc "randomizer/wavy_ice.asm"  ; This has to exist in RAM
warnpc $891000

; Include SNES port functions that doesn't have to be in the common code area
org $979000
incsrc "labels.asm"
incsrc "init.asm"
incsrc "snes.asm"
print "m1 SNES port functions end = ", pc
warnpc $979fff

; Include randomizer additions
org $988000
incsrc "randomizer/main.asm"

; Don't use more than up to bank $8F for this if possible, the rest of this bank is global data

namespace off
