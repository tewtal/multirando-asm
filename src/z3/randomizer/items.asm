;
; ALTTP Extended items
; This file contains the code and data to extend the regular ALTTPR itemset
; with new items for SM for example
;

; Replace link's house item for testing
pushpc
org $01E9BC
    db $d0
pullpc

AddReceivedItemExpanded_extended:
    phx
    phy
    php

    %ai16()
    ; Check if the item belongs to this game
    lda $02d8
    and #$00ff
    jsl mb_CheckItemGame
    cmp.w #$0001
    beq .alttpItem

    ; Do things here with items before receiving them
    ; if we need to do things for some reason
    
    plp : ply : plx
    sec
    rtl

.alttpItem
    plp : ply : plx
    clc
    rtl

AddReceivedItemExpandedGetItem_extended:
    phx
    phy
    php

    %ai16()
    pha
    lda $02d8       ; Get item Id
    and #$00ff

    ; Check if the item belongs to this game
    jsl mb_CheckItemGame
    cmp.w #$0001
    beq .alttpItem

    ; Ok, this is an "out-of-game" item, so we need to handle it
    lda $02d8
    and #$00ff
    jsl mb_WriteItemToInventory         ; Write item to out-of-game inventory
    
    pla : plp : ply : plx
    sec
    rtl
.alttpItem
    pla : plp : ply : plx
    clc
    rtl


GetAnimatedSpriteGfxFile_extended:
    CMP.b #$50 : BCC .end
    CMP.b #$70 : BCS +
        LDY.b #$F0 : BRA .end
    +
    CMP.b #$90 : BCS +
        LDY.b #$F1 : BRA .end
    +
    CMP.b #$B0 : BCS +
        LDY.b #$F2 : BRA .end
    +
    CMP.b #$D0 : BCS .end
        LDY.b #$F3 : BRA .end        
    .end
    RTL

GetAnimatedSpriteBufferPointer_CopyId:
    AND.w #$00FF
    ASL
    STA.w !IRAM_ALTTP_GFX_POINTER
    RTL

GetAnimatedSpriteBufferPointer_extended:
    PHP
    REP #$30
    LDX.w !IRAM_ALTTP_GFX_POINTER
    CPX.w #$00A0 : BCC .end
	LDA.b $00 : CLC : ADC.l GetAnimatedSpriteBufferPointer_table_extended-$A0, X
.end
    PLP
    RTL

GetAnimatedSpriteBufferPointer_table_extended:
    ;#$50 - Super Metroid Item pointers
    dw $0600, $0630, $0660, $0690, $06C0, $06F0, $0720, $0750
    dw $0900, $0930, $0960, $0990, $09C0, $09F0, $0A20, $0A50
    dw $0C00, $0C30, $0C60, $0C90, $0CC0, $0CF0, $0D20, $0D50

    ;#$68-6F - Unused
    dw $0600, $0600, $0600, $0600, $0600, $0600, $0600, $0600

    ;#$70 - Super Metroid Item Graphics #2
    dw $0600, $0630, $0660, $0690, $06C0, $06F0, $0720, $0750
    dw $0900, $0930, $0960, $0990, $09C0, $09F0, $0A20, $0A50
    dw $0C00, $0C30, $0C60, $0C90, $0CC0, $0CF0, $0D20, $0D50
    
    ; Unused
    dw $0600, $0600, $0600, $0600, $0600, $0600, $0600, $0600

    ;#$90 - Metroid 1 Graphics + Zelda 1 Graphics #1
    dw $0600, $0630, $0660, $0690, $06C0, $06F0, $0720, $0750
    dw $0900, $0930, $0960, $0990, $09C0, $09F0, $0A20, $0A50
    dw $0C00, $0C30, $0C60, $0C90, $0CC0, $0CF0, $0D20, $0D50

    dw $0600, $0600, $0600, $0600, $0600, $0600, $0600, $0600
    
    ;#$B0 - Zelda 1 Graphics #2
    dw $0600, $0630, $0660, $0690, $06C0, $06F0, $0720, $0750
    dw $0900, $0930, $0960, $0990, $09C0, $09F0, $0A20, $0A50
    dw $0C00, $0C30, $0C60, $0C90, $0CC0, $0CF0, $0D20, $0D50

    dw $0600, $0600, $0600, $0600, $0600, $0600, $0600, $0600

