HasMap_BookCheck:
    lda.l config_book_reveals_maps
    beq .vanilla
    lda InvBook
    beq .vanilla
    lda CurLevel
    beq .vanilla
    lda #$ff
    clc
    rtl

.vanilla
    ldx #$11
    lda CurLevel
    beq .overworld
    sec                 ; carry set -> caller falls through to the vanilla tail at $B5F5
    rtl

.overworld
    clc                 ; carry clear -> caller branches to the RTS at $B607 with A=0
    rtl

LoadItemIdToDescriptor_BookCheck:
    tay

    lda.l config_book_reveals_maps
    beq .exit

    cpy #$0A
    bne .exit

    lda CurLevel
    beq .exit

    lda #$01
    sta StatusBarMapTrigger

.exit
    lda.l ItemIdToDescriptor_extended, x
    rtl

HandleShotBlocked_BookCheck:
    lda.l config_book_reveals_maps
    bne .deactivate

    lda InvBook
    bne .continue

.deactivate
    lda #$00

.continue
    rtl