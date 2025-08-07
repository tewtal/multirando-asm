CommonBankStart:
LongJumpToRoutine_common:    
    php
    rep #$30

    pha
    lda $04, s
    inc
    sta $d0
    lda $06, s
    sta $d2

    lda [$d0]
    sta $d0

    lda $04, s
    inc #2
    sta $04, s
    pla
    
    sep #$30
    phb : phk : plb
    pea .ret-1
    jmp ($00d0)
.ret
    plb : plp
    rtl

; Replace the NES NMI start with a SNES-specific one and allow hooking of NMI before any standard code
NMIStart:
    pha : phx : phy : phb : php
    phk : plb

    jsl ResetBg1hofs

    sep #$30
    lda $4210
    jsl SnesOamDMA
    jsl SnesProcessPPUString
    jsl nes_overlay_handle

    lda.b z1FrameCounter
    jsl nes_UpdateItemAnimations

    jsl SnesApplyBGPriority

    lda $ff
    ldx $5c
    jmp $E488

; Replace the NES NMI end with a SNES-specific one and allow hooking of NMI after any standard code
NMIEnd:
    jsl SnesUpdateAudio
    jsl SnesProcessFrame
    plp : plb : ply : plx : pla
    jmp $E576

print "sttb = ", pc
SnesTransferTileBuf:
    lda #$01
    sta.w TransferSourceSet
    phb : pla : sta $02
    jsl SnesPPUPrepare
    rts

; Emulate MMC1 PRG bank switch, bank number in A
; This instead uses the SNES banks to simulate NES PRG banking
; It also overwrites the NMI code in I-RAM so that it uses the correct bank when entering NMI
MMCWriteReg3:
    PHA
    CLC : ADC #!BASE_BANK
    PHA : PLB
    STA NMIJumpBank
    STA BankSwitchBank
    REP #$20
    LDA #.continue : STA BankSwitchAddr
    JML.w [BankSwitchAddr]
    .continue
    SEP #$20
    PLA
    RTS

; PPU Update routines    
WritePPUCTRL:
    sta PPUCNT0ZP
    pha
    and #$80
    ora #$01    ; Always keep auto-joypad read active
    sta.l $004200
    pla
    rts

WritePPUCTRL1:
    sta PPUCNT1ZP
    pha
    and #$18
    beq .blank
    lda #$0f
    bra +
.blank
    lda #$8f
+
    sta.l $002100
    pla
    rts

WritePPUCTRL1AndResetScroll:
    jsr WritePPUCTRL1
    stz.w CurVScroll
    stz.w CurHScroll
    jsl UpdateScrollHDMA
    rts

; Params:
; [00:01]: source address
; [03:02]: size
; A: low byte of desination VRAM address

SnesTransferPatternBlock:
    PHX : PHY
    STA PPUAddrTmpLo
   
    lda #$8f
    sta $2100

    LDA PPUAddrTmpLo
    STA $2116

    LDA PPUAddrTmpHi
    STA $2117

    REP #$20
    LDA $02 : XBA : STA $02
    SEP #$20

    LDA #$80
    STA $2115       ; PPU increment

.Loop
    ; Do some trickery to convert NES 2bpp -> SNES 4bpp

    LDY #$08
    LDX #$08

-
    LDA ($00)
    STA $2118
    LDA ($00), Y
    STA $2119

    REP #$20
    INC $00
    DEC $02
    LDA $02
    BEQ .Exit
    SEP #$20

    DEX
    BNE -

    REP #$20
    LDA $00
    CLC : ADC #$0008
    STA $00
    LDA $02
    CMP #$0008
    BCC .Exit
    SEC : SBC #$0008
    STA $02
    LDX #$08
-
    STZ $2118
    DEX
    BNE -

    LDA $02
    BEQ .Exit

    SEP #$20
    BRA .Loop

.Exit
    SEP #$20
    PLY : PLX

    ; The block is done. Increment the block index.
    INC.w PatternBlockIndex
    
    lda PPUCNT1ZP : jsr WritePPUCTRL1
    RTS

;
; Look up and transfer destination PPU address by PatternBlockIndex.
;

PatternBlockPpuAddrs:
    db $17, $00
    db $08, $E0

PatternBlockPpuAddrsExtra:
    db $09, $E0
    db $0C, $00

SnesTransferPatternBlock_Indexed:
    PHX : PHY : PHP

    lda #$8f
    sta $2100

    LDA PatternBlockIndex
    ASL
    TAX
    LDA PatternBlockPpuAddrs, X
    STA $2117
    INX
    LDA PatternBlockPpuAddrs, X
    STA $2116


    LDA #$80
    STA $2115

    LDY #$00                    ; Start copying.

    REP #$30
    LDA $02 : XBA : STA $02
    SEP #$30

