org $d00000
sm_transition_table:
    ;  door,  game,  destination, args
    dw CrateriaMapDoorData_out, $0001, $0200, $0000
    dw $9306, $0001, $0201, $0000
    dw $a8f4, $0001, $0202, $0040
    dw LNRefillDoorData_out, $0001, $0203, $0040
    dw $0000

warnpc $d01000