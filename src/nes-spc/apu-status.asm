;  Methods exposed for $4015 writes


;  Methods
Status:

;.GetOutput(?)
;.GetState(?)

;  Process $4015 write
.set:
    push y
    mov y, a    ; save value

    call Run

    mov a, y
    and a, !Square0Flag
    beq ..sq0Disabled
..sq0Enabled:
    set1 !sq0LengthEnabledFlag
    bra +
..sq0Disabled:
    clr1 !sq1ConstantVolumeFlag
    mov a, #$00
    mov sq0LengthCounter+x, a       ; lengthCounter = 0
+
    ;  TODO: rest
    pop y
jmp ProcessWrites_handlerReturn
