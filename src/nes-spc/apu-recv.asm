
!ApuIo0 = $f4
!ApuIo1 = $f5
!ApuIo2 = $f6
ExpectedWriteIndex = $1a

; SPC700 receive loop
; Receives 2-byte records from SNES via APU ports
; Stores sequentially at $20, $21, $22, ...
; Write index increments by +2 each block
; Terminates when write index == $FF
apurecv:
    mov !ApuIo0, a              ; reply to CPU with $d7 (begin transfer)

    ; 63.613 cycles per scanline
    ; Transfer via HDMA must take no more than 66 cycles per byte (currently N/A to quad rando)
    ; Cycles used during transfer: 25 = 3+2 + 3+5+4 + 2+2+4

RecvLoop:
        mov   y, #$00             ; destination offset
        mov ExpectedWriteIndex, #$00    ;  First expected index is 2

; --- Main receive loop ---
NextBlock:
WaitIndex:
        mov   a, !ApuIo2
        cmp   a, #$FF
        beq   Done
        cmp   a, ExpectedWriteIndex
        bne   WaitIndex           ; wait for expected index

        ; Read and store data bytes
        mov   a, !ApuIo0
        mov   $20+y, a
        inc   y

        mov   a, !ApuIo1
        mov   $20+y, a
        inc   y

        ; expected index += 2
        mov   a, ExpectedWriteIndex
        inc   a
        inc   a
        mov   ExpectedWriteIndex, a
        mov   !ApuIo2, a    ;  signal for the next block

        bra   NextBlock

Done:
    call PrepActiveVars

    ; --- Finished transfer.  Prep cpu for next send.
    mov $f4, #$7d            ; move $7D to port 0 (SPC ready)
    bra WaitTick
;  End apurecv


PrepActiveVars:
    mov a, no4016
    and a, #$20
    beq .done
    mov Active4017, #$01
.done:
    ret