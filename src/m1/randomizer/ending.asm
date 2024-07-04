CheckEndingSequence:
    php
    rep #$30

    lda #$0001
    sta.l !SRAM_M1_COMPLETED      ; Set zelda 1 as completed
    
    lda.l !SRAM_ALTTP_COMPLETED
    and.l !SRAM_SM_COMPLETED
    and.l !SRAM_Z1_COMPLETED
    bne .all_done

    sep #$30

    lda #$0a
    sta $98

    ; Set the game up to reload from the start point
    lda #$ff
    sta $1f

    lda #$01
    sta $24

    bra .exit

.all_done
    sep #$30
    lda #$05
    sta $98
    lda #$80
    sta $99

.exit
    plp
    rtl

CheckExtraEndingTitleModes:
    lda $1f
    cmp #$ff    ; Check if the title routine is $ff (restart from ending)
    beq .restartFromEnding
    
    ; hooked code
    cmp #$15
    rtl

.restartFromEnding
    ; Set the title mode to something sane (waiting for start at password screen)
    lda #$1a
    sta $1f

    ; Set area to brinstar
    lda #$00
    sta $74

    ; pop the return address off the stack
    pla : pla : pla

    ; Run initialize game
    lda #$80 : sta m1_NMIJumpBank
    pea $8080 : plb : plb
    jml $8092d4

StartCredits:
    %ai16()
    lda.w #$0004  ; Credits
    sta.l !IRAM_TRANSITION_GAME_ID
    lda.w #$0000
    STA.l !IRAM_TRANSITION_DESTINATION_ID
    lda.w #$0000
    sta.l !IRAM_TRANSITION_DESTINATION_ARGS
    jml transition_from_m1