;
; Repointed Room Items
;
RoomItemsUW_extended:
print "RoooItemsExtended = ", pc

; Levels 1-6
db $2F, $19, $2F, $1B, $05, $2F, $2F, $2F, $2F, $2F, $2F, $2F, $1B, $1B, $1A, $0C
db $2F, $2F, $2F, $1A, $1B, $2F, $19, $2F, $2F, $17, $19, $2F, $1A, $2F, $00, $2F
db $2F, $17, $2F, $19, $1A, $2F, $19, $19, $0F, $19, $19, $2F, $2F, $19, $2F, $0F
db $2F, $2F, $2F, $19, $2F, $1A, $1B, $16, $2F, $2F, $2F, $2F, $00, $1B, $19, $00
db $19, $2F, $2F, $17, $1D, $19, $17, $19, $2F, $19, $00, $19, $17, $1A, $19, $1E
db $2F, $19, $2F, $19, $16, $19, $00, $0F, $19, $2F, $16, $00, $2F, $0F, $2F, $17
db $0D, $2F, $16, $2F, $2F, $00, $19, $2F, $16, $00, $2F, $19, $19, $2F, $2F, $16
db $19, $2F, $19, $2F, $19, $10, $2F, $19, $2F, $2F, $19, $19, $2F, $2F, $19, $0A

; Levels 7-9
db $13, $2F, $2F, $2F, $2F, $2F, $2F, $2F, $2F, $0F, $19, $00, $00, $2F, $00, $0B
db $2F, $00, $0F, $2F, $2F, $0F, $00, $2F, $17, $2F, $2F, $00, $2F, $00, $2F, $2F
db $2F, $2F, $2F, $00, $2F, $00, $0F, $17, $2F, $2F, $1A, $1B, $1B, $2F, $17, $2F
db $2F, $2F, $2F, $2F, $0F, $16, $2F, $00, $0F, $2F, $19, $2F, $1A, $2F, $2F, $00
db $0F, $2F, $0E, $2F, $0F, $2F, $2F, $19, $2F, $2F, $07, $19, $19, $2F, $0F, $09
db $2F, $2F, $2F, $2F, $2F, $2F, $19, $19, $0F, $2F, $16, $2F, $19, $19, $19, $16
db $2F, $19, $0F, $2F, $2F, $2F, $2F, $2F, $00, $00, $2F, $2F, $00, $19, $0F, $11
db $2F, $2F, $2F, $2F, $2F, $2F, $2F, $2F, $19, $2F, $00, $2F, $2F, $0F, $2F, $19

;
; Repointed cave data to support extended item id
; ranges
;
print "CaveShopItems_extended = ", pc
CaveShopItems_extended:
    db $2F, $01, $2F
    db $20, $2F, $1A
    db $2F, $02, $2F
    db $2F, $03, $2F
    db $2F, $2F, $2F
    db $2F, $2F, $2F
    db $18, $18, $18
    db $2F, $2F, $2F
    db $2F, $15, $2F
    db $2F, $2F, $2F
    db $1F, $2F, $20
    db $18, $18, $18
    db $18, $18, $18
    db $1C, $00, $08
    db $1C, $19, $06
    db $1C, $04, $22
    db $19, $12, $04
    db $2F, $18, $2F
    db $2F, $18, $2F
    db $2F, $18, $2F

CaveShopFlags_extended:
    db $00, $00, $40
    db $00, $00, $40
    db $40, $00, $40
    db $40, $00, $40
    db $00, $00, $00
    db $00, $00, $00
    db $80, $80, $C0
    db $00, $00, $00
    db $00, $00, $40
    db $00, $00, $00
    db $00, $00, $C0
    db $80, $40, $C0
    db $80, $40, $C0
    db $00, $00, $C0
    db $00, $00, $C0
    db $00, $00, $C0
    db $00, $00, $C0
    db $00, $80, $40
    db $00, $80, $40
    db $00, $80, $40

CaveShopPrices_extended:
    db $00, $00, $00
    db $00, $00, $00
    db $00, $00, $00
    db $00, $00, $00
    db $00, $00, $00
    db $00, $00, $00
    db $0A, $0A, $0A
    db $00, $00, $00
    db $00, $00, $00
    db $00, $00, $00
    db $28, $00, $44
    db $05, $0A, $14
    db $0A, $1E, $32
    db $82, $14, $50
    db $A0, $64, $3C
    db $5A, $64, $0A
    db $50, $FA, $3C
    db $00, $1E, $00
    db $00, $64, $00
    db $00, $0A, $00

