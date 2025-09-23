; Sets the ending flag (in A) for the current game and check if all other requirements are met
; If true, returns 1 in A if all games are completed, otherwise 0
check_and_set_ending:
    php
    rep #$20
    and.w #$00ff
    cmp.w #$0001
    bne +
        lda.w #$0001 : sta.l !SRAM_SM_COMPLETED
+   cmp.w #$0002
    bne +
        lda.w #$0001 : sta.l !SRAM_ALTTP_COMPLETED
+   cmp.w #$0003
    bne +
        lda.w #$0001 : sta.l !SRAM_Z1_COMPLETED
+   cmp.w #$0004
    bne +
        lda.w #$0001 : sta.l !SRAM_M1_COMPLETED
+        
    lda.w #$0001 : sta.w !IRAM_ENDING_TEMP
    lda.l config_sm
    beq +
        lda.l !SRAM_SM_COMPLETED : and.w !IRAM_ENDING_TEMP : sta.w !IRAM_ENDING_TEMP
+   lda.l config_z3
    beq +
        lda.l !SRAM_ALTTP_COMPLETED : and.w !IRAM_ENDING_TEMP : sta.w !IRAM_ENDING_TEMP
+   lda.l config_z1
    beq +
        lda.l !SRAM_Z1_COMPLETED : and.w !IRAM_ENDING_TEMP : sta.w !IRAM_ENDING_TEMP
+   lda.l config_m1
    beq +
        lda.l !SRAM_M1_COMPLETED : and.w !IRAM_ENDING_TEMP : sta.w !IRAM_ENDING_TEMP
+
    plp
    lda.w !IRAM_ENDING_TEMP
    rtl

check_other_games_ending:
    phx : php
    rep #$20
    and #$00ff : tax
    lda.w #$0001 : sta.w !IRAM_ENDING_TEMP

    lda.l config_sm
    beq +
    cpx.w #$0001
    beq +
        lda.l !SRAM_SM_COMPLETED : and.w !IRAM_ENDING_TEMP : sta.w !IRAM_ENDING_TEMP
+
    lda.l config_z3
    beq +
    cpx.w #$0002
    beq +
        lda.l !SRAM_ALTTP_COMPLETED : and.w !IRAM_ENDING_TEMP : sta.w !IRAM_ENDING_TEMP
+
    lda.l config_z1
    beq +
    cpx.w #$0003
    beq +
        lda.l !SRAM_Z1_COMPLETED : and.w !IRAM_ENDING_TEMP : sta.w !IRAM_ENDING_TEMP
+
    lda.l config_m1
    beq +
    cpx.w #$0004
    beq +
        lda.l !SRAM_M1_COMPLETED : and.w !IRAM_ENDING_TEMP : sta.w !IRAM_ENDING_TEMP
+

    plp : plx
    lda.w !IRAM_ENDING_TEMP
    rtl