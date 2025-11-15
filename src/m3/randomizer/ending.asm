org $8fc922
    jml sm_check_ending_door

org $A9B1D0
    jsl sm_check_ending_mb

org $A9B305
    jml sm_check_ending_mb_event

org $809E1C
    jml sm_check_ending_mb_timer

org $A9B33C
    jml sm_check_ending_mb_anim

org $8bde80
    jml sm_setup_credits

org $809e21
    dw #$0500                ; Set timer to 5 minutes for now so map rando escape should always be possible

org $b7fd00
sm_check_ending_door:        ; Check if all the other games has been beaten, and only then activate the escape.
    pha
    lda #$0001
    jsl mb_check_other_games_ending

    bne .alttp_done
    pla
    jsl $808212         ; Clear event flag if set
    jml $8fc932         ; Jump to "RTS"
.alttp_done
    pla
    jsl $8081fa         ; Call the code we replaced
    jml $8fc926         ; Jump to "LDA #$0012"

sm_check_ending_mb:
    ; Refill energy and ammo after beating the game to make escape easier
    ; Mostly a map rando thing, but isn't a problem in other cases either
    lda $09c4 : sta $09c2  ; Energy
    lda $09c8 : sta $09c6  ; Missiles
    lda $09cc : sta $09ca  ; Super Missiles
    lda $09d0 : sta $09ce  ; Power Bombs
    lda $09d4 : sta $09d6  ; Reserve Tanks

    lda #$0001
    jsl mb_check_and_set_ending
   
    bne .alttp_done
    lda #$b2f9
    sta $0fa8
    lda #$0020
    sta $0fb2
    rtl

.alttp_done    
    lda #$0000
    sta $7e7808
    rtl

sm_check_ending_mb_event:
    jsl $90F084
    lda #$0001
    jsl mb_check_other_games_ending
    bne .alttp_done
    jml $A9B31a

.alttp_done
    jml $A9B309

sm_check_ending_mb_timer:
    lda #$0001
    jsl mb_check_other_games_ending
    bne .alttp_done
    clc
    jml $809E2E

.alttp_done
    jsl $809E93         ; Call the code we replaced
    jml $809E20

sm_check_ending_mb_anim:
    lda #$0001
    jsl mb_check_other_games_ending
    bne .alttp_done
    lda #$b3b5
    sta $0fa8
    jml $A9B345

.alttp_done
    lda $1840
    bne +
    jml $a9b341
+
    jml $A9B345

; Jumping to credits is the same as transitioning to game 4
sm_setup_credits:
    %ai16()
    
    lda.w #$0004  ; Credits
    sta.l !IRAM_TRANSITION_GAME_ID
    lda.w #$0000
    STA.l !IRAM_TRANSITION_DESTINATION_ID
    lda.w #$0000
    sta.l !IRAM_TRANSITION_DESTINATION_ARGS    
    jml sm_do_transition_ext