.Loop
    ; Do some trickery to convert NES 2bpp -> SNES 4bpp

    LDY #$08
    LDX #$08

-
    LDA ($00)
    STA $2118
    LDA ($00), Y
    STA $2119

    REP #$20
    INC $00
    DEC $02
    LDA $02
    BEQ .Exit
    SEP #$20

    DEX
    BNE -

    REP #$20
    LDA $00
    CLC : ADC #$0008
    STA $00
    LDA $02
    CMP #$0008
    BCC .Exit
    SEC : SBC #$0008
    STA $02
    LDX #$08
-
    STZ $2118
    DEX
    BNE -

    LDA $02
    BEQ .Exit

    SEP #$20
    BRA .Loop

.Exit
    PLP
    INC.w PatternBlockIndex       ; Mark this block finished, and we're ready for the next one.
    PLY : PLX
    lda PPUCNT1ZP : jsr WritePPUCTRL1
    RTS

CheckCaveTransitionOut_common:
if not(defined("STANDALONE"))
    jsl check_cave_transition_out
endif
    jmp $ea2b

InitMode_EnterRoom_UW_Hook:
    inc.w NeedsBGPriorityUpdate
    jsr $7013
    rts

print "apu-routines = ", pc
; APU Update routines
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
    lda ($e2), y
    jsr WriteAPUNoiseCtrl1
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

WriteAPUSq0Ctrl0:
    sta.w APUBase
    rts

WriteAPUSq0Ctrl0_I_Y:
    sta.w APUBase, y
    rts

WriteAPUSq0Ctrl0_Y:
    sty.w APUBase
    rts

WriteAPUSq0Ctrl0_X:
    stx.w APUBase
    rts

WriteAPUSq0Ctrl1:
    xba
    lda #$40
    tsb.w APUBase+$16
    xba
    sta.w APUBase+$01
    rts

WriteAPUSq0Ctrl1_Y:
    xba
    lda #$40
    tsb.w APUBase+$16
    xba
    sty.w APUBase+$01
    rts    

WriteAPUSq0Ctrl1_I_Y:
    cpy #$00
    bne +
    jsr WriteAPUSq0Ctrl1
    rts
+
    cpy #$04
    bne +
    jsr WriteAPUSq1Ctrl1
    rts
+
    sta $0901, y
    rts

WriteAPUSq0Ctrl2:
    sta.w APUBase+$02
    rts

WriteAPUSq0Ctrl2_X:
    stx.w APUBase+$02
    rts

WriteAPUSq0Ctrl2_I_Y:
    sta.w APUBase+$02, y
    rts

WriteAPUSq0Ctrl3:
    phx
    sta.w APUBase+$03
    tax
    lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    sta.w APUSq0Length
    xba
    lda #$01
    tsb.w APUBase+$15
    tsb.w APUExtraControl
    plx
    xba
    rts

WriteAPUSq0Ctrl3_X:
    pha
    stx.w APUBase+$03
    lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    sta.w APUSq0Length
    lda #$01
    tsb.w APUBase+$15
    tsb.w APUExtraControl   
    pla
    rts

WriteAPUSq0Ctrl3_I_Y:
    cpy #$00
    bne +
    jsr WriteAPUSq0Ctrl3
    rts
+
    cpy #$04
    bne +
    jsr WriteAPUSq1Ctrl3
    rts
+
    cpy #$08
    bne +
    jsr WriteAPUTriCtrl3
    rts
+
    jsr WriteAPUNoiseCtrl3    
    rts

WriteAPUSq1Ctrl0:
    sta.w APUBase+$04
    rts

WriteAPUSq1Ctrl0_X:
    stx.w APUBase+$04
    rts

WriteAPUSq1Ctrl0_Y:
    sty.w APUBase+$04
    rts

WriteAPUSq1Ctrl1:
    xba
    lda #$80
    tsb.w APUBase+$16
    xba
    sta.w APUBase+$05
    rts

WriteAPUSq1Ctrl1_X:
    xba
    lda #$80
    tsb.w APUBase+$16
    xba
    stx.w APUBase+$05
    rts   

WriteAPUSq1Ctrl1_Y:
    xba
    lda #$80
    tsb.w APUBase+$16
    xba
    sty.w APUBase+$05
    rts   

WriteAPUSq1Ctrl2:
    sta.w APUBase+$06
    rts

WriteAPUSq1Ctrl2_X:
    stx.w APUBase+$06
    rts

WriteAPUSq1Ctrl3:
    phx
    sta.w APUBase+$07
    tax
    lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    sta.w APUSq1Length
    xba
    lda #$02
    tsb.w APUBase+$15
    tsb.w APUExtraControl
    plx
    xba
    rts

