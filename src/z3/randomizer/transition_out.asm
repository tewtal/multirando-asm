; Hook exiting or entering a cave/dungeon to see if this is a cross-game transition
; We need to make sure to support both entering and exiting to properly support entrance shuffling between games


print "tfz = ", pc
transition_from_zelda:
    sei
    %a8()

    lda $000202
    sta !SRAM_ALTTP_EQUIPMENT_1
    lda $000303
    sta !SRAM_ALTTP_EQUIPMENT_2
    jsl $00894a                           ; Autosave ALTTP state
    jsr zelda_save_randomizer_ram

    ; TODO: Copy temporary item buffers to the other games respective SRAM (this needs to be done on save as well)
    ; TODO: Do any other maintenance that needs to be done to properly clear ALTTP state and prepare for the next game

    %i16()
    %a8()

    phk
    plb                         ; Set data bank program bank

    lda.b #$01
    sta.w $420d                   ; Toggle FastROM on

    lda.b #$00
    sta.l $004200                 ; Disable NMI and Joypad autoread
    sta.l $00420c                 ; Disable H-DMA

    lda.b #$8f
    sta.l $002100                 ; Enable PPU force blank

    jsl spc_reset

    lda.b #$81                  
    sta.l $002200             ; Trigger IRQ with message 1 to SA-1 (transition to new game)
    jml mb_snes_transition    ; Jump the SNES CPU into BW-RAM routines that let the SA-1 control it


check_teleport_in:
    phx : phy : php
    rep #$30

    ldx #$0000
.check_room
    lda.l transition_table_in, x
    beq .end

    cmp.w $a0
    bne .next

    lda.l transition_table_in+$6, x
    cmp.l $7ec140
    beq .found_room

.next
    txa : clc : adc.w #$0008 : tax
    bra .check_room

.found_room
    lda.l transition_table_in+$2, x
    sta.l !IRAM_TRANSITION_GAME_ID
    lda.l transition_table_in+$4, x
    sta.l !IRAM_TRANSITION_DESTINATION_ID
    jml transition_from_zelda
    
.end
    ; Run the original code
    plp : ply : plx

    ; Run the original code
    lda $cbb3,x
    sta $e8
    jml $02d714 

check_teleport_out:
    phx : phy : php
    rep #$30

    ldx #$0000
.check_room
    lda.l transition_table_out, x
    beq .end

    cmp.w $a0
    beq .found_room

    txa : clc : adc.w #$0008 : tax
    bra .check_room

.found_room
    lda.l transition_table_out+$2, x
    sta.l !IRAM_TRANSITION_GAME_ID
    lda.l transition_table_out+$4, x
    sta.l !IRAM_TRANSITION_DESTINATION_ID
    jml transition_from_zelda
    
.end
    ; Run the original code
    plp : ply : plx
    lda.w #$0000
    sta.l $7EC017
    jml $02e218


zelda_save_randomizer_ram:
    php
    %ai16()
    ldx #$0000
-
    lda.l $7F5000,x
    sta.l !SRAM_ALTTP_RANDOMIZER_BUF,x
    inx
    inx
    cpx #$00d0
    bne -
    lda #$0000
    sta.l !SRAM_ALTTP_RANDOMIZER_SAVED
    plp
    rts
