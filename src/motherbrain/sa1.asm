; Mother Brain - This code runs on the SA-1 and provides services and features to the main games

init:
    sei
    clc
    xce
    rep #$38
    lda #$0000
    tcd
    lda #$01ff
    tcs
    rep #$20
    pea $0000 : plb :  plb
    
    sep #$20

    lda #$ff
    sta $222a   ; Write-enable I-RAM

    lda #$80
    sta $2227   ; Write-enable BW-RAM

    lda #$00 : sta $2209  ; Set NMI/IRQ to be used from SNES

    rep #$30


    ; Wait for the main CPU to become ready
-
    lda.w $37fe
    cmp.w #$cafe
    bne -

    jml menu_init

; The menu will kick the SA-1 back here when a game is loaded and ready making the SA-1 available for IRQ commands
; Todo: Implement IRQ commands
; One of them might be to load the menu system
main:
    jmp main

    