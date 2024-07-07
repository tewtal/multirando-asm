!IBranchItem = #$887C
!ISetItem = #$8899
!ILoadSpecialGraphics = #$8764
!ISetGoto = #$8A24
!ISetPreInstructionCode = #$86C1
!IDrawCustom1 = #$E04F
!IDrawCustom2 = #$E067
!IGoto = #$8724
!IKill = #$86BC
!IPlayTrackNow = #$8BDD
!IJSR = #$8A2E
!ISetCounter8 = #$874E
!IGotoDecrement = #$873F
!IGotoIfDoorSet = #$8A72
!ISleep = #$86B4
!IVisibleItem = #i_visible_item
!IChozoItem = #i_chozo_item
!IHiddenItem = #i_hidden_item
!ILoadCustomGraphics = #i_load_custom_graphics
!IPickup = #i_pickup
!IStartDrawLoop = #i_start_draw_loop
!IStartHiddenDrawLoop = #i_start_hidden_draw_loop

!DP_MsgRewardType = $3A
!DP_MsgBitFlag = $3E
!DP_MsgOverride = $40

!ITEM_PLM_BUF = $7ffb00

org $C12D7C   ; Patch to Crateria surface palette for Z3 items e.g. PoH, Pearl
    incbin "../../data/Crateria_palette.bin"

org $C13798   ; Crocomire's room changes colors $1E, $2E, $2F, $3E, and $3F for reasons unknown.
    incbin "../../data/Crocomire_palette.bin"

org $848794
    jsr get_item_bank

org $DC0000
new_item_graphics_data:
    incbin "../../data/newitems_sm.bin"

;  Replace terminator item for testing
; org $8f8432
;    dw $Efe0
; org $8f8432+$5
;    db $50

; Add our new custom item PLMs
org $84efe0
plm_items:
    dw i_visible_item_setup, v_item       ;efe0
    dw i_visible_item_setup, c_item       ;efe4
    dw i_hidden_item_setup,  h_item       ;efe8
v_item:
    dw !IVisibleItem
c_item:
    dw !IChozoItem
h_item:
    dw !IHiddenItem

i_visible_item:
    lda #$0006
    jsr i_load_rando_item
    rts

i_chozo_item:
    lda #$0008
    jsr i_load_rando_item
    rts

i_hidden_item:
    lda #$000A
    jsr i_load_rando_item
    rts

i_load_rando_item:
    cmp #$0006 : bne +
    ldy #p_visible_item
    bra .end
+   cmp #$0008 : bne +    
    ldy #p_chozo_item
    bra .end
+   ldy #p_hidden_item

.end
    rts

p_visible_item:
    dw !ILoadCustomGraphics
    dw !IBranchItem, .end
    dw !ISetGoto, .trigger
    dw !ISetPreInstructionCode, $df89
    ;dw !IStartDrawLoop
    .loop
    dw !IDrawCustom1
    dw !IDrawCustom2
    dw !IGoto, .loop
    .trigger
    dw !ISetItem
    dw SOUNDFX : db !Click
    dw !IPickup
    .end
    dw !IGoto, $dfa9

p_chozo_item:
    dw !ILoadCustomGraphics
    dw !IBranchItem, .end
    dw !IJSR, $dfaf
    dw !IJSR, $dfc7
    dw !ISetGoto, .trigger
    dw !ISetPreInstructionCode, $df89
    dw !ISetCounter8 : db $16
    ;dw !IStartDrawLoop
    .loop
    dw !IDrawCustom1
    dw !IDrawCustom2
    dw !IGoto, .loop
    .trigger
    dw !ISetItem
    dw SOUNDFX : db !Click
    dw !IPickup
    .end
    dw $0001, $a2b5
    dw !IKill   

p_hidden_item:
    dw !ILoadCustomGraphics
    .loop2
    dw !IJSR, $e007
    dw !IBranchItem, .end
    dw !ISetGoto, .trigger
    dw !ISetPreInstructionCode, $df89
    dw !ISetCounter8 : db $16
    ;dw !IStartHiddenDrawLoop
    .loop
    dw !IDrawCustom1
    dw !IDrawCustom2
    dw !IGotoDecrement, .loop
    dw !IJSR, $e020
    dw !IGoto, .loop2
    .trigger
    dw !ISetItem
    dw SOUNDFX : db !Click
    dw !IPickup
    .end
    dw !IJSR, $e032
    dw !IGoto, .loop2

