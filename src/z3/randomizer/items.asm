;
; ALTTP Extended items
; This file contains the code and data to extend the regular ALTTPR itemset
; with new items for SM for example
;

GetAnimatedSpriteGfxFile_extended:
    CMP.b #$50 : BCC .end
    CMP.b #$70 : BCS +
        LDY.b #$F0 : BRA .end
    + 
        CMP.b #$90 : BCS .end
        LDY.b #$F1 : BRA .end

    .end
    RTL

GetAnimatedSpriteBufferPointer_extended:
    CPX.b #$A0 : BCC .end
	LDA.b $00 : CLC : ADC.l GetAnimatedSpriteBufferPointer_table_extended-$A0, X
.end
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
	db GFX_SM_Items>>16, GFX_SM_Items_2>>16, $00, $00, $00, $00, $00, $00
.high
	db GFX_SM_Items>>8, GFX_SM_Items_2>>8, $00, $00, $00, $00, $00, $00
.low
	db GFX_SM_Items, GFX_SM_Items_2, $00, $00, $00, $00, $00, $00

pushpc
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
	db $65, $66, $67, $65, $66, $67, $65, $66, $67, $65, $66, $67, $65, $67, $65, $67 ; Super Metroid Keycards

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
	; $D0
	db $04, $02, $04, $04, $02, $04, $04, $02, $04, $04, $02, $04, $04, $04, $04, $04 ; Super Metroid Keycards

org AddReceivedItemExpanded_y_offsets+$B0
	db -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4 ; Unused
	db -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4 ; Unused
	db -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4 ; Unused

org AddReceivedItemExpanded_x_offsets+$B0
	db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; Unused
	db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; Unused
	db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; Unused

org AddReceivedItemExpanded_item_graphics_indices+$B0
	db $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F ; Super Metroid	
	; #$C0 - SM Items
	db $60, $61, $62, $63, $64	
	db $70, $71, $72, $73 ; Boss Tokens	
	db $49 ; Super Metroid - Unused
	db $77, $77, $77, $77 ; Super Metroid - Map Station Items
	db $49, $49 ; Super Metroid - Unused	
	; #$D0 - SM Items (Keycards)
	db $65, $66, $67, $65, $66, $67, $65, $66, $67, $65, $66, $67, $65, $67, $65, $67 ; Super Metroid

org AddReceivedItemExpanded_wide_item_flag+$B0
	db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02 ; Unused
	db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02 ; Unused
	db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02 ; Unused
	db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02 ; Unused

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
	db  2, 1, 2, 2, 1, 2, 2, 1, 2, 2, 1, 2, 2, 2, 2, 2 ; Keycards    

org AddReceivedItemExpanded_item_target_addr+($B0*2)
	dw $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A ; Unused
	dw $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A ; Unused
	dw $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A ; Unused
	dw $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A, $F36A ; Unused

org AddReceivedItemExpanded_item_values+$B0
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ; Unused
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ; Unused
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ; Unused
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ; Unused    
pullpc