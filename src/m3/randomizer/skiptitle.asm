; Starts the game directly into save file 1 when the game is reset/booted
; Any file management is done by the top level menu

; Skip initial nintendo boot logo
org $8b92e2
    jml $8b9355

; Hook end of boot sequence to start the game directly
org $80856e
    jml skip_title

org $8bf800
; Sets the initial game mode to $06 (load new game) to instantly start a game at the last save point 
skip_title:
    rep #$20
    lda.w #$0006
    sta.w $0998
    pea $8282 : plb : plb

    ; ; Load file 1
    ; lda.w #$0000
    ; jsl $818085

    ; Run main loop in game mode 06 (loading game)
    jml $828944