i_load_custom_graphics:
    phy : phx 
    lda.l !ITEM_PLM_BUF, x  ; Load item id

    %a8()
    sta $4202
    lda #$0A
    sta $4203
    nop : nop : %ai16()
    lda $4216               ; Multiply it by 0x0A
    clc
    adc #item_graphics
    tay                     ; Add it to the graphics table and transfer into Y
    lda $0000, y
    cmp #$1000
    bcc .no_custom    
    jsr $8764               ; Jump to original PLM graphics loading routine
    plx
    ply
    rts

.no_custom
    tay
    lda $0000, y
    sta.l $7edf0c, x
    plx
    ply
    rts

i_visible_item_setup:
    phy : phx
    jsr load_item_id                
    %a8()
    sta $4202
    lda #$0A
    sta $4203
    nop : nop : %ai16()
    lda $4216                       ; Multiply it by 0x0A
    tax

    lda item_graphics, x
    cmp #$1000
    bcc .no_custom
    plx : ply
    jmp $ee64

.no_custom
    plx : ply
    tyx
    sta.l $7edf0c, x
    jmp $ee64

i_hidden_item_setup:
    phy : phx
    jsr load_item_id
    %a8()
    sta $4202
    lda #$0A
    sta $4203
    nop : nop : %ai16()
    lda $4216                       ; Multiply it by 0x0A
    tax

    lda item_graphics, x
    cmp #$1000
    bcc .no_custom
    plx : ply
    jmp $ee8e
    
.no_custom
    plx : ply
    tyx
    sta.l $7edf0c, x
    jmp $ee8e

i_pickup:
    phx : phy : php
    lda !ITEM_PLM_BUF, x : pha
    
    ; Check if this item belongs to SM
    jsl mb_CheckItemGame
    bne .notSm
    pla

    jsr receive_sm_item
    bra .end

.notSm
    ; If this item belongs to another game, then use common item routine
    pla : pha
    jsl mb_WriteItemToInventory

    ; Show item message here
    pla : sta !DP_MsgRewardType : asl : tax
    lda.l item_message_table, x
    and #$00ff
    jsl $858080

.end
    plp : ply : plx
    rts

; This should only ever be called for new items
receive_sm_item:
    cmp #$0020
    bcs .keycard
    cmp #$001A
    bcs .mapMarker
    bra .end

.keycard
    and #$000f
    sta !DP_MsgRewardType       ; Store keycard index
    clc : adc #$0080            ; Turn this into an event id
    jsl $8081fa                 ; Set event (receive keycard)
    lda #$0022
    jsl $858080                 ; Display message 62 - keycard
    bra .end

.mapMarker
    and #$000f
    sec : sbc #$000a
    sta !DP_MsgRewardType       ; Store map marker index
    clc : adc #$00a0            ; Set event (map marker received)
    jsl $8081fa
    lda #$0024
    jsl $858080                 ; Display message 64 - map marker
    bra .end      

.end
    rts

load_item_id:
    phx : phy

    ; Load the item id from the PLM room argument
    ; Store it in X, and then clear the item id from the room argument
    lda $1dc7, y
    pha : xba : and #$00ff
    tax : pla
    and #$00ff
    sta $1dc7, y
    txa
    
    ; Potentially upgrade this progressive item
    jsl mb_CheckProgressiveItemLong
    ply
    tyx
    sta !ITEM_PLM_BUF, x
    plx
    rts


