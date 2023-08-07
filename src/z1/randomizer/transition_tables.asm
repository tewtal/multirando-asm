; Transition tables for going from Z1 -> Another game
; Starts at $8F8000
; If we're in a dungeon, "OR" the room_id with $8000

; Transition table when entering a dungeon/cave
transition_table_in:
;  room_id,  game,  destination, args
dw $0077, $0002, $060E, $C000       ; Dungeon 1 -> Construction Zone (M1), Vertical Scroll, Right Door
dw $0000

org $8FA000
; Transition table when exiting a dungeon/cave
transition_table_out:
;  room_id,  game,  destination, args
dw $0000
