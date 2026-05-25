;  Methods exposed for $4015 writes

;  Methods
Status:

;  Process $4015 write
.Set:  ; Cycles: 93 + 5 for each disabled bit among $4015 bits 0-3. Counts DMC_Run as call only.
    push y

    mov BitwiseScratch, a

    mov a, #$00
    mov y, #$00
    mov1 c, BitwiseScratch.0
    mov1 !sq0LengthEnabledFlag, c
    bcs +
    movw sq0LengthCounter, ya   ;  also clears length reload value byte
+

    mov1 c, BitwiseScratch.1
    mov1 !sq1LengthEnabledFlag, c
    bcs +
    movw sq1LengthCounter, ya   ;  also clears length reload value byte
+

    mov1 c, BitwiseScratch.2
    mov1 !triLengthEnabledFlag, c
    bcs +
    movw triLengthCounter, ya   ;  also clears length reload value byte
+

    mov1 c, BitwiseScratch.3
    mov1 !noiseLengthEnabledFlag, c
    bcs +
    movw noiseLengthCounter, ya   ;  also clears length reload value byte
+

    mov1 c, BitwiseScratch.4
    mov1 !dmcLengthEnabledFlag, c
    call DMC_Run    ; no length counter on this channel; must call Run to process sequential $4015 writes

    pop y
    jmp ProcessWrites_handlerReturn
