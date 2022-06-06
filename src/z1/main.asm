namespace z1
sa1rom 0,3,6,0

!BASE_BANK = $80

incsrc "labels.asm"

; Temp code that incbins the ROM in the right places
incsrc "rom.asm"

; Include hooks
incsrc "hooks.asm"

; Include common code (will be copied to WRAM $1000-$1FFF when switching to M1)
; The reason for this is that the main "common" MMC1 bank at $C000-$FFFF is more or less full
; so instead we use this free space in WRAM for code accessible from all banks
org $878000
base $7E1000
incsrc "common.asm"
warnpc $872000

; Include SNES port functions that doesn't have to be in the common code area
org $889000
incsrc "init.asm"
incsrc "snes.asm"

; Include randomizer additions
org $898000

namespace off
