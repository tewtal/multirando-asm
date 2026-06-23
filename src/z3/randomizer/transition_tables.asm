; Transition tables for going from Z3 -> Another game
; Starts at $AA8000

; Transition table when entering a dungeon/cave
transition_table_in:
;  room_id, owscrl, game,  destination, args
dw $011f, $0002, $0003, $0b0c, $0040       ; Z3 Lumberjack House -> M1 $0B0C, right-hand door, vertical Brinstar
dw $0122, $0035, $0000, m3_CrateriaMapDoorData_in, $0000       ; Hylia Fortune teller -> M3 Parlor
dw $0122, $0011, $0002, $0066, $0003       ; Kakariko Fortune teller -> Z1

dw $00E5, $0003, $0000, $97c2, $0000       ; Death mountain cave -> Norfair map station
dw $010E, $0077, $0000, $a894, $0000       ; Dark world ice rod cave -> Maridia missile refill
dw $0115, $0070, $0000, m3_LNRefillDoorData_in, $0000       ;  Misery mire right side -> LN GT Refill


dw $0000

org $A8A000
; Transition table when exiting a dungeon/cave
transition_table_out:
;  room_id,  reserved, game,  destination, args
;dw $0112, $0000, $0000, $8bce, $0000       ; Shop exit -> Parlor
dw $0000
