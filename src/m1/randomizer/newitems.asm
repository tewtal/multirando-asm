UploadItemPalettes:
    lda #$80 : sta $2100
    
    lda #$C0 : sta $2121
    ldx #$00
-
    lda.l new_item_palettes, x
    sta $2122
    lda.l new_item_palettes+1, x
    sta $2122
    inx : inx
    cpx #$80
    bne -

    lda #$8f : sta $2100
    rtl    

ScanForItems_Start:
    lda.b #(brinstar_item_table>>16)
    sta.b $02
    lda.w $9598
    sta.b $00
    rtl

GetFramePtrTable_extended:
    phx
    
    lda $4B
    cmp #$40
    bcc .normal_item
    cmp #$50
    bcs .normal_item

    rep #$30

    lda.b $4c : and #$00ff : tax
    lda.w $074C, x    ; Check if this is a custom item
    beq .normal_item

    lda.w $0748, x    ; Load item id
    and.w #$00ff
    cmp.w #$00ff
    beq .normal_item

    asl #5
    clc : adc.w #FrameDataTable_extended
    cpx.w #$0008
    bne +
    clc : adc.w #$0010
+
    sta.b $cc

    sep #$30
    lda.b #(FrameDataTable_extended>>16)
    sta.b $ce
    plx
    bra .end

.normal_item
    sep #$30
    plx
    lda $860B, x
    sta $cc
    lda $860C, x
    sta $cd
    phb : pla
    sta $ce
.end
    rtl

GetEnemyFramePtrTable_extended:
    lda ($41), y
    bcc +
    lda ($43), y
+   sta $cc
    iny
    lda ($41), y
    bcc +
    lda ($43), y
+   sta $cd
    phb : pla
    sta $ce
    rtl

StorePowerUpYCoord_extended:
    ora.b #$08
    
    ; Store PowerUpYCoord
    sta.w $074A, x  
    
    ; Reset custom item flags
    stz.w $074C, x  
    stz.w $074D, x

    rtl

StoreSpriteAttributes_extended:
    pha
    sta $0202, x                    ; Write sprite attributes
    
    ; Check if this is a sprite that has loaded data from
    ; our extended table
    lda.b $ce
    cmp.b #(FrameDataTable_extended>>16)
    bne .end

    ; In that case, set extended sprite flag
    ; This makes it use OAM2 and sprite palettes 5-8
    lda $0202, x
    ora #$04
    sta $0202, x

.end
    pla
    inc $11
    rtl

UpdatePaletteEffect_extended:
    phx
    ldx $4c
    lda $074C, x        ; Don't flashy flashy for custom items
    bne .end

    lda $2d
    lsr
    and.b #$03
    ora.b #$80
    sta $6b
.end
    plx
    rtl

CustomItemHandler:
    jsr CheckItemBit
    bcs .end

    jsl $811000 : dw $EDFE          ; JSR to $81EDFE

    phy
    phx

    lda #$01
    sta.w $074C, x                  ; Set custom item data
    sta.w $074D, x                  ; Two bytes that can be anything we want

    rep #$30
    
    lda.l SnesPPUDataStringPtr
    tay
    
    lda.l #SnesPPUDataString
    sta $d0
    lda.l #(SnesPPUDataString>>8)
    sta $d1

    lda.w #$0005
    sta [$d0], y
    iny #2

    txa : and #$00ff
    beq .slot_1
    
    lda.w #$4040
    bra .slot_2

.slot_1
    lda.w #$4000

.slot_2
    sta [$d0], y
    iny #4

    lda.w #$0080
    sta [$d0], y
    iny #2

    ; Load item id
    lda $0748, x
    ; Multiply with $80
    asl #7 : clc : adc #new_item_graphics
    sta [$d0], y
    iny #2
    lda #(new_item_graphics>>16)
    sta [$d0], y
    iny #2
    lda #$0000
    sta [$d0], y
    
    tya    
    sta.l SnesPPUDataStringPtr

    sep #$30


    plx
    ply

.end
    rtl

PickupItem_extended:
    tay
    
    ; Play pickup music
    jsl $811000 : dw $CBF9

    ldx $4C
    lda $074C, x
    beq .end

    ; Save powerup name table, needed for some routines
    lda $074B, x
    sta $08

    ; Ok, we have a custom item, handle picking it up here
    
    ; Flag this item as picked up
    jsr SetItemBit

    sec ; Setting carry skips the normal processing
    rtl

.end
    clc
    rtl

SetItemBit:
    pha : phx
    
    lda $50                         ;
    sta $07                         ;Temp storage of Samus map position x and y in $07-->
    lda $4F                         ;and $06 respectively.
    sta $06                         ;
    lda ScrollDir                   ;Load scroll direction and shift LSB into carry bit.
    lsr                             ;
    php                             ;Temp storage of processor status.
    beq +                           ;Branch if scrolling up/down.
    bcc ++                          ;Branch if scrolling right.

    lda ScrollX                     ;Unless the scroll x offset is 0, the actual room x pos-->
    beq ++                          ;needs to be decremented in order to be correct.
    dec $07                         ;
    bcs ++                          ;Branch always.

+   bcc ++                          ;Branch if scrolling up.
    lda ScrollY                     ;Unless the scroll y offset is 0, the actual room y pos-->
    beq ++                          ;needs to be decremented in order to be correct.
    dec $06                         ;
++  lda PPUCNT0ZP                   ;If item is on the same nametable as current nametable,-->
    eor $08                         ;then no further adjustment to item x and y position needed.
    and #$01                        ;
    plp                             ;Restore the processor status and clear the carry bit.
    clc                             ;
    beq +++                         ;If Scrolling up/down, branch to adjust item y position.
    adc $07                         ;Scrolling left/right. Make any necessary adjustments to-->
    sta $07                         ;item x position before writing to unique item history.
    bra .add_to_history             ;($DC51)Add unique item to unique item history.
+++ adc $06                         ;Scrolling up/down. Make any necessary adjustments to-->
    sta $06                         ;item y position before writing to unique item history.

.add_to_history
    lda.b $06                         ; Load item Y coordinate
    sta.w $211b
    stz.w $211b
    lda.b #$20
    sta.w $211c

    rep #$30

    lda.w $07 : and #$00ff
    clc : adc.w $2134                       ; X * Y (for room coordinates)
    lsr #3 : tax                      ; X = item array offset
    phx

    lda.w $07 : and #$00ff
    clc : adc.w $2134
    and.w #$0007
    tax
    
    lda.w #$0000
    sec
-
    rol
    dex
    bpl -

    plx

    sep #$20
    ora.w m1_ItemBitArray, x
    sta.w m1_ItemBitArray, x

    sep #$30
    plx : pla
    rts

CheckItemBit:
    pha : phx
    lda.b $4F                         ; Load item Y coordinate
    sta.w $211b
    stz.w $211b
    lda.b #$20                        ; Multiply by #$20
    sta.w $211c
    rep #$30

    lda.w $50 : and #$00ff
    clc : adc.w $2134                       ; X * Y (for room coordinates)
    lsr #3 : tax                      ; X = item array offset
    phx

    lda.w $50 : and #$00ff
    clc : adc.w $2134
    and.w #$0007
    tax
    
    lda.w #$0000
    sec
-
    rol
    dex
    bpl -

    plx

    sep #$20
    and.w m1_ItemBitArray, x
    beq .not_set
    
    sep #$30
    pla : plx
    sec
    rts

.not_set
    sep #$30
    pla : plx
    clc
    rts    

ChooseHandlerTable_extended:
    dw $C45C                        ; rts.
    dw $EDF8                        ; Some squeepts.
    dw $EDFE                        ; power-ups.
    dw $EE63                        ; Special enemies(Mellows, Melias and Memus).
    dw $EEA1                        ; Elevators.
    dw $EEA6                        ; Mother brain room cannons.
    dw $EEAE                        ; Mother brain.
    dw $EECA                        ; Zeebetites.
    dw $EEEE                        ; Rinkas.
    dw $EEF4                        ; Some doors.
    dw $EEFA                        ; Background palette change.
    dw CustomItemHandler_common     ; Custom Items


macro itemdata(name, topleft, topright, bottomleft, bottomright)
    db $0D|(<topleft><<4), $03, $03, $00, $fd, <topright>, $01, $fd, <bottomleft>, $02, $fd, <bottomright>, $03, $ff, $ff, $ff
    db $0D|(<topleft><<4), $03, $03, $04, $fd, <topright>, $05, $fd, <bottomleft>, $06, $fd, <bottomright>, $07, $ff, $ff, $ff
endmacro

FrameDataTable_extended:
    %itemdata(sm_bomb, 0, 0, 0, 0)          ;    00
    %itemdata(sm_gravity, 0, 0, 0, 0)       ;    01
    %itemdata(sm_grapple, 0, 0, 0, 0)       ;    02
    %itemdata(sm_xray, 0, 0, 0, 0)          ;    03
    %itemdata(sm_springball, 0, 0, 0, 0)    ;    04
    %itemdata(sm_varia, 0, 0, 0, 0)         ;    05
    %itemdata(sm_speedbooster, 0, 0, 0, 0)  ;    06
    %itemdata(sm_charge, 0, 0, 0, 0)        ;    07
    %itemdata(sm_hijump, 0, 0, 0, 0)        ;    08
    %itemdata(sm_screwattack, 0, 0, 0, 0)   ;    09
    %itemdata(sm_icebeam, 3, 3, 3, 3)       ;    0A
    %itemdata(sm_wavebeam, 1, 2, 1, 1)      ;    0B
    %itemdata(sm_spacejump, 0, 0, 0, 0)     ;    0C
    %itemdata(sm_morphball, 0, 0, 0, 0)     ;    0D
    %itemdata(sm_plasma, 1, 1, 1, 1)        ;    0E
    %itemdata(sm_spazer, 0, 0, 0, 0)        ;    0F
    %itemdata(sm_reserve, 0, 0, 0, 0)       ;    10
    %itemdata(alttp_hookshot, 0, 0, 0, 0)   ;    11
    %itemdata(alttp_firerod, 2, 0, 0, 0)    ;    12

