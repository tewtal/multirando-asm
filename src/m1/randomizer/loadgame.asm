; Runs at Game over to instantly save out of game items
SaveItems:
    php
    rep #$30

    lda #$0003                     ; Since M1 "saves" on death, we need to properly save all items found
    jsl mb_RestoreItemBuffers      ; Restore all item buffers to proper SRAM in all games

    plp

    ; Original hooked code
    ldx.b #$b9
    ldy.b #$93
    rtl

RestoreSamusHealth:
    php
    sep #$30
    lda.w $6877
    and.b #$0F
    asl #4
    ora.b #$09
    sta $107
    lda.b #$90
    sta $106
    plp
    rtl


