print "transition to z1 = ", pc
transition_to_z1:
    ; At this point, we have WRAM restored from backup
    ; and the common routines copied back to $1000

    %ai16()
    sei
    phk : plb
    ldx.w #$1FFF : txs

    jsl spc_init_driver

    sep #$30
    lda #$8f : sta $2100
    lda #$21 : sta $2107
    lda #$01 : sta $210B
    lda #$01 : sta $2105
    lda #$00 : sta $2101
    lda #$11 : sta $212C
    lda #$00 : sta $212d
    
    jsl SetupScrollHDMA

    ; Clear SNES port buffers
    rep #$30
    ldx #$0000
    lda #$0000

-
    sta.l $7e2000, x
    inx #2
    cpx #$2000
    bne -

    lda #$845C : sta $000810
    lda #$80E4 : sta $000812


    ; Restore stack
    ldx #$01ff : txs

    sep #$30

    ; Store the overworld map exit id
    lda.l !IRAM_TRANSITION_DESTINATION_ID
    sta.b $526

    ; Store the level id in $10 (high byte of destination id)
    lda.l !IRAM_TRANSITION_DESTINATION_ID+$1
    sta.b $10

    ; Transition args (low byte) =
    ; xxxxxxSC
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

    ; Load common patterns
    jsl $821000 : dw $8012

    ; Set game mode
    lda #$02 : sta $12
    stz $11

    ; Enable NMI and clear pending interrupts
    cli : lda.l $004210
    lda.b #$81 : sta.l $004200
    lda PPUCNT0ZP : ora #$80 : and #$fc : sta PPUCNT0ZP

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

    ; Jump the game into its loop and wait for NMI to pick up
    jml $85E45B