Decomp_spr_high_extended:
	cpy #$f0
	bcs .extended

	lda $d033,y : sta $ca
	lda $d112,y : sta $c9
	lda $d1f1,y : sta $c8
	jml Decomp_spr_high_extended_return

.extended
	tya
	and #$0f
	phx
	tax
	lda.l .bank,x : sta $ca
	lda.l .high,x : sta $c9
	lda.l .low,x  : sta $c8
	plx
	jml Decomp_spr_high_extended_return

.bank
	db GFX_SM_Items>>16, GFX_SM_Items_2>>16, GFX_M1Z1_Items>>16, GFX_Z1_Items_2>>16, $00, $00, $00, $00
.high
	db GFX_SM_Items>>8, GFX_SM_Items_2>>8,GFX_M1Z1_Items>>8, GFX_Z1_Items_2>>8, $00, $00, $00, $00
.low
	db GFX_SM_Items, GFX_SM_Items_2, GFX_M1Z1_Items, GFX_Z1_Items_2, $00, $00, $00, $00

pushpc
org GetSpriteID_gfxSlots+$62
    ;62-65 (M1)
    db $99, $90, $9A, $92

org GetSpriteID_gfxSlots+$68
    ;68-69 (M1)
    db $91, $93

org GetSpriteID_gfxSlots+$6C
    ;6C-6F (M1)
    db $9C, $9B, $98, $95

org GetSpriteID_gfxSlots+$70
    ;70-71 (Keycards)
    db $65, $66

org GetSpriteID_gfxSlots+$7B
    ;7B (Keycards)
    db $67

org GetSpriteID_gfxSlots+$7E
    ;7E (Keycards)
    db $67

org GetSpriteID_gfxSlots+$80
    ;80-81 (Keycards)
    db $65, $66

org GetSpriteID_gfxSlots+$8B
    ;8B (Keycards)
    db $67

org GetSpriteID_gfxSlots+$8E
    ;8E-8F (Keycards)
    db $65, $67

org GetSpriteID_gfxSlots+$90
    ;90-91 (Keycards)
    db $65, $66

org GetSpriteID_gfxSlots+$9B
    ;9B (Keycards)
    db $67

org GetSpriteID_gfxSlots+$9E
    ;9E-9F (Keycards)
    db $65, $67

org GetSpriteID_gfxSlots+$A0
    ;90-91 (Keycards)
    db $65, $66

; Overwrite ALTTPR gfxSlots with SM items
org GetSpriteID_gfxSlots+$B0
	;Bx
	db $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F ; Super Metroid Items	
	;Cx
	db $60, $61, $62, $63, $64	; Super Metroid Items	
	;C5x
	db $70, $71, $72, $73 ; Super Metroid Boss Tokens	
	;C9x
	db $49
	;CAx .. 
	db $77, $77, $77, $77, $49, $49 ; Super Metroid - Map stations	
	
    ;Dx
	db $A6, $9D, $BD, $B3, $9E, $9F, $BC, $A0, $A1, $BE, $A2, $A3, $BA, $BB, $00, $A5 ; Z1 Items
    ;Ex
	db $B4, $B1, $94, $B2, $B6, $B7, $B9, $B5, $A5, $A4, $B8, $00, $B7, $A8, $A8, $BF ; Z1 Items
    ;Fx
	db $B0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; Z1 Items


org GetSpritePalette_gfxPalettes+$62
    ;62-65 (M1)
    db $08, $08, $08, $08

