; Runs at password screen to save items
SaveItems:
    php
    rep #$30

    lda #$0003                     ; Since M1 "saves" on death, we need to properly save all items found
    jsl mb_RestoreItemBuffers      ; Restore all item buffers to proper SRAM in all games
    
    jsl backup_wram                ; Backup M1 WRAM to buffer
    lda #$0003
    jsl mb_CopyItemBuffer          ; Copy the M1 items to item buffer so that on a reset no M1 items are lost

    plp

    ; Original hooked code
    ldx.b #$7f
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

; Runs at startup, restore items from SRAM backup
LoadItems:
    php
    rep #$30
    lda.w #$0003
    jsl mb_RestoreItemBuffer
    plp

    lda.b #$02
    sta.b $24

    rtl