; Repointed extended tables for item data
; Item descriptor class, high nibble = class, low nibble = upgrade level etc
; Class 0 = regular unique item (special handling from certain slots)
; Class 1 = Item type with amount (rupees, hearts, keys, etc)
; Class 2 = Item type by grade (as specificied by low nibble)
; Class 4 = New item
; Class 8 = Reserved

ItemIdToDescriptor_extended:
    db $14, $21, $22, $23, $01, $01, $21, $22 ; 00-07
    db $21, $22, $01, $01, $01, $01, $01, $15 ; 08-1f
    db $01, $01, $21, $22, $01, $01, $01, $01 ; 10-17
    db $11, $11, $10, $01, $01, $01, $01, $11 ; 18-1f
    db $22, $01, $10, $12, $00, $00, $00, $00 ; 20-27
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 27-2f
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 30-38
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 38-3f
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 40-47
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 48-4f
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 50-57
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 58-5f
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 60-67
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 68-6f
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 70-77
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 78-7f
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 80-87
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 88-8f
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 90-97
    db $40, $40, $40, $40, $40, $40, $40, $40 ; 98-9f
    db $40, $40, $40, $40, $40, $40, $40, $40 ; a0-a7
    db $40, $40, $40, $40, $40, $40, $40, $40 ; a8-af
    db $40, $40, $40, $40, $40, $40, $40, $40 ; b0-b7
    db $40, $40, $40, $40, $40, $40, $40, $40 ; b8-bf
    db $40, $40, $40, $40, $40, $40, $40, $40 ; c0-c7
    db $40, $40, $40, $40, $40, $40, $40, $40 ; c8-cf
    db $40, $40, $40, $40, $40, $40, $40, $40 ; d0-d7
    db $40, $40, $40, $40, $40, $40, $40, $40 ; d8-df
    db $40, $40, $40, $40, $40, $40, $40, $40 ; e0-e7
    db $40, $40, $40, $40, $40, $40, $40, $40 ; e8-ef
    db $40, $40, $40, $40, $40, $40, $40, $40 ; f0-f7
    db $40, $40, $40, $40, $40, $40, $40, $00 ; f8-ff

;
; Inventory slot to place the item in
; Can be used here to use the same graphics for the same items
;

ItemIdToSlot_extended:
    db $01, $00, $00, $00, $06, $05, $04, $04 ; 00-07
    db $02, $02, $03, $0D, $09, $0C, $1B, $1C ; 08-1f
    db $08, $0A, $0B, $0B, $0E, $0F, $10, $11 ; 10-17
    db $16, $17, $18, $1A, $1F, $1D, $1E, $07 ; 18-1f
    db $07, $15, $19, $14, $00, $00, $00, $00 ; 20-27
    db $00, $00, $00, $00, $00, $00, $00, $2f ; 27-2f
    db $30, $31, $32, $33, $34, $35, $36, $37 ; 30-38
    db $38, $39, $3A, $3B, $3C, $3D, $3E, $3F ; 38-3f
    db $40, $41, $42, $43, $44, $45, $46, $47 ; 40-47
    db $48, $49, $4A, $4B, $4C, $4D, $4E, $4F ; 48-4f
    db $50, $51, $52, $53, $54, $55, $56, $57 ; 50-57
    db $58, $59, $5A, $5B, $5C, $5D, $5E, $5F ; 58-5f
    db $60, $61, $62, $63, $64, $65, $66, $67 ; 60-67
    db $68, $69, $6A, $6B, $6C, $6D, $6E, $6F ; 68-6f
    db $70, $71, $72, $73, $74, $75, $76, $77 ; 70-77
    db $78, $79, $7A, $7B, $7C, $7D, $7E, $7F ; 78-7f
    db $80, $81, $82, $83, $84, $85, $86, $87 ; 80-87
    db $88, $89, $8A, $8B, $8C, $8D, $8E, $8F ; 88-8f
    db $90, $91, $92, $93, $94, $95, $96, $97 ; 90-97
    db $98, $99, $9A, $9B, $9C, $9D, $9E, $9F ; 98-9f
    db $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7 ; a0-a7
    db $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF ; a8-af
    db $B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7 ; b0-b7
    db $B8, $B9, $BA, $BB, $BC, $BD, $BE, $BF ; b8-bf
    db $C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7 ; c0-c7
    db $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF ; c8-cf
    db $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7 ; d0-d7
    db $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF ; d8-df
    db $E0, $E1, $E2, $E3, $E4, $E5, $E6, $E7 ; e0-e7
    db $E8, $E9, $EA, $EB, $EC, $ED, $EE, $EF ; e8-ef
    db $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7 ; f0-f7
    db $F8, $F9, $FA, $FB, $FC, $FD, $FE, $2f ; f8-ff