org GetSpritePalette_gfxPalettes+$68
    ;68-69 (M1)
    db $04, $08

org GetSpritePalette_gfxPalettes+$6C
    ;6C-6F (M1)
    db $04, $0A, $08, $08

org GetSpritePalette_gfxPalettes+$70
    ;70-71 (Keycards)
    db $04, $02

org GetSpritePalette_gfxPalettes+$7B
    ;7B (Keycards)
    db $04

org GetSpritePalette_gfxPalettes+$7E
    ;7E (Keycards)
    db $04

org GetSpritePalette_gfxPalettes+$80
    ;80-81 (Keycards)
    db $04, $02

org GetSpritePalette_gfxPalettes+$8B
    ;8B (Keycards)
    db $04

org GetSpritePalette_gfxPalettes+$8E
    ;8E-8F (Keycards)
    db $04, $04

org GetSpritePalette_gfxPalettes+$90
    ;90-91 (Keycards)
    db $04, $02

org GetSpritePalette_gfxPalettes+$9B
    ;9B (Keycards)
    db $04

org GetSpritePalette_gfxPalettes+$9E
    ;9E-9F (Keycards)
    db $04, $04

org GetSpritePalette_gfxPalettes+$A0
    ;90-91 (Keycards)
    db $04, $02

org GetSpritePalette_gfxPalettes+$B0

	; $B0
	db $02, $0A, $02, $04, $04, $08, $04, $04, $04, $02, $08, $02, $04, $04, $04, $08 ; Super Metroid	
	; $C0
	db $02, $02, $04, $08, $08	
	; $C5..
	db $08, $04, $04, $02	
	; $C8
	db $08	
	; $CA ..
	db $08, $08, $08, $08, $08, $08 ; Super Metroid - Map station item icons	
	
    ; $D0 - Z1 Items
	db $0A, $08, $0A, $08, $08, $08, $0A, $08, $08, $0A, $08, $08, $08, $04, $00, $0A
	; $E0
	db $0A, $08, $0A, $08, $08, $0A, $08, $08, $08, $08, $08, $00, $04, $08, $0A, $0A
	; $F0
	db $08, $00, $00, $00, $00, $00, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00


org AddReceivedItemExpanded_y_offsets+$62
    ;62-65 (M1)
    db -4, -4, -4, -4

org AddReceivedItemExpanded_y_offsets+$68
    ;68-69 (M1)
    db -4, -4

org AddReceivedItemExpanded_y_offsets+$6C
    ;6C-6F (M1)
    db -4, -4, -4, -4

org AddReceivedItemExpanded_y_offsets+$70
    ;70-71 (Keycards)
    db -4, -4

org AddReceivedItemExpanded_y_offsets+$7B
    ;7B (Keycards)
    db -4

org AddReceivedItemExpanded_y_offsets+$7E
    ;7E (Keycards)
    db -4

org AddReceivedItemExpanded_y_offsets+$80
    ;80-81 (Keycards)
    db -4, -4

org AddReceivedItemExpanded_y_offsets+$8B
    ;8B (Keycards)
    db -4

org AddReceivedItemExpanded_y_offsets+$8E
    ;8E-8F (Keycards)
    db -4, -4

org AddReceivedItemExpanded_y_offsets+$90
    ;90-91 (Keycards)
    db -4, -4

org AddReceivedItemExpanded_y_offsets+$9B
    ;9B (Keycards)
    db -4

org AddReceivedItemExpanded_y_offsets+$9E
    ;9E-9F (Keycards)
    db -4, -4

org AddReceivedItemExpanded_y_offsets+$A0
    ;90-91 (Keycards)
    db -4, -4

org AddReceivedItemExpanded_y_offsets+$B0
	db -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4 ; Unused
	db -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4 ; Unused
	db -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4 ; Unused
	db -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4 ; Unused
	db -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4 ; Unused

