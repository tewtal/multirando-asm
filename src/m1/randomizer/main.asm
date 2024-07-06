incsrc "hooks.asm"

org $988000
incsrc "tables.asm"

warnpc $98F000
org $98F000
incsrc "transition_tables.asm"

org $998000
incsrc "newitems.asm"
incsrc "transition_out.asm"
incsrc "transition_in.asm"
incsrc "loadgame.asm"
incsrc "ending.asm"

org $9A8000
incsrc "data.asm"

org $9B8000
incsrc "../../common/overlay.asm"


; Patch transition door
org $90A6C9
    db $03, $1f