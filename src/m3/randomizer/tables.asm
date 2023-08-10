org $DF0000

boss_rewards:
; Table to write what the bosses will reward when killed
;  Type   Flag   Icon   Ext
dw $0080, $0001, $4032, $0000   ; Kraid
dw $0080, $0002, $4234, $0000   ; Phantoon
dw $0080, $0004, $4438, $0000   ; Draygon
dw $0080, $0008, $463A, $0000   ; Ridley

; Types: $0000 = Pendant, $0040 = Crystal, $0080 = SM Boss Token
; Flag: Bitmask flag for the boss/pendant/crystal
; Icon: Icon to show on minimap
org $DF0100
starting_equipment:
dw $0000, $0000, $0063 ; Equipment, Beams, Energy
dw $0000, $0000, $0000 ; Missiles, Supers, Power Bombs

; Config flags

org $DF0200
; Number of SM bosses to defeat
config_sm_bosses:
    dw #$0004

; starting events
; 0001 is zebes awake (default)
; 0400 is Tourian open (AKA Fast MB)
; 03C0 is G4 statues already grey (no animation)
config_events:       ; F47202
    dw #$0001