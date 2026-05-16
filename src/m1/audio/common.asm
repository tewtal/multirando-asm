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
    stz !ApuWritesIndex

.end
    plp : pla : ply : plx
    rtl


SendOneAudioRecord:
    phx : pha
    ;  cpu<->apu handshake
    lda !ApuIo0
    cmp !SpcReadyValue    ;  Check for spc readiness
    beq +
    jmp .end
+

    lda #$01
    sta !ApuIo2            ;  Send transfer length
    lda !CpuReadyValue     ;  Indicate cpu readiness
    sta !ApuIo0

-   lda !ApuIo0            ;  Wait for SPC to ack CPU ready
    cmp !CpuReadyValue
    bne -

    ldx #$00
    stz !ApuPacketSeq

    lda !ApuValueWrites, x
    sta !ApuIo1

    lda !ApuPacketSeq
    ora !ApuNumberWrites, x
    sta !ApuIo0
.finishedTransfer:
    stz !ApuWritesIndex

.end:
    pla : plx
    rts


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
    ;lda ($e2), y
    ;jsr WriteAPUNoiseCtrl1
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
    ; sta.w APUBase, y
    plp    
    rts

WriteAPUSq0Ctrl0_Y:
    php
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sty.w APUBase
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
    ; stx.w APUBase
    pla
    plp
    rts

!apuReg = #$01 ;$4001

WriteAPUSq0Ctrl1:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; xba
    ; lda #$40
    ; tsb.w APUBase+$16
    ; xba
    ; sta.w APUBase+$01
    plp
    rts

WriteAPUSq0Ctrl1_Y:
    php
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; xba
    ; lda #$40
    ; tsb.w APUBase+$16
    ; xba
    ; sty.w APUBase+$01
    pla
    plp
    rts    

WriteAPUSq0Ctrl1_I_Y:
    php
    xba
    tya     ;  [Y] has the apu BASE reg.
    inc
    jsr EnqueueApuWrite
;     cpy #$00
;     bne +
;     jsr WriteAPUSq0Ctrl1
;     rts
; +
;     cpy #$04
;     bne +
;     jsr WriteAPUSq1Ctrl1
;     rts
; +
;     sta $0901, y
    plp
    rts

!apuReg = #$02 ;$4002

WriteAPUSq0Ctrl2:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sta.w APUBase+$02
    plp
    rts

WriteAPUSq0Ctrl2_X:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; stx.w APUBase+$02
    pla
    plp
    rts

WriteAPUSq0Ctrl2_I_Y:
    php
    xba
    tya     ;  [Y] has the apu BASE reg.
    inc : inc
    jsr EnqueueApuWrite
    ; sta.w APUBase+$02, y
    plp
    rts

!apuReg = #$03 ;$4003

WriteAPUSq0Ctrl3:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; phx
    ; sta.w APUBase+$03
    ; tax
    ; lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    ; sta.w APUSq0Length
    ; xba
    ; lda #$01
    ; tsb.w APUBase+$15
    ; tsb.w APUExtraControl
    ; plx
    ; xba
    plp
    rts

WriteAPUSq0Ctrl3_X:
    php
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; pha
    ; stx.w APUBase+$03
    ; lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    ; sta.w APUSq0Length
    ; lda #$01
    ; tsb.w APUBase+$15
    ; tsb.w APUExtraControl   
    ; pla
    pla
    plp
    rts

WriteAPUSq0Ctrl3_I_Y:
    php
    xba
    tya     ;  [Y] has the apu BASE reg.
    clc : adc #$03
    jsr EnqueueApuWrite
;     cpy #$00
;     bne +
;     jsr WriteAPUSq0Ctrl3
;     rts
; +
;     cpy #$04
;     bne +
;     jsr WriteAPUSq1Ctrl3
;     rts
; +
;     cpy #$08
;     bne +
;     jsr WriteAPUTriCtrl3
;     rts
; +
;     jsr WriteAPUNoiseCtrl3    
    plp
    rts

!apuReg = #$04 ;$4004

WriteAPUSq1Ctrl0:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sta.w APUBase+$04
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
    ; stx.w APUBase+$04
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
    ; sty.w APUBase+$04
    plp
    rts

