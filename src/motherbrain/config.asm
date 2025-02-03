; Common Combo Randomizer ROM confiuration flags

org $FFFF00
base $40FF00
config_flags:

; Enable "Multiworld"
config_multiworld:  ; $FFFF00
    dw #$0000

; Custom sprite enabled?
config_alttp_sprite: ; $FFFF02
    dw #$0000
config_sm_sprite:    ; $FFFF04
    dw #$0000
   
; Game-selection flags
org $FFFFE0
base $40FFE0
; Which game to start with
config_start:       ; $FFFFE0
    dw #$0000       ; 0 = SM, 1 = Z3, 2 = Z1, 3 = M1

; Which games are enabled
config_sm:          ; $FFFFE2
    dw #$0001
config_z3:          ; $FFFFE4
    dw #$0001
config_z1:          ; $FFFFE6
    dw #$0001
config_m1:          ; $FFFFE8
    dw #$0001


org $FFFFF0
base $40FFF0
config_seed:
    dd $ffffffff
