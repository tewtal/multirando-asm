
apurecv:
    mov $F4,a               ; reply to CPU with $D7 (begin transfer)
    mov $F5, #$ff

    ; 63.613 cycles per scanline
    ; Transfer via HDMA must take no more than 66 cycles per byte
    ; Cycles used during transfer: 25 = 3+2 + 3+5+4 + 2+2+4

    mov x,#0
xfer:                       ;  -- this happens *relatively* quickly once we trigger the cpu to start the transfer
    cmp x,$F4               ; wait for port 0 to have current byte #
    bne xfer

    mov a,$F5               ; load data on port 1
    mov $40+x,a             ; store data at $40 - $55

    inc x
    mov a, x
    mov $F5, a
    cmp x,#$17
    bne xfer

    ; --- Finished transfer.  Prep cpu for next send.
    mov $F4,#$7D            ; move $7D to port 0 (SPC ready)
    bra WaitTick