org AddReceivedItemExpanded_x_offsets+$62
    ;62-65 (M1)
    db 0, 0, 0, 0

org AddReceivedItemExpanded_x_offsets+$68
    ;68-69 (M1)
    db 0, 0

org AddReceivedItemExpanded_x_offsets+$6C
    ;6C-6F (M1)
    db 0, 0, 0, 0

org AddReceivedItemExpanded_x_offsets+$70
    ;70-71 (Keycards)
    db 0, 0

org AddReceivedItemExpanded_x_offsets+$7B
    ;7B (Keycards)
    db 0

org AddReceivedItemExpanded_x_offsets+$7E
    ;7E (Keycards)
    db 0

org AddReceivedItemExpanded_x_offsets+$80
    ;80-81 (Keycards)
    db 0, 0

org AddReceivedItemExpanded_x_offsets+$8B
    ;8B (Keycards)
    db 0

org AddReceivedItemExpanded_x_offsets+$8E
    ;8E-8F (Keycards)
    db 0, 0

org AddReceivedItemExpanded_x_offsets+$90
    ;90-91 (Keycards)
    db 0, 0

org AddReceivedItemExpanded_x_offsets+$9B
    ;9B (Keycards)
    db 0

org AddReceivedItemExpanded_x_offsets+$9E
    ;9E-9F (Keycards)
    db 0, 0

org AddReceivedItemExpanded_x_offsets+$A0
    ;90-91 (Keycards)
    db 0, 0


org AddReceivedItemExpanded_x_offsets+$B0
	db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; Unused
	db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; Unused
	db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; Unused
	db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; Unused
	db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; Unused

org AddReceivedItemExpanded_item_graphics_indices+$62
    ;62-65 (M1)
    db $99, $90, $9A, $92

org AddReceivedItemExpanded_item_graphics_indices+$68
    ;68-69 (M1)
    db $91, $93

org AddReceivedItemExpanded_item_graphics_indices+$6C
    ;6C-6F (M1)
    db $9C, $9B, $98, $95

org AddReceivedItemExpanded_item_graphics_indices+$70
    ;70-71 (Keycards)
    db $65, $66

org AddReceivedItemExpanded_item_graphics_indices+$7B
    ;7B (Keycards)
    db $67

org AddReceivedItemExpanded_item_graphics_indices+$7E
    ;7E (Keycards)
    db $67

org AddReceivedItemExpanded_item_graphics_indices+$80
    ;80-81 (Keycards)
    db $65, $66

org AddReceivedItemExpanded_item_graphics_indices+$8B
    ;8B (Keycards)
    db $67

org AddReceivedItemExpanded_item_graphics_indices+$8E
    ;8E-8F (Keycards)
    db $65, $67

org AddReceivedItemExpanded_item_graphics_indices+$90
    ;90-91 (Keycards)
    db $65, $66

org AddReceivedItemExpanded_item_graphics_indices+$9B
    ;9B (Keycards)
    db $67

org AddReceivedItemExpanded_item_graphics_indices+$9E
    ;9E-9F (Keycards)
    db $65, $67

org AddReceivedItemExpanded_item_graphics_indices+$A0
    ;90-91 (Keycards)
    db $65, $66

org AddReceivedItemExpanded_item_graphics_indices+$B0
	db $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F ; Super Metroid	
	; #$C0 - SM Items
	db $60, $61, $62, $63, $64	
	db $70, $71, $72, $73 ; Boss Tokens	
	db $49 ; Super Metroid - Unused
	db $77, $77, $77, $77 ; Super Metroid - Map Station Items
	db $49, $49 ; Super Metroid - Unused	

    ;Dx
	db $A6, $9D, $BD, $B3, $9E, $9F, $BC, $A0, $A1, $BE, $A2, $A3, $BA, $BB, $00, $A5 ; Z1 Items
    ;Ex
	db $B4, $B1, $94, $B2, $B6, $B7, $B9, $B5, $A5, $A4, $B8, $00, $B7, $A8, $A8, $BF ; Z1 Items
    ;Fx
	db $B0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; Z1 Items

