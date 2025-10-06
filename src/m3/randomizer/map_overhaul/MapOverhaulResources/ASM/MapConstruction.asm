
;---------------------------------------------------------------------------------------------------
;|x|                                    BANK $??        Map Construction                         |x|
;---------------------------------------------------------------------------------------------------
{

!AlwaysActive = ""
!MapStationActive = "LDA $0789 : BNE + : LDA #$0300 : STA $2E"	;check if mapstation is active in current area

ORG !Freespace_MapConstruction
LoadMapFromPause:
	PHP : REP #$30 : STZ $2E
	!MapDecorationAppearence		;config: draw map deco depending on mapstation setting
+ : LDA #$4000 : JSR MainMapConstruction		;construct map in this RAM location
	INC !Update_Minimap_VRAM_Flag	;set bit for transfer to VRAM
	PLP : RTL


ConstructMapFromMapStation:
	INC $0789				;set mapstation loaded bit
	BRA ConstructMapFromGameStart
ConstructMapFromAreaTransition:
	JSL $80858C : BRA ConstructMap		;transfer explored bits of next area
ConstructMapFromGameStart:
	STZ $0727 : STZ $0753	;set pause screen index and pause label index to "map"
	STZ $0763				;set pause screen mode to "map" (found by "Tundain)
ConstructMap:
	LDA $1F5B : STA !OriginAreaIndex
	LDA #$0300 : STA $2E
	LDA.w #!RAM_ActiveMap : JSR MainMapConstruction : RTL


;[A] = address in bank $7E (RAM)
MainMapConstruction:
	PHB : STA $04					;save address
	LDA #$007E : STA $06 : STA $0E	;set bank of target address to 7E

	LDA.w #!EmptyTile : STA [$04]	;set defining tile as empty maptile
	LDX $04 : TXY : INY : INY		;set source and target
	LDA #$0FFD : MVN $7E7E			;clear up entire map with empty maptiles
	PHK : PLB

	JSR MapDecoration
	JSL LoadSourceMapData			;[$00] = long pointer to current area map data
;map station loaded maptiles pointer
	LDA $1F5B : ASL A : TAX : LDA #$0082 : STA $0A
	LDA $829717,x : STA $08
;prepare first 16 bits of loaded tiles
	LDA [$08] : XBA : STA $26 : INC $08 : INC $08
;prepare first 16 bits of explored tiles
	LDA $1F5B : CMP !OriginAreaIndex : BEQ +	;check if in current area
	XBA : CLC : ADC #$CD52 : BRA ++				;use different explored area bit array
+ : LDA #$07F7 : ++ : STA $0C					;else use current area explored bit array
	LDA [$0C] : XBA : STA $28 : INC $0C : INC $0C
	LDY #$0000

.tile : LDA [$00],y : ASL $28 : BCC +	;is tile explored?
	ASL $26 : BRA .save		;yes! go to save directly
+ : ASL $26 : BCC .skip		;no! Skip if tile is not loaded
	LDX $0789 : BEQ .skip	;skip if map station is not activated in this area
;If tile loaded and map station active: load tile with different tile and palette
++ : PHY : SEP #$30
	TAX : LDA.l CoverTileList,x					;load cover tile
	XBA : TAY : AND #$1C : LSR : LSR : TAX		;unexplored palette index
	TYA : AND #$E3 : ORA.w UnexploredPalette,x	;set palette
	XBA : REP #$30 : PLY
.save : STA [$04],y							;save tile
.skip : INY : INY : CPY #$1000 : BPL ++		;branch if all tiles asigned
	TYA : BIT #$001F : BNE .tile
	LDA [$08] : XBA : STA $26 : INC $08 : INC $08	;load next 16 bits of loaded tiles
	LDA [$0C] : XBA : STA $28 : INC $0C : INC $0C	;load next 16 bits of explored tiles
	BRA .tile : ++

;check for any itembits who change tiles in this region
	LDY #$0000								;set [Y] to 0
-- : TYX : LDA $7ED870,x : BEQ .empty		;check if 16 bits of itembits are 0
	STA $14 : LDX #$0000

.loop : LSR $14 : BCS +	;if shifted a item bit out
	BEQ .empty			;if no item bits left
- : INX : BRA .loop		;set counter to next item bit

;bit has been found
+ : STX $10 : TYA : ASL #3 : CLC : ADC $10	;offset of itembit checklist from itembits
	JSR ChangeTileWithItembit
	LDX $10 : BRA -

.empty : INY : INY : CPY.w #!ItemIDCheckLimit>>3 : BCC --	;loop
	STZ !SamusMapPositionMirror											;zero minimap mirror upon map construction
	STZ !PauseScreenX_PositionMirror : STZ !PauseScreenY_PositionMirror	;zero pause screen position mirror
	PLB : RTS


;change palette of unexplored tile
print "UnexploredPalette", pc
UnexploredPalette:
	DB !UnexploredTilePalette0<<2, !UnexploredTilePalette1<<2, !UnexploredTilePalette2<<2, !UnexploredTilePalette3<<2
	DB !UnexploredTilePalette4<<2, !UnexploredTilePalette3<<2, !UnexploredTilePalette5<<2, !UnexploredTilePalette7<<2


; [A] = Itembit
; $04 = Map (destination)
; $20 = Item tilecheck bitmask
; $22 = Maptile from map
ChangeTileWithItembit:
	ASL : TAX : LDA.l ItemTileCheckList,x	;load from list
	STA $20 : BEQ +++						;if entry is empty
	AND #$3800 : LSR #3 : XBA : CMP $1F5B : BNE +++		;check if in current area
	TYX : LDA $20 : AND #$07FF : ASL : TAY : LDA [$04],y : STA $22	;load tile from position of tilecheck
	LDA $20 : ASL : BCS +						;MSB set: <tile> +, else <tile> -
	DEC $22 : ASL : BCC ++ : DEC $22 : BRA ++	;if next bit is set: additional <tile> -
+ : INC $22 : ASL : BCC ++ : INC $22			;if next bit is set: additional <tile> +
++ : LDA $22 : STA [$04],y : TXY
+++ : RTS


ChangeTileFromPLM:		;used in bank $84
	STA $7ED870,x		;save itembit
	LDA.w #!RAM_ActiveMap : STA $04		;save destination of loaded map to DirectPage
	LDA #$007E : STA $06
	LDA $04,s : TAX : LDA $1DC7,x		;gather item index
	JSR ChangeTileWithItembit
	STZ !SamusMapPositionMirror : RTL	;zero minimap mirror upon item collection


; $04 = Map (destination)
MapDecoration:
	PHB : PEA.w !Freespace_MapDecoration>>8 : PLB : PLB		;set bank to decoration data
	LDA $1F5B : ASL : TAX : LDA.w MapDecoration_AreaPointer,x : TAX : BRA +	;pointer to decoration data of current area

--- : LDX $12 : INX #4					;next deco tilegroup
+ : STX $12 : LDA $0000,x : BPL +++		;if not a pointer (terminator) -> return
	STA $14 : SEP #$20					;$14 = pointer of current deco tilegroup
	LDA $0003,x : XBA : LDA $0002,x : ASL #3 : REP #$20 : LSR #2 : TAY	;tilegroup offset from X and Y coords
	LDA $0002,x : BIT #$0020 : BEQ +				;check if deco tilegroup X position is >= $20 (right map page)
	TYA : ORA #$0800 : TAY : + : LDX $14			;adjust offset to right page
-- : STY $16										;$16 = starting offset of starting/next row
	LDA $0000,x : AND #$00FF : BIT #$00C0 : BNE ---	;set tile amount of row, terminator is >= $40 (over max map size)
	STA $14 : INX									;$14 = tile amount
;Draw row of deco tilegroup
- : DEC $14 : BMI .nextrow							;branch if row done
	LDA $0000,x : BEQ + : BIT $2E : BNE + : STA [$04],y		;save tile, skip if $0000
+ : INX #2 : INY #2 : TYA : BIT #$003F : BNE -		;check if reaching map page border
	CLC : ADC #$07C0 : CMP #$1000 : BPL .failsave	;adjust to map page border, goto failsave if offset over map size
	TAY : BRA -
.nextrow : LDA $16 : CLC : ADC #$0040 : CMP #$1000 : BPL --- : TAY : BRA --	;adjust offset to next row, skip current deco tilegroup if over map size
.failsave : INX #2 : DEC $14 : BNE .failsave : BRA .nextrow					;skip current row tile drawing and proceed to next row
+++ : PLB : RTS


;Code from $829517 (top and bottom code are the same as original, but the big middle part is nearly, if not identical as $82943D)
;Used as map loading after hex map
LoadMapFromGameMenuBeforeStart:
;set background data
	SEP #$30
	LDX $1F5B : LDA.l VerticalAreaMapBit : AND $82B7C9,x : BEQ +	;check for vertical bit of current area
	LDA #$52 : STA $58		;change tilemap BG1 to vertical
+ : LDA #$33 : STA $5D
	LDA #$13 : STA $69
	REP #$30
	LDA $1F5B : STA !OriginAreaIndex
	LDA #$0300 : STA $2E
	LDA #$4000 : JSR MainMapConstruction
;transfer to VRAM
	LDX $0330
	LDA #$1000 : STA $D0,x								;size
	LDA #$4000 : STA $D2,x : LDA #$007E : STA $D4,x		;source
	LDA $58 : AND #$00FC : XBA : STA $D5,x				;destination
	TXA : CLC : ADC #$0007 : STA $0330
	RTL

;---------------------------------------------------------------------------------------------------

; $00 = door sprite entry counter
; $03 = palette for sprites
; $06 = door sprite data pointer
; $09 = sprite limit counter
ConstructDoorSpriteMain:
;check for any doorbits who add sprites on the map
	LDA.w #!DoorSpritePalette<<9 : STA $03		 	;door sprite palette
	LDA.w #!DoorSpriteLimit : STA $09
	LDA $1F5B : ASL : TAX : LDA.w DoorSpriteAreaCount,x : DEC : BMI ++ : STA $00
	LDA.w DoorSpriteAreaList,x : STA $06 : TAX
-- : LDA.l !Freespace_DoorbitSpritelock&$FF0000,x : AND #$01FF : JSL $80818E	;get door bit index of current entry
	LDA $7ED8B0,x : AND $05E7 : BNE +		;check if door bit is not set
	LDX $06 : LDA.l (!Freespace_DoorbitSpritelock&$FF0000)+$01,x : LSR
	JSR AddSpriteWithDoorbit : BCS ++		;spawn door icon, return if sprite cap hit
+ : LDX $06 : INX #3 : STX $06				;increase entry index
	DEC $00 : BPL --						;loop to next entry
++ : LDA $05D1 : RTL						;return


; $12 = page bit for X position
; $14 = page bit for Y position
; $20 = door tilecheck bitmask
AddSpriteWithDoorbit:
	STA $20 : AND #$0007 : TAX				;bit offset
	LDA $20 : AND #$07F8 : LSR #3 : TAY		;offset of explored bit table
	ASL : AND #$0100 : STA $12 : STZ $14	;page bit

	LDA $1F5B : CMP !OriginAreaIndex : BNE + : LDA $07F7,y : BRA ++		;load explored bit of current area if in current area
+ : PHX : XBA : CLC : ADC #$CD52 : STY $0C : ADC $0C : TAX				;load explored bit of different area
	LDA $7E0000,x : PLX

++ : SEP #$20 : BIT $B88A,x : BEQ +++		;check if explored bit is set
	LDX $1F5B : LDA.l VerticalAreaMapBit : BIT $B7C9,x : REP #$20 : BEQ +	;check if vertical area is set
	LDA $12 : STA $14 : STZ $12				;change page bit for Y position
+ : LDA $20 : AND #$001F : ASL #3 : ORA $12 : SEC : SBC $B1 : TAX			;set X position for door sprite
	LDA $20 : AND #$03E0 : LSR #2 : ORA $14 : SEC : SBC $B3					;set Y position for door sprite
	BIT #$FF00 : BNE +++ : TAY				;check if out of range

	LDA $20 : XBA : LSR #3 : AND #$000F : CLC : ADC #$0068	;calculate door sprite index
	JSL $81891F : DEC $09 : BPL +++ : SEC : RTS				;decrease sprite counter, return if 0
+++ : REP #$20 : CLC : RTS

;---------------------------------------------------------------------------------------------------

; $00 = main page map tilemap offset
; $03 = sub page map tilemap offset
; $06/08 = X/Y offset for DMA transfer
; $08/0A/0C/0E = BG1 update tilemap pointer
; $12 = new screen X position
; $14 = new screen Y position
; $16 = BG1 tilemap rearrangement flag
ContinueScrolling:
;Followup of "MapScrollMain"
	PHB : PEA $7E7E : PLB : PLB
	STZ $05FB							;zero available directions
	LDA #$007E : STA $02 : STA $05		;indirect indexed bank setup
	LDA.w !PauseScreenX_PositionMirror : STA $12
	LDA.w !PauseScreenY_PositionMirror : STA $14
	LDA $58 : AND #$0001 : STA $16

	LDA $B1 : LSR #3 : BIT #$1000 : BEQ + : ORA #$F000 : + : CMP $12 : BEQ +++	;check if X screen position change
	BMI + : INC !PauseScreenX_PositionMirror : INC $12 : BRA ++					;adjust X screen mirror
+ : DEC !PauseScreenX_PositionMirror : DEC $12 : ++ : JSR HorizontalUpdate : PLB : RTL

+++ : LDA $B3 : LSR #3 : BIT #$1000 : BEQ + : ORA #$F000 : + : CMP $14 : BEQ +++	;check if X screen position change
	BMI + : INC !PauseScreenY_PositionMirror : INC $14 : BRA ++					;adjust X screen mirror
+ : DEC !PauseScreenY_PositionMirror : DEC $14 : ++ : JSR VerticalUpdate

+++ : PLB : RTL


HorizontalUpdate:
	STZ $06 : STZ $08					;DMA transfer offset
	LDA #$0040 : STA $0956 : STA $0958	;DMA transfer size
;Adjust DMA size and offset if screen Y axis is screen wrapping
	LDA $14 : BPL ++ : ASL : AND #$003E : STA $0956 : BRA +++
++ : LDA $16 : BEQ + : LDA $14 : BRA ++
+ : LDA $14 : CMP #$0020 : BMI +++
	SEC : SBC #$0020
++ : ASL : AND #$003E : STA $06 : EOR #$003E : STA $0956
	LDA $06 : INC #2 : ASL #5 : STA $06
;Screen position left outside setup
+++ : LDA $12 : BPL ++ : AND #$001F : DEC : BPL + : RTS
+ : STA $095A : STA $095C : ASL : ORA #$4000 : STA $03 : ORA #$0800 : ORA $06 : STA $00
	LDA $14 : BMI + : LDA $16 : BNE +			;swap values to "wrapped" addresses, if Y screen axis is negative and map is vertical
	JSR HorizontalTilemapOffsetSwap
+ : LSR $06 : LDA #$4C00 : ORA $06 : TSB $095A	;DMA transfer location + offset
	LSR $08 : LDA #$4800 : ORA $08 : TSB $095C
	LDA #$C8C8 : STA $08 : LDA #$C9D0 : STA $0A	;map tilemap location setup for transfer
	LDA #$C908 : STA $0C : LDA #$CA10 : STA $0E
	JMP .tilemap
;Screen position right outside setup
++ : LDA $16 : BNE + : LDA $12 : BRA ++	;check if map is horizontal
+ : LDA $12 : CMP #$0020 : BPL + : RTS
+ : SEC : SBC #$0020
++ : CMP #$001F : BMI + : RTS
+ : STA $095A : STA $095C : INC : ASL : ORA #$4800 : STA $03 : AND #$F7FF : ORA $06 : STA $00
	LDA $14 : BPL + : LDA $16 : BNE +			;swap values to "wrapped" addresses, if Y screen axis is positive and map is vertical
	JSR HorizontalTilemapOffsetSwap
+ : LSR $06 : LDA #$4800 : ORA $06 : TSB $095A	;DMA transfer location + offset
	LSR $08 : LDA #$4C00 : ORA $08 : TSB $095C
	LDA #$C8C8 : STA $0C : LDA #$C9D0 : STA $0E	;map tilemap location setup for transfer
	LDA #$C908 : STA $08 : LDA #$CA10 : STA $0A
;Setup source tilemap
.tilemap : LDX #$001F : LDY #$0000
- : LDA [$00] : STA ($08),y : LDA [$03] : STA ($0A),y
	LDA.w #!EmptyTile : STA ($0C),y : STA ($0E),y
	LDA $00 : CLC : ADC #$0040 : STA $00
	LDA $03 : CLC : ADC #$0040 : STA $03
	INY #2 : DEX : BPL -

	INC $0962	;set horizontal DMA transfer flag
++ : LDA $16 : BEQ + : STZ $0958 : RTS		;disable DMA transfer for "wrapped" tilemap if map is horizontal
+ : LDA #$C9D0 : STA $095E : LDA #$CA10 : STA $0960 : RTS		;DMA source pointers for "wrapped" tilemap in vertical map


HorizontalTilemapOffsetSwap:
	LDA $0956 : PHA : LDA $0958 : STA $0956 : PLA : STA $0958 : BRA TilemapOffsetSwapBranch	;swap DMA transfer size between "wrapped" and "unwrapped"
VerticalTilemapOffsetSwap:
	LDA $0964 : PHA : LDA $0966 : STA $0964 : PLA : STA $0966
TilemapOffsetSwapBranch:
	LDA $06 : STA $08 : STZ $06 : TSB $03 : TRB $00 : RTS				;swap DMA source offset


VerticalUpdate:
	STZ $06 : STZ $08					;DMA transfer offset
	LDA #$0040 : STA $0964 : STA $0966	;DMA transfer size
;Adjust DMA size and offset if screen X axis is screen wrapping
	LDA $12 : BPL ++ : ASL : AND #$003E : STA $0964 : BRA +++
++ : LDA $16 : BNE + : LDA $12 : BRA ++
+ : LDA $12 : CMP #$0020 : BMI +++
	SEC : SBC #$0020
++ : INC : ASL : STA $06 : EOR #$003E : INC #2 : STA $0964
;Screen position top outside setup
+++ : LDA $14 : BPL ++ : AND #$001F : DEC : BPL + : RTS
+ : XBA : LSR #3 : STA $0968 : STA $096A : ASL : ORA #$4000 : STA $03 : ORA #$0800 : ORA $06 : STA $00
	LDA $12 : BMI + : LDA $16 : BEQ +			;swap values to "wrapped" addresses, if X screen axis is negative and map is horizontal
	JSR VerticalTilemapOffsetSwap
+ : LSR $06 : LDA #$4C00 : ORA $06 : TSB $0968	;DMA transfer location + offset
	LSR $08 : LDA #$4800 : ORA $08 : TSB $096A
	LDA #$C948 : STA $08 : LDA #$CA50 : STA $0A	;map tilemap location setup for transfer
	LDA #$C98C : STA $0C : LDA #$CA94 : STA $0E
	JMP .tilemap
;Screen position bottom outside setup
++ : LDA $16 : BEQ + : LDA $14 : BRA ++
+ : LDA $14 : CMP #$0020 : BPL + : RTS
+ : SEC : SBC #$0020
++ : ASL #5 : CMP #$0400 : BMI + : RTS
+ : STA $0968 : STA $096A : CLC : ADC #$0020 : ASL : ORA #$4800 : STA $03 : AND #$F7FF : ORA $06 : STA $00
	LDA $12 : BPL + : LDA $16 : BEQ +			;swap values to "wrapped" addresses, if X screen axis is positive and map is horizontal
	JSR VerticalTilemapOffsetSwap
+ : LSR $06 : LDA #$4800 : ORA $06 : TSB $0968	;DMA transfer location + offset
	LSR $08 : LDA #$4C00 : ORA $08 : TSB $096A
	LDA #$C948 : STA $0C : LDA #$CA50 : STA $0E	;map tilemap location setup for transfer
	LDA #$C98C : STA $08 : LDA #$CA94 : STA $0A
;Setup source tilemap
.tilemap : LDX #$001F : LDY #$0000
- : LDA [$00] : STA ($08),y : LDA [$03] : STA ($0A),y
	LDA.w #!EmptyTile : STA ($0C),y : STA ($0E),y
	INC $00 : INC $00
	INC $03 : INC $03
	INY #2 : DEX : BPL -

	INC $0970	;set vertical DMA transfer flag
++ : LDA $16 : BNE + : STZ $0966 : RTS		;disable DMA transfer for "wrapped" tilemap if map is vertical
+ : LDA #$CA50 : STA $096C : LDA #$CA94 : STA $096E : RTS		;DMA source pointers for "wrapped" tilemap in horizontal map


SetBG1AddressDuringPausing:
	PHP : LDA $0763 : BEQ MapTransitionBG1Branch : PLP			;check if entering map screen during pause transition
EquipmentTransitionBG1Address:
	PHP : LDA #$54 : STA $58 : PLP : RTL	;set BG1 address to equipment screen
SetBG1ScreenPositionDuringTransition:
	PHP
	LDA $BD : STA $B1		;adapt map screen position
	LDA $BF : STA $B3
	SEP #$30 : BRA MapTransitionBG1Branch
MapTransitionBG1Address:
	PHP
MapTransitionBG1Branch:
	LDA #$49 : STA $58		;change BG1 address to horizontal/vertical mirroring depending on vertical map bits
	LDX $1F5B : LDA.l VerticalAreaMapBit : AND $82B7C9,x : BEQ +
	INC $58 : + : LDA $58 : PLP : RTL
}