WriteAPUSq1Ctrl3_X:
    pha
    stx.w APUBase+$07
    lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    sta.w APUSq1Length
    lda #$02
    tsb.w APUBase+$15
    tsb.w APUExtraControl   
    pla
    rts

WriteAPUTriCtrl0:
    sta.w APUBase+$08
    rts

WriteAPUTriCtrl1:
    sta.w APUBase+$09
    rts

WriteAPUTriCtrl2:
    sta.w APUBase+$0A
    rts

WriteAPUTriCtrl2_X:
    stx.w APUBase+$0A
    rts

WriteAPUTriCtrl3:
    phx
    sta.w APUBase+$0B
    tax
    lda #$04
    tsb.w APUExtraControl
    tsb.w APUBase+$15
    lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    sta.w APUTriLength
    txa
    plx
    rts

WriteAPUNoiseCtrl0:
    sta.w APUBase+$0C
    rts

WriteAPUNoiseCtrl1:
    sta.w APUBase+$0D
    rts

WriteAPUNoiseCtrl2:
    sta.w APUBase+$0E
    rts

WriteAPUNoiseCtrl2_X:
    stx.w APUBase+$0E
    rts

WriteAPUNoiseCtrl3:
    phx
    sta.w APUBase+$0F
    tax
    lda #$08
    tsb.w APUExtraControl
    tsb.w APUBase+$15
    lda.w Sound__EmulateLengthCounter_length_d3_mixed, x
    sta.w APUNoiLength
    txa
    plx
    rts

WriteAPUControl:
    sta.w APUIOTemp
    xba
    lda.w APUIOTemp
    eor.b #$ff
    and.b #$1f
    trb.w APUBase+$15
    trb.w APUExtraControl
    lsr.w APUIOTemp
    bcs +
        stz.w APUBase+$03
        stz.w APUSq0Length
+
    lsr.w APUIOTemp
    bcs +
        stz.w APUBase+$07
        stz.w APUSq1Length
+
    lsr.w APUIOTemp
    bcs +
        stz.w APUBase+$0B
        stz.w APUTriLength
+
    lsr.w APUIOTemp
    bcs +
        stz.w APUBase+$0F
        stz.w APUNoiLength
+
    lsr.w APUIOTemp
    bcc +
        lda.b #$10
        tsb.w APUBase+$15
        bne +
            tsb.w APUExtraControl
+
    xba
    rts

WriteAPUDMCCounter:
    stx.w DmcCounter_4011
rts

WriteAPUDMCFreq:
    sta DmcFreq_4010
rts

WriteAPUDMCAddr:
    sta DmcAddress_4012
rts

WriteAPUDMCLength:
    sta DmcLength_4013
rts

WriteAPUDMCPlay:
    sta ApuStatus_4015
    and #%00010000
    sta APUExtraControl
rts


Sound__EmulateLengthCounter_length_d3_mixed:
fillbyte $06 : fill 8
fillbyte $80 : fill 8
fillbyte $0B : fill 8
fillbyte $02 : fill 8
fillbyte $15 : fill 8
fillbyte $03 : fill 8
fillbyte $29 : fill 8
fillbyte $04 : fill 8
fillbyte $51 : fill 8
fillbyte $05 : fill 8
fillbyte $1F : fill 8
fillbyte $06 : fill 8
fillbyte $08 : fill 8
fillbyte $07 : fill 8
fillbyte $0F : fill 8
fillbyte $08 : fill 8
fillbyte $07 : fill 8
fillbyte $09 : fill 8
fillbyte $0D : fill 8
fillbyte $0A : fill 8
fillbyte $19 : fill 8
fillbyte $0B : fill 8
fillbyte $31 : fill 8
fillbyte $0C : fill 8
fillbyte $61 : fill 8
fillbyte $0D : fill 8
fillbyte $25 : fill 8
fillbyte $0E : fill 8
fillbyte $09 : fill 8
fillbyte $0F : fill 8
fillbyte $11 : fill 8
fillbyte $10 : fill 8

SnesResetVerticalGameScroll:
    pha
    sta $0106
    lda CurVScroll
    beq +
    stz.w CurVScroll
    jsl UpdateVScrollHDMA
+   
    pla
    rts

HScrollTable:
.sblen
db $01
.sbval
dw $0000
.len
db $01
.val
dw $0000
db $00

VScrollTable:
.sblen
db $01
.sbval
dw $000f
.len1
db $7F
.val1
dw $0000
.len2
db $01
.val2
dw $0000
.len3
db $01
.val3
dw $0000
db $00

CommonBankEnd: