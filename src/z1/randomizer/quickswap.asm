print "z1quickswap = ", pc
QuickSwapCheck:
    ; Check if L/R is pressed
    lda ButtonsPressedSnes
    and #$30
    beq .end

    ; Check which one it is
    and #$10
    beq .left

    lda $0656 : sta QuickSwapTemp
    lda #$08 : sta $0604        ; Play sound effect

-
    lda $0656
    inc
    cmp #$09
    bne +
    lda #$00
+
    cmp QuickSwapTemp
    beq .end        ; If we went a full circle without success, bail

    sta $0656
    jsr QuickSwapAllowed
    bcc -
    bra .end

.left
    lda $0656 : sta QuickSwapTemp
    lda #$08 : sta $0604        ; Play sound effect
-
    lda $0656
    dec
    cmp #$ff
    bne +
    lda #$08
+
    cmp QuickSwapTemp
    beq .end        ; If we went a full circle without success, bail

    sta $0656
    jsr QuickSwapAllowed
    bcc -
    bra .end

    ; Run original code and return
.end
    lda $f8
    and #$20
    rtl

; B item index in a, returns carry set if allowed
QuickSwapAllowed:
    phb
    pha
    phk : plb
    rep #$30
    and #$00ff
    asl #2 : tax
    ldy QuickSwapInventoryTable, x  ; Y = address
    beq .notOk
    lda $0000, y ; A = item status
    and #$00ff
    bne .ok
    ldy QuickSwapInventoryTable+$2, x
    beq .notOk
    lda $0000, y
    and #$00ff
    bne .ok
    bra .notOk
.ok
    sep #$30
    pla
    plb
    sec
    rts
.notOk
    sep #$30
    pla
    plb
    clc
    rts

QuickSwapInventoryTable:
    dw $0674, $0675         ; Boomerang / Magical Boomerang
    dw $0658, $0000         ; Number of bombs
    dw $0000, $0000         ; Arrow (skip)
    dw $065A, $0000         ; Bow
    dw $065B, $0000         ; Candle
    dw $065C, $0000         ; Recorder
    dw $065D, $0000         ; Food
    dw $065E, $0000         ; Potion / Letter (skip)
    dw $065F, $0000         ; Magical Rod
