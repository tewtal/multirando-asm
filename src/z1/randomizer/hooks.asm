; ========================================================================
; Cross-game transitions
; ========================================================================

; Entering a Cave
; $EB = RoomId (of the overworld room we're coming from, and will exit to)
; LDA $AB45, X : STA $02
org $85AB4F
    jsl check_cave_transition_in : nop

; Exiting a Cave
; $EB = RoomId (of the overworld room we're coming from, and will exit to)
; JMP $EA2B
org $85B157
    jmp CheckCaveTransitionOut_common

; Entering or exiting dungeon - hook this, this also runs when exiting a dungeon
; $10 (current level) will be $00 when exiting (and $01+ when entering depending on dungeon)
; $EB = Previous RoomId (for the room we're entering from)
; $6BAD = New RoomId (for the room we're going to)
; LDA $10
; BNE $85EA1C
org $85EA11
    jml check_dungeon_transition


; ========================================================================
; New items support
; ========================================================================

; Hook all loads from item/object related tables to use our extended tables
; in a different bank
%zhook($E71E, "jsr LoadItemIdToDescriptor_extended")
%zhook($E729, "jsr LoadItemIdToSlot_extended")
%zhook($E73A, "jsr LoadItemSlotToPaletteOffsetsOrValues_extended")
org $81AC02 : jsr LoadItemIdToSlot_extended
org $81AC06 : jsr LoadItemIdToDescriptor_extended
org $81B1A6 : jsr LoadAnim_ItemFrameOffsets_extended_y
org $81B1AD : jsr LoadAnim_ItemFrameTiles_extended_y

; Hook for displaying dynamically loaded item sprites
org $81B19C
    jsl Anim_WriteSpecificItemSprites_extended
    bcc +
    bra $33 : +

; Hook "TakeItem" for our item descriptor class 0x40
;    LDA #$FF                   
;    CPY #$07
;    BNE :+
;    CMP #$03
;    BCC :+
;    LDA #$02
org $81AC5B
    jsl TakeItem_SetItemValueFF_extended
    bcc +
    rts
+
    bra $03

; 85B847  A4 EB          LDY $EB
; 85B849  B9 7E 6A       LDA $6A7E,Y
; 85B84C  29 1F          AND #$1F
; 85B84E  C9 03          CMP #$03
; Load Room Item Id for underworld rooms
org $85B847
    jsl LoadRoomItemIdUW_extended : nop #5

; ========================================================================
; Shops
; ========================================================================

; Change shops to use 2F as empty item, and remove 3F mask
org $818764
    and #$FF
    cmp #$2F

org $8188A2
    and #$FF
    cmp #$2F

org $818915
    and #$FF

org $818619
    jsl LoadCaveShopItems_extended
    bra $0A

; ========================================================================
