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

    jsl SnesProcessFrame

    plp : plb : ply : plx : pla
    rti

;  After z2 sound routine 1, sends the register writes batch to the apu for processing
AudioRoutine1:
    jsl SnesUpdateAudio

    ;  Native code
    LDA      #$00                      ; 0x18020 $8010 A9 00
    STA      $EB                       ; 0x18022 $8012 85 EB
    STA      $EA                       ; 0x18024 $8014 85 EA
rts

;  After z2 sound routine 2, sends the register writes batch to the apu for processing
AudioRoutine2:
    jsl SnesUpdateAudio

    ;  Native code
    LDA      #$00                      ; 0x19032 $9022 A9 00
    STA      $EF                       ; 0x19034 $9024 85 EF
    STA      $EE                       ; 0x19036 $9026 85 EE
    STA      $ED                       ; 0x19038 $9028 85 ED
    STA      $EC                       ; 0x1903a $902A 85 EC
    STA      $EB                       ; 0x1903c $902C 85 EB
    STA      $E9                       ; 0x1903e $902E 85 E9
rts

;  Handles one-off $4015 writes that do not call the main sound routines (e.g., when game is paused)
AudioShortCircuitedStatus_WriteA:
    jsr Apu_Control_WriteA
    jsl SnesUpdateAudio
rts

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