org AddReceivedItemExpanded_wide_item_flag+$62
    ;62-65 (M1)
    db $02, $02, $02, $02

org AddReceivedItemExpanded_wide_item_flag+$68
    ;68-69 (M1)
    db $02, $02

org AddReceivedItemExpanded_wide_item_flag+$6C
    ;6C-6F (M1)
    db $02, $02, $02, $02

org AddReceivedItemExpanded_wide_item_flag+$70
    ;70-71 (Keycards)
    db $02, $02

org AddReceivedItemExpanded_wide_item_flag+$7B
    ;7B (Keycards)
    db $02

org AddReceivedItemExpanded_wide_item_flag+$7E
    ;7E (Keycards)
    db $02

org AddReceivedItemExpanded_wide_item_flag+$80
    ;80-81 (Keycards)
    db $02, $02

org AddReceivedItemExpanded_wide_item_flag+$8B
    ;8B (Keycards)
    db $02

org AddReceivedItemExpanded_wide_item_flag+$8E
    ;8E-8F (Keycards)
    db $02, $02

org AddReceivedItemExpanded_wide_item_flag+$90
    ;90-91 (Keycards)
    db $02, $02

org AddReceivedItemExpanded_wide_item_flag+$9B
    ;9B (Keycards)
    db $02

org AddReceivedItemExpanded_wide_item_flag+$9E
    ;9E-9F (Keycards)
    db $02, $02

org AddReceivedItemExpanded_wide_item_flag+$A0
    ;90-91 (Keycards)
    db $02, $02

org AddReceivedItemExpanded_wide_item_flag+$B0
	db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02 ; Unused
	db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02 ; Unused
	db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02 ; Unused
	db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02 ; Unused
	db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02 ; Unused

org AddReceivedItemExpanded_properties+$62
    ;62-65 (M1)
    db $04, $04, $04, $04

org AddReceivedItemExpanded_properties+$68
    ;68-69 (M1)
    db $02, $04

org AddReceivedItemExpanded_properties+$6C
    ;6C-6F (M1)
    db $02, $05, $04, $04

org AddReceivedItemExpanded_properties+$70
    ;70-71 (Keycards)
    db $02, $01

org AddReceivedItemExpanded_properties+$7B
    ;7B (Keycards)
    db $02

org AddReceivedItemExpanded_properties+$7E
    ;7E (Keycards)
    db $02

org AddReceivedItemExpanded_properties+$80
    ;80-81 (Keycards)
    db $02, $01

org AddReceivedItemExpanded_properties+$8B
    ;8B (Keycards)
    db $02

org AddReceivedItemExpanded_properties+$8E
    ;8E-8F (Keycards)
    db $02, $02

org AddReceivedItemExpanded_properties+$90
    ;90-91 (Keycards)
    db $02, $01

org AddReceivedItemExpanded_properties+$9B
    ;9B (Keycards)
    db $02

org AddReceivedItemExpanded_properties+$9E
    ;9E-9F (Keycards)
    db $02, $02

org AddReceivedItemExpanded_properties+$A0
    ;90-91 (Keycards)
    db $02, $01

org AddReceivedItemExpanded_properties+$B0
	; #$B0 - SM Items
	db  1, 5, 1, 2, 2, 4, 2, 2, 2, 1, 4, 1, 2, 2, 2, 4 ; SM Items #1	
	; #$C0 - SM Items Continued
	db  1, 1, 2, 4, 4	
	; #$C5 ... - SM Boss Reward tokens
	db  4, 2, 2, 1	
	db  4	
	; #$CA ...  - SM Map stations
	db  4, 4, 4, 4, 4, 4

    ; #$D0
	db  5, 4, 5, 4, 4, 4, 5, 4, 4, 5, 4, 4, 4, 1, 0, 5 ; Z1
	db  5, 4, 5, 4, 4, 5, 4, 4, 4, 4, 4, 0, 2, 4, 5, 5 ; Z1
	db  4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; Z1

