print "apu-routines = ", pc

!ApuWritesIndex = $0900
!ApuWrites      = $0901
!ApuIo0        = $2140
!ApuIo1        = $2141
!ApuIo2        = $2142
!SpcReadyValue = #$7d
!CpuReadyValue = #$d7
!CpuDoneValue  = #$ff

; APU Update routines
SnesUpdateAudio:
    phx : phy : pha : php
    sep #$30

;     lda $915
;     bne +
;     ; silence everything
;     ldx #$00
; -
;     stz $900, x
;     inx
;     cpx #$17
;     bne -

; +

    ;  cpu<->apu handshake
    lda !ApuIo0
    cmp !SpcReadyValue    ;  Check for spc readiness
    beq +
    jmp .end
+

    lda #$f5
    sta !ApuIo2           ;  Init index to an invalid value (refactor this later)
    lda !CpuReadyValue    ;  Indicate cpu readiness
    sta !ApuIo0

-   ;  spc ack wait loop
    lda !ApuIo0
    cmp !CpuReadyValue
    bne -
    ;  end handshake

;  spc now ready to receive data
;; Transfers a variable length queue of audio register writes
;; to the spc-700 receiving loop in ../nes-spc/apu-recv.asm:11
    ldx #$00
--
    cpx !ApuWritesIndex     ;  Exit condition
    beq .finishedTransfer

    lda !ApuWrites,x
    sta !ApuIo0     ;  Send the apu index
    inx

    lda !ApuWrites,x
    sta !ApuIo1     ;  Send the apu value
    dex : stx !ApuIo2     ;  Send the current write index
    inx : inx       ;  Next write index

    ;  spc ack wait loop
-   cpx !ApuIo2
    bne -

    bra --          ;  Next iteration

.finishedTransfer:
    stz !ApuWritesIndex     ;  Reset queue
    lda !CpuDoneValue
    sta !ApuIo2         ;  Send "I'm done" value; no need to wait for ack

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
    sta !ApuWrites,x     ;  Write reg. number
    inx
    xba
    sta !ApuWrites,x     ;  Write reg. value
    inx
    stx !ApuWritesIndex       ;  Update index
    plx
    rts

!apuReg = #$00 ;$4000

WriteAPUSq0Ctrl0:
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    rts

WriteAPUSq0Ctrl0_I_Y:
    xba
    tya     ;  [Y] has the apu reg.
    jsr EnqueueApuWrite
    ; sta.w APUBase, y
    rts

WriteAPUSq0Ctrl0_Y:
    pha
    tya
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sty.w APUBase
    pla
    rts

WriteAPUSq0Ctrl0_X:
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; stx.w APUBase
    pla
    rts

!apuReg = #$01 ;$4001

WriteAPUSq0Ctrl1:
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; xba
    ; lda #$40
    ; tsb.w APUBase+$16
    ; xba
    ; sta.w APUBase+$01
    rts

WriteAPUSq0Ctrl1_Y:
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
    rts    

;  TODO: deprecate
WriteAPUSq0Ctrl1_I_Y:
    xba
    tya     ;  [Y] has the apu reg.
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
    rts

!apuReg = #$02 ;$4002

WriteAPUSq0Ctrl2:
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sta.w APUBase+$02
    rts

WriteAPUSq0Ctrl2_X:
    pha
    txa
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; stx.w APUBase+$02
    pla
    rts

;  TODO: deprecate
WriteAPUSq0Ctrl2_I_Y:
    xba
    tya     ;  [Y] has the apu reg.
    jsr EnqueueApuWrite
    ; sta.w APUBase+$02, y
    rts

!apuReg = #$03 ;$4003

WriteAPUSq0Ctrl3:
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
    rts

WriteAPUSq0Ctrl3_X:
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
    rts

;  TODO: deprecate
WriteAPUSq0Ctrl3_I_Y:
    xba
    tya     ;  [Y] has the apu reg.
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
    rts



;  TODO: implement all channels below


WriteAPUSq1Ctrl0:
    ; sta.w APUBase+$04
    rts

WriteAPUSq1Ctrl0_X:
    ; stx.w APUBase+$04
    rts

