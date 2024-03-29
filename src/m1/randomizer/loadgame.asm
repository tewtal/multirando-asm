; This is run when the game is supposed to restore items from
; password data, but we've hooked it since we don't care about that
; Instead we make sure to save the buffer of items to SRAM
LoadItemsFromPassword:
    php
    rep #$30

    lda #$0003                     ; Since M1 "saves" on death, we need to properly save all items found
    jsl mb_RestoreItemBuffers      ; Restore all item buffers to proper SRAM in all games

    plp
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


