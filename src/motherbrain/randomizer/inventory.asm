;
; Copies all item buffers from regular SRAM into our buffers
;
CopyItemBuffers:
    php
    %ai16()

    ldx.w #$0000
-
    lda.l $400010, x
    sta.l !SM_BUFFER_START, x
    inx #2
    cpx.w #(!SM_BUFFER_END-!SM_BUFFER_START)
    bne -

    ldx.w #$0000
-
    lda.l $402300, x
    sta.l !ALTTP_BUFFER_START, x
    inx #2
    cpx.w #(!ALTTP_BUFFER_END-!ALTTP_BUFFER_START)
    bne -

    ldx.w #$0000
-
    lda.l $40CE57, x
    sta.l !Z1_BUFFER_START, x
    inx #2
    cpx.w #(!Z1_BUFFER_END-!Z1_BUFFER_START)
    bne -

    ldx.w #$0000
-
    lda.l $408876, x
    sta.l !M1_BUFFER_START, x
    inx #2
    cpx.w #(!M1_BUFFER_END-!M1_BUFFER_START)
    bne -

    plp
    rtl
;
; Restores all item buffers except for the game in A
; Used when we're saving in a game to also save the state
; in all other games.
;
; Also used during transitions to write back state to all games
;
RestoreItemBuffers:
    php
    %ai16()
    and #$00ff  ; Mask off the high byte

    cmp #$0000
    bne +
    lda #$0001 : jsl RestoreItemBuffer
    lda #$0002 : jsl RestoreItemBuffer
    lda #$0003 : jsl RestoreItemBuffer
    bra .end
+
    cmp #$0001
    bne +
    lda #$0000 : jsl RestoreItemBuffer
    lda #$0002 : jsl RestoreItemBuffer
    lda #$0003 : jsl RestoreItemBuffer
    bra .end
+
    cmp #$0002
    bne +
    lda #$0000 : jsl RestoreItemBuffer
    lda #$0001 : jsl RestoreItemBuffer
    lda #$0003 : jsl RestoreItemBuffer
    bra .end
+
    lda #$0000 : jsl RestoreItemBuffer
    lda #$0001 : jsl RestoreItemBuffer
    lda #$0002 : jsl RestoreItemBuffer

.end
    plp
    rtl

;
; Restore item buffer
; Copies the item buffer back into SRAM for a given game
; This will break checksums so we have to recalculate them
; Game in A
RestoreItemBuffer:
    php
    %ai16()
    and #$00ff  ; Mask off the high byte
    cmp #$0000
    bne +
    jmp .smBuffer
+
    cmp #$0001
    bne +
    jmp .alttpBuffer
+
    cmp #$0002
    bne +
    jmp .z1Buffer
+
    jmp .m1Buffer
+

.smBuffer
    ldx.w #$0000
-
    lda.l !SM_BUFFER_START, x
    sta.l $400010, x
    inx #2
    cpx.w #(!SM_BUFFER_END-!SM_BUFFER_START)
    bne -
    jsl FixSMChecksum
    jmp .end

.alttpBuffer
    ldx.w #$0000
-
    lda.l !ALTTP_BUFFER_START, x
    sta.l $402300, x
    inx #2
    cpx.w #(!ALTTP_BUFFER_END-!ALTTP_BUFFER_START)
    bne -
    jsl FixALTTPChecksum
    jmp .end

.z1Buffer
    ldx.w #$0000
-
    lda.l !Z1_BUFFER_START, x
    sta.l $40CE57, x
    inx #2
    cpx.w #(!Z1_BUFFER_END-!Z1_BUFFER_START)
    bne -

    ; We're skipping the save mechanic completely in Z1 and copy items
    ; directly into WRAM so we don't need to fix checksums and deal with saving

    jmp .end

.m1Buffer
    ldx.w #$0000
-
    lda.l !M1_BUFFER_START, x
    sta.l $408876, x
    inx #2
    cpx.w #(!M1_BUFFER_END-!M1_BUFFER_START)
    bne -
    jmp .end

    ; M1 has no save-files so we don't need to fix checksums

.end
    plp
    rtl

FixSMChecksum:
    lda.w #$0000
    sta.l !IRAM_INVENTORY_TEMP_1
    ldx.w #$0010
 -
    lda.l $400000,x
    clc
    adc.l !IRAM_INVENTORY_TEMP_1
    sta.l !IRAM_INVENTORY_TEMP_1
    inx
    inx
    cpx.w #$065c
    bne -

    ldx.w #$0000
    lda.l !IRAM_INVENTORY_TEMP_1
    sta.l $400000,x
    sta.l $401ff0,x
    eor #$ffff
    sta.l $400008,x
    sta.l $401ff8,x
    rtl

FixALTTPChecksum:
    ldx.w #$0000              ; Copy main SRAM to backup SRAM
-
    lda.l $402000,x
    sta.l $402f00,x
    inx : inx
    cpx.w #$04fe
    bne -

    ldx.w #$0000
    lda.w #$0000
-
    clc
    adc.l $402000,x
    inx
    inx
    cpx.w #$04fe
    bne -

    sta.l !IRAM_INVENTORY_TEMP_1
    lda.w #$5a5a
    sec
    sbc.l !IRAM_INVENTORY_TEMP_1
    ;sta $7EF4fe
    sta.l $4024fe
    sta.l $4033fe
    rtl

;
; Writes the item to the correct SRAM buffer and handles anything extra that needs to be done
; for items that are not in the active game
;
; Inputs:
;   A - Item Id
;
; Returns:
;   A - Written value
;   X - Game Id
;   Y = Item Type
;
WriteItemToInventory:
    php : phb : phk : plb                     ; Set bank to 40

    %ai16()
    and.w #$00ff
    pha                                 ; Save item id
