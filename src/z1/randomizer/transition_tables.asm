; Transition tables for going from Z1 -> Another game
; Starts at $87A000
; For dungeon/underworld transitions, "OR" the room_id with $8000

; Transition table when entering a dungeon/cave
transition_table_in:
;  room_id,  game,  destination, args
dw $0066, $0001, $0220, $0000
dw $0000

org $87B000
; Transition table when exiting a dungeon/cave
transition_table_out:
;  room_id,  game,  destination, args
;dw $8073, $0000, $8BCE, $0000       ; Dungeon 1 -> Parlor
dw $0000

org $87BFFF
db $00
