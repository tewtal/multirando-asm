; Transition tables for going from Z3 -> Another game
; Starts at $A88000

; Transition table when entering a dungeon/cave
transition_table_in:
;  room_id,  game,  destination, owscrl
dw $0122, $0000, $8bce, $0035       ; Hylia Fortune teller -> Parlor
dw $0000

org $A8A000
; Transition table when exiting a dungeon/cave
transition_table_out:
;  room_id,  game,  destination, extra
dw $0112, $0000, $8bce, $0000       ; Shop exit -> Parlor
dw $0000
