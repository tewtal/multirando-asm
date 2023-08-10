transition_from_m1:    
    sei
    
    ; TODO: Save M1 SRAM and all state that needs to be saved properly
    ; TODO: Copy temporary item buffers to the other games respective SRAM (this needs to be done on save as well)
    ; TODO: Do any other maintenance that needs to be done to properly clear M1 state and prepare for the next game

    %ai16()

    ; TODO: Change to DMA
    ; Backup RAM to BW-RAM so we can restore it on transition in

    ldx #$0000
-
    lda.w $0000, x
    sta.l $40D000, x
    inx #2
    cpx.w #$0800
    bne -

    ; Set previous game id
    lda.w #$0003
    sta.l !IRAM_TRANSITION_GAME_PREV_ID

    %i16()
    %a8()

    phk
    plb                       ; Set data bank program bank

    lda #$01
    sta $420d                 ; Toggle FastROM on

    lda #$00
    sta $004200               ; Disable NMI and Joypad autoread
    sta $00420c               ; Disable H-DMA

    lda #$8f
    sta $002100               ; Enable PPU force blank

    lda #$f5
    sta $002140               ; Reset SPC

    lda #$81
    sta.l $002200             ; Trigger IRQ with message 1 to SA-1 (transition to new game)
    jml mb_snes_transition    ; Jump the SNES CPU into BW-RAM routines that let the SA-1 control it


SamusInDoor_extended:
    phx
    sta $56

    rep #$30
    and #$00ff
    ldx #$0000
.loop
    lda.l transition_table, x
    cmp.w #$0000
    beq .end

    cmp.b $4f
    bne .next
    
    lda.b $56 : and #$00ff
    cmp.l transition_table+$2, x
    bne .next

    ; We found a cross-game door, takes us out!
    lda.l transition_table+$4, x
    sta !IRAM_TRANSITION_GAME_ID
    lda.l transition_table+$6, x
    sta !IRAM_TRANSITION_DESTINATION_ID
    lda.l transition_table+$8, x
    sta !IRAM_TRANSITION_DESTINATION_ARGS
    jml transition_from_m1

.next
    txa : clc : adc #$000A : tax

.end
    sep #$30
    plx
    lda.b $56
    ora.b #$80
    sta.b $56 
    rtl
