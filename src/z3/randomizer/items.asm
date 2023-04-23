;
; ALTTP Extended items
; This file contains the code and data to extend the regular ALTTPR itemset
; with new items for SM for example
;
; This most likely needs to be a smarter implementation
; at some point with fully dynamic items to support all the M1 and Z1 items as well
; as multiworld support
;
; But let's leave it at this for now since we'll start with SMZ3 support
;
;

AddReceivedItemExpandedGetItem_extended:
    phx
    phy
    php
    %ai16()
    pha
    lda $02d8
    and #$00ff
    cmp #$00b0
    bcs +
    jmp .no_item
+
    sec
    sbc #$00b0
    asl : asl : asl
    tax

    lda.l alttp_sm_item_table+2,x     ; Load item type
    beq .equipment
    cmp #$0001
    beq .tank
    cmp #$0002
    beq .empty_tank
    cmp #$0003
    beq .spazplaz
    cmp #$0004
    beq .ammo
    cmp #$0005 : bne + : brl .keycard : +
    jmp .no_item

.equipment
    lda.l alttp_sm_item_table,x       ; Load SRAM offset
    tay
    lda.l alttp_sm_item_table+4,x     ; Load value
    pha
    tyx
    ora.l !SRAM_SM_ITEM_BUF,x
    sta.l !SRAM_SM_ITEM_BUF,x
    pla
    ora.l !SRAM_SM_ITEM_BUF+$2,x
    sta.l !SRAM_SM_ITEM_BUF+$2,x    
    bra .end

.spazplaz
    lda.l alttp_sm_item_table,x       ; Load SRAM offset
    tay
    lda.l alttp_sm_item_table+4,x     ; Load value
    tyx
    ora.l !SRAM_SM_ITEM_BUF+$2,x
    sta.l !SRAM_SM_ITEM_BUF+$2,x    
    bra .end

.tank
    lda.l alttp_sm_item_table,x       ; Load SRAM offset
    tay
    lda.l alttp_sm_item_table+4,X     ; Load value
    tyx
    clc
    adc.l !SRAM_SM_ITEM_BUF+$2,x
    sta.l !SRAM_SM_ITEM_BUF+$2,x
    lda.l !SRAM_SM_ITEM_BUF+$2,x
    sta.l !SRAM_SM_ITEM_BUF,x             ; Refill Samus health fully when grabbing an e-tank 
    bra .end

.empty_tank
    lda.l alttp_sm_item_table,x       ; Load SRAM offset
    tay
    lda.l alttp_sm_item_table+4,X     ; Load value
    tyx
    clc
    adc.l !SRAM_SM_ITEM_BUF,x
    sta.l !SRAM_SM_ITEM_BUF,x
    bra .end
.ammo
    lda.l alttp_sm_item_table,x       ; Load SRAM offset
    tay
    lda.l alttp_sm_item_table+4,X     ; Load value
    pha
    tyx
    clc
    adc.l !SRAM_SM_ITEM_BUF,x
    sta.l !SRAM_SM_ITEM_BUF,x
    pla
    clc
    adc.l !SRAM_SM_ITEM_BUF+$2,x
    sta.l !SRAM_SM_ITEM_BUF+$2,x
    bra .end
.keycard
     lda.l alttp_sm_item_table,x       ; Load SRAM offset
    tay
    lda.l alttp_sm_item_table+4,x      ; Load value
    tyx
    ora.l !SRAM_SM_ITEM_BUF,x
    sta.l !SRAM_SM_ITEM_BUF,x
    bra .end   
.end
    %ai16()
    ; jsl sm_fix_checksum        ; Correct SM's savefile checksum
    ; No need to fix checksum here since items don't save to the real SRAM anymore

.no_item
    pla
    plp
    ply
    plx
    rtl

alttp_sm_item_table:
    ;  offset type   value  extra
    dw $0000, $0000, $4000, $0000      ; Grapple
    dw $0000, $0000, $8000, $0000      ; X-Ray
    dw $0000, $0000, $0001, $0000      ; Varia Suit
    dw $0000, $0000, $0002, $0000      ; Springball
    dw $0000, $0000, $0004, $0000      ; Morphball
    dw $0000, $0000, $0008, $0000      ; Screw attack
    dw $0000, $0000, $0020, $0000      ; Gravity suit
    dw $0000, $0000, $0100, $0000      ; Hi-Jump
    dw $0000, $0000, $0200, $0000      ; Space Jump
    dw $0000, $0000, $1000, $0000      ; Bomb
    dw $0000, $0000, $2000, $0000      ; Speed booster
    
    dw $0004, $0000, $1000, $0000      ; Charge beam
    dw $0004, $0000, $0002, $0000      ; Ice beam
    dw $0004, $0000, $0001, $0000      ; Wave beam
    dw $0004, $0003, $0004, $0000      ; Spazer
    dw $0004, $0003, $0008, $0000      ; Plasma

;  $c0
    dw $0020, $0001,   100, $0000      ; E-Tank
    dw $0032, $0002,   100, $0000      ; Reserve-tank

    dw $0024, $0004,     5, $0000      ; Missiles
    dw $0028, $0004,     5, $0000      ; Super Missiles
    dw $002c, $0004,     5, $0000      ; Power Bombs

;  $c5
    dw $0072, $0005, $0001, $0000      ; Kraid Boss Token
    dw $0072, $0005, $0002, $0000      ; Phantoon Boss Token
    dw $0072, $0005, $0004, $0000      ; Draygon Boss Token
    dw $0072, $0005, $0008, $0000      ; Ridley Boss Token
    dw $0000, $ffff, $0000, $0000      ; c9
    dw $0074, $0005, $0001, $0000      ; Brinstar Map
    dw $0074, $0005, $0002, $0000      ; Wrecked Ship Map
    dw $0074, $0005, $0004, $0000      ; Maridia Map
    dw $0074, $0005, $0008, $0000      ; Lower Norfair Map
    dw $0000, $ffff, $0000, $0000      ; ce
    dw $0000, $ffff, $0000, $0000      ; cf

; $d0
    dw $0070, $0005, $0001, $0000      ; keycard 0
    dw $0070, $0005, $0002, $0000      ; keycard 1
    dw $0070, $0005, $0004, $0000      ; keycard 2
    dw $0070, $0005, $0008, $0000      ; keycard 3
    dw $0070, $0005, $0010, $0000      ; keycard 4
    dw $0070, $0005, $0020, $0000      ; keycard 5
    dw $0070, $0005, $0040, $0000      ; keycard 6
    dw $0070, $0005, $0080, $0000      ; keycard 7
    dw $0070, $0005, $0100, $0000      ; keycard 8
    dw $0070, $0005, $0200, $0000      ; keycard 9
    dw $0070, $0005, $0400, $0000      ; keycard a 
    dw $0070, $0005, $0800, $0000      ; keycard b
    dw $0070, $0005, $1000, $0000      ; keycard c 
    dw $0070, $0005, $2000, $0000      ; keycard d
    dw $0070, $0005, $4000, $0000      ; keycard e 
    dw $0070, $0005, $8000, $0000      ; keycard f

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