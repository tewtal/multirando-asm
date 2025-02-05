sa1rom 7,3,6,5
namespace z2
!BASE_BANK = $B8



incsrc "rom.asm"

; Include hooks
incsrc "hooks.asm"

; Include common code (will be copied to WRAM $1000-$1FFF when switching to M1)
; The reason for this is that the main "common" MMC1 bank at $C000-$FFFF is more or less full
; so instead we use this free space in WRAM for code accessible from all banks
org $BF8000
base $7E1000
incsrc "common.asm"
warnpc $BFC000

; Include SNES port functions that doesn't have to be in the common code area
org $9D8000
incsrc "labels.asm"
incsrc "init.asm"
incsrc "snes.asm"
; Include randomizer additions
; incsrc "randomizer/main.asm"


namespace off