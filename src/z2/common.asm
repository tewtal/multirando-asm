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
    sep #$30
    lda $4210
    jsl SnesOamDMA
    jsl SnesProcessPPUString
    jsl SnesProcessCHRRequest
    ;jsl nes_overlay_handle
    ;jsl SnesApplyBGPriority

    php
    bit $0100
    jmp $C07f

; Replace the NES NMI end with a SNES-specific one and allow hooking of NMI after any standard code
NMIEnd:
    jsl SnesUpdateAudio    
    jsl SnesProcessFrame

    lda $ff
    ora #$80
    sta $ff
    jsr WritePPUCTRL
    pla

    plp : plb : ply : plx : pla
    rti

; Replace the NES NMI end with a SNES-specific one and allow hooking of NMI after any standard code
NMIEnd_Bank5:
    jsl SnesUpdateAudio    
    jsl SnesProcessFrame

    lda $ff
    ora #$80
    sta $ff
    jsr WritePPUCTRL

    plp : plb : ply : plx : pla
    rti

NMIEnd_Code1:
    pla
    plp

    jsl SnesUpdateAudio    
    jsl SnesProcessFrame

    plp : plb : ply : plx : pla
    rti


; Emulate MMC1 PRG bank switch, bank number in A
; This instead uses the SNES banks to simulate NES PRG banking
; It also overwrites the NMI code in I-RAM so that it uses the correct bank when entering NMI
MMCWriteReg3:
    PHA
    CLC : ADC #!BASE_BANK
    PHA : PLB
    STA z2_NMIJumpBank
    STA z2_BankSwitchBank
    REP #$20
    LDA #.continue : STA z2_BankSwitchAddr
    JML.w [z2_BankSwitchAddr]
    .continue
    SEP #$20
    PLA
    RTS

; Emulate MMC1 CHR Bank 0 switch, bank number in A
MMCWriteReg1:
    sta.w z2_ChrBank0Request
    rts

; PPU Update routines    
WritePPUCTRL:
    ;sta PPUCNT0ZP
    pha
    and #$80
    ;ora #$01    ; Always keep auto-joypad read active
    sta.l $004200
    pla
    rts

WritePPUCTRL_x:
    pha
    txa
    ;sta PPUCNT0ZP
    and #$80
    ;ora #$01    ; Always keep auto-joypad read active
    sta.l $004200
    pla
    rts


WritePPUCTRL1:
    ;sta PPUCNT1ZP
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
    stz.w z2_CurVScroll
    stz.w z2_CurHScroll
    ;jsl UpdateScrollHDMA
    rts

print "sttb = ", pc
SnesTransferTileBuf:
    lda #$01
    sta.w z2_TransferSourceSet
    phb : pla : sta $02
    jsl SnesPPUPrepare
    rts

ChrRomTable:
    dl chr_rom_0 : db $00
    dl chr_rom_1 : db $00
    dl chr_rom_2 : db $00
    dl chr_rom_3 : db $00