org AddReceivedItemExpanded_item_target_addr+($62*2)
    ;62-65 (M1)
    dw $F36A, $F36A, $F36A, $F36A

org AddReceivedItemExpanded_item_target_addr+($68*2)
    ;68-69 (M1)
    dw $F36A, $F36A

org AddReceivedItemExpanded_item_target_addr+($6C*2)
    ;6C-6F (M1)
    dw $F36A, $F36A, $F36A, $F36A

org AddReceivedItemExpanded_item_target_addr+($70*2)
    ;70-71 (Keycards)
    dw $F36A, $F36A

org AddReceivedItemExpanded_item_target_addr+($7B*2)
    ;7B (Keycards)
    dw $F36A

org AddReceivedItemExpanded_item_target_addr+($7E*2)
    ;7E (Keycards)
    dw $F36A

org AddReceivedItemExpanded_item_target_addr+($80*2)
    ;80-81 (Keycards)
    dw $F36A

org AddReceivedItemExpanded_item_target_addr+($8B*2)
    ;8B (Keycards)
    dw $F36A

org AddReceivedItemExpanded_item_target_addr+($8E*2)
    ;8E-8F (Keycards)
    dw $F36A

org AddReceivedItemExpanded_item_target_addr+($90*2)
    ;90-91 (Keycards)
    dw $F36A

org AddReceivedItemExpanded_item_target_addr+($9B*2)
    ;9B (Keycards)
    dw $F36A

org AddReceivedItemExpanded_item_target_addr+($9E*2)
    ;9E-9F (Keycards)
    dw $F36A, $F36A

org AddReceivedItemExpanded_item_target_addr+($A0*2)
    ;90-91 (Keycards)
    dw $F36A, $F36A

org AddReceivedItemExpanded_item_target_addr+($B0*2)
	dw $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A ; Unused
	dw $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A ; Unused
	dw $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A ; Unused
	dw $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A ; Unused
	dw $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A ; Unused

org AddReceivedItemExpanded_item_values+$62
    ;62-65 (M1)
    db $FF, $FF, $FF, $FF

org AddReceivedItemExpanded_item_values+$68
    ;68-69 (M1)
    db $FF, $FF

org AddReceivedItemExpanded_item_values+$6C
    ;6C-6F (M1)
    db $FF, $FF, $FF, $FF

org AddReceivedItemExpanded_item_values+$70
    ;70-71 (Keycards)
    db $FF, $FF

org AddReceivedItemExpanded_item_values+$7B
    ;7B (Keycards)
    db $FF

org AddReceivedItemExpanded_item_values+$7E
    ;7E (Keycards)
    db $FF

org AddReceivedItemExpanded_item_values+$80
    ;80-81 (Keycards)
    db $FF, $FF

org AddReceivedItemExpanded_item_values+$8B
    ;8B (Keycards)
    db $FF

org AddReceivedItemExpanded_item_values+$8E
    ;8E-8F (Keycards)
    db $FF, $FF

org AddReceivedItemExpanded_item_values+$90
    ;90-91 (Keycards)
    db $FF, $FF

org AddReceivedItemExpanded_item_values+$9B
    ;9B (Keycards)
    db $FF

org AddReceivedItemExpanded_item_values+$9E
    ;9E-9F (Keycards)
    db $FF, $FF

org AddReceivedItemExpanded_item_values+$A0
    ;90-91 (Keycards)
    db $FF, $FF

org AddReceivedItemExpanded_item_values+$B0
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ; Unused
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ; Unused
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ; Unused
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ; Unused    
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ; Unused    


pullpc