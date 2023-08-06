; Transition tables for going from Z1 -> Another game
; Starts at $8F8000
; If we're in a dungeon, "OR" the room_id with $8000

; Transition table when entering a dungeon/cave
transition_table_in:
;  room_id,  game,  destination, extra
dw $0000

org $8FA000
; Transition table when exiting a dungeon/cave
transition_table_out:
;  room_id,  game,  destination, extra
dw $0073, $0001, $0201, $0000       ; Dungeon 1 -> Exit 201 in Z3
dw $0000
