transition_from_z1:    
    sei
    
    ; TODO: Save Z1 SRAM and all state that needs to be saved properly
    ; TODO: Copy temporary item buffers to the other games respective SRAM (this needs to be done on save as well)
    ; TODO: Do any other maintenance that needs to be done to properly clear ALTTP state and prepare for the next game

    %ai16()

    ; TODO: Change to DMA
    ; Backup RAM to BW-RAM so we can restore it on transition in

    ldx #$0000
-
    lda.w $0000, x
    sta.l $40C800, x
    inx #2
    cpx.w #$0800
    bne -

    %i16()
    %a8()

    phk
    plb                         ; Set data bank program bank

    lda #$01
    sta $420d                   ; Toggle FastROM on

    lda #$00
    sta $004200                 ; Disable NMI and Joypad autoread
    sta $00420c                 ; Disable H-DMA

    lda #$8f
    sta $002100                 ; Enable PPU force blank

    lda #$f5
    sta $002140                   ; Reset SPC

    lda #$81
    sta.l $002200             ; Trigger IRQ with message 1 to SA-1 (transition to new game)
    jml mb_snes_transition    ; Jump the SNES CPU into BW-RAM routines that let the SA-1 control it

check_cave_transition_out:
    phx : phy : php
    rep #$30
    lda.w #transition_table_out
    sta.w ExitRoomTable    
    jsr check_cave_transition
    plp : ply : plx
    rtl

check_cave_transition_in:
    phx : phy : php
    rep #$30
    lda.w #transition_table_in
    sta.w ExitRoomTable
    jsr check_cave_transition
    plp : ply : plx
    lda $AB45, X : sta $02
    rtl

check_cave_transition:
    lda.b $eb
    ; Force the room Id to 8-bit
    and.w #$00ff
    sta.w ExitRoomTemp

    ldx.w ExitRoomTable
-
    lda.l transition_table_in&$ff0000, x
    beq .exit
    cmp.w ExitRoomTemp
    beq .transition_found
    txa : clc : adc #$0008 : tax
    bra -

.transition_found
    lda.l transition_table_in&$ff0000+2, x
    sta !IRAM_TRANSITION_GAME_ID
    lda.l transition_table_in&$ff0000+4, x
    sta !IRAM_TRANSITION_DESTINATION_ID
    lda.l transition_table_in&$ff0000+6, x
    sta !IRAM_TRANSITION_DESTINATION_ARGS

    jml transition_from_z1

.exit    
    rts

check_dungeon_transition:
    phx : phy : php
    rep #$30
    lda $10 ; Current level we're transitioning to, 0 = overworld
    and #$00ff    
    beq .check_overworld_transition

    lda.w #transition_table_in
    sta.w ExitRoomTable
    lda $6bad ; Room ID we're going to (in case of entering)
    bra .check_room
.check_overworld_transition
    lda.w #transition_table_out
    sta.w ExitRoomTable
    lda $eb ; Room ID we're coming from (in case of exiting)
.check_room
    
    ; Force the room Id to 8-bit
    and.w #$00ff
    sta.w ExitRoomTemp

    ldx.w ExitRoomTable
-
    lda.l transition_table_in&$ff0000, x
    beq .exit
    cmp.w ExitRoomTemp
    beq .transition_found
    txa : clc : adc #$0008 : tax
    bra -

.transition_found
    lda.l transition_table_in&$ff0000+2, x
    sta !IRAM_TRANSITION_GAME_ID
    lda.l transition_table_in&$ff0000+4, x
    sta !IRAM_TRANSITION_DESTINATION_ID
    lda.l transition_table_in&$ff0000+6, x
    sta !IRAM_TRANSITION_DESTINATION_ARGS

    jml transition_from_z1

.exit
    plp : ply : plx
    lda $10
    bne +
    jml $85ea15
+
    jml $85ea1c
    








