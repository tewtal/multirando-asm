
!ApuIo0 = $f4
!ApuIo1 = $f5
!ApuIo2 = $f6
ExpectedWriteIndex = $00
QueueLength  = $1f
NumbersQueue = $20
ValuesQueue  = $50

; SPC700 receive loop
; Receives 2-byte records from SNES via APU ports
; Stores register numbers at $20, $21, $22, ...
; Stores register values  at $50, $51, $52, ...
; Transfer length is sent via APU port 2 before the first record.
; [Optimization TODO: transition to a two-values-at-once loop:
;   - register numbers can be stored in 5 bits because $4009, $4014, $4016 are unused,
;       leaving just 21 valid register numbers.  Then use the remaining 3 bits to
;       come up with a simple diff scheme (add/sub?) to determine a second register number
;   - Then use ApuIo1 and ApuIo2 for two register values, and ApuIo3 for the expected index value
;       - or can we encode the expected index value into the 3 spare bits in ApuIo0, and use ApuIo3 for the second register number?
;]
apurecv:
    mov a, !ApuIo2              ; read transfer length
    mov QueueLength, a
    mov x, #$00
    mov ExpectedWriteIndex, #$00
    mov !ApuIo2, #$00           ; ack length, request record 0
    mov !ApuIo0, #$d7           ; ack CPU ready after length is captured

NextBlock:
    mov a, ExpectedWriteIndex
    cmp a, QueueLength
    beq Done

WaitIndex:
    mov a, !ApuIo2
    cmp a, ExpectedWriteIndex
    bne WaitIndex

    mov a, !ApuIo0
    mov NumbersQueue+x, a

    mov a, !ApuIo1
    mov ValuesQueue+x, a

    inc x
    inc ExpectedWriteIndex
    mov !ApuIo2, ExpectedWriteIndex
    bra NextBlock

Done:
    mov $f4, #$7d
    call ProcessWrites
    bra WaitTick