item_graphics:
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 00 Dummy - L1SwordAndShield        
    dw $5A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 01 Master Sword
    dw $5B00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 02 Tempered Sword
    dw $5C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 03 Gold Sword
    dw $5F00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 04 Blue Shield
    dw $6000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 05 Red Shield
    dw $6100 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 06 Mirror Shield
    dw $3F00 : db $02, $00, $00, $00, $02, $00, $00, $00    ; 07 Fire Rod
    dw $4000 : db $00, $03, $00, $00, $00, $03, $00, $00    ; 08 Ice Rod
    dw $4500 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 09 Hammer
    dw $2100 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 0A Hookshot
    dw $2200 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 0B Bow
    dw $6F00 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 0C Blue Boomerang
    dw $1700 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 0D Powder
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 0E Bee (bottle contents)
    dw $4100 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 0F Bombos

    dw $4200 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 10 Ether
    dw $4300 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 11 Quake
    dw $4400 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 12 Lamp
    dw $4600 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 13 Shovel
    dw $4700 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 14 Flute
    dw $5100 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 15 Somaria
    dw $4A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 16 Empty Bottle
    dw $6200 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 17 Heart Piece
    dw $5200 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 18 Cane of Byrna
    dw $5300 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 19 Cape
    dw $5400 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 1A Mirror
    dw $5500 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 1B Gloves
    dw $5600 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 1C Titan's Mitts
    dw $4900 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 1D Book
    dw $5800 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 1E Flippers
    dw $5900 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 1F Moon Pearl

    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 20 Dummy     
    dw $4800 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 21 Bug-Catching Net
    dw $5D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 22 Blue Tunic
    dw $5E00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 23 Red Tunic
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 24 Dummy - Key       
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 25 Dummy - Compass
    dw $6300 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 26 Heart Container (no animation)
    dw $2400 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 27 One bomb
    dw $6700 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 28 3 Bombs
    dw $2600 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 29 Mushroom
    dw $7000 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 2A Red Boomerang
    dw $4B00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 2B Red Potion Bottle
    dw $4C00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 2C Green Potion Bottle
    dw $4D00 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 2D Blue Potion Bottle
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 2E Dummy - Red potion (contents)
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 2F Dummy - Green potion (contents)

    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 30 Dummy - Blue potion (contents)
    dw $6800 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 31 10 Bombs
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 32 Dummy - Big key
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 33 Dummy - Map
    dw $6900 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 34 1 Rupee
    dw $6A00 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 35 5 Rupees
    dw $6B00 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 36 20 Rupees
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 37 Dummy - Pendant of Courage
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 38 Dummy - Pendant of Wisdom
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 39 Dummy - Pendant of Power
    dw $2200 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 3A Bow and Arrows
    dw $6E00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 3B Silver Arrows
    dw $4E00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 3C Bee Bottle
    dw $5000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 3D Fairy Bottle
    dw $6300 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 3E Heart Container - Boss
    dw $6300 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 3F Heart Container - Sanc

    dw $6D00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 40 100 Rupees
    dw $6C00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 41 50 Rupees
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 42 Dummy - Small heart
    dw $6400 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 43 Single Arrow
    dw $6600 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 44 10 Arrows
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 45 Dummy - Small magic
    dw $2300 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 46 300 Rupees
    dw $6B00 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 47 20 Rupees
    dw $4F00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 48 Good Bee Bottle
    dw $7700 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 49 Fighter Sword
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 4A Dummy - Activated flute
    dw $5700 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 4B Boots
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 4C Dummy - 50 Bomb upgrade
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 4D Dummy - 70 Arrow upgrade
    dw $7100 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 4E Half Magic
    dw $7200 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 4F Quarter Magic

    dw $5A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 50 Master Sword    
    dw $7300 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 51 5 Bomb Upgrade
    dw $7400 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 52 10 Bomb Upgrade
    dw $7500 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 53 5 Arrow Upgrade
    dw $7600 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 54 10 Arrow Upgrade
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 55 Dummy - Programmable 1
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 56 Dummy - Programmable 2
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 57 Dummy - Programmable 3
    dw $6E00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 58 Silver Arrows

    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 59 - Unused
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 5A - Unused
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 5B - Unused
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 5C - Unused
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 5D - Unused
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 5E - Progressive Sword
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 5F - Progressive Shield

    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 60 - Progressive Armor
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 61 - Progressive Glove
    dw $2D00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 62 - Bombs                  (M1)
    dw $2800 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 63 - High Jump              (M1)
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 64 - Reserved - Progressive Bow                 (Why two here? Are both used?)
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 65 - Reserved - Progressive Bow                 (Why two here? Are both used?)
    dw $2E00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 66 - Long Beam              (M1)
    dw $2A00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 67 - Screw Attack           (M1)
    dw $2900 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 68 - Morph Ball             (M1)
    dw $2B00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 69 - Varia Suit             (M1)
    dw $7800 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 6A - Reserved - Goal Item (Single/Triforce)
    dw $7800 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 6B - Reserved - Goal Item (Multi/Power Star)    (Is this used for anything)
    dw $3000 : db $02, $02, $02, $02, $02, $02, $02, $02    ; 6C - Wave Beam              (M1)
    dw $2F00 : db $03, $03, $03, $03, $03, $03, $03, $03    ; 6D - Ice Beam               (M1)
    dw $2C00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 6E - Energy Tank            (M1)
    dw $9600 : db $01, $01, $01, $01, $01, $01, $01, $01    ; 6F - Missiles               (M1)

    dw $7E00 : db $03, $00, $00, $00, $03, $00, $00, $00    ; 70 - Crateria L1 Key
    dw $7F00 : db $02, $00, $00, $00, $02, $00, $00, $00    ; 71 - Crateria L2 Key
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 72 - Ganons Tower Map
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 73 - Turtle Rock Map
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 74 - Thieves' Town Map
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 75 - Tower of Hera Map
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 76 - Ice Palace Map
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 77 - Skull Woods Map
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 78 - Misery Mire Map
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 79 - Palace Of Darkness Map
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 7A - Swamp Palace Map
    dw $8000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 7B - Crateria Boss Key
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 7C - Desert Palace Map
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 7D - Eastern Palace Map
    dw $8000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 7E - Maridia Boss Key
    dw $7D00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 7F - Hyrule Castle Map

    dw $7E00 : db $03, $00, $00, $00, $03, $00, $00, $00    ; 80 - Brinstar L1 Key
    dw $7F00 : db $02, $00, $00, $00, $02, $00, $00, $00    ; 81 - Brinstar L2 Key
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 82 - Ganons Tower Compass
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 83 - Turtle Rock Compass
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 84 - Thieves' Town Compass
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 85 - Tower of Hera Compass
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 86 - Ice Palace Compass
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 87 - Skull Woods Compass
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 88 - Misery Mire Compass
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 89 - Palace of Darkness Compass
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 8A - Swamp Palace Compass
    dw $8000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 8B - Brinstar Boss Key
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 8C - Desert Palace Compass
    dw $7C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 8D - Eastern Palace Compass
    dw $7E00 : db $03, $00, $00, $00, $03, $00, $00, $00    ; 8E - Wrecked Ship L1 Key
    dw $8000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 8F - Wrecked Ship Boss Key

    dw $7E00 : db $03, $00, $00, $00, $03, $00, $00, $00    ; 90 - Norfair L1 Key
    dw $7F00 : db $02, $00, $00, $00, $02, $00, $00, $00    ; 91 - Norfair L2 Key
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 92 - Ganons Tower Big Key
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 93 - Turtle Rock Big Key
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 94 - Thieves' Town Big Key
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 95 - Tower of Hera Big Key
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 96 - Ice Palace Big Key
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 97 - Skull Woods Big Key
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 98 - Misery Mire Big Key
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 99 - Palace of Darkness Big Key
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 9A - Swamp Palace Big Key
    dw $8000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 9B - Norfair Boss Key
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 9C - Desert Palace Big Key
    dw $7A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 9D - Eastern Palace Big Key
    dw $7E00 : db $03, $00, $00, $00, $03, $00, $00, $00    ; 9E - Lower Norfair L1 Key
    dw $8000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; 9F - Lower Norfair Boss Key

    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; A0 - Hyrule Castle Small Key
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; A1 - Unused
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; A2 - Unused
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; A3 - Desert Palace Small Key
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; A4 - Castle Tower Small Key
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; A5 - Swamp Palace Small Key
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; A6 - Palace of Darkness Small Key
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; A7 - Misery Mire Small Key
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; A8 - Skull Woods Small Key
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; A9 - Ice Palace Small Key
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; AA - Tower of Hera Small Key
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; AB - Thieves' Town Small Key
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; AC - Turtle Rock Small Key
    dw $7B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; AD - Ganons Tower Small Key
    dw $7E00 : db $03, $00, $00, $00, $03, $00, $00, $00    ; AE - Maridia L1 Key
    dw $7F00 : db $02, $00, $00, $00, $02, $00, $00, $00    ; AF - Maridia L2 Key

    ; SM (B0-FF)
    dw $1800 : db $00, $00, $00, $00, $00, $00, $00, $00    ; B0 - Grapple beam
    dw $1900 : db $01, $01, $00, $00, $03, $03, $00, $00    ; B1 - X-ray scope
    dw $1300 : db $00, $00, $00, $00, $00, $00, $00, $00    ; B2 - Varia suit
    dw $1200 : db $00, $00, $00, $00, $00, $00, $00, $00    ; B3 - Spring ball
    dw $1700 : db $00, $00, $00, $00, $00, $00, $00, $00    ; B4 - Morph ball
    dw $1500 : db $00, $00, $00, $00, $00, $00, $00, $00    ; B5 - Screw attack
    dw $1100 : db $00, $00, $00, $00, $00, $00, $00, $00    ; B6 - Gravity suit
    dw $1400 : db $00, $00, $00, $00, $00, $00, $00, $00    ; B7 - Hi-Jump
    dw $1600 : db $00, $00, $00, $00, $00, $00, $00, $00    ; B8 - Space jump
    dw $1000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; B9 - Bombs
    dw $1A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; BA - Speed booster
    dw $1B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; BB - Charge
    dw $1C00 : db $00, $03, $00, $00, $00, $03, $00, $00    ; BC - Ice Beam
    dw $1D00 : db $00, $02, $00, $00, $00, $02, $00, $00    ; BD - Wave beam
    dw $1F00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; BE - Spazer
    dw $1E00 : db $00, $01, $00, $00, $00, $01, $00, $00    ; BF - Plasma beam

    ; C0
    dw $0008 : db $00, $00, $00, $00, $00, $00, $00, $00    ; C0 - Energy Tank
    dw $2000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; C1 - Reserve tank
    dw $000A : db $00, $00, $00, $00, $00, $00, $00, $00    ; C2 - Missile
    dw $000C : db $00, $00, $00, $00, $00, $00, $00, $00    ; C3 - Super Missile
    dw $000E : db $00, $00, $00, $00, $00, $00, $00, $00    ; C4 - Power Bomb    
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; C5 - Kraid Boss Token
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; C6 - Phantoon Boss Token
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; C7 - Draygon Boss Token
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; C8 - Ridley Boss Token
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; C9 - Unused
    dw $8400 : db $00, $00, $00, $00, $00, $00, $00, $00    ; CA - Kraid Map 
    dw $8400 : db $00, $00, $00, $00, $00, $00, $00, $00    ; CB - Phantoon Map
    dw $8400 : db $00, $00, $00, $00, $00, $00, $00, $00    ; CC - Draygon Map
    dw $8400 : db $00, $00, $00, $00, $00, $00, $00, $00    ; CD - Ridley Map
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; CE - Unused
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; CF - Unused (Reserved)

    ; Z1 (D0-FF)
    dw $3A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; D0 - Bombs
    dw $3100 : db $00, $00, $00, $00, $00, $00, $00, $00    ; D1 - Wooden Sword
    dw $9200 : db $00, $00, $00, $00, $00, $00, $00, $00    ; D2 - White Sword
    dw $8800 : db $01, $01, $01, $01, $01, $01, $01, $01    ; D3 - Magical Sword
    dw $3200 : db $01, $01, $01, $01, $01, $01, $01, $01    ; D4 - Bait
    dw $3300 : db $00, $00, $00, $00, $00, $00, $00, $00    ; D5 - Recorder
    dw $9100 : db $00, $00, $00, $00, $00, $00, $00, $00    ; D6 - Blue Candle
    dw $3400 : db $01, $01, $01, $01, $01, $01, $01, $01    ; D7 - Red Candle
    dw $3500 : db $00, $00, $00, $00, $00, $00, $00, $00    ; D8 - Arrows
    dw $9300 : db $00, $00, $00, $00, $00, $00, $00, $00    ; D9 - Silver Arrows
    dw $3600 : db $00, $00, $00, $00, $00, $00, $00, $00    ; DA - Bow
    dw $3700 : db $01, $01, $01, $01, $01, $01, $01, $01    ; DB - Magical Key
    dw $8F00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; DC - Raft
    dw $9000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; DD - Stepladder
    dw $EE00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; DE - Unused?
    dw $3900 : db $00, $00, $00, $00, $00, $00, $00, $00    ; DF - 5 Rupees
    
    dw $8900 : db $03, $03, $03, $03, $03, $03, $03, $03    ; E0 - Magical Rod
    dw $3D00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; E1 - Book of Magic
    dw $9500 : db $00, $00, $00, $00, $00, $00, $00, $00    ; E2 - Blue Ring
    dw $3E00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; E3 - Red Ring
    dw $8B00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; E4 - Power Bracelet
    dw $8A00 : db $03, $03, $03, $03, $03, $03, $03, $03    ; E5 - Letter
    dw $8E00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; E6 - Compass
    dw $8A00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; E7 - Dungeon Map
    dw $3900 : db $01, $01, $01, $01, $01, $01, $01, $01    ; E8 - 1 Rupee
    dw $3800 : db $01, $01, $01, $01, $01, $01, $01, $01    ; E9 - Small Key
    dw $8D00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; EA - Heart Container
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; EB - Triforce Fragment
    dw $8C00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; EC - Magical Shield
    dw $3B00 : db $00, $00, $00, $00, $00, $00, $00, $00    ; ED - Boomerang
    dw $3B00 : db $03, $03, $03, $03, $03, $03, $03, $03    ; EE - Magical Boomerang
    dw $9400 : db $00, $00, $00, $00, $00, $00, $00, $00    ; EF - Blue Potion

    dw $3C00 : db $01, $01, $01, $01, $01, $01, $01, $01    ; F0 - Red Potion
    dw $F600 : db $00, $00, $00, $00, $00, $00, $00, $00    ; F1 - Clock
    dw $F700 : db $00, $00, $00, $00, $00, $00, $00, $00    ; F2 - Small Heart
    dw $F100 : db $00, $00, $00, $00, $00, $00, $00, $00    ; F3 - Fairy
    dw $F180 : db $00, $00, $00, $00, $00, $00, $00, $00    ; F4 - Unused
    dw $F200 : db $00, $00, $00, $00, $00, $00, $00, $00    ; F5 - Unused
    dw $F280 : db $00, $00, $00, $00, $00, $00, $00, $00    ; F6 - Unused

    ; These plaques have to go at some point since they're taking up valuable
    ; item ids
    dw $8500 : db $00, $00, $00, $00, $00, $00, $00, $00    ; F7 - L1 Key Plaque
    dw $8600 : db $00, $00, $00, $00, $00, $00, $00, $00    ; F8 - L2 Key Plaque
    dw $8700 : db $00, $00, $00, $00, $00, $00, $00, $00    ; F9 - Boss Key Plaque
    dw $8100 : db $00, $00, $00, $00, $00, $00, $00, $00    ; FA - Zero Marker
    dw $8180 : db $00, $00, $00, $00, $00, $00, $00, $00    ; FB - One Marker
    dw $8200 : db $00, $00, $00, $00, $00, $00, $00, $00    ; FC - Two Marker
    dw $8280 : db $00, $00, $00, $00, $00, $00, $00, $00    ; FD - Three Marker
    dw $8300 : db $00, $00, $00, $00, $00, $00, $00, $00    ; FE - Four Marker
    dw $0000 : db $00, $00, $00, $00, $00, $00, $00, $00    ; FF - Unused

get_item_bank:
    cpy #item_graphics
    bcc .original
.custom
    lda.w #(new_item_graphics_data>>16)
    bra .end
.original
    lda.w #$0089
.end
    rts

warnpc $84fe00

; Patch SFX
org $8498e3
CLIPCHECK:
	LDA $05D7
	CMP #$0002
	BEQ $0E
	LDA #$0000
	JSL $808FF7
	LDA $07F5
	JSL $808FC1
	LDA #$0000
	STA $05D7
	RTL

CLIPSET:
	LDA #$0001
	STA $05D7
	JSL $82BE17
	LDA #$0000
	RTS
SOUNDFX:
	JSR SETFX
	AND #$00FF
	JSL $809049
	RTS
SPECIALFX:
	JSR SETFX
	JSL $8090CB
	RTS
MISCFX:
	JSR SETFX
	JSL $80914D
	RTS
SETFX:
	LDA #$0002
	STA $05D7
	LDA $0000,y
	INY
	RTS