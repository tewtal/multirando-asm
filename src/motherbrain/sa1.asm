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
    lda #$80 : sta $220a  ; Enable IRQ from SNES

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
    phk : plb
    cli

    - : jmp -

; IRQ triggered (should only be from SNES side)
sa1_handle_irq:
    pha : phx : phy : php : phb
    phk : plb

    sep #$30
    lda #$80 : sta.l $00220b    ; ACK IRQ
    lda.l $002301 ; Load message from SNES
    beq .end
    dec : asl : tax
    pea $4040 : plb : plb
    jsr (irq_routines, x)
.end
    plb : plp : ply : plx : pla
    rtl

irq_routines:
    dw handle_transition

    