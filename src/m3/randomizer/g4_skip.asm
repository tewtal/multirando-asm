; Set door asm pointer (Door going into the corridor before G4)
org $838c5c
    db $00, $ea

; Door ASM to set the G4 open event bit if all major bosses are killed
org $8fea00
    phx

    ; Count number of set SM boss flags
    ; using the new event bits for the SM boss credits

    lda $7ed834
    stz $12
    ldx #$0000

-
    lsr : bcc +
    inc $12 ; If C is set, count this as a killed boss
+
    inx
    cpx #$0004
    bne -

    lda $12
    cmp.l config_sm_bosses
    bcc +

    lda $7ed820
    ora.w #$07C0
    sta $7ed820

+   plx
    rts
