!MAX_DYNAMIC_SLOTS = 4

SaveItems:
    php
    rep #$30

    lda #$0002                     ; Copy all items back to their original game on save
    jsl mb_RestoreItemBuffers      ; Restore all item buffers to proper SRAM in all games
    
    jsl backup_wram                ; Backup WRAM to WRAM-buffer
    lda #$0002
    jsl mb_CopyItemBuffer          ; Copy Z1 items from WRAM-buffer into item buffer
    
    plp
    lda.b #$00
    sta.b $11
    rtl

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

;
; Executes when any item is being picked up
;
TakeItem_ShowItemOverlay:
    pha
    cmp #$1b
    beq .end
    cmp #$0e
    beq .end
    cmp #$00
    beq .end
    cmp #$0f
    beq .end
    cmp #$18
    beq .end
    cmp #$21
    beq .end
    cmp #$22
    beq .end
    cmp #$23
    beq .end


    cmp #$30
    bcs .extended
    clc : adc #$d0
    bra .show
.extended
    sec : sbc #$30
.show
    jsl nes_overlay_show_item
.end
    ldx #$08 : stx $0602
    pla
    rtl

; Executes when links picks up an item of class 0x30 or higher
; Class in A
; Item Id in X
TakeItem_SetItemValueFF_extended:
    phy : phx : pha
    lda.l ItemIdToDescriptor_extended, x
    cmp #$40
    bcc .notExtended

    ; Class 40 extended item - write to out of game inventory
    ; If we want to have some kind of extra info there's the lower nybble of the descriptor
    ; saved at $0A here
    txa
    sec : sbc #$30
    jsl mb_WriteItemToInventory
    pla : plx : ply
    sec
    rtl

; Run original code and return
.notExtended
    pla : plx : ply
    cpy #$07
    bne +
    cmp #$03
    bcc +
    lda #$02
+
    clc
    rtl

;
; Loads the underworld room item Id from our extended tables instead of from
; the original level data (this lets us use the full 8-bit for item id:s)
;
LoadRoomItemIdUW_extended:
    phx
    ldy $EB
    
    ; Load dungeon id
    lda.b $10
    cmp.b #$07
    bcc .firstLevels
    tya : clc : adc.b #$80 : tax
    bra .loadItem
.firstLevels
    tyx
.loadItem
    lda.l RoomItemsUW_extended, x
    plx
    cmp.b #$2F
    rtl


; Params:
; X: cycle sprite index / object index
; Y: item slot
; [00]: X
; [01]: Y
; [04]: left sprite attributes
; [05]: right sprite attributes
; [07]: Has two sides
; [0A]: X separation
; [0C]: frame
; [0F]: flip horizontally
; [0343]: LeftSpriteOffset
; [0344]: RightSpriteOffset
print "Anim_WriteSpecificItemSprites_extended = ", pc
Anim_WriteSpecificItemSprites_extended:
    stx $08     ;  ATS - store object index in [X] regardless of which branch we take
    cpy.b #$30
    bcs .extended
    lda #$01                    
    sta $07
    lda #$08                    
    clc
    rtl

.extended
    phx
    tya
    jsl PrepDynamicItem

    ldx.w DynamicItemSlot
    lda.w DynamicItemSlots, x
    sta $02
    inc #2
    sta $03
    txa : asl : tax
    lda.w DynamicItemAttrs, x
    sta $04
    lda.w DynamicItemAttrs+$1, x
    sta $05
    lda.b #$01
    sta $07 ; Has two sides
    lda.b #$08
    sta $0A ; X separation

    plx
    sec
    rtl

;  ATS - Currently unused
GetDynamicItemIndex:
    phx
    ldx #!MAX_DYNAMIC_SLOTS
-    
    cmp.w DynamicItemIndexes, x
    beq .found
    inx
    bne -
    bra .notFound
.found
    stx.w DynamicItemSlot
    plx
    rtl

.notFound
    ldx.w #$ff
    stx.w DynamicItemSlot
    plx
    rtl

;
; [A] = Item Slot
; Returns the correct item slot for this item slot as loaded
;
PrepDynamicItem:
    pha : phx : phy
    ldx #$00