!apuReg = #$05 ;$4005

WriteAPUSq1Ctrl1:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; xba
    ; lda #$80
    ; tsb.w APUBase+$16
    ; xba
    ; sta.w APUBase+$05
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
    ; xba
    ; lda #$80
    ; tsb.w APUBase+$16
    ; xba
    ; stx.w APUBase+$05
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
    ; xba
    ; lda #$80
    ; tsb.w APUBase+$16
    ; xba
    ; sty.w APUBase+$05
    plp
    rts   

!apuReg = #$06 ;$4006

WriteAPUSq1Ctrl2:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sta.w APUBase+$06
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
    ; stx.w APUBase+$06
    plp
    rts

!apuReg = #$07 ;$4007

WriteAPUSq1Ctrl3:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; phx
    ; sta.w APUBase+$07
    ; tax
    ; lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    ; sta.w APUSq1Length
    ; xba
    ; lda #$02
    ; tsb.w APUBase+$15
    ; tsb.w APUExtraControl
    ; plx
    ; xba
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
    ; pha
    ; stx.w APUBase+$07
    ; lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    ; sta.w APUSq1Length
    ; lda #$02
    ; tsb.w APUBase+$15
    ; tsb.w APUExtraControl   
    ; pla
    plp
    rts

!apuReg = #$08 ;$4008

WriteAPUTriCtrl0:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sta.w APUBase+$08
    plp
    rts

!apuReg = #$09 ;$4009

WriteAPUTriCtrl1:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sta.w APUBase+$09
    plp
    rts

!apuReg = #$0a ;$400a

WriteAPUTriCtrl2:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sta.w APUBase+$0A
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
    ; stx.w APUBase+$0A
    plp
    rts

!apuReg = #$0b ;$400b

WriteAPUTriCtrl3:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; phx
    ; sta.w APUBase+$0B
    ; tax
    ; lda #$04
    ; tsb.w APUExtraControl
    ; tsb.w APUBase+$15
    ; lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    ; sta.w APUTriLength
    ; txa
    ; plx
    plp
    rts

!apuReg = #$0c ;$400c

WriteAPUNoiseCtrl0:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sta.w APUBase+$0C
    plp
    rts

; !apuReg = #$0d ;$400d

; WriteAPUNoiseCtrl1:
;     php
;     xba
;     lda !apuReg
;     jsr EnqueueApuWrite
;     ; sta.w APUBase+$0D
;     plp
;     rts

!apuReg = #$0e ;$400e

WriteAPUNoiseCtrl2:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sta.w APUBase+$0E
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
    ; stx.w APUBase+$0E
    plp
    rts

!apuReg = #$0f ;$400f

WriteAPUNoiseCtrl3:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; phx
    ; sta.w APUBase+$0F
    ; tax
    ; lda #$08
    ; tsb.w APUExtraControl
    ; tsb.w APUBase+$15
    ; lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    ; sta.w APUNoiLength
    ; txa
    ; plx
    plp
    rts

!apuReg = #$15 ;$4015

WriteAPUControl:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
;     sta.w APUIOTemp
;     xba
;     lda.w APUIOTemp
;     eor.b #$ff
;     and.b #$1f
;     trb.w APUBase+$15
;     trb.w APUExtraControl
;     lsr.w APUIOTemp
;     bcs +
;         stz.w APUBase+$03
;         stz.w APUSq0Length
; +
;     lsr.w APUIOTemp
;     bcs +
;         stz.w APUBase+$07
;         stz.w APUSq1Length
; +
;     lsr.w APUIOTemp
;     bcs +
;         stz.w APUBase+$0B
;         stz.w APUTriLength
; +
;     lsr.w APUIOTemp
;     bcs +
;         stz.w APUBase+$0F
;         stz.w APUNoiLength
; +
;     lsr.w APUIOTemp
;     bcc +
;         lda.b #$10
;         tsb.w APUBase+$15
;         bne +
;             tsb.w APUExtraControl
; +
;     xba
    plp
    rts

!apuReg = #$17 ;$4017

WriteApuFrameCounter:
    php
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sta ApuFrameCounter
    ; lda #$20
    ; tsb.w APUExtraControl
    plp
    rts
