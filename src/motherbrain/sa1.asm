; Mother Brain - This code runs on the SA-1 and provides services and features to the main games

init:
    sei
    clc
    xce
    rep #$38
    lda #$0000
    tcd
    lda #$1fff
    tcs
    rep #$20
    pea $0000 : plb :  plb
    
    lda #$37f0
    sta $220c ; Set NMI Vector to $37f0 (I-RAM)

    lda #$37f4
    sta $220e ; Set IRQ Vector to $37f4 (I-RAM)
    
    sep #$20
    
    lda #$50 : sta $2209  ; Set NMI to be used from SA-1 vector
    jmp main

main:
    jmp main


    