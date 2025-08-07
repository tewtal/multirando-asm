print "transition to z1 = ", pc
transition_to_z1:
    ; At this point, we have WRAM restored from backup
    ; and the common routines copied back to $1000

    ;
    ; Any items found for this game is also already copied to RAM/SRAM by the SA-1 during the transition
    ; 

    %ai16()
    sei
    phk : plb
    ldx.w #$1FFF : txs

    jsl spc_init_dpcm
    jsl spc_init_driver

    sep #$30
    lda #$8f : sta.l $002100
    lda #$21 : sta.l $002107
    lda #$01 : sta.l $00210B
    lda #$01 : sta.l $002105
    lda #$00 : sta.l $002106
    lda #$00 : sta.l $002101
    lda #$11 : sta.l $00212C
    lda #$00 : sta.l $00212d
    
    lda #$00 : sta.l $002130
    lda #$00 : sta.l $002131
    jsl SetupScrollHDMA

    jsl nes_initOAMBuffer  ; Clear SNES OAM Buffer

    ; Clear SNES port buffers
    rep #$30
    ldx #$0000
    lda #$0000

-
    sta.l $7e2200, x
    inx #2
    cpx #$1e00
    bne -

    ldx #$0000
-
    sta.l $7e0800, x
    inx #2
    cpx #$0400
    bne -    

    sep #$30
    jsl UploadItemPalettes
    jsl nes_initSpecialPaletteEntry

    %ai16()

    lda #$845C : sta $000810
    lda #$80E4 : sta $000812


    ; Restore stack
    ldx #$01ff : txs

    sep #$30

    ; Store the overworld map exit id
    lda.l !IRAM_TRANSITION_DESTINATION_ID
    sta.w $526
    sta.b $EB

    ; Store the level id in $10 (high byte of destination id)
    lda.l !IRAM_TRANSITION_DESTINATION_ID+$1
    sta.b $10

    ; Transition args (low byte) =
    ; xxxxxDSC
    ; D = Entering a dungeon
    ; S = Make link walk up stairs
    ; C = Exit from cave (otherwise link appears in the middle)

    ; Set cave state
    lda.l !IRAM_TRANSITION_DESTINATION_ARGS
    and.b #$01
    beq +
    lda.b #$24 : sta.b $65
+
    ; Set stairs state
    lda.l !IRAM_TRANSITION_DESTINATION_ARGS
    and.b #$02
    beq +
    lda.b #$01 : sta.b $5A
+
    ; Entering a dungeon
    lda.l !IRAM_TRANSITION_DESTINATION_ARGS
    and.b #$04
    beq +
    lda.b #$00 : sta.b $5A
+

    ; Load demo patterns
    jsl $811000 : dw $8D47

    ; Load common patterns
    jsl $821000 : dw $8012

    ; Set game mode
    lda #$02 : sta $12
    stz $11     
    stz $13     ; Clear submode
    stz $E3     ; Clear sprite 0 flag

    ; Set rendering to off
    lda #$0f : sta PPUCNT1ZP

    ; Reset scrolling
    stz.b CurVScroll
    stz.b CurHScroll
    jsl UpdateScrollHDMA

    stz.w ScrollYDMA
    stz.w ScrollXDMA

    lda #$00 : sta $210d
    lda #$00 : sta $210d

    jsl nes_overlay_init

    ; Enable NMI and clear pending interrupts
    cli : lda.l $004210
    lda.b #$81 : sta.l $004200
    lda PPUCNT0ZP : ora #$80 : and #$fc : sta PPUCNT0ZP

    ; Jump the game into its loop and wait for NMI to pick up
    jml $85E45B
