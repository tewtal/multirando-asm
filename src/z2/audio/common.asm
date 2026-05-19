print "z2-apu-routines = ", pc

!ApuWritesIndex  = $090f
!ApuNumberWrites = $0910
!ApuValueWrites  = $0940
!ApuIo0          = $2140
!ApuIo1          = $2141
!ApuIo2          = $2142
!ApuIo3          = $2143
!ApuPacketSeq    = $0970
!SpcReadyValue   = #$7d
!CpuReadyValue   = #$d7

; APU Update routines
SnesUpdateAudio:
    phx : phy : pha : php
    sep #$30

    ldy !ApuWritesIndex   ;  Set up decrementing loop index in [Y]
    beq .end              ;  no queued writes, skip handshake/transfer

    ;  cpu<->apu handshake
    lda !ApuIo0
    cmp !SpcReadyValue    ;  Check for spc readiness
    beq +
    jmp .end
+

    sty !ApuIo2           ;  Send transfer length
    lda !CpuReadyValue    ;  Indicate cpu readiness
    sta !ApuIo0

-   lda !ApuIo0           ;  Wait for SPC to ack CPU ready
    cmp !CpuReadyValue
    bne -

    ldx #$00
    stz !ApuPacketSeq
.transferLoop:
    lda !ApuValueWrites,x
    sta !ApuIo1           ;  Send first apu value

    cpy #$01
    beq .sendSingle

    inx
    lda !ApuNumberWrites,x
    sta !ApuIo2           ;  Send second apu index

    lda !ApuValueWrites,x
    sta !ApuIo3           ;  Send second apu value

    dex
    lda !ApuPacketSeq
    ora !ApuNumberWrites,x
    sta !ApuIo0           ;  Send packet sequence + first apu index

    inx                   ;  Next write index
    inx
    dey
    dey
    beq .finishedTransfer

    lda !ApuPacketSeq
    clc
    adc #$20
    and #$e0
    sta !ApuPacketSeq

    ;  spc packet ack wait loop
-   lda !ApuIo0
    and #$e0
    cmp !ApuPacketSeq
    bne -

    bra .transferLoop

.sendSingle:
    lda !ApuPacketSeq
    ora !ApuNumberWrites,x
    sta !ApuIo0           ;  Send packet sequence + first apu index

.finishedTransfer:
-   lda !ApuIo0
    cmp !SpcReadyValue      ; wait until SPC has reached Done and published $7d
    bne -
    stz !ApuIo0             ; leave SPC-readable CPU->APU port 0 as fixed benign value
    stz !ApuWritesIndex     ;  Reset queue

.end
    plp : pla : ply : plx
    rtl

;  Params:
;   [A] has the apu register number
;   [B] has the apu register value
;  Caller should preserve original [A] outside the routine if needed
EnqueueApuWrite:
    phx     ;  Preserve [X]
    ldx !ApuWritesIndex
    sta !ApuNumberWrites,x     ;  Write reg. number
    xba
    sta !ApuValueWrites,x     ;  Write reg. value
    inx
    stx !ApuWritesIndex       ;  Update index
    plx
    rts

;  Group of methods for the square wave 0 channel
Sq0:

;  Methods and properties for duty
.Duty

!apuReg = #$00 ;$4000

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

..WriteX:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

..WriteY:
    php
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

;  Methods and properties for pitch sweep
.Sweep

!apuReg = #$01 ;$4001

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

..WriteY:
    php
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

;  Methods and properties for the timer
.Timer

!apuReg = #$02 ;$4002

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

..WriteX:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

..WriteXIndexed:
    php
    xba
    txa     ;  [X] has the apu base reg.
    inc : inc ; base+!apuReg

    jsr EnqueueApuWrite
    plp
    rts

;  Methods and properties for note length
.Length

!apuReg = #$03 ;$4003

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

..WriteXIndexed:
    php
    xba
    txa     ;  [X] has the apu reg.
    inc : inc : inc ; base+!apuReg
    jsr EnqueueApuWrite
    plp
    rts

;  Group of methods for the square wave 1 channel
Sq1:

;  Methods and properties for duty
.Duty

!apuReg = #$04 ;$4004

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

..WriteX:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

;  Methods and properties for pitch sweep
.Sweep

!apuReg = #$05 ;$4005

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

..WriteY:
    php
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts   

.Timer

!apuReg = #$06 ;$4006

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

.Length

!apuReg = #$07 ;$4007

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

;  Group of methods for the triangle channel
Tri:

;  Methods and properties for linear
.Linear

!apuReg = #$08 ;$4008

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts


..WriteX:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

..WriteY:
    php
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts   

;  Group of methods for the noise channel
Noise:

;  Methods and properties for volume
.Volume

!apuReg = #$0c ;$400c

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

..WriteX:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

;  Methods and properties for noise frequency
.Period

!apuReg = #$0e ;$400e

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

..WriteX:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

;  Methods and properties for note length
.Length

!apuReg = #$0f ;$400f

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

..WriteY:
    php
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts   

Dmc:

.Frequency

!apuReg = #$10 ;$4010

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

.Address

!apuReg = #$12 ;$4012

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

.Length

!apuReg = #$13 ;$4013

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

Apu:

.Control

!apuReg = #$15 ;$4015

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

..WriteX:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

.FrameCounter

!apuReg = #$17 ;$4017

..WriteA:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts
