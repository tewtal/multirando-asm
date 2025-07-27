UploadItemPalettes:
    lda #$80 : sta $2100
    
    lda #$90 : sta $2121
    ldx #$00
-
    lda.l nes_new_item_palettes, x
    sta $2122
    lda.l nes_new_item_palettes+1, x
    sta $2122
    inx : inx
    cpx #$e0
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

    jsl mb_CheckProgressiveItemLong

    ; Get pointer to FrameDataTable graphics string
    phx
    asl #2 : tax
    lda.l ItemData+$2, x
    plx

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
    eor $05
    sta $0202, x                    ; Write sprite attributes

    ; Check if this is a sprite that has loaded data from
    ; our extended table
    lda.b $ce
    cmp.b #(FrameDataTable_extended>>16)
    bne .end

    ; In that case, set extended sprite flag
    ; This makes it use OAM2 and sprite palettes 5-8
    lda $0202, x
    and #$4f    ;  Restrict to horizontal flip, palette, and name select bits
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

    ; Jump to a copy of the default item handler
    ; but this one doesn't continue processing items
    jsl $910000+(PowerUpHandler_extended&$ffff)

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

    ; Load item id and get the pointer to the graphics data
    lda.w $0748, x
    and.w #$00ff
    
    jsl mb_CheckProgressiveItemLong
    
    asl #2 : tax
    lda.l ItemData, x

    sta [$d0], y
    iny #2
    lda #(nes_new_item_graphics>>16)
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


print "pickupitemextended = ", pc
PickupItem_extended:
    tay
    
    ; Play pickup music
    ; jsl $911000 : dw $CBF9

    ldx $4C
    lda $074C, x
    beq .m1item

    ; Save powerup name table, needed for some routines
    lda $074B, x
    sta $08

    ; Ok, we have a custom item, handle picking it up here
    lda.w $0748, x    ; Load item id
    jsl nes_overlay_show_item
    
    phx : phy
    jsl mb_WriteItemToInventory
    ply : plx
    
    ; Flag this item as picked up
    jsr SetItemBit

    sec ; Setting carry skips the normal processing
    rtl

.m1item
    pha : phx
    lda.w $0748, x  ; Load item id
    tax
    lda.l M1ItemIdMap, x ; Load M1 item id mapping
    jsl nes_overlay_show_item
    plx : pla

    clc
    rtl

M1ItemIdMap:
    db $62      ; Bombs
    db $63      ; HiJump
    db $66      ; LongBeam
    db $67      ; Screw
    db $68      ; Morph
    db $69      ; Varia
    db $6C      ; Wave
    db $6D      ; Ice Beam
    db $6E      ; ETank
    db $6F      ; Missiles

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
    <name>:
    db $0D|(<topleft><<4), $03, $03, $00, $fd, <topright>, $01, $fd, <bottomleft>, $02, $fd, <bottomright>, $03, $ff, $ff, $ff
    db $0D|(<topleft><<4), $03, $03, $04, $fd, <topright>, $05, $fd, <bottomleft>, $06, $fd, <bottomright>, $07, $ff, $ff, $ff
endmacro

macro flippeditemdata(name, topleft, topright, bottomleft, bottomright)
    <name>:
    db $0D|(<topleft><<4), $03, $03, $01, $fd, <topright>, $00, $fd, <bottomleft>, $03, $fd, <bottomright>, $02, $ff, $ff, $ff
    db $0D|(<topleft><<4), $03, $03, $05, $fd, <topright>, $04, $fd, <bottomleft>, $07, $fd, <bottomright>, $06, $ff, $ff, $ff
endmacro

FrameDataTable_extended:
    %itemdata(pal_0, 0, 0, 0, 0)
    %itemdata(pal_1, 1, 1, 1, 1)
    %itemdata(pal_2, 2, 2, 2, 2)
    %itemdata(pal_3, 3, 3, 3, 3)
    %itemdata(pal_ice, 0, 3, 0, 0)
    %itemdata(pal_plasma, 0, 1, 0, 0)
    %itemdata(pal_wave, 0, 2, 0, 0)
    %itemdata(pal_firerod, 2, 0, 0, 0)
    %itemdata(pal_icerod, 0, 3, 0, 0)

    ;  Add even MORE extended palettes by utilizing the horizontal mirror attribute bit.
    ;  xHxx xxxx.  Since none of our custom items will need mirroring, we reprocess this
    ;  in SnesOamPrepare to select from snes OAM palettes #1->#3.
    %flippeditemdata(pal_e1, 5, $51, $51, $51)
    %flippeditemdata(pal_e2, 6, $52, $52, $52)
    %flippeditemdata(pal_e3, 7, $53, $53, $53)


