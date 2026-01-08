;  Methods exposed for $4015 writes
    ChannelFlagLoop = $87  ;  Heap memory to loop through each channel flag in Status_Set
    ChannelFlagOffset = $88  ;  Heap memory to track the current flag offset through each channel in Status_Set

;  Methods
Status:

;.GetOutput(?)
;.GetState(?)

;  Process $4015 write
.Set:
    push y
    mov y, a    ; save value

    call Run

    mov ChannelFlagLoop, !Square0Flag   
    mov ChannelFlagOffset, !Square0Offset ;  Start with sq0 and loop through all channels

..loop:
    mov x, ChannelFlagOffset    ;  x == index into zero page based on current channel
    mov a, y
    and a, ChannelFlagLoop
    beq ..channelDisabled
..channelEnabled:
    mov a, sq0StateFlags+x
    or a, #!LengthEnabled
    mov sq0StateFlags+x, a
    bra +
..channelDisabled:
    mov a, sq0StateFlags+x
    and a, #~!LengthEnabled
    mov sq0StateFlags+x, a
    mov a, #$00
    mov sq0LengthCounter+x, a       ; lengthCounter = 0 (TODO: ensure this applies to all 5 channels)
+
    asl ChannelFlagLoop
    cmp ChannelFlagLoop, #%00100000
    beq ..done

    clrc : adc ChannelFlagOffset, #$10
    bra ..loop
..done:
    pop y
jmp ProcessWrites_handlerReturn