-    
    cmp.w DynamicItemIndexes, x
    beq .found
    inx
    cpx #!MAX_DYNAMIC_SLOTS
    bne -
    bra .notFound

; This item is already loaded, return the slot we found it at
.found
    sep #$30
    stx.w DynamicItemSlot
    ply : plx : pla
    rtl

.notFound
    ; Store the item id in the slot
    pha
    ldx.w DynamicItemIndex
    sta.w DynamicItemIndexes, x
    txa : asl : tay
    pla

    rep #$30
    and #$00ff

    ; Get the ROM address containing the item data to be uploaded
    sec : sbc #$0030 
    jsl mb_CheckProgressiveItemLong
    asl #2 : tax
    
    ; Store Attribute data
    lda.l ItemData+$2, x 
    sta.w DynamicItemAttrs, y

    ; Load offset into item graphics data

    ; TODO: update for rupee animation

    lda.l ItemData, x : pha

    ; Prep SNES PPU Transfer string
    lda.l SnesPPUDataStringPtr
    tay

    lda.l #SnesPPUDataString
    sta $F0

    lda.l #(SnesPPUDataString>>8)
    sta $F1

    lda.w #$0005
    sta [$F0], y
    iny #2

    lda.w DynamicItemIndex : asl : tax
    lda.l DynamicItemVramOffsets, x

    sta [$F0], y
    iny #4
    
    lda.w #$0080
    sta [$F0], y
    iny #2

    ; Get our ROM address back
    pla 
    sta [$F0], y
    iny #2    
    
    lda #(nes_new_item_graphics>>16)
    sta [$F0], y
    iny #2    
    
    lda #$0000
    sta [$F0], y

    tya    
    sta.l SnesPPUDataStringPtr

    sep #$30
    ldx.w DynamicItemIndex
    lda.l DynamicItemVramSlots, x
    sta.w DynamicItemSlots, x
    stx.w DynamicItemSlot

    lda.w DynamicItemIndex
    inc
    cmp #$04
    bne +
    lda #$00
+
    sta.w DynamicItemIndex

    ply : plx : pla
    rtl

DynamicItemVramOffsets:
    dw $1300
    dw $1340
    dw $1380
    dw $13C0

DynamicItemVramSlots:
    db $30
    db $34
    db $38
    db $3C

; New item data (for external items) - We use item id:s 0x30 and up
; So when working with this data, just remove 0x30 from the index
;
; There's a problem here though with space for items
; Even with placing Z3 items at the end of this mapping
; we can't use items above 0xCF (because 0xD0 to 0xFF is phased out by subtracting from the Z1 id)
; Right now we're using D0->DF for SM keys, but we can move them to an earlier slot
;

; This will be the SM + ALTTP Items (offset by 0x30)

