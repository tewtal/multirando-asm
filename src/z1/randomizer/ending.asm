CheckEndingSequence:
    php
    rep #$30

    lda #$0001
    sta.l !SRAM_Z1_COMPLETED      ; Set zelda 1 as completed
    
    lda.l !SRAM_ALTTP_COMPLETED
    and.l !SRAM_SM_COMPLETED
    and.l !SRAM_M1_COMPLETED
    bne .all_done

    ; Not all games are done, don't spawn zelda and instead teleport us out of the dungeon
    plp
    sec
    rtl 


.all_done
    ; Run the normal ending sequence
    plp
    ldx #$05
-
    lda $a8bf, x
    sta $70, x
    lda $a8c4, x
    sta $84, x
    lda #$3f
    sta $034f, x
    dex
    bne -

    lda #$37
    sta $0350

    clc
    rtl

StartCredits:
    %ai16()
    lda.w #$0004  ; Credits
    sta.l !IRAM_TRANSITION_GAME_ID
    lda.w #$0000
    STA.l !IRAM_TRANSITION_DESTINATION_ID
    lda.w #$0000
    sta.l !IRAM_TRANSITION_DESTINATION_ARGS
    jml transition_from_z1