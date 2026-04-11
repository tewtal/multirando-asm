
!ApuIo0 = $f4
!ApuIo1 = $f5
!ApuIo2 = $f6
!MaxQueueSize = #$30
ExpectedWriteIndex = $00
QueueLength  = $1f
NumbersQueue = $20
ValuesQueue  = $50

; SPC700 receive loop
; Receives 2-byte records from SNES via APU ports
; Stores register numbers at $20, $21, $22, ...
; Stores register values  at $50, $51, $52, ...
; Terminates when write index == $30
; [Optimization TODO: transition to a two-values-at-once loop:
;   - register numbers can be stored in 5 bits because $4009, $4014, $4016 are unused,
;       leaving just 21 valid register numbers.  Then use the remaining 3 bits to
;       come up with a simple diff scheme (add/sub?) to determine a second register number
;   - Then use ApuIo1 and ApuIo2 for two register values, and ApuIo3 for the expected index value
;       - or can we encode the expected index value into the 3 spare bits in ApuIo0, and use ApuIo3 for the second register number?
;]
apurecv:
    mov !ApuIo0, a              ; reply to CPU with $d7 (begin transfer)

    ; 63.613 cycles per scanline
    ; Transfer via HDMA must take no more than 66 cycles per byte (currently N/A to quad rando)
    ; Cycles used during transfer: 25 = 3+2 + 3+5+4 + 2+2+4

RecvLoop:
        mov   x, #$00                   ; destination offset
        mov ExpectedWriteIndex, #$00    ;  First expected index is 0

; --- Main receive loop ---
NextBlock:
WaitIndex:
        mov   a, !ApuIo2
        cmp   a, !MaxQueueSize
        beq   Done
        cmp   a, ExpectedWriteIndex
        bne   WaitIndex           ; wait for expected index

        ; Read and store data bytes
        mov   a, !ApuIo0
        mov   NumbersQueue+x, a

        mov   a, !ApuIo1
        mov   ValuesQueue+x, a
        inc   x

        ; expected index++
        inc   ExpectedWriteIndex
        mov   !ApuIo2, ExpectedWriteIndex    ;  signal for the next block

        bra   NextBlock

Done:
    ; --- Finished transfer.  Prep cpu for next send.
    mov $f4, #$7d           ; move $7D to port 0 (SPC ready)

    mov QueueLength, x      ; store the new writes queue length for processing
    call ProcessWrites

    bra WaitTick
;  End apurecv