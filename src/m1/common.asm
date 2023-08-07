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
    sep #$30
    lda $4210
    jsl UpdateScrollHDMA
    jmp $C0DF

; Replace the NES NMI end with a SNES-specific one and allow hooking of NMI after any standard code
NMIEnd:
    jsl SnesUpdateAudio
    plp : plb : ply : plx : pla
    jmp $C113

; PPU Update routines    
WritePPUCTRL:
    sta PPUCNT0ZP
    pha
    and #$80
    sta $4200
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
    sta $2100
    pla
    rts

; This method will jump to a pointer found in a table pointed to by the long
; address after the call to this routine
ChooseRoutineExtended:
    phy : phx
    asl : tax

    rep #$30
    ldy.w #$0001
    lda.b ($03, s), y 
    sta.b $d0
    iny
    lda.b ($03, s), y
    sta.b $d1

    txy
    lda.b [$d0], y
    sta.b $0c
    sep #$30
    plx : ply
    pla : pla   ; Adjust stack
    jmp ($000c)

CustomItemHandler_common:
    jsl CustomItemHandler
    rts

GetEnemyData_long:
    lda [$00],y                     ;Get 1st byte again.
    and #$F0                        ;Get object slot that enemy will occupy.
    tax                             ;
    jsr $EB7a                       ;($EB7A)Check if object slot is already in use.
    bne .exit                       ;Exit if object slot taken.
    iny                             ;
    lda [$00],y                     ;Get enemy type.
    jsr GetEnemyType_long           ;($EB28)Load data about enemy.
    ldy #$02                        ;
    lda [$00],y                     ;Get enemy initial position(%yyyyxxxx).
    jsr $EB4D
    pha
.ret
    pla
.exit
    lda #$03                        ;Number of bytes to add to ptr to find next room item.
    rts

GetEnemyType_long:
    pha                             ;Store enemy type.
    and #$C0                        ;If MSB is set, the "tough" version of the enemy  
    sta $040F,x                     ;is to be loaded(more hit points, except rippers).
    asl                             ;
    bpl ++                          ;If bit 6 is set, the enemy is either Kraid or Ridley.
    lda $74                         ;Load current area Samus is in(to check if Kraid or-->
    and #$06                        ;Ridley is alive or dead).
    lsr                             ;Use InArea to find status of Kraid/Ridley statue.
    tay                             ;
    lda $687A,y                     ;Load status of Kraid/Ridley statue.
    beq +                           ;Branch if Kraid or Ridley needs to be loaded.
    pla                             ;
    pla                             ;Mini boss is dead so pull enemy info and last address off-->
    jmp GetEnemyData_long_ret       ;stack so next enemy/door item can be loaded.

+   lda #$01                        ;Samus is in Kraid or Ridley's room and the-->
    sta $6987                       ;mini boss is alive and needs to be loaded.

++  pla                             ;Restore enemy type data.
    and #$3F                        ;Keep 6 lower bits to use as index for enemy data tables.
    sta $6B02,x                     ;Store index byte.
    rts

LoadDoor_long:
    iny
    lda [$00],y                     ;Get door type.
    jmp $EB95

InitTransitionData:
    phy
    ; Clear nametables
    jsr $C158
    ply

    ; Get bank and perform a bank switch 
    jsr $C4E2

    ; Copy room pointers
    jsr $C8B0

    ; Destroy enemies
    jsr $C8BB

    ; Erase all sprites
    jsr $C1A3

    ; Restart music
    jsr $D92C

    rtl


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

WriteAPUSq0Ctrl1:
    xba
    lda #$40
    tsb.w APUBase+$16
    xba
    sta.w APUBase+$01
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

WriteAPUSq1Ctrl2:
    sta.w APUBase+$06
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

WriteAPUTriCtrl0:
    sta.w APUBase+$08
    rts

WriteAPUTriCtrl1:
    sta.w APUBase+$09
    rts

WriteAPUTriCtrl2:
    sta.w APUBase+$0A
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


ScrollTable:
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