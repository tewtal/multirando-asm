; Transition tables for going from Z3 -> Another game
; Starts at $AA8000

; Transition table when entering a dungeon/cave
transition_table_in:
;  room_id, owscrl, game,  destination, args
dw $0122, $0035, $0003, $060E, $C000       ; Hylia Fortune teller -> M1 Construction Zone
dw $0122, $0011, $0002, $0066, $0003       ; Kakariko Fortune teller -> Z1
dw $0000

org $A8A000
; Transition table when exiting a dungeon/cave
transition_table_out:
;  room_id,  reserved, game,  destination, args
;dw $0112, $0000, $0000, $8bce, $0000       ; Shop exit -> Parlor
dw $0000
