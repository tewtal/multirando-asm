; Zelda 1 - Randomizer patches

incsrc "hooks.asm"

org $898000
incsrc "transition_out.asm"
incsrc "transition_in.asm"

org $8F8000
incsrc "transition_tables.asm"