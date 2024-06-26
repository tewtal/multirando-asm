; prevent ending without beating both games
;

alttp_check_ending:
    lda.b #$01
    sta.l !SRAM_ALTTP_COMPLETED
    
    lda.l !SRAM_SM_COMPLETED
    and.l !SRAM_Z1_COMPLETED
    and.l !SRAM_M1_COMPLETED
    bne .sm_completed
    lda.b #$08 : sta $010c
    lda.b #$0f : sta $10
    lda.b #$20 : sta $a0
    lda.b #$00 : sta $a1
    
    stz $11
    stz $b0

    jsl $09ac57 ;Ancilla_TerminateSelectInteractives
    lda $0362 : beq .exit
    stz $4d : stz $46
    lda.b #$ff : sta $29 : sta $c7
    stz $3d : stz $5e : stz $032b : stz $0372
    lda.b #$00 : sta $5d

    lda.b #$00 : sta $0abd  ; Set Link to not use alternate palette
    bra .exit

.sm_completed
    lda.b #$19 : sta $10
    stz $11 : stz $b0

.exit
    plb
    rtl

alttp_setup_credits:
    %ai16()
    lda.w #$0004  ; Credits
    sta.l !IRAM_TRANSITION_GAME_ID
    lda.w #$0000
    STA.l !IRAM_TRANSITION_DESTINATION_ID
    lda.w #$0000
    sta.l !IRAM_TRANSITION_DESTINATION_ARGS    
    jml transition_from_zelda
