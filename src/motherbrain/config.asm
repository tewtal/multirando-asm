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

; Enables keysanity specific code sections.
config_keysanity:    ; $FFFF06
    dw #$0000
