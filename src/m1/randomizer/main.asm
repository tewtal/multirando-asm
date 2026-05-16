incsrc "hooks.asm"

; Don't move this
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
warnpc $99ffff

; Patch transition door
org $90A6C9
    db $03, $1f