ItemData:
    ;  addr   attrs
    dw $A780, $0404     ; 00 - Dummy - L1SwordAndShield 
    dw $9B00, $0404     ; 01 - Master Sword
    dw $9B80, $0505     ; 02 - Tempered Sword
    dw $9D00, $0404     ; 02 - Gold Sword
    dw $9F80, $0707     ; 04 - Shield
    dw $A000, $3434     ; 05 - Red Shield
    dw $A080, $0404     ; 06 - Mirror Shield
    dw $8900, $1414     ; 07 - Firerod
    dw $9000, $2424     ; 08 - Icerod
    dw $9480, $0505     ; 09 - Hammer
    dw $8880, $0404     ; 0A - Hookshot
    dw $8A00, $0404     ; 0B - Bow
    dw $A100, $2424     ; 0C - Blue Boomerang
    dw $8E80, $0404     ; 0D - Powder
    dw $9E00, $0404     ; 0E - Dummy - Bee (bottle content)
    dw $9080, $0404     ; 0F - Bombos
    
    dw $9200, $0404     ; 10 - Ether
    dw $9280, $0404     ; 11 - Quake
    dw $9400, $0505     ; 12 - Lamp
    dw $9600, $0404     ; 13 - Shovel
    dw $9680, $0707     ; 14 - Flute                      
    dw $9180, $1414     ; 15 - Somaria
    dw $9A00, $0404     ; 16 - Bottle
    dw $A200, $1414     ; 17 - Piece of Heart
    dw $9300, $0707     ; 18 - Byrna
    dw $9380, $1414     ; 19 - Cape
    dw $9500, $0404     ; 1A - Mirror
    dw $9580, $0404     ; 1B - Glove
    dw $9700, $0404     ; 1C - Mitt
    dw $9880, $0505     ; 1D - Book
    dw $9900, $0707     ; 1E - Flippers
    dw $9980, $1414     ; 1F - Pearl
    
    dw $8000, $0404     ; 20 - Dummy 
    dw $9800, $0404     ; 21 - Net
    dw $9D80, $0404     ; 22 - Blue Tunic
    dw $9F00, $0505     ; 23 - Red Tunic
    dw $AB80, $0404     ; 24 - Dummy - key
    dw $AD00, $0404     ; 25 - Dummy - compass
    dw $A280, $1414     ; 26 - Heart Container - no anim
    dw $8C00, $0707     ; 27 - Bomb 1
    dw $A680, $0707     ; 28 - 3 Bombs                    
    dw $8E00, $0505     ; 29 - Mushroom
    dw $AE80, $1414     ; 2A - Red Boomerang
    dw $9A80, $0505     ; 2B - Red Potion
    dw $9C00, $0505     ; 2C - Green Potion
    dw $9C00, $0707     ; 2D - Blue Potion
    dw $8000, $0404     ; 2E - Dummy - red
    dw $8000, $0404     ; 2F - Dummy - green
    
    dw $8000, $0404     ; 30 - Dummy - blue
    dw $A800, $0707     ; 31 - 10 Bombs
    dw $AB00, $0404     ; 32 - Dummy - big key
    dw $AD80, $0404     ; 33 - Dummy - map
    dw $A880, $3434     ; 34 - 1 Rupee
    dw $AA00, $2424     ; 35 - 5 Rupees
    dw $AA80, $1414     ; 36 - 20 Rupees
    dw $8000, $0404     ; 37 - Dummy - Pendant of Courage
    dw $8000, $0404     ; 38 - Dummy - Pendant of Wisdom
    dw $8000, $0404     ; 39 - Dummy - Pendant of Power
    dw $8000, $0404     ; 3A - Bow and arrows
    dw $8000, $0404     ; 3B - Bow and silver Arrows
    dw $9E00, $0404     ; 3C - Bee
    dw $9100, $0404     ; 3D - Fairy
    dw $A280, $1414     ; 3E - Heart Container - Boss
    dw $A280, $1414     ; 3F - Heart Container - Sanc
    
    dw $AC80, $0505     ; 40 - 100 Rupees
    dw $AC00, $0505     ; 41 - 50 Rupees
    dw $8000, $0404     ; 42 - Dummy - small heart
    dw $A400, $0404     ; 43 - 1 Arrow
    dw $A600, $0404     ; 44 - 10 Arrows
    dw $8000, $0404     ; 45 - Dummy - small magic
    dw $8A80, $0505     ; 46 - 300 Rupees
    dw $AA80, $1414     ; 47 - 20 Rupees
    dw $9E80, $0404     ; 48 - Good Bee
    dw $A780, $0404     ; 49 - Fighter Sword
    dw $8000, $0404     ; 4A - Dummy - activated flute
    dw $9780, $1414     ; 4B - Boots                      
    dw $8000, $0404     ; 4C - Dummy - 50+bombs
    dw $8000, $0404     ; 4D - Dummy - 70+arrows
    dw $A180, $0505     ; 4E - Half Magic
    dw $A300, $0505     ; 4F - Quarter Magic              
    
    dw $9B00, $0404     ; 50 - Master Sword
    dw $A380, $0707     ; 51 - +5 Bombs
    dw $A500, $0707     ; 52 - +10 Bombs
    dw $A580, $0404     ; 53 - +5 Arrows
    dw $A700, $0404     ; 54 - +10 Arrows
    dw $0000, $0404     ; 55 - Dummy - Programmable 1
    dw $0000, $0404     ; 56 - Dummy - Programmable 2
    dw $0000, $0404     ; 57 - Dummy - Programmable 3
    dw $AE00, $0404     ; 58 - Silver Arrows

    dw $0000, $0000     ; 59 - Unused (Rupoor)        
    dw $0000, $0000     ; 5A - Unused (Null Item)     
    dw $0000, $0000     ; 5B - Unused (Red Clock)     
    dw $0000, $0000     ; 5C - Unused (Blue Clock)    
    dw $0000, $0000     ; 5D - Unused (Green Clock)   
    dw $0000, $0000     ; 5E - Progressive Sword
    dw $0000, $0000     ; 5F - Progressive Shield

    dw $0000, $0404     ; 60 - Progressive Armor
    dw $0000, $0404     ; 61 - Progressive Glove
    dw $B480, $0505     ; 62 - Bombs                  (M1)
    dw $B200, $0505     ; 63 - High Jump              (M1)
    dw $0000, $0404     ; 64 - Reserved - Progressive Bow                 (Why two here? Are both used?)
    dw $0000, $0404     ; 65 - Reserved - Progressive Bow                 (Why two here? Are both used?)
    dw $B500, $0505     ; 66 - Long Beam              (M1)
    dw $B300, $0505     ; 67 - Screw Attack           (M1)
    dw $B280, $0404     ; 68 - Morph Ball             (M1)
    dw $B380, $0505     ; 69 - Varia Suit             (M1)
    dw $A900, $0404     ; 6A - Reserved - Goal Item (Single/Triforce)
    dw $A900, $0404     ; 6B - Reserved - Goal Item (Multi/Power Star)    (Is this used for anything)
    dw $B600, $0606     ; 6C - Wave Beam              (M1)
    dw $B580, $0707     ; 6D - Ice Beam               (M1)
    dw $B400, $0505     ; 6E - Energy Tank            (M1)
    dw $C480, $0505     ; 6F - Missiles               (M1)

    dw $AF00, $0404     ; 70 - Crateria L1 Key        (SM)
    dw $AF80, $0404     ; 71 - Crateria L2 Key        (SM)
    dw $AD80, $0404     ; 72 - Ganons Tower Map
    dw $AD80, $0404     ; 73 - Turtle Rock Map
    dw $AD80, $0404     ; 74 - Thieves' Town Map
    dw $AD80, $0404     ; 75 - Tower of Hera Map
    dw $AD80, $0404     ; 76 - Ice Palace Map
    dw $AD80, $0404     ; 77 - Skull Woods Map
    dw $AD80, $0404     ; 78 - Misery Mire Map
    dw $AD80, $0404     ; 79 - Palace Of Darkness Map
    dw $AD80, $0404     ; 7A - Swamp Palace Map
    dw $8980, $0404     ; 7B - Crateria Boss Key      (SM)
    dw $AD80, $0404     ; 7C - Desert Palace Map
    dw $AD80, $0404     ; 7D - Eastern Palace Map
    dw $8980, $0404     ; 7E - Maridia Boss Key       (SM)
    dw $AD80, $0404     ; 7F - Hyrule Castle Map

    dw $AF00, $0404     ; 80 - Brinstar L1 Key        (SM)
    dw $AF80, $0404     ; 81 - Brinstar L2 Key        (SM)
    dw $AD00, $0404     ; 82 - Ganons Tower Compass
    dw $AD00, $0404     ; 83 - Turtle Rock Compass
    dw $AD00, $0404     ; 84 - Thieves' Town Compass
    dw $AD00, $0404     ; 85 - Tower of Hera Compass
    dw $AD00, $0404     ; 86 - Ice Palace Compass
    dw $AD00, $0404     ; 87 - Skull Woods Compass
    dw $AD00, $0404     ; 88 - Misery Mire Compass
    dw $AD00, $0404     ; 89 - Palace of Darkness Compass
    dw $AD00, $0404     ; 8A - Swamp Palace Compass
    dw $8980, $0404     ; 8B - Brinstar Boss Key      (SM)
    dw $AD00, $0404     ; 8C - Desert Palace Compass
    dw $AD00, $0404     ; 8D - Eastern Palace Compass
    dw $AF00, $0404     ; 8E - Wrecked Ship L1 Key    (SM)
    dw $8980, $0404     ; 8F - Wrecked Ship Boss Key  (SM)

    dw $AF00, $0404     ; 90 - Norfair L1 Key         (SM)
    dw $AF80, $0404     ; 91 - Norfair L2 Key         (SM)
    dw $AB00, $0404     ; 92 - Ganons Tower Big Key
    dw $AB00, $0404     ; 93 - Turtle Rock Big Key
    dw $AB00, $0404     ; 94 - Thieves' Town Big Key
    dw $AB00, $0404     ; 95 - Tower of Hera Big Key
    dw $AB00, $0404     ; 96 - Ice Palace Big Key
    dw $AB00, $0404     ; 97 - Skull Woods Big Key
    dw $AB00, $0404     ; 98 - Misery Mire Big Key
    dw $AB00, $0404     ; 99 - Palace of Darkness Big Key
    dw $AB00, $0404     ; 9A - Swamp Palace Big Key
    dw $8980, $0404     ; 9B - Norfair Boss Key       (SM)
    dw $AB00, $0404     ; 9C - Desert Palace Big Key
    dw $AB00, $0404     ; 9D - Eastern Palace Big Key
    dw $AF00, $0404     ; 9E - Lower Norfair L1 Key   (SM)
    dw $8980, $0404     ; 9F - Lower Norfair Boss Key (SM)

    dw $AB80, $0404     ; A0 - Hyrule Castle Small Key
    dw $AB80, $0404     ; A1 - Sewers Small Key
    dw $AB80, $0404     ; A2 - Eastern Palace Small Key
    dw $AB80, $0404     ; A3 - Desert Palace Small Key
    dw $AB80, $0404     ; A4 - Castle Tower Small Key
    dw $AB80, $0404     ; A5 - Swamp Palace Small Key
    dw $AB80, $0404     ; A6 - Palace of Darkness Small Key
    dw $AB80, $0404     ; A7 - Misery Mire Small Key
    dw $AB80, $0404     ; A8 - Skull Woods Small Key
    dw $AB80, $0404     ; A9 - Ice Palace Small Key
    dw $AB80, $0404     ; AA - Tower of Hera Small Key
    dw $AB80, $0404     ; AB - Thieves' Town Small Key
    dw $AB80, $0404     ; AC - Turtle Rock Small Key
    dw $AB80, $0404     ; AD - Ganons Tower Small Key
    dw $AF00, $0404     ; AE - Maridia L1 Key         (SM)
    dw $AF80, $0404     ; AF - Maridia L2 Key         (SM)

    dw $8100, $0404     ; B0 - Grapple beam
    dw $8180, $0404     ; B1 - X-ray scope
    dw $8280, $0404     ; B2 - Varia suit
    dw $8200, $0404     ; B3 - Spring ball
    dw $8680, $0404     ; B4 - Morph ball
    dw $8480, $0404     ; B5 - Screw attack
    dw $8080, $0404     ; B6 - Gravity suit
    dw $8400, $0404     ; B7 - Hi-Jump
    dw $8600, $0404     ; B8 - Space jump
    dw $8000, $0404     ; B9 - Bombs
    dw $8300, $0404     ; BA - Speed booster
    dw $8380, $0404     ; BB - Charge
    dw $8500, $0404     ; BC - Ice Beam
    dw $8580, $0404     ; BD - Wave beam
    dw $8780, $0404     ; BE - Spazer
    dw $8700, $0404     ; BF - Plasma beam

    dw $B100, $0404     ; C0 - Energy Tank
    dw $8800, $0404     ; C1 - Reserve tank
    dw $B000, $0404     ; C2 - Missile
    dw $B080, $0404     ; C3 - Super Missile
    dw $B180, $0404     ; C4 - Power Bomb
    dw $A980, $0404     ; C5 - Kraid Boss Token     TODO: Add actual boss token graphics
    dw $A980, $0404     ; C6 - Phantoon Boss Token  TODO: Add actual boss token graphics
    dw $A980, $0404     ; C7 - Draygon Boss Token   TODO: Add actual boss token graphics
    dw $A980, $0404     ; C8 - Ridley Boss Token    TODO: Add actual boss token graphics
    dw $0000, $0404     ; C9 - Unused
    dw $8B80, $0404     ; CA - Kraid Map 
    dw $8B80, $0404     ; CB - Phantoon Map
    dw $8B80, $0404     ; CC - Draygon Map
    dw $8B80, $0404     ; CD - Ridley Map
    dw $0000, $0404     ; CE - Unused
    dw $0000, $0404     ; CF - Unused (Reserved)


    ; Note - The can't be accessed from Z1 atm (due to all items being offset by 0x30)
    ; But these are in the same order as original Z1 items, so they're at (00-2F) in the game as their
    ; original Z1 counterparts

    dw $BB00, $0404     ; D0 - Bombs                (Z1)
    dw $B680, $0404     ; D1 - Wooden Sword         (Z1)
    dw $C280, $0404     ; D2 - White Sword          (Z1)
    dw $BD80, $0505     ; D3 - Magical Sword        (Z1)
    dw $B700, $0505     ; D4 - Bait                 (Z1)
    dw $B780, $0404     ; D5 - Recorder             (Z1)
    dw $C200, $0404     ; D6 - Blue Candle          (Z1)
    dw $B800, $0505     ; D7 - Red Candle           (Z1)
    dw $B880, $0404     ; D8 - Arrows               (Z1)
    dw $C300, $0404     ; D9 - Silver Arrows        (Z1)
    dw $B900, $0404     ; DA - Bow                  (Z1)
    dw $B980, $0505     ; DB - Magical Key          (Z1)
    dw $C100, $0404     ; DC - Raft                 (Z1)
    dw $C180, $0404     ; DD - Stepladder           (Z1)
    dw $0000, $0404     ; DE - Unused?              (Z1) ; Internal item
    dw $BA80, $0404     ; DF - 5 Rupees             (Z1)

    dw $BE00, $0707     ; E0 - Magical Rod          (Z1)
    dw $BC80, $0505     ; E1 - Book of Magic        (Z1)
    dw $C400, $0404     ; E2 - Blue Ring            (Z1)
    dw $BD00, $0505     ; E3 - Red Ring             (Z1)
    dw $BF00, $0505     ; E4 - Power Bracelet       (Z1)
    dw $BE80, $0707     ; E5 - Letter               (Z1)
    dw $C080, $0505     ; E6 - Compass              (Z1)
    dw $BE80, $0404     ; E7 - Dungeon Map          (Z1)
    dw $BA80, $0505     ; E8 - 1 Rupee              (Z1)
    dw $BA00, $0505     ; E9 - Small Key            (Z1)
    dw $C000, $3434     ; EA - Heart Container      (Z1)
    dw $0000, $0404     ; EB - Triforce Fragment    (Z1)    ; TODO: Add this when shuffling rewards
    dw $BF80, $0404     ; EC - Magical Shield       (Z1)
    dw $BB80, $0404     ; ED - Boomerang            (Z1)
    dw $BB80, $0707     ; EE - Magical Boomerang    (Z1)
    dw $C380, $0404     ; EF - Blue Potion          (Z1)

    dw $BC00, $0505     ; F0 - Red Potion           (Z1)
    dw $0000, $0000     ; F1 - Clock                (Z1)  ; Internal item
    dw $0000, $0000     ; F2 - Small Heart          (Z1)  ; Internal item
    dw $0000, $0000     ; F3 - Fairy                (Z1)  ; Internal item
    dw $0000, $0000     ; F4 - Unused
    dw $0000, $0000     ; F5 - Unused
    dw $0000, $0000     ; F6 - Unused
    dw $0000, $0000     ; F7 - Unused
    dw $0000, $0000     ; F8 - Unused
    dw $0000, $0000     ; F9 - Unused
    dw $0000, $0000     ; FA - Unused
    dw $0000, $0000     ; FB - Unused
    dw $0000, $0000     ; FC - Unused
    dw $0000, $0000     ; FD - Unused
    dw $0000, $0000     ; FE - Unused
    dw $0000, $0000     ; FF - Unused (Reserved)



