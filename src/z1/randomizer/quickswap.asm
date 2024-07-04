print "z1quickswap = ", pc
QuickSwapCheck:
    phx
    phy

    ; Check if L/R is pressed
    lda ButtonsPressedSnes
    and #$30
    bne +
    jmp .end
+

    ; Check which one it is
    and #$10
    beq .left
    lda #$01 : sta QuickSwapDir ; Right
    bra +
.left
    stz.w QuickSwapDir ; Left
+

    stz.w QuickSwapFound
    lda $0656 : sta QuickSwapTemp ; Store original value
    ldx #$04
-
    lda.l .swapTable, x
    cmp QuickSwapTemp
    beq ++
    cmp #$ff
    bne +
    jmp .end    ; could not find the index for some reason
+
    inx #4
    bra -
++

    ; Move to the next table index
-
    lda QuickSwapDir
    bne +
    dex #4
    bra ++
+
    inx #4
++
    lda.l .swapTable, x
    cmp QuickSwapTemp
    beq -

.nextItemCheck
    lda.l .swapTable, x
    cmp #$ff
    bne +
    ; Wrap around
    lda.l .swapTable+$03, x : tax
+
    lda.l .swapTable, x : sta QuickSwapIndex
    cmp QuickSwapTemp
    beq .end

    ; x = index into the table for checking data
    lda.l .swapTable+$03, x : sta QuickSwapType
    rep #$30
    lda.l .swapTable+$01, x : tay
    lda $0000, y
    and #$00ff
    sep #$30
    bne .foundItem
    ; no item found, continue to next
    stz.w QuickSwapFound
    bra .nextIndex

.foundItem
    inc.w QuickSwapFound
    lda QuickSwapType
    and #$f0
    cmp #$10 ; Require x amount
    beq .checkBoth
    cmp #$20 ; Letter (only swap to if no potions)
    bne +
    lda $065E  ; Check potions
    bne .skipLetter
+
    bra .selectItem
.checkBoth
    lda QuickSwapType
    and #$0f
    cmp QuickSwapFound
    bne .nextIndex
    bra .selectItem
.skipLetter
    stz.w QuickSwapFound

.nextIndex
    lda QuickSwapDir
    bne +
    dex #4
    bra .nextItemCheck
+
    inx #4
    bra .nextItemCheck

.selectItem
    lda QuickSwapIndex : sta $0656
    lda #$08 : sta $0604        ; Play sound effect

.end
    ply
    plx
    lda $f8
    and #$20
    rtl


; icon index, mem, type (1x = require all x), (2x, letter special) wrap around index
.swapTable
    db $ff : dw $ffff : db $2c  ; Wrap around
    db $00 : dw $0674 : db $00  ; Boomerang
    db $00 : dw $0675 : db $00  ; Magical Boomerang
    db $01 : dw $0658 : db $00  ; Number of bombs
    db $02 : dw $065A : db $12  ; Bow
    db $02 : dw $0659 : db $12  ; Arrow
    db $04 : dw $065B : db $00  ; Candle
    db $05 : dw $065C : db $00  ; Recorder
    db $06 : dw $065D : db $00  ; Food
    db $07 : dw $065E : db $00  ; Potion 
    db $0F : dw $0666 : db $20  ; Letter
    db $08 : dw $065F : db $00  ; Magical Rod
.swapTableEnd
    db $ff : dw $ffff : db $04  ; Wrap around