WriteAPUSq1Ctrl0_Y:
    ; sty.w APUBase+$04
    rts

WriteAPUSq1Ctrl1:
    ; xba
    ; lda #$80
    ; tsb.w APUBase+$16
    ; xba
    ; sta.w APUBase+$05
    rts

WriteAPUSq1Ctrl1_X:
    ; xba
    ; lda #$80
    ; tsb.w APUBase+$16
    ; xba
    ; stx.w APUBase+$05
    rts   

WriteAPUSq1Ctrl1_Y:
    ; xba
    ; lda #$80
    ; tsb.w APUBase+$16
    ; xba
    ; sty.w APUBase+$05
    rts   

WriteAPUSq1Ctrl2:
    ; sta.w APUBase+$06
    rts

WriteAPUSq1Ctrl2_X:
    ; stx.w APUBase+$06
    rts

WriteAPUSq1Ctrl3:
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
    rts

WriteAPUSq1Ctrl3_X:
    ; pha
    ; stx.w APUBase+$07
    ; lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    ; sta.w APUSq1Length
    ; lda #$02
    ; tsb.w APUBase+$15
    ; tsb.w APUExtraControl   
    ; pla
    rts

WriteAPUTriCtrl0:
    ; sta.w APUBase+$08
    rts

WriteAPUTriCtrl1:
    ; sta.w APUBase+$09
    rts

WriteAPUTriCtrl2:
    ; sta.w APUBase+$0A
    rts

WriteAPUTriCtrl2_X:
    ; stx.w APUBase+$0A
    rts

WriteAPUTriCtrl3:
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
    rts

WriteAPUNoiseCtrl0:
    ; sta.w APUBase+$0C
    rts

WriteAPUNoiseCtrl1:
    ; sta.w APUBase+$0D
    rts

WriteAPUNoiseCtrl2:
    ; sta.w APUBase+$0E
    rts

WriteAPUNoiseCtrl2_X:
    ; stx.w APUBase+$0E
    rts

WriteAPUNoiseCtrl3:
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
    rts

WriteAPUControl:
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
    rts

!apuReg = #$17 ;$4017

WriteApuFrameCounter:
    xba
    lda !apuReg
    jsr EnqueueApuWrite
    ; sta ApuFrameCounter
    ; lda #$20
    ; tsb.w APUExtraControl
rts

WriteAPUDMCCounter:
    ; stx.w DmcCounter_4011
rts

WriteAPUDMCFreq:
    ; sta DmcFreq_4010
rts

WriteAPUDMCAddr:
    ; sta DmcAddress_4012
rts

WriteAPUDMCLength:
    ; sta DmcLength_4013
rts

WriteAPUDMCPlay:
    ; sta ApuStatus_4015
    ; and #%00010000
    ; sta APUExtraControl
rts


; Sound__EmulateLengthCounter_length_d3_mixed:
; fillbyte $06 : fill 8
; fillbyte $80 : fill 8
; fillbyte $0B : fill 8
; fillbyte $02 : fill 8
; fillbyte $15 : fill 8
; fillbyte $03 : fill 8
; fillbyte $29 : fill 8
; fillbyte $04 : fill 8
; fillbyte $51 : fill 8
; fillbyte $05 : fill 8
; fillbyte $1F : fill 8
; fillbyte $06 : fill 8
; fillbyte $08 : fill 8
; fillbyte $07 : fill 8
; fillbyte $0F : fill 8
; fillbyte $08 : fill 8
; fillbyte $07 : fill 8
; fillbyte $09 : fill 8
; fillbyte $0D : fill 8
; fillbyte $0A : fill 8
; fillbyte $19 : fill 8
; fillbyte $0B : fill 8
; fillbyte $31 : fill 8
; fillbyte $0C : fill 8
; fillbyte $61 : fill 8
; fillbyte $0D : fill 8
; fillbyte $25 : fill 8
; fillbyte $0E : fill 8
; fillbyte $09 : fill 8
; fillbyte $0F : fill 8
; fillbyte $11 : fill 8
; fillbyte $10 : fill 8
