; Zelda 1 - Randomizer patches
incsrc "hooks.asm"

org $898000
incsrc "transition_out.asm"
incsrc "transition_in.asm"
incsrc "newitems.asm"
incsrc "caves.asm"
incsrc "ending.asm"
incsrc "quickswap.asm"

org $8A8000
incsrc "tables.asm"
incsrc "../../common/item_overlay.asm"

org $8B8000
incsrc "data.asm"


org $878000+(CommonBankEnd-CommonBankStart)
base $7E1000+(CommonBankEnd-CommonBankStart)
incsrc "common.asm"
warnpc $879000
base off

; Put the transition table data at the end of the "common code" bank
org $87E000
incsrc "transition_tables.asm"
warnpc $888000