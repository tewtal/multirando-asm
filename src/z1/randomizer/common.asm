; Add anything here that needs to be easily available in all banks

; Local bank functions that makes it easy to replace the regular loads with long loads
LoadItemIdToDescriptor_extended:
    lda.l ItemIdToDescriptor_extended, x
    rts

LoadItemIdToSlot_extended:
    lda.l ItemIdToSlot_extended, x
    rts

LoadItemSlotToPaletteOffsetsOrValues_extended:
    lda.l ItemSlotToPaletteOffsetsOrValues_extended, x
    rts

LoadAnim_ItemFrameOffsets_extended_y:
    phx : tyx
    lda.l Anim_ItemFrameOffsets_extended, x
    plx
    rts

LoadAnim_ItemFrameTiles_extended_y:
    phx : tyx
    lda.l Anim_ItemFrameTiles_extended, x
    plx
    rts

GetDynamicItemIndex_near:
    jsl GetDynamicItemIndex
    rts

InitMode8_SaveItems:
    jsl SaveItems
    jsr $E625
    rts

; =============================================
; Expanded dungeons support
; =============================================

CopyBlock_Common:
    jsl CopyBlock_LevelData
    rts