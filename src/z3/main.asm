namespace z3
sa1rom 4,5,4,5
incsrc "rom.asm"
incsrc "sa1rom.asm"

; Include the base ALTTP ROM (with minor changes)
; it should be much easier to keep this in sync now since it
; can use exactly the same addresses as the regular ALTTP randomizer

; Don't edit anything in this folder that isn't strictly just fixing things
; to make it run under the SA-1 memory map
!FEATURE_NEW_TEXT = 1
incsrc "z3randomizer/LTTP_RND_GeneralBugfixes.asm"

; Include additional changes required for this randomizer
incsrc "randomizer/main.asm"

; Banks $B8-$BF are reserved for Zelda 2

namespace off