transition_from_m1:    
    sei
    
    ; TODO: Save M1 SRAM and all state that needs to be saved properly
    ; TODO: Copy temporary item buffers to the other games respective SRAM (this needs to be done on save as well)
    ; TODO: Do any other maintenance that needs to be done to properly clear M1 state and prepare for the next game

    %ai16()

    ; TODO: Change to DMA
    ; Backup RAM to BW-RAM so we can restore it on transition in
    jsl backup_wram

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


print "samusenterdoor = ", pc
SamusEnterDoor_extended:
    jsl m1_transition_out_call_current_bank_routine
    dw $8B13                        ; Vanilla SamusEnterDoor.

    lda.b $56                       ; DoorStatus has bit 7 set only after vanilla accepts entry.
    bpl .no_transition
    lda.b $59                       ; DoorDelay is set to $12 on the entry frame.
    cmp.b #$12                      ; This check isn't strictly necessary, but avoids
                                    ; possible churn during vanilla door processing.
                                    ; I would like to find a less brittle check
                                    ; than door delay timer, since we may choose
                                    ; to patch that value in the future.
    bne .no_transition

    phx
    rep #$30
    ldx #$0000
.loop
    lda.l transition_table, x
    cmp.w #$0000
    beq .end

    jsr m1_transition_out_room_matches
    bcc .next

    lda.l transition_table+$2, x
    jsr m1_transition_out_door_matches
    bcc .next

    ; We found a cross-game door, take us out
    lda.l transition_table+$4, x
    sta.l !IRAM_TRANSITION_GAME_ID
    lda.l transition_table+$6, x
    sta.l !IRAM_TRANSITION_DESTINATION_ID
    lda.l transition_table+$8, x
    sta.l !IRAM_TRANSITION_DESTINATION_ARGS
    jml transition_from_m1

.next
    txa : clc : adc #$000A : tax

.end
    sep #$30
    plx

.no_transition
    jsl m1_transition_out_call_current_bank_routine
    dw $8B79                        ; Vanilla door object update/display.
    jmp m1_transition_out_return_to_update_world

m1_transition_out_room_matches:
    sta.w m1_TableBankTemp
    lda.w $004F                     ; Current room as XXYY.
    cmp.w m1_TableBankTemp
    beq .match

    jsr m1_transition_out_centered_room
    cmp.w m1_TableBankTemp
    beq .match

    clc
    rts

.match
    sec
    rts

m1_transition_out_centered_room:
    lda.w $0056                     ; DoorStatus low bits select the centering scroll.
    and.w #$007F
    cmp.w #$0003
    beq .scroll_down
    cmp.w #$0004
    beq .scroll_up

.current
    lda.w $004F
    rts

.scroll_down
    lda.w $0049                     ; Duplicate only ScrollDown's MapPosY effect.
    and.w #$00FF
    beq .increment_y
    cmp.w #$0001
    bne .current
    lda.w $00FC
    and.w #$00FF
    bne .current

.increment_y
    lda.w $004F
    inc
    rts

.scroll_up
    lda.w $0049                     ; Duplicate only ScrollUp's MapPosY effect.
    and.w #$00FF
    cmp.w #$0001
    beq .decrement_y
    cmp.w #$0000
    bne .current
    lda.w $00FC
    and.w #$00FF
    bne .current

.decrement_y
    lda.w $004F
    dec
    rts

m1_transition_out_door_matches:
    and.w #$00FF
    cmp.w #$0003
    bcs .match_vertical_entry

    sta.w m1_TableBankTemp          ; Table values 1/2 match vanilla door side.
    lda.w $0057
    and.w #$00FF
    cmp.w #$0003
    bcc .compare_side

    lda.w $030E                     ; In vertical shafts, infer side the way vanilla does.
    and.w #$00FF
    cmp.w #$0080
    bcc .left_side
    lda.w #$0001                    ; ObjectX negative/high = right-hand door.
    bra .compare_side

.left_side
    lda.w #$0002

.compare_side
    cmp.w m1_TableBankTemp
    beq .match
    clc
    rts

.match_vertical_entry
    lda.w $0057                     ; Legacy table values 3/4 match either vertical entry state.
    and.w #$00FF
    cmp.w #$0003
    bcc .no_match

.match
    sec
    rts

.no_match
    clc
    rts

m1_transition_out_call_current_bank_routine:
    php
    rep #$20
    sta.w m1_TableBankTemp
    sep #$30
    lda.b $23
    clc
    adc.b #$90
    sta.w m1_BankSwitchBank
    rep #$20
    lda.w #$1000
    sta.w m1_BankSwitchAddr
    lda.w m1_TableBankTemp
    plp
    jml.w [m1_BankSwitchAddr]

m1_transition_out_return_to_update_world:
    sep #$30
    lda.b $23
    clc
    adc.b #$90
    sta.w m1_BankSwitchBank
    rep #$20
    lda.w #$CB51
    sta.w m1_BankSwitchAddr
    sep #$30
    jml.w [m1_BankSwitchAddr]

backup_wram:
    php
    %ai16();
    ldx #$0000
-
    lda.w $0000, x
    sta.l $40D000, x
    inx #2
    cpx.w #$0800
    bne -

    plp
    rtl