.recheckItem
    asl #3 : tax                        ; Multiply by 8 to get offset
    lda.w ItemData, x                   ; Get the Game Id
    
    asl : tay
    lda ItemBufferOffsets, y            ; Get the SRAM offset into Y
    sec : sbc.w #!SRAM_ITEM_BUFFER      ; Subtract the SRAM buffer start
    clc : adc.w ItemData+2, x           ; Add the item offset to the SRAM offset
    tay

    ; X = pointer to item data
    ; Y = SRAM offset to item

    lda ItemData+4, x                   ; Get the item type

.itemCheck
    cmp #$0018
    bne +
        jsr UpgradeProgressiveItem      ; Returns new item id in A
        tax : pla : txa : pha
        bra .recheckItem
+   cmp #$0000
    bne +
       jmp .normalItem
+   cmp #$0001
    bne +
        jmp .incrementItem
+   cmp #$0002
    bne +
        jmp .bitmaskItem16
+   cmp #$0003
    bne +
        jmp .bitmaskItem8
+   cmp #$0012
    bne +
        jmp .alttpBottle
+   cmp #$0013
    bne +
        jmp .alttpPieceOfHeart
+   cmp #$0014
    bne +
        jmp .alttpRupees
+   cmp #$0015
    bne +
        jmp .alttpBoots
+   cmp #$0016
    bne +
        jmp .alttpFlippers
+   cmp #$0017
    bne +
        jmp .alttpSilvers
+   cmp #$0018
    bne +
        jmp .alttpDungeon
+   cmp #$0019
    bne +
        jmp .alttpDungeonKey
+   cmp #$0020
    bne +
        jmp .smEquipment
+   cmp #$0021
    bne +
        jmp .smSpazPlaz
+   cmp #$0022
    bne +
        jmp .smEnergyTank
+   cmp #$0023
    bne +
        jmp .smReserveTank
+   cmp #$0024
    bne +
        jmp .smAmmo
+   cmp #$0030
    bne +
        jmp .z1Rupees
+   cmp #$0031
    bne +
        jmp .z1HeartContainer
+   cmp #$0040
    bne +
        jmp .m1Ammo
+   jmp .end

.normalItem
    lda.w ItemData+6, x                 ; Get the item value
    %a8()
    cmp.w !SRAM_ITEM_BUFFER, y          ; Compare to the current value
    bcc ..preventDowngrade               ; If the new value is less than the current value, don't update
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the item to the SRAM buffer
    bra ..normalItemEnd
..preventDowngrade
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current value so we can return it
..normalItemEnd
    %a16()
    jmp .end

.incrementItem
    %a8()
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current value
    clc
    adc.w ItemData+6, x                 ; Add the item value
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the item to the SRAM buffer
    %a16()
    jmp .end

.bitmaskItem16
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current value
    ora.w ItemData+6, x                 ; OR the item value
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the item to the SRAM buffer
    jmp .end

.bitmaskItem8
    %a8()
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current value
    ora.w ItemData+6, x                 ; OR the item value
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the item to the SRAM buffer
    %a16()
    jmp .end

.alttpBottle
    %a8()
    phx
    lda.b #$01
    sta.w !SRAM_ITEM_BUFFER, y          ; Write bottle flag to the SRAM buffer

    ldx.w #$0000
-
    lda.w !ALTTP_BUFFER_START+$5C, x    ; Check for empty bottle
    beq ..foundBottleIndex
    inx
    cpx #$0004
    bne -
    plx
    bra ..bottleEnd
..foundBottleIndex    
    txa : plx : phy : tay               ; Restore pointer to ItemData, and move bottle index to Y
    lda.w ItemData+6, x                 ; Get the item value
    sta.w !ALTTP_BUFFER_START+$5C, y    ; Write the item to the SRAM buffer
    ply
..bottleEnd
    %a16()
    jmp .end

.alttpPieceOfHeart
    %a8()
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current value
    inc                                 ; Increment the value
    cmp.b #$04                          ; Check if we have 4 pieces of heart
    bne ..notFullHeart
    lda.b #$00                          ; Reset the value to 0
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the heart pieces
    lda.w !ALTTP_BUFFER_START+$6C       ; Get the current heart count
    clc : adc #$08                      ; Add 8 to the heart count
    sta.w !ALTTP_BUFFER_START+$6C       ; Write the heart count to the SRAM buffer
    sta.w !ALTTP_BUFFER_START+$6D       ; Refill links health
    bra ..alttpPieceOfHeartEnd
..notFullHeart
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the heart pieces
..alttpPieceOfHeartEnd
    %a16()
    jmp .end

.alttpRupees
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current rupees
    clc : adc.w ItemData+6, x           ; Add the rupee value
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the rupees
    sta.w !SRAM_ITEM_BUFFER+$2, y       ; Write the rupees to the rupee counter
    jmp .end

.alttpBoots
    %a8()
    lda.w ItemData+6, x                 ; Get the item value
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the item to the SRAM buffer
    
    lda.w !ALTTP_BUFFER_START+$79       ; Get movement bits
    ora #$04                            ; Set the boots bit
    sta.w !ALTTP_BUFFER_START+$79       ; Write the movement bits to the SRAM buffer
    %a16()
    jmp .end

.alttpFlippers
    %a8()
    lda.w ItemData+6, x                 ; Get the item value
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the item to the SRAM buffer
    
    lda.w !ALTTP_BUFFER_START+$79       ; Get movement bits
    ora #$02                            ; Set the flippers bit
    sta.w !ALTTP_BUFFER_START+$79       ; Write the movement bits to the SRAM buffer
    %a16()
    jmp .end

.alttpSilvers
    %a8()
    lda.w !ALTTP_BUFFER_START+$40       ; Load bow value
    beq ..noBow
    clc : adc #$02                      ; Add 2 to the bow value
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the item to the SRAM buffer
    bra ..silversEnd
..noBow
    lda.b #$01
    sta.w !ALTTP_BUFFER_START+$76      ; Give upgrade only silver arrows
