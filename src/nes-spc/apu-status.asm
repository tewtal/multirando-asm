;  Methods exposed for $4015 writes

;  Methods
Status:

;  Process $4015 write
.Set:
    push y

    mov BitwiseScratch, a

    ;  72 cycles
    mov a, #$00
    mov1 c, BitwiseScratch.0
    mov1 !sq0LengthEnabledFlag, c
    bcs +
    mov sq0LengthCounter, a
+

    mov1 c, BitwiseScratch.1
    mov1 !sq1LengthEnabledFlag, c
    bcs +
    mov sq1LengthCounter, a
+

    mov1 c, BitwiseScratch.2
    mov1 !triLengthEnabledFlag, c
    bcs +
    mov triLengthCounter, a
+

    mov1 c, BitwiseScratch.3
    mov1 !noiseLengthEnabledFlag, c
    bcs +
    mov noiseLengthCounter, a
+

    mov1 c, BitwiseScratch.4
    mov1 !dmcLengthEnabledFlag, c
    call DMC_Run    ; no length counter on this channel; must call Run to process sequential $4015 writes

    pop y
    jmp ProcessWrites_handlerReturn