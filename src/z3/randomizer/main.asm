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
;incsrc "skiptitle.asm"

print "Z3 Randomizer Extras End = ", pc

org $AA8000
incsrc "transition_tables.asm"
warnpc $AAFFFF

; org $01E9BC
;     db $ca

; Banks B8-BE seems to be free as well in ALTTPR
; Use this for the WRAM/VRAM dumps used for game transitions
; Ideally transitions would need less of this data, but let's keep this for now

org $b88000
zelda_wram:
    incbin "../../data/z3-newwram.bin":0000-8000
org $b98000
    incbin "../../data/z3-newwram.bin":8000-10000
org $ba8000
    incbin "../../data/z3-newwram.bin":10000-18000
org $bb8000
    incbin "../../data/z3-newwram.bin":18000-20000

org $bc8000
zelda_vram:
    incbin "../../data/zelda-vram-1.bin"
org $bd8000
    incbin "../../data/zelda-vram-2.bin"