..silversEnd
    %a16()
    jmp .end

.alttpDungeon
    lda.w ItemData+6, x                 ; Get the item bitmask
    ora.w !SRAM_ITEM_BUFFER, y          ; Add the dungeon bits to the SRAM bitmask
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the dungeon bits to the SRAM buffer
    jmp .end

.alttpDungeonKey
    %a8()
    lda.w ItemData+6, x                 ; Get the item value
    clc : adc.w !SRAM_ITEM_BUFFER, y    ; Add the key value
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the key to the SRAM buffer

    lda.w ItemData+2, x                 ; Get the offset
    cmp.b #$7C
    bne ..notHyruleCastle
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the hyrule castle keys
    sta.w !SRAM_ITEM_BUFFER+$1, y       ; Write to sewer keys
..notHyruleCastle
    %a16()
    jmp .end

.smEquipment
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current value
    ora.w ItemData+6, x                 ; OR the item value
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the equipment to the SRAM buffer

    lda.w !SRAM_ITEM_BUFFER+$2, y       ; Get the current value
    ora.w ItemData+6, x                 ; OR the item value
    sta.w !SRAM_ITEM_BUFFER+$2, y       ; Write the equipment to the SRAM buffer
    jmp .end

.smSpazPlaz
    lda.w !SRAM_ITEM_BUFFER+$2, y       ; Get the current value
    ora.w ItemData+6, x                 ; OR the item value
    sta.w !SRAM_ITEM_BUFFER+$2, y       ; Write the equipment to the SRAM buffer
    jmp .end

.smEnergyTank
    lda.w ItemData+6, x                 ; Get the item value
    clc
    adc.w !SRAM_ITEM_BUFFER+$2, y       ; Add the energy tank value
    sta.w !SRAM_ITEM_BUFFER+$2, y       ; Write the energy tank to the SRAM buffer
    lda.w !SRAM_ITEM_BUFFER+$2, y       ; Get the current value
    sta.w !SRAM_ITEM_BUFFER, y          ; Refill samus energy when we get an etank
    jmp .end

.smReserveTank
    lda.w ItemData+6, x                 ; Get the item value
    clc
    adc.w !SRAM_ITEM_BUFFER, y          ; Add the reserve tank value    
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the reserve tank to the SRAM buffer
    jmp .end

.smAmmo
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current value
    clc
    adc.w ItemData+6, x                 ; Add the ammo max value
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the ammo max to the SRAM buffer
    lda.w !SRAM_ITEM_BUFFER+$2, y       ; Get the current ammo value
    clc
    adc.w ItemData+6, x                 ; Add the ammo value
    sta.w !SRAM_ITEM_BUFFER+$2, y       ; Write the ammo to the SRAM buffer
    jmp .end

.z1Rupees
    %a16()
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current value
    and #$00ff
    clc
    adc.w ItemData+6, x                 ; Add to the current rupees
    cmp.w #$0100                        ; Check for overflow   
    bcc ..noOverflow
    lda.w #$00ff
..noOverflow
    %a8()
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the rupees to the SRAM buffer
    %a16()
    jmp .end

.z1HeartContainer
    %a8()
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current value
    lsr #4                              ; Divide by 16
    clc
    adc.w ItemData+6, x                 ; Add to the current heart containers
    sta.w !INVENTORY_TEMP_1             ; Store the new value
    asl #4
    ora.w !INVENTORY_TEMP_1             ; OR the new value to refill hearts
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the heart containers to the SRAM buffer
    %a16()
    jmp .end

.m1Ammo
    %a8()
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current value
    clc
    adc.w ItemData+6, x                 ; Add the ammo max value
    sta.w !SRAM_ITEM_BUFFER, y          ; Write the ammo max to the SRAM buffer
    lda.w !SRAM_ITEM_BUFFER+$1, y       ; Get the current ammo value
    clc
    adc.w ItemData+6, x                 ; Add the ammo value
    sta.w !SRAM_ITEM_BUFFER+$1, y       ; Write the ammo to the SRAM buffer
    %a16()
    jmp .end

.end
    pla

    ; Do things here specific to the item id in case there are items with special behavior    
    jsr CheckItemSwap                   ; Check for item swapping


    ; Set up return values
    lda.w !SRAM_ITEM_BUFFER, y          ; Get the current value so we can return it
    ldy.w ItemData, x : phy             ; Get the game
    ldy.w ItemData+4, x                 ; Get the type
    plx                                 ; Restore game to x
    plb
    plp                      
    rtl

; This checks for specific ALTTP items that needs a special item swap bit set
CheckItemSwap:
    pha
    phy
    php    
    %ai8()
    tay
	CPY.b #$0C : BNE + ; Blue Boomerang
		LDA !ALTTP_INVENTORY_SWAP : ORA #$80 : STA !ALTTP_INVENTORY_SWAP
		BRL .done
	+ CPY.b #$2A : BNE + ; Red Boomerang
		LDA !ALTTP_INVENTORY_SWAP : ORA #$40 : STA !ALTTP_INVENTORY_SWAP
		BRL .done
	+ CPY.b #$29 : BNE + ; Mushroom
		LDA !ALTTP_INVENTORY_SWAP : ORA #$20 : STA !ALTTP_INVENTORY_SWAP
		BRL .done
	+ CPY.b #$0D : BNE + ; Magic Powder
		LDA !ALTTP_INVENTORY_SWAP : ORA #$10 : STA !ALTTP_INVENTORY_SWAP
		BRL .done
	+ CPY.b #$13 : BNE + ; Shovel
		LDA !ALTTP_INVENTORY_SWAP : ORA #$04 : STA !ALTTP_INVENTORY_SWAP
		BRL .done
	+ CPY.b #$14 : BNE + ; Flute (Inactive)
		LDA !ALTTP_INVENTORY_SWAP : ORA #$02 : STA !ALTTP_INVENTORY_SWAP
		BRL .done
	+ CPY.b #$4A : BNE + ; Flute (Active)
		LDA !ALTTP_INVENTORY_SWAP : ORA #$01 : STA !ALTTP_INVENTORY_SWAP
		BRL .done
	+ CPY.b #$0B : BNE + ; Bow
    	LDA !ALTTP_INVENTORY_SWAP_2 : ORA #$80 : STA !ALTTP_INVENTORY_SWAP_2
		BRL .done
	+ CPY.b #$3A : BNE + ; Bow & Arrows
		LDA !ALTTP_INVENTORY_SWAP_2 : ORA #$80 : STA !ALTTP_INVENTORY_SWAP_2
		BRL .done
	+ CPY.b #$3B : BNE + ; Bow & Silver Arrows
		LDA !ALTTP_INVENTORY_SWAP_2 : ORA #$40 : STA !ALTTP_INVENTORY_SWAP_2
		BRL .done
	+ CPY.b #$43 : BNE + ; Single arrow
		LDA !ALTTP_INVENTORY_SWAP_2 : ORA #$80 : STA !ALTTP_INVENTORY_SWAP_2 ; activate wood arrows in quick-swap
		BRL .done
	+ CPY.b #$58 : BNE + ; Upgrade-Only Silver Arrows
		LDA !ALTTP_INVENTORY_SWAP_2 : ORA #$40 : STA !ALTTP_INVENTORY_SWAP_2
	+ CPY.b #$49 : BNE + ; Fighter's Sword
		;JSR .stampSword
		BRL .done
	+ CPY.b #$01 : BNE + ; Master Sword
		;JSR .stampSword
		BRL .done
	+ CPY.b #$50 : BNE + ; Master Sword
		;JSR .stampSword
		BRL .done
	+ CPY.b #$02 : BNE + ; Tempered Sword
		;JSR .stampSword
		BRL .done
	+ CPY.b #$03 : BNE + ; Golden Sword
		;JSR .stampSword
		BRL .done
	+ CPY.b #$4B : BNE + ; Pegasus Boots
		;JSR .stampBoots
		BRL .done
	+ CPY.b #$1A : BNE + ; Magic Mirror
		;JSR .stampMirror
		BRL .done
    + 
.done
    plp
    ply
    pla
    rts

; Return new upgraded item id in A
UpgradeProgressiveItem:
    phy

    %a8()    
    lda.w !SRAM_ITEM_BUFFER, y          ; Get current item value
    ldy.w ItemData+6, x                 ; Get index to progressive item table
    cmp.w AlttpProgressiveItems+2, y    ; Compare against max value
    beq .maxValue
    inc
.maxValue
    sty.w !INVENTORY_TEMP_1
    clc : adc.w !INVENTORY_TEMP_1
    tay
    lda.w AlttpProgressiveItems+2, y    ; Get new upgraded item id

    %a16()
    and #$00ff
    ply
    rts

; Takes an item id in A, and returns the upgrade item id in A
CheckProgressiveItemLong:
    phy : phx : php : phb : pha
    phk : plb

    %ai16()

    asl #3 : tax                        ; Multiply by 8 to get offset
    lda.w ItemData, x                   ; Get the Game Id
    
    asl : tay
    lda.w ItemBufferOffsets, y          ; Get the SRAM offset into Y
    sec : sbc.w #!SRAM_ITEM_BUFFER      ; Subtract the SRAM buffer start
    clc : adc.w ItemData+2, x           ; Add the item offset to the SRAM offset
    tay

    lda ItemData+4, x                   ; Get the item type
    cmp #$0018
    bne .notProgressive

    pla
    jsr UpgradeProgressiveItem
    plb : plp : plx : ply
    rtl

.notProgressive
    ; If it's not progressive, return the same item id
    pla : plb : plp : plx : ply
    rtl

CheckItemGame:
    phx : php
    %ai16()
    asl #3 : tax                        ; Multiply by 8 to get offset
    lda.l ItemData, x                   ; Get the Game Id
    plp : plx
    rtl


AlttpProgressiveItems:
    db $5E, $59, $04, $49, $01, $02, $03, $00     ; Progressive sword
    db $5F, $5A, $03, $04, $05, $06, $00, $00     ; Progressive shield
    db $60, $5B, $02, $22, $23, $00, $00, $00     ; Progressive armor
    db $61, $54, $02, $1B, $1C, $00, $00, $00     ; Progressive glove
    db $FF

ItemBufferOffsets:
    dw !SM_BUFFER_START
    dw !ALTTP_BUFFER_START
    dw !Z1_BUFFER_START
    dw !M1_BUFFER_START

;
; Games: 0 = SM, 1 = ALTTP, 2 = Z1, 3 = M1
; Types:
;   Generic Item Types
;   -------------------
;   00 - Normal Item (Set value at offset to item value) (8-bit)
;   01 - Increment Item (Increment value at offset with item value) (8-bit)
;   02 - Bitmask Item (OR value at offset with item value) (16-bit)
;   03 - Bitmask Item (OR value at offset with item value) (8-bit)

;   ALTTP Item Types
;   ------------------------
;   12 - ALTTP Bottle
;   13 - ALTTP Piece of Heart
;   14 - ALTTP Rupees
;   15 - ALTTP Boots
;   16 - ALTTP Flippers
;   17 - ALTTP Silvers
;   18 - ALTTP Progressive Item
;   19 - ALTTP Dungeon Item
;   1A - ALTTP Dungeon Key
;   1B-1F - Reserved for further ALTTP specific items

;   SM Item Types
;   -----------------------
;   20 - SM Equipment (Bitmask at two offsets)
;   21 - Spaz/Plaz (Special handling to not cause space/time beam)
;   22 - SM Energy Tanks
;   23 - SM Reserve Tanks
;   24 - SM Ammo

