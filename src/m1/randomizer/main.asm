incsrc "hooks.asm"

org $888000
incsrc "tables.asm"

warnpc $88F000
org $88F000
incsrc "transition_tables.asm"

org $898000
incsrc "newitems.asm"
incsrc "transition_out.asm"
incsrc "transition_in.asm"

org $8A8000
incsrc "data.asm"