;
; Attribute flags for the item (based on slot)
;

ItemSlotToPaletteOffsetsOrValues_extended:
    db $FF, $01, $FF, $00, $00, $02, $02, $00 ; 00-07
    db $01, $00, $02, $00, $00, $02, $02, $01 ; 08-1f
    db $02, $02, $02, $02, $02, $02, $02, $02 ; 10-17
    db $02, $02, $02, $02, $01, $00, $01, $00 ; 18-1f
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 20-27
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 27-2f
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 30-38
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 38-3F
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 40-47
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 48-4F
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 50-57
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 58-5F
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 60-67
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 68-6F
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 70-77
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 78-7F
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 80-87
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 88-8F
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 90-97
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 98-9F
    db $00, $00, $00, $00, $00, $00, $00, $00 ; A0-A7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; A8-AF
    db $00, $00, $00, $00, $00, $00, $00, $00 ; B0-B7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; B8-BF
    db $00, $00, $00, $00, $00, $00, $00, $00 ; C0-C7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; C8-CF
    db $00, $00, $00, $00, $00, $00, $00, $00 ; D0-D7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; D8-DF
    db $00, $00, $00, $00, $00, $00, $00, $00 ; E0-E7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; E8-EF
    db $00, $00, $00, $00, $00, $00, $00, $00 ; F0-F7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; F8-FF

;
; Item animation data (based on slot)
; Index into FrameTiles for what VRAM tiles to use
;

Anim_ItemFrameOffsets_extended:
    db $00, $03, $07, $0A, $0B, $0C, $0D, $0E ; 00-07
    db $0F, $11, $12, $13, $14, $15, $16, $17 ; 08-1f
    db $18, $17, $18, $17, $19, $1B, $1C, $1D ; 10-17
    db $1E, $1F, $20, $21, $1C, $22, $22, $26 ; 18-1f
    db $27, $28, $29, $2B, $2E, $00, $00, $00 ; 20-27
    db $00, $00, $00, $00, $00, $00, $00, $3f ; 27-2f
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 30-38
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 39-3f
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 40-47
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 48-4f
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 50-57
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 58-5f
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 60-67
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 68-6f
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 70-77
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 78-7f
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 80-87
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 88-8f
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 90-97
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 98-9f
    db $00, $00, $00, $00, $00, $00, $00, $00 ; a0-a7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; a8-af
    db $00, $00, $00, $00, $00, $00, $00, $00 ; b0-b7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; b8-bf
    db $00, $00, $00, $00, $00, $00, $00, $00 ; c0-c7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; c8-cf
    db $00, $00, $00, $00, $00, $00, $00, $00 ; d0-d7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; d8-df
    db $00, $00, $00, $00, $00, $00, $00, $00 ; e0-e7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; e8-ef
    db $00, $00, $00, $00, $00, $00, $00, $00 ; f0-f7
    db $00, $00, $00, $00, $00, $00, $00, $00 ; f8-ff

;
; Item graphics indexes
; Direct index to the VRAM tiles to use
;

Anim_ItemFrameTiles_extended:
    db $20, $82, $3C, $34, $70, $72, $74, $28 ; 00-07
    db $86, $3C, $2A, $26, $24, $22, $40, $4A ; 08-1f
    db $8A, $6C, $42, $46, $76, $2C, $4E, $4C ; 10-17
    db $6A, $50, $52, $66, $32, $2E, $68, $F3 ; 18-1f
    db $6E, $F2, $36, $38, $3A, $3C, $56, $48 ; 20-27
    db $78, $20, $82, $7A, $7C, $30, $64, $62 ; 27-2f
    db $00, $00, $00, $00, $00, $00, $00, $00 ; 30-37
    db $00, $00, $00, $00, $00, $00, $00, $4F ; 38-3f