; New item data (for external items) - We use item id:s 0x30 and up
; So when working with this data, just remove 0x30 from the index
; This table is quite bit and uses 16-bytes per entry but we have space
; It'll still be at most 0x1000 big.

; This will be the SM + ALTTP Items (offset by 0x30)

ItemData:
    ;  addr   attrs
    dw $A780, pal_0        ; 00 Dummy - L1SwordAndShield 
    dw $9B00, pal_0        ; 01 Master Sword
    dw $9B80, pal_1        ; 02 Tempered Sword
    dw $9D00, pal_0        ; 02 Gold Sword
    dw $9F80, pal_3        ; 04 Shield
    dw $A000, pal_0        ; 05 Red Shield
    dw $A080, pal_0        ; 06 Mirror Shield
    dw $8900, pal_firerod  ; 07 Firerod
    dw $9000, pal_icerod   ; 08 Icerod  
    dw $9480, pal_1        ; 09 Hammer
    dw $8880, pal_0        ; 0A Hookshot
    dw $8A00, pal_0        ; 0B Bow
    dw $A100, pal_3        ; 0C Blue Boomerang
    dw $8E80, pal_0        ; 0D Powder
    dw $9E00, pal_0        ; 0E Dummy - Bee (bottle contentt)
    dw $9080, pal_0        ; 0F Bombos

    dw $9200, pal_0        ; 10 Ether
    dw $9280, pal_0        ; 11 Quake
    dw $9400, pal_1        ; 12 Lamp
    dw $9600, pal_0        ; 13 Shovel
    dw $9680, pal_3        ; 14 Flute                       
    dw $9180, pal_2        ; 15 Somaria
    dw $9A00, pal_0        ; 16 Bottle
    dw $A200, pal_e1        ; 17 Piece of Heart
    dw $9300, pal_3        ; 18 Byrna
    dw $9380, pal_e1        ; 19 Cape
    dw $9500, pal_0        ; 1A Mirror
    dw $9580, pal_0        ; 1B Glove
    dw $9700, pal_0        ; 1C Mitt
    dw $9880, pal_1        ; 1D Book
    dw $9900, pal_3        ; 1E Flippers
    dw $9980, pal_2        ; 1F Pearl

    dw $8000, pal_0        ; 20 Dummy 
    dw $9800, pal_0        ; 21 Net
    dw $9D80, pal_0        ; 22 Blue Tunic
    dw $9F00, pal_1        ; 23 Red Tunic
    dw $AB80, pal_0        ; 24 Dummy - key
    dw $AD00, pal_0        ; 25 Dummy - compass
    dw $A280, pal_e1        ; 26 Heart Container - no anim
    dw $8C00, pal_3        ; 27 Bomb 1
    dw $A680, pal_3        ; 28 3 Bombs                     
    dw $8E00, pal_1        ; 29 Mushroom
    dw $AE80, pal_2        ; 2A Red Boomerang
    dw $9A80, pal_1        ; 2B Red Potion
    dw $9C00, pal_1        ; 2C Green Potion
    dw $9C00, pal_3        ; 2D Blue Potion
    dw $8000, pal_0        ; 2E Dummy - red
    dw $8000, pal_0        ; 2F Dummy - green

    dw $8000, pal_0        ; 30 Dummy - blue
    dw $A800, pal_3        ; 31 10 Bombs
    dw $AB00, pal_0        ; 32 Dummy - big key
    dw $AD80, pal_0        ; 33 Dummy - map
    dw $A880, pal_1        ; 34 1 Rupee
    dw $AA00, pal_3        ; 35 5 Rupees
    dw $AA80, pal_e1        ; 36 20 Rupees
    dw $8000, pal_0        ; 37 Dummy - Pendant of Courage
    dw $8000, pal_0        ; 38 Dummy - Pendant of Wisdom
    dw $8000, pal_0        ; 39 Dummy - Pendant of Power
    dw $8000, pal_0        ; 3A Bow and arrows
    dw $8000, pal_0        ; 3B Bow and silver Arrows
    dw $9E00, pal_0        ; 3C Bee
    dw $9100, pal_0        ; 3D Fairy
    dw $A280, pal_e1        ; 3E Heart Container - Boss
    dw $A280, pal_e1        ; 3F Heart Container - Sanc

    dw $AC80, pal_1        ; 40 100 Rupees
    dw $AC00, pal_1        ; 41 50 Rupees
    dw $8000, pal_0        ; 42 Dummy - small heart
    dw $A400, pal_0        ; 43 1 Arrow
    dw $A600, pal_0        ; 44 10 Arrows
    dw $8000, pal_0        ; 45 Dummy - small magic
    dw $8A80, pal_1        ; 46 300 Rupees
    dw $AA80, pal_e1        ; 47 20 Rupees
    dw $9E80, pal_0        ; 48 Good Bee
    dw $A780, pal_0        ; 49 Fighter Sword
    dw $8000, pal_0        ; 4A Dummy - activated flute
    dw $9780, pal_2        ; 4B Boots                       
    dw $8000, pal_0        ; 4C Dummy - 50+bombs
    dw $8000, pal_0        ; 4D Dummy - 70+arrows
    dw $A180, pal_1        ; 4E Half Magic
    dw $A300, pal_1        ; 4F Quarter Magic               

    dw $9B00, pal_0        ; 50 Master Sword
    dw $A380, pal_3        ; 51 +5 Bombs
    dw $A500, pal_3        ; 52 +10 Bombs
    dw $A580, pal_0        ; 53 +5 Arrows
    dw $A700, pal_0        ; 54 +10 Arrows
    dw $0000, pal_0        ; 55 Dummy - Programmable 1
    dw $0000, pal_0        ; 56 Dummy - Programmable 2
    dw $0000, pal_0        ; 57 Dummy - Programmable 3
    dw $AE00, pal_0        ; 58 Silver Arrows

    dw $0000, $0000        ; 59 Unused (Rupoor)        
    dw $0000, $0000        ; 5A Unused (Null Item)     
    dw $0000, $0000        ; 5B Unused (Red Clock)     
    dw $0000, $0000        ; 5C Unused (Blue Clock)    
    dw $0000, $0000        ; 5D Unused (Green Clock)   
    dw $0000, $0000        ; 5E Progressive Sword
    dw $0000, $0000        ; 5F Progressive Shield

    dw $0000, pal_0        ; 60 - Progressive Armor
    dw $0000, pal_0        ; 61 - Progressive Glove
    dw $B480, pal_1        ; 62 - Bombs                  (M
    dw $B200, pal_1        ; 63 - High Jump              (M
    dw $0000, $0000        ; 64 - Reserved - Progressive Bo
    dw $0000, $0000        ; 65 - Reserved - Progressive Bo
    dw $B500, pal_1        ; 66 - Long Beam              (M
    dw $B300, pal_1        ; 67 - Screw Attack           (M
    dw $B280, pal_0        ; 68 - Morph Ball             (M
    dw $B380, pal_1        ; 69 - Varia Suit             (M
    dw $A900, pal_0        ; 6A - Reserved - Goal Item (Sin
    dw $A900, pal_0        ; 6B - Reserved - Goal Item (Mul
    dw $B600, pal_2        ; 6C - Wave Beam              (M
    dw $B580, pal_3        ; 6D - Ice Beam               (M
    dw $B400, pal_1        ; 6E - Energy Tank            (M
    dw $C480, pal_1        ; 6F - Missiles               (M

    dw $AF00, pal_0        ; 70 - Crateria L1 Key        (S
    dw $AF80, pal_0        ; 71 - Crateria L2 Key        (S
    dw $AD80, pal_0        ; 72 - Ganons Tower Map
    dw $AD80, pal_0        ; 73 - Turtle Rock Map
    dw $AD80, pal_0        ; 74 - Thieves' Town Map
    dw $AD80, pal_0        ; 75 - Tower of Hera Map
    dw $AD80, pal_0        ; 76 - Ice Palace Map
    dw $AD80, pal_0        ; 77 - Skull Woods Map
    dw $AD80, pal_0        ; 78 - Misery Mire Map
    dw $AD80, pal_0        ; 79 - Palace Of Darkness Map
    dw $AD80, pal_0        ; 7A - Swamp Palace Map
    dw $8980, pal_0        ; 7B - Crateria Boss Key      (S
    dw $AD80, pal_0        ; 7C - Desert Palace Map
    dw $AD80, pal_0        ; 7D - Eastern Palace Map
    dw $8980, pal_0        ; 7E - Maridia Boss Key       (S
    dw $AD80, pal_0        ; 7F - Hyrule Castle Map

    dw $AF00, pal_0        ; 80 - Brinstar L1 Key        (S
    dw $AF80, pal_0        ; 81 - Brinstar L2 Key        (S
    dw $AD00, pal_0        ; 82 - Ganons Tower Compass
    dw $AD00, pal_0        ; 83 - Turtle Rock Compass
    dw $AD00, pal_0        ; 84 - Thieves' Town Compass
    dw $AD00, pal_0        ; 85 - Tower of Hera Compass
    dw $AD00, pal_0        ; 86 - Ice Palace Compass
    dw $AD00, pal_0        ; 87 - Skull Woods Compass
    dw $AD00, pal_0        ; 88 - Misery Mire Compass
    dw $AD00, pal_0        ; 89 - Palace of Darkness Compasss
    dw $AD00, pal_0        ; 8A - Swamp Palace Compass
    dw $8980, pal_0        ; 8B - Brinstar Boss Key      (S
    dw $AD00, pal_0        ; 8C - Desert Palace Compass
    dw $AD00, pal_0        ; 8D - Eastern Palace Compass
    dw $AF00, pal_0        ; 8E - Wrecked Ship L1 Key    (S
    dw $8980, pal_0        ; 8F - Wrecked Ship Boss Key  (S

    dw $AF00, pal_0        ; 90 - Norfair L1 Key         (S
    dw $AF80, pal_0        ; 91 - Norfair L2 Key         (S
    dw $AB00, pal_0        ; 92 - Ganons Tower Big Key
    dw $AB00, pal_0        ; 93 - Turtle Rock Big Key
    dw $AB00, pal_0        ; 94 - Thieves' Town Big Key
    dw $AB00, pal_0        ; 95 - Tower of Hera Big Key
    dw $AB00, pal_0        ; 96 - Ice Palace Big Key
    dw $AB00, pal_0        ; 97 - Skull Woods Big Key
    dw $AB00, pal_0        ; 98 - Misery Mire Big Key
    dw $AB00, pal_0        ; 99 - Palace of Darkness Big Keey
    dw $AB00, pal_0        ; 9A - Swamp Palace Big Key
    dw $8980, pal_0        ; 9B - Norfair Boss Key       (S
    dw $AB00, pal_0        ; 9C - Desert Palace Big Key
    dw $AB00, pal_0        ; 9D - Eastern Palace Big Key
    dw $AF00, pal_0        ; 9E - Lower Norfair L1 Key   (S
    dw $8980, pal_0        ; 9F - Lower Norfair Boss Key (S

    dw $AB80, pal_0        ; A0 - Hyrule Castle Small Key
    dw $AB80, pal_0        ; A1 - Sewers Small Key
    dw $AB80, pal_0        ; A2 - Eastern Palace Small Key
    dw $AB80, pal_0        ; A3 - Desert Palace Small Key
    dw $AB80, pal_0        ; A4 - Castle Tower Small Key
    dw $AB80, pal_0        ; A5 - Swamp Palace Small Key
    dw $AB80, pal_0        ; A6 - Palace of Darkness Small  Key
    dw $AB80, pal_0        ; A7 - Misery Mire Small Key
    dw $AB80, pal_0        ; A8 - Skull Woods Small Key
    dw $AB80, pal_0        ; A9 - Ice Palace Small Key
    dw $AB80, pal_0        ; AA - Tower of Hera Small Key
    dw $AB80, pal_0        ; AB - Thieves' Town Small Key
    dw $AB80, pal_0        ; AC - Turtle Rock Small Key
    dw $AB80, pal_0        ; AD - Ganons Tower Small Key
    dw $AF00, pal_0        ; AE - Maridia L1 Key         (S
    dw $AF80, pal_0        ; AF - Maridia L2 Key         (S

    dw $8100, pal_0        ; B0 - Grapple beam
    dw $8180, pal_0        ; B1 - X-ray scope
    dw $8280, pal_0        ; B2 - Varia suit
    dw $8200, pal_0        ; B3 - Spring ball
    dw $8680, pal_0        ; B4 - Morph ball
    dw $8480, pal_0        ; B5 - Screw attack
    dw $8080, pal_0        ; B6 - Gravity suit
    dw $8400, pal_0        ; B7 - Hi-Jump
    dw $8600, pal_0        ; B8 - Space jump
    dw $8000, pal_0        ; B9 - Bombs
    dw $8300, pal_0        ; BA - Speed booster
    dw $8380, pal_0        ; BB - Charge
    dw $8500, pal_ice      ; BC - Ice Beam
    dw $8580, pal_wave     ; BD - Wave beam
    dw $8780, pal_0        ; BE - Spazer
    dw $8700, pal_plasma   ; BF - Plasma beam

    dw $B100, pal_0        ; C0 - Energy Tankd to graphics data
    dw $8800, pal_0        ; C1 - Reserve tank
    dw $B000, pal_0        ; C2 - Missiled to graphics data
    dw $B080, pal_0        ; C3 - Super Missiled to graphics data
    dw $B180, pal_0        ; C4 - Power Bombd to graphics data
    dw $A980, pal_0        ; C5 - Kraid Boss Token     TODO
    dw $A980, pal_0        ; C6 - Phantoon Boss Token  TODO
    dw $A980, pal_0        ; C7 - Draygon Boss Token   TODO
    dw $A980, pal_0        ; C8 - Ridley Boss Token    TODO
    dw $0000, pal_0        ; C9 - Unused
    dw $8B80, pal_0        ; CA - Kraid Map 
    dw $8B80, pal_0        ; CB - Phantoon Map
    dw $8B80, pal_0        ; CC - Draygon Map
    dw $8B80, pal_0        ; CD - Ridley Map
    dw $0000, pal_0        ; CE - Unused
    dw $0000, pal_0        ; CF - Unused (Reserved)

    dw $BB00, pal_0        ; D0 - Bombs                (Z1)
    dw $B680, pal_0        ; D1 - Wooden Sword         (Z1)
    dw $C280, pal_0        ; D2 - White Sword          (Z1)
    dw $BD80, pal_1        ; D3 - Magical Sword        (Z1)
    dw $B700, pal_1        ; D4 - Bait                 (Z1)
    dw $B780, pal_0        ; D5 - Recorder             (Z1)
    dw $C200, pal_0        ; D6 - Blue Candle          (Z1)
    dw $B800, pal_1        ; D7 - Red Candle           (Z1)
    dw $B880, pal_0        ; D8 - Arrows               (Z1)
    dw $C300, pal_0        ; D9 - Silver Arrows        (Z1)
    dw $B900, pal_0        ; DA - Bow                  (Z1)
    dw $B980, pal_1        ; DB - Magical Key          (Z1)
    dw $C100, pal_0        ; DC - Raft                 (Z1)
    dw $C180, pal_0        ; DD - Stepladder           (Z1)
    dw $0000, pal_0        ; DE - Unused?              (Z1)
    dw $BA80, pal_0        ; DF - 5 Rupees             (Z1)

    dw $BE00, pal_3        ; E0 - Magical Rod          (Z1)
    dw $BC80, pal_1        ; E1 - Book of Magic        (Z1)
    dw $C400, pal_0        ; E2 - Blue Ring            (Z1)
    dw $BD00, pal_1        ; E3 - Red Ring             (Z1)
    dw $BF00, pal_1        ; E4 - Power Bracelet       (Z1)
    dw $BE80, pal_3        ; E5 - Letter               (Z1)
    dw $C080, pal_1        ; E6 - Compass              (Z1)
    dw $BE80, pal_0        ; E7 - Dungeon Map          (Z1)
    dw $BA80, pal_1        ; E8 - 1 Rupee              (Z1)
    dw $BA00, pal_1        ; E9 - Small Key            (Z1)
    dw $C000, pal_1        ; EA - Heart Container      (Z1)
    dw $0000, pal_0        ; EB - Triforce Fragment    (Z1)
    dw $BF80, pal_0        ; EC - Magical Shield       (Z1)
    dw $BB80, pal_0        ; ED - Boomerang            (Z1)
    dw $BB80, pal_3        ; EE - Magical Boomerang    (Z1)
    dw $C380, pal_0        ; EF - Blue Potion          (Z1)

    dw $BC00, pal_1        ; F0 - Red Potion           (Z1)
    dw $0000, pal_0        ; F1 - Clock                (Z1)
    dw $0000, pal_0        ; F2 - Small Heart          (Z1)
    dw $0000, pal_0        ; F3 - Fairy                (Z1)
    dw $0000, pal_0        ; F4 - Unused
    dw $0000, pal_0        ; F5 - Unused
    dw $0000, pal_0        ; F6 - Unused
    dw $0000, pal_0        ; F7 - Unused
    dw $0000, pal_0        ; F8 - Unused
    dw $0000, pal_0        ; F9 - Unused
    dw $0000, pal_0        ; FA - Unused
    dw $0000, pal_0        ; FB - Unused
    dw $0000, pal_0        ; FC - Unused
    dw $0000, pal_0        ; FD - Unused
    dw $0000, pal_0        ; FE - Unused
    dw $0000, pal_0        ; FF - Unused (Reserved)



