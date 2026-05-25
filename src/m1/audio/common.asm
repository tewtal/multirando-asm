; APU Update routines

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

    sty !ApuIo2            ;  Send transfer length
    lda !CpuReadyValue     ;  Indicate cpu readiness
    sta !ApuIo0

-   lda !ApuIo0            ;  Wait for SPC to ack CPU ready
    cmp !CpuReadyValue
    bne -

    ldx #$00
    stz !ApuPacketSeq
.transferLoop:
    lda !ApuValueWrites, x
    sta !ApuIo1

    cpy #$01
    beq .sendSingle

    inx
    lda !ApuNumberWrites, x
    sta !ApuIo2

    lda !ApuValueWrites, x
    sta !ApuIo3

    dex
    lda !ApuPacketSeq
    ora !ApuNumberWrites, x
    sta !ApuIo0

    inx
    inx
    dey
    dey
    beq .finishedTransfer

    lda !ApuPacketSeq
    clc
    adc #$20
    and #$e0
    sta !ApuPacketSeq

-   lda !ApuIo0
    and #$e0
    cmp !ApuPacketSeq
    bne -

    bra .transferLoop

.sendSingle:
    lda !ApuPacketSeq
    ora !ApuNumberWrites, x
    sta !ApuIo0

.finishedTransfer:
-   lda !ApuIo0
    cmp !SpcReadyValue      ; wait until SPC has reached Done and published $7d
    bne -
    stz !ApuIo0             ; leave SPC-readable CPU->APU port 0 as fixed benign value
    stz !ApuWritesIndex     ;  Reset queue

.end
    plp : pla : ply : plx
    rtl


LoadSFXRegisters:
    lda $e0
    cmp #$00
    beq .sq1
    cmp #$04
    beq .sq2
    cmp #$08
    beq .tri
.noise
    lda ($e2), y
    jsr WriteAPUNoiseCtrl0
    iny
    ;  Don't write to unused register $400d (sloppy m1 devs)
    iny
    lda ($e2), y
    jsr WriteAPUNoiseCtrl2
    iny
    lda ($e2), y
    jsr WriteAPUNoiseCtrl3
    iny
    bra .end
.sq1
    lda ($e2), y
    jsr WriteAPUSq0Ctrl0
    iny
    lda ($e2), y
    jsr WriteAPUSq0Ctrl1
    iny
    lda ($e2), y
    jsr WriteAPUSq0Ctrl2
    iny
    lda ($e2), y
    jsr WriteAPUSq0Ctrl3
    iny
    bra .end
.sq2
    lda ($e2), y
    jsr WriteAPUSq1Ctrl0
    iny
    lda ($e2), y
    jsr WriteAPUSq1Ctrl1
    iny
    lda ($e2), y
    jsr WriteAPUSq1Ctrl2
    iny
    lda ($e2), y
    jsr WriteAPUSq1Ctrl3
    iny
    bra .end
.tri
    lda ($e2), y
    jsr WriteAPUTriCtrl0
    iny
    lda ($e2), y
    jsr WriteAPUTriCtrl1
    iny
    lda ($e2), y
    jsr WriteAPUTriCtrl2
    iny
    lda ($e2), y
    jsr WriteAPUTriCtrl3
    iny
    bra .end
.end
    lda #$00
    rts


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

!apuReg = #$00 ;$4000

WriteAPUSq0Ctrl0:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

WriteAPUSq0Ctrl0_I_Y:
    php
    xba
    tya     ;  [Y] has the apu BASE reg.
    jsr EnqueueApuWrite
    plp    
    rts

WriteAPUSq0Ctrl0_Y:
    php
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

WriteAPUSq0Ctrl0_X:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

!apuReg = #$01 ;$4001

WriteAPUSq0Ctrl1:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

WriteAPUSq0Ctrl1_Y:
    php
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts    

WriteAPUSq0Ctrl1_I_Y:
    php
    xba
    tya     ;  [Y] has the apu BASE reg.
    inc
    jsr EnqueueApuWrite
    plp
    rts

!apuReg = #$02 ;$4002

WriteAPUSq0Ctrl2:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

WriteAPUSq0Ctrl2_X:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

WriteAPUSq0Ctrl2_I_Y:
    php
    xba
    tya     ;  [Y] has the apu BASE reg.
    inc : inc
    jsr EnqueueApuWrite
    plp
    rts

!apuReg = #$03 ;$4003

WriteAPUSq0Ctrl3:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

WriteAPUSq0Ctrl3_X:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

WriteAPUSq0Ctrl3_I_Y:
    php
    xba
    tya     ;  [Y] has the apu BASE reg.
    clc : adc #$03
    jsr EnqueueApuWrite
    plp
    rts

!apuReg = #$04 ;$4004

WriteAPUSq1Ctrl0:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

WriteAPUSq1Ctrl0_X:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

WriteAPUSq1Ctrl0_Y:
    php
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

!apuReg = #$05 ;$4005

WriteAPUSq1Ctrl1:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

WriteAPUSq1Ctrl1_X:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts   

WriteAPUSq1Ctrl1_Y:
    php
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts   

!apuReg = #$06 ;$4006

WriteAPUSq1Ctrl2:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

WriteAPUSq1Ctrl2_X:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

!apuReg = #$07 ;$4007

WriteAPUSq1Ctrl3:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

WriteAPUSq1Ctrl3_X:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

!apuReg = #$08 ;$4008

WriteAPUTriCtrl0:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

!apuReg = #$09 ;$4009

WriteAPUTriCtrl1:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

!apuReg = #$0a ;$400a

WriteAPUTriCtrl2:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

WriteAPUTriCtrl2_X:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

!apuReg = #$0b ;$400b

WriteAPUTriCtrl3:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

!apuReg = #$0c ;$400c

WriteAPUNoiseCtrl0:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

!apuReg = #$0e ;$400e

WriteAPUNoiseCtrl2:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

WriteAPUNoiseCtrl2_X:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    pla
    plp
    rts

!apuReg = #$0f ;$400f

WriteAPUNoiseCtrl3:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

!apuReg = #$15 ;$4015

WriteAPUControl:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts

!apuReg = #$17 ;$4017

WriteApuFrameCounter:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    plp
    rts
