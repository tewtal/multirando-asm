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

    ;  Run standard z1 nmi start code:
    lda $ff
    ldx $5c
    jmp $E488


; Replace the NES NMI end with a SNES-specific one and allow hooking of NMI after any standard code
NMIEnd:
    jsl SnesProcessFrame
    plp : plb : ply : plx : pla
    jmp $E576

print "sttb = ", pc
SnesTransferTileBuf:
    lda.w SnesTileBufPrepped
    beq +
    stz.w SnesTileBufPrepped
    rts
+
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

    ; When the UW boss block (index 3) finishes, PatternBlockIndex
    ; becomes 4. At that point TransferLevelPatternBlocks has loaded
    ; the level-native sprite set ($09E0) and boss set ($0C00) into
    ; VRAM. Sync the per-room swap tracking vars to match, so a room
    ; whose enemy needs a different block actually re-triggers a swap.
    ; Without this, CurrentSpriteSet/CurrentBossSet can be left over
    ; from the previous level and HandleRoomSpriteSwap would wrongly
    ; skip the DMA, showing the wrong enemy graphics (e.g. darknuts
    ; rendered with another set's tiles).
if not(defined("STANDALONE"))
    php : sep #$30
    lda.w PatternBlockIndex
    cmp #$04
    bne .NoSync
    ldx.b CurLevel
    lda.l LevelToSpriteSet, x
    sta.w CurrentSpriteSet
    lda.l LevelToBossSet, x
    sta.w CurrentBossSet
.NoSync
    plp
endif

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

CueTransferPlayAreaAttrsHalfAndPrepareSnesBuffer:
    jsr $B0E1  ; CopyPlayAreaAttrsHalfToDynTransferBuf
    lda #$01
    sta.w TransferSourceSet
    sta.w SnesTileBufPrepped
    lda.b #DynTileBuf
    sta $00
    lda.b #(DynTileBuf>>8)
    sta $01
    phb : pla : sta $02
    jsl SnesPPUPrepare
    inc.b GameSubmode
    rts

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