;
;   Z1 Item Types
;   ------------------------
;   30 - Z1 Rings
;   31 - Z1 Rupees
;   32 - Z1 Heart Container

;   M1 Item Types
;   ------------------------
;   40 - M1 Missiles


ItemData:
    ;   game  offset type  value  
    dw $0001, $0000, $0000, $0000        ; 00 - Dummy - L1SwordAndShield 
    dw $0001, $0059, $0000, $0002        ; 01 - Master Sword
    dw $0001, $0059, $0000, $0003        ; 02 - Tempered Sword
    dw $0001, $0059, $0000, $0004        ; 02 - Gold Sword
    dw $0001, $005A, $0000, $0001        ; 04 - Shield
    dw $0001, $005A, $0000, $0002        ; 05 - Red Shield
    dw $0001, $005A, $0000, $0003        ; 06 - Mirror Shield
    dw $0001, $0045, $0000, $0001        ; 07 - Firerod
    dw $0001, $0046, $0000, $0001        ; 08 - Icerod  
    dw $0001, $004B, $0000, $0001        ; 09 - Hammer
    dw $0001, $0042, $0000, $0001        ; 0A - Hookshot
    dw $0001, $0040, $0000, $0002        ; 0B - Bow                       
    dw $0001, $0041, $0000, $0001        ; 0C - Blue Boomerang
    dw $0001, $0044, $0000, $0002        ; 0D - Powder
    dw $0001, $0000, $0000, $0000        ; 0E - Dummy - Bee (bottle content)
    dw $0001, $0047, $0000, $0001        ; 0F - Bombos
    
    dw $0001, $0048, $0000, $0001        ; 10 - Ether
    dw $0001, $0049, $0000, $0001        ; 11 - Quake
    dw $0001, $004A, $0000, $0001        ; 12 - Lamp
    dw $0001, $004C, $0000, $0001        ; 13 - Shovel
    dw $0001, $004C, $0000, $0002        ; 14 - Flute                      
    dw $0001, $0050, $0000, $0001        ; 15 - Somaria
    dw $0001, $004F, $0012, $0002        ; 16 - Bottle
    dw $0001, $006B, $0013, $0001        ; 17 - Piece of Heart
    dw $0001, $0051, $0000, $0001        ; 18 - Byrna
    dw $0001, $0052, $0000, $0001        ; 19 - Cape
    dw $0001, $0053, $0000, $0002        ; 1A - Mirror
    dw $0001, $0054, $0000, $0001        ; 1B - Glove
    dw $0001, $0054, $0000, $0002        ; 1C - Mitt
    dw $0001, $004E, $0000, $0001        ; 1D - Book
    dw $0001, $0056, $0016, $0001        ; 1E - Flippers
    dw $0001, $0057, $0000, $0001        ; 1F - Pearl
    
    dw $0001, $0000, $0000, $0000        ; 20 - Dummy 
    dw $0001, $004D, $0000, $0001        ; 21 - Net
    dw $0001, $005B, $0000, $0001        ; 22 - Blue Tunic
    dw $0001, $005B, $0000, $0002        ; 23 - Red Tunic
    dw $0001, $0000, $0000, $0000        ; 24 - Dummy - key
    dw $0001, $0000, $0000, $0000        ; 25 - Dummy - compass
    dw $0001, $006C, $0001, $0008        ; 26 - Heart Container - no anim
    dw $0001, $0075, $0001, $0001        ; 27 - Bomb 1
    dw $0001, $0075, $0001, $0003        ; 28 - 3 Bombs                    
    dw $0001, $0044, $0000, $0001        ; 29 - Mushroom
    dw $0001, $0041, $0000, $0002        ; 2A - Red Boomerang
    dw $0001, $004F, $0012, $0003        ; 2B - Red Potion
    dw $0001, $004F, $0012, $0004        ; 2C - Green Potion
    dw $0001, $004F, $0012, $0005        ; 2D - Blue Potion
    dw $0001, $0000, $0000, $0000        ; 2E - Dummy - red
    dw $0001, $0000, $0000, $0000        ; 2F - Dummy - green
    
    dw $0001, $0000, $0000, $0000        ; 30 - Dummy - blue
    dw $0001, $0075, $0001, $000A        ; 31 - 10 Bombs
    dw $0001, $0000, $0000, $0000        ; 32 - Dummy - big key
    dw $0001, $0000, $0000, $0000        ; 33 - Dummy - map
    dw $0001, $0060, $0014, $0001        ; 34 - 1 Rupee
    dw $0001, $0060, $0014, $0005        ; 35 - 5 Rupees
    dw $0001, $0060, $0014, $0014        ; 36 - 20 Rupees
    dw $0001, $0000, $0000, $0000        ; 37 - Dummy - Pendant of Courage
    dw $0001, $0000, $0000, $0000        ; 38 - Dummy - Pendant of Wisdom
    dw $0001, $0000, $0000, $0000        ; 39 - Dummy - Pendant of Power
    dw $0001, $0040, $0000, $0002        ; 3A - Bow and arrows
    dw $0001, $0040, $0017, $0003        ; 3B - Bow and silver Arrows
    dw $0001, $004F, $0012, $0007        ; 3C - Bee
    dw $0001, $004F, $0012, $0006        ; 3D - Fairy
    dw $0001, $006C, $0001, $0008        ; 3E - Heart Container - Boss
    dw $0001, $006C, $0001, $0008        ; 3F - Heart Container - Sanc
    
    dw $0001, $0060, $0014, $0064        ; 40 - 100 Rupees
    dw $0001, $0060, $0014, $0032        ; 41 - 50 Rupees
    dw $0001, $0000, $0000, $0000        ; 42 - Dummy - small heart
    dw $0001, $0076, $0001, $0001        ; 43 - 1 Arrow
    dw $0001, $0076, $0001, $000A        ; 44 - 10 Arrows
    dw $0001, $0000, $0000, $0000        ; 45 - Dummy - small magic
    dw $0001, $0060, $0014, $012C        ; 46 - 300 Rupees
    dw $0001, $0060, $0014, $0014        ; 47 - 20 Rupees
    dw $0001, $004F, $0012, $0008        ; 48 - Good Bee
    dw $0001, $0059, $0000, $0001        ; 49 - Fighter Sword
    dw $0001, $0000, $0000, $0000        ; 4A - Dummy - activated flute
    dw $0001, $0055, $0015, $0001        ; 4B - Boots                      
    dw $0001, $0000, $0000, $0000        ; 4C - Dummy - 50+bombs
    dw $0001, $0000, $0000, $0000        ; 4D - Dummy - 70+arrows
    dw $0001, $007B, $0000, $0001        ; 4E - Half Magic
    dw $0001, $007B, $0000, $0002        ; 4F - Quarter Magic              
    
    dw $0001, $0059, $0000, $0002        ; 50 - Master Sword
    dw $0001, $0070, $0001, $0005        ; 51 - +5 Bombs
    dw $0001, $0070, $0001, $000A        ; 52 - +10 Bombs
    dw $0001, $0071, $0001, $0005        ; 53 - +5 Arrows
    dw $0001, $0071, $0001, $000A        ; 54 - +10 Arrows
    dw $0000, $0000, $0000, $0000        ; 55 - Dummy - Programmable 1
    dw $0000, $0000, $0000, $0000        ; 56 - Dummy - Programmable 2
    dw $0000, $0000, $0000, $0000        ; 57 - Dummy - Programmable 3
    dw $0001, $0040, $0017, $0003        ; 58 - Silver Arrows

    dw $0000, $0000, $0000, $0000        ; 59 - Unused (Rupoor)        
    dw $0000, $0000, $0000, $0000        ; 5A - Unused (Null Item)     
    dw $0000, $0000, $0000, $0000        ; 5B - Unused (Red Clock)     
    dw $0000, $0000, $0000, $0000        ; 5C - Unused (Blue Clock)    
    dw $0000, $0000, $0000, $0000        ; 5D - Unused (Green Clock)   
    dw $0001, $0059, $0018, $0000        ; 5E - Progressive Sword
    dw $0001, $005A, $0018, $0008        ; 5F - Progressive Shield

    dw $0001, $005B, $0018, $0010        ; 60 - Progressive Armor
    dw $0001, $0054, $0018, $0018        ; 61 - Progressive Glove
    dw $0003, $0002, $0003, $0001        ; 62 - Bombs                  (M1)
    dw $0003, $0002, $0003, $0002        ; 63 - High Jump              (M1)
    dw $0001, $0000, $0000, $0000        ; 64 - Reserved - Progressive Bow                 (Why two here? Are both used?)
    dw $0001, $0000, $0000, $0000        ; 65 - Reserved - Progressive Bow                 (Why two here? Are both used?)
    dw $0003, $0002, $0003, $0004        ; 66 - Long Beam              (M1)
    dw $0003, $0002, $0003, $0008        ; 67 - Screw Attack           (M1)
    dw $0003, $0002, $0003, $0010        ; 68 - Morph Ball             (M1)
    dw $0003, $0002, $0003, $0020        ; 69 - Varia Suit             (M1)
    dw $0001, $0000, $0000, $0000        ; 6A - Reserved - Goal Item (Single/Triforce)
    dw $0001, $0000, $0000, $0000        ; 6B - Reserved - Goal Item (Multi/Power Star)    (Is this used for anything)
    dw $0003, $0002, $0003, $0040        ; 6C - Wave Beam              (M1)
    dw $0003, $0002, $0003, $0080        ; 6D - Ice Beam               (M1)
    dw $0003, $0001, $0001, $0001        ; 6E - Energy Tank            (M1)
    dw $0003, $0003, $0040, $0005        ; 6F - Missiles               (M1)

    dw $0000, $0070, $0002, $0001        ; 70 - Crateria L1 Key        (SM)
    dw $0000, $0070, $0002, $0002        ; 71 - Crateria L2 Key        (SM)
    dw $0001, $0068, $0019, $0004        ; 72 - Ganons Tower Map
    dw $0001, $0068, $0019, $0008        ; 73 - Turtle Rock Map
    dw $0001, $0068, $0019, $0010        ; 74 - Thieves' Town Map
    dw $0001, $0068, $0019, $0020        ; 75 - Tower of Hera Map
    dw $0001, $0068, $0019, $0040        ; 76 - Ice Palace Map
    dw $0001, $0068, $0019, $0080        ; 77 - Skull Woods Map
    dw $0001, $0068, $0019, $0100        ; 78 - Misery Mire Map
    dw $0001, $0068, $0019, $0200        ; 79 - Palace Of Darkness Map
    dw $0001, $0068, $0019, $0400        ; 7A - Swamp Palace Map
    dw $0000, $0070, $0002, $0004        ; 7B - Crateria Boss Key      (SM)
    dw $0001, $0068, $0019, $1000        ; 7C - Desert Palace Map
    dw $0001, $0068, $0019, $2000        ; 7D - Eastern Palace Map
    dw $0000, $0070, $0002, $0800        ; 7E - Maridia Boss Key       (SM)
    dw $0001, $0068, $0019, $C000        ; 7F - Hyrule Castle Map

    dw $0000, $0070, $0002, $0008        ; 80 - Brinstar L1 Key        (SM)
    dw $0000, $0070, $0002, $0010        ; 81 - Brinstar L2 Key        (SM)
    dw $0001, $0064, $0019, $0004        ; 82 - Ganons Tower Compass
    dw $0001, $0064, $0019, $0008        ; 83 - Turtle Rock Compass
    dw $0001, $0064, $0019, $0010        ; 84 - Thieves' Town Compass
    dw $0001, $0064, $0019, $0020        ; 85 - Tower of Hera Compass
    dw $0001, $0064, $0019, $0040        ; 86 - Ice Palace Compass
    dw $0001, $0064, $0019, $0080        ; 87 - Skull Woods Compass
    dw $0001, $0064, $0019, $0100        ; 88 - Misery Mire Compass
    dw $0001, $0064, $0019, $0200        ; 89 - Palace of Darkness Compass
    dw $0001, $0064, $0019, $0400        ; 8A - Swamp Palace Compass
    dw $0000, $0070, $0002, $0020        ; 8B - Brinstar Boss Key      (SM)
    dw $0001, $0064, $0019, $1000        ; 8C - Desert Palace Compass
    dw $0001, $0064, $0019, $2000        ; 8D - Eastern Palace Compass
    dw $0000, $0070, $0002, $1000        ; 8E - Wrecked Ship L1 Key    (SM)
    dw $0000, $0070, $0002, $2000        ; 8F - Wrecked Ship Boss Key  (SM)

    dw $0000, $0070, $0002, $0040        ; 90 - Norfair L1 Key         (SM)
    dw $0000, $0070, $0002, $0080        ; 91 - Norfair L2 Key         (SM)
    dw $0001, $0066, $0019, $0004        ; 92 - Ganons Tower Big Key
    dw $0001, $0066, $0019, $0008        ; 93 - Turtle Rock Big Key
    dw $0001, $0066, $0019, $0010        ; 94 - Thieves' Town Big Key
    dw $0001, $0066, $0019, $0020        ; 95 - Tower of Hera Big Key
    dw $0001, $0066, $0019, $0040        ; 96 - Ice Palace Big Key
    dw $0001, $0066, $0019, $0080        ; 97 - Skull Woods Big Key
    dw $0001, $0066, $0019, $0100        ; 98 - Misery Mire Big Key
    dw $0001, $0066, $0019, $0200        ; 99 - Palace of Darkness Big Key
    dw $0001, $0066, $0019, $0400        ; 9A - Swamp Palace Big Key
    dw $0000, $0070, $0002, $0100        ; 9B - Norfair Boss Key       (SM)
    dw $0001, $0066, $0019, $1000        ; 9C - Desert Palace Big Key
    dw $0001, $0066, $0019, $2000        ; 9D - Eastern Palace Big Key
    dw $0000, $0070, $0002, $4000        ; 9E - Lower Norfair L1 Key   (SM)
    dw $0000, $0070, $0002, $8000        ; 9F - Lower Norfair Boss Key (SM)

    dw $0000, $007C, $001A, $0001        ; A0 - Hyrule Castle Small Key
    dw $0000, $007C, $001A, $0001        ; A1 - Sewers Small Key
    dw $0000, $007E, $001A, $0001        ; A2 - Eastern Palace Small Key
    dw $0000, $007F, $001A, $0001        ; A3 - Desert Palace Small Key
    dw $0000, $0080, $001A, $0001        ; A4 - Castle Tower Small Key
    dw $0000, $0081, $001A, $0001        ; A5 - Swamp Palace Small Key
    dw $0000, $0082, $001A, $0001        ; A6 - Palace of Darkness Small Key
    dw $0000, $0083, $001A, $0001        ; A7 - Misery Mire Small Key
    dw $0000, $0084, $001A, $0001        ; A8 - Skull Woods Small Key
    dw $0000, $0085, $001A, $0001        ; A9 - Ice Palace Small Key
    dw $0000, $0086, $001A, $0001        ; AA - Tower of Hera Small Key
    dw $0000, $0087, $001A, $0001        ; AB - Thieves' Town Small Key
    dw $0000, $0088, $001A, $0001        ; AC - Turtle Rock Small Key
    dw $0000, $0089, $001A, $0001        ; AD - Ganons Tower Small Key
    dw $0001, $0070, $0002, $0200        ; AE - Maridia L1 Key          (SM)
    dw $0001, $0070, $0002, $0400        ; AF - Maridia L2 Key          (SM)

    dw $0000, $0000, $0020, $4000        ; B0 - Grapple beam            (SM)
    dw $0000, $0000, $0020, $8000        ; B1 - X-ray scope             (SM)
    dw $0000, $0000, $0020, $0001        ; B2 - Varia suit              (SM)
    dw $0000, $0000, $0020, $0002        ; B3 - Spring ball             (SM)
    dw $0000, $0000, $0020, $0004        ; B4 - Morph ball              (SM)
    dw $0000, $0000, $0020, $0008        ; B5 - Screw attack            (SM)
    dw $0000, $0000, $0020, $0020        ; B6 - Gravity suit            (SM)
    dw $0000, $0000, $0020, $0100        ; B7 - Hi-Jump                 (SM)
    dw $0000, $0000, $0020, $0200        ; B8 - Space jump              (SM)
    dw $0000, $0000, $0020, $1000        ; B9 - Bombs                   (SM)
    dw $0000, $0000, $0020, $2000        ; BA - Speed booster           (SM)
    dw $0000, $0004, $0020, $1000        ; BB - Charge                  (SM)
    dw $0000, $0004, $0020, $0002        ; BC - Ice Beam                (SM)
    dw $0000, $0004, $0020, $0001        ; BD - Wave beam               (SM)
    dw $0000, $0004, $0021, $0004        ; BE - Spazer                  (SM)
    dw $0000, $0004, $0021, $0008        ; BF - Plasma beam             (SM)

    dw $0000, $0020, $0022, $0064        ; C0 - Energy Tank             (SM)
    dw $0000, $0032, $0023, $0064        ; C1 - Reserve tank            (SM)
    dw $0000, $0024, $0024, $0005        ; C2 - Missile                 (SM)
    dw $0000, $0028, $0024, $0005        ; C3 - Super Missile           (SM)
    dw $0000, $002c, $0024, $0005        ; C4 - Power Bomb              (SM)
    dw $0000, $0072, $0002, $0001        ; C5 - Kraid Boss Token        (SM)
    dw $0000, $0072, $0002, $0002        ; C6 - Phantoon Boss Token     (SM)
    dw $0000, $0072, $0002, $0004        ; C7 - Draygon Boss Token      (SM)
    dw $0000, $0072, $0002, $0008        ; C8 - Ridley Boss Token       (SM)
    dw $0000, $0000, $0000, $0000        ; C9 - Unused
    dw $0000, $0074, $0002, $0001        ; CA - Kraid Map               (SM)
    dw $0000, $0074, $0002, $0002        ; CB - Phantoon Map            (SM)
    dw $0000, $0074, $0002, $0004        ; CC - Draygon Map             (SM)
    dw $0000, $0074, $0002, $0008        ; CD - Ridley Map              (SM)
    dw $0000, $0000, $0000, $0000        ; CE - Unused
    dw $0000, $0000, $0000, $0000        ; CF - Unused (Reserved)

    ; Note - The can't be accessed from Z1 atm (due to all items being offset by 0x30)
    ; But these are in the same order as original Z1 items, so they're at (00-2F) in the game as their
    ; original Z1 counterparts

    dw $0002, $0001, $0001, $0004        ; D0 - Bombs                (Z1)
    dw $0002, $0000, $0000, $0001        ; D1 - Wooden Sword         (Z1)
    dw $0002, $0000, $0000, $0002        ; D2 - White Sword          (Z1)
    dw $0002, $0000, $0000, $0003        ; D3 - Magical Sword        (Z1)
    dw $0002, $0006, $0000, $0001        ; D4 - Bait                 (Z1)
    dw $0002, $0005, $0000, $0001        ; D5 - Recorder             (Z1)
    dw $0002, $0004, $0000, $0001        ; D6 - Blue Candle          (Z1)
    dw $0002, $0004, $0000, $0002        ; D7 - Red Candle           (Z1)
    dw $0002, $0002, $0000, $0001        ; D8 - Arrows               (Z1)
    dw $0002, $0002, $0000, $0002        ; D9 - Silver Arrows        (Z1)
    dw $0002, $0003, $0000, $0001        ; DA - Bow                  (Z1)
    dw $0002, $000D, $0000, $0001        ; DB - Magical Key          (Z1)
    dw $0002, $0009, $0000, $0001        ; DC - Raft                 (Z1)
    dw $0002, $000C, $0000, $0001        ; DD - Stepladder           (Z1)
    dw $0002, $0000, $0000, $0000        ; DE - Unused?              (Z1) ; Internal item
    dw $0002, $0016, $0030, $0005        ; DF - 5 Rupees             (Z1)

    dw $0002, $0008, $0000, $0001        ; E0 - Magical Rod          (Z1)
    dw $0002, $000A, $0000, $0001        ; E1 - Book of Magic        (Z1)
    dw $0002, $000B, $0000, $0001        ; E2 - Blue Ring            (Z1)
    dw $0002, $000B, $0000, $0002        ; E3 - Red Ring             (Z1)
    dw $0002, $000E, $0000, $0001        ; E4 - Power Bracelet       (Z1)
    dw $0002, $000F, $0000, $0001        ; E5 - Letter               (Z1)
    dw $0002, $0010, $0000, $0000        ; E6 - Compass              (Z1)  ; Bitmask per level (don't place this)
    dw $0002, $0011, $0000, $0000        ; E7 - Dungeon Map          (Z1)  ; Bitmask per level (don't place this)
    dw $0002, $0016, $0030, $0001        ; E8 - 1 Rupee              (Z1)
    dw $0002, $0017, $0001, $0001        ; E9 - Small Key            (Z1)
    dw $0002, $0018, $0031, $0001        ; EA - Heart Container      (Z1)
    dw $0002, $0000, $0000, $0000        ; EB - Triforce Fragment    (Z1)    ; TODO: Add this when shuffling rewards
    dw $0002, $001F, $0000, $0001        ; EC - Magical Shield       (Z1)
    dw $0002, $001D, $0000, $0001        ; ED - Boomerang            (Z1)
    dw $0002, $001E, $0000, $0001        ; EE - Magical Boomerang    (Z1)
    dw $0002, $0007, $0000, $0002        ; EF - Blue Potion          (Z1)

    dw $0002, $0007, $0000, $0001        ; F0 - Red Potion           (Z1)
    dw $0002, $0000, $0000, $0000        ; F1 - Clock                (Z1)  ; Internal item
    dw $0002, $0000, $0000, $0000        ; F2 - Small Heart          (Z1)  ; Internal item
    dw $0002, $0000, $0000, $0000        ; F3 - Fairy                (Z1)  ; Internal item
    dw $0002, $0000, $0000, $0000        ; F4 - Unused  (Triforce 1?)
    dw $0002, $0000, $0000, $0000        ; F5 - Unused  (Triforce 2?)
    dw $0002, $0000, $0000, $0000        ; F6 - Unused  (Triforce 3?)
    dw $0002, $0000, $0000, $0000        ; F7 - Unused  (Triforce 4?)
    dw $0002, $0000, $0000, $0000        ; F8 - Unused  (Triforce 5?)
    dw $0002, $0000, $0000, $0000        ; F9 - Unused  (Triforce 6?)
    dw $0002, $0000, $0000, $0000        ; FA - Unused  (Triforce 7?)
    dw $0002, $0000, $0000, $0000        ; FB - Unused  (Triforce 8?)
    dw $0002, $0000, $0000, $0000        ; FC - Unused
    dw $0002, $0000, $0000, $0000        ; FD - Unused
    dw $0002, $0000, $0000, $0000        ; FE - Unused
    dw $0002, $0000, $0000, $0000        ; FF - Unused (Reserved)