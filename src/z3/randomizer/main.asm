;
; ALTTP Randomizer Specific Changes
;

incsrc "hooks.asm"

; Bank A6-A8 is unused in regular ALTTPR ASM, so we'll use
; bank A6 for code, and banks A7-A8 for data as needed

org $A68000
incsrc "items.asm"
incsrc "ending.asm"
incsrc "spc.asm"

org $A78000
GFX_SM_Items:
    incbin data/newitems_sm.gfx

org $A7A000
GFX_SM_Items_2:
    incbin data/newitems_sm_2.gfx
warnpc $A7FFFF