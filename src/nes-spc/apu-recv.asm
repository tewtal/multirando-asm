
!ApuIo0 = $f4
!ApuIo1 = $f5
!ApuIo2 = $f6
!ApuIo3 = $f7
ExpectedPacketSeq = $00
QueueLength  = $1f
NumbersQueue = $20
ValuesQueue  = $50

; SPC700 receive loop
; Receives up to two 2-byte records per SNES/APU port packet
; Stores register numbers at $20, $21, $22, ...
; Stores register values  at $50, $51, $52, ...
; Transfer length is sent via APU port 2 before the first record.
; Packet format:
;   f4 bits 0-4: register 0; bits 5-7: packet sequence/ack
;   f5: value 0
;   f6: register 1; ignored when QueueLength ends after record 0
;   f7: value 1
apurecv:
    mov a, !ApuIo2              ; read transfer length
    mov QueueLength, a
    mov x, #$00
    mov ExpectedPacketSeq, #$00
    mov !ApuIo0, #$d7           ; ack CPU ready after length is captured

NextPacket:
    mov a, x
    cmp a, QueueLength
    beq Done

WaitPacket:
    mov a, !ApuIo0
    and a, #$e0
    cmp a, ExpectedPacketSeq
    bne WaitPacket

    mov a, !ApuIo0
    and a, #$1f
    mov NumbersQueue+x, a

    mov a, !ApuIo1
    mov ValuesQueue+x, a

    inc x

    mov a, x
    cmp a, QueueLength
    beq Done

    mov a, !ApuIo2
    mov NumbersQueue+x, a

    mov a, !ApuIo3
    mov ValuesQueue+x, a

    inc x

    mov a, x
    cmp a, QueueLength
    beq Done

    mov a, ExpectedPacketSeq
    clrc
    adc a, #$20
    and a, #$e0
    mov ExpectedPacketSeq, a
    mov !ApuIo0, a
    bra NextPacket

Done:
    mov $f4, #$7d
    call ProcessWrites
    bra WaitTick
