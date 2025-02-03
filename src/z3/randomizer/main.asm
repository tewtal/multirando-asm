;
; ALTTP Randomizer Specific Changes
;

incsrc "hooks.asm"

; Bank A6 is unused in regular ALTTPR ASM, so we'll use
; bank A6 for code, bank A7 is used for GFX


org $A68000
incsrc "ending.asm"
incsrc "spc.asm"
incsrc "transition_in.asm"
incsrc "transition_out.asm"
incsrc "skiptitle.asm"
incsrc "misc.asm"

print "Z3 Randomizer Extras End = ", pc

org $AA8000
incsrc "transition_tables.asm"
warnpc $AAFFFF

; place temp item
org $01E9BC
    db $ca
