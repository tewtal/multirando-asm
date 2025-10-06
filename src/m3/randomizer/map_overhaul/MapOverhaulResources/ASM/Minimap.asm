
;---------------------------------------------------------------------------------------------------
;|x|                                    BANK $90        Minimap                                  |x|
;---------------------------------------------------------------------------------------------------
{
ORG $90A7E8
	INC $05F7 : STZ !SamusMapPositionMirror	;disable minimap ;zero samus minimap mirror position
	LDA.w #!BossfightMinimapCovertile		;tile used to cover minimap during bossfights

;Mark boss room as explored offsets
ORG $90A840 : DW CrocomireMarkMaptileOffset	;pointer to offsets for Crocomire
ORG $90A844 : DW PhantoonMarkMaptileOffset	;pointer to offsets for Phantoon
ORG $90A848
	DW $A852							;Draygon shares pointer with Kraid, as there room size are similar
	DW $0001, PhantoonMarkMaptileOffset	;replace Mother Brain's explore table slot with fake Ridley

ORG $90A864
PhantoonMarkMaptileOffset:
	DW $0000, $0000, $FFFF
CrocomireMarkMaptileOffset:	;this covers from the spike wall all the way to the freestanding item
	DW $0200, $0000, $0300, $0000, $0400, $0000, $0500, $0000, $0600, $0000, $0700, $0000, $FFFF
;6 bytes left


;Change tiles in active map when entering a boss room ;update minimap
ORG $90A8C2 : TAX
ORG $90A8DF
;Set tiles explored for boss rooms
	TAY : JSR UpdateActiveMapWithExplored : REP #$30
	PLY : PLX : PLP : RTS


MinimapASM:
	PHP : STZ $12 : STZ $16 : SEP #$20
	LDA $05F7 : BNE .return				;minimap disabled
	LDA $0AF7 : CMP $07A9 : BCS +++
	LDA $0AFB : CMP $07AB : BCS +++		;is samus still in room
	LDA $0AF7 : CLC : ADC $07A1 : STA $12	;samus X map coord
	LDA $0AFB : CLC : ADC $07A3 : INC		;samus Y map coord
	STA $16 : CMP.w !SamusMapPositionMirror+1 : BNE ++
	LDA $12 : CMP.w !SamusMapPositionMirror : BEQ +++		;check if samus map coord has changed
	STA.w !SamusMapPositionMirror : BRA +					;save mirror and update minimap
++ : STA.w !SamusMapPositionMirror+1 : + : JSR UpdateMinimapTileset
+++ : LDA $7EC681 : AND #$E3 : TAX								;filter out palette from samus minimap position
	LDA $05B5 : BIT.b #$01<<!SamusMinimapPositionTimer : BNE +	;check global time for palette change
	AND.b #$01<<!SamusMinimapPositionTimer-1 : BNE .return		;check if palette has to be reverted back to origin
	TXA : ORA !MinimapIndicatorPalette : BRA ++		;set palette back to origin
+ : TXA : ORA.b #!SamusMinimapPositionPalette<<2	;set palette to position indicator palette
++ : STA $7EC681 : .return : PLP : RTL				;save palette ;return

UpdateMinimapTileset:
	PHP : REP #$30
	LDA $12 : AND #$0020 : STA $22	;$22 = map page
	LDA $12 : AND #$001F : STA $12 : AND #$0007 : TAX			;[X] bit index for explored bit
	LDA $12 : LSR #3 : STA $14
	LDA $16 : CLC : ADC $22 : ASL : ASL : CLC : ADC $14 : TAY	;[Y] index for explored bit
	JSR UpdateActiveMapWithExplored : REP #$30

	LDA $16 : CLC : ADC $22 : XBA : LSR #3 : CLC : ADC $12 : STA $14	;$14 = maptile index
	LDA $22 : BEQ + : LDA $12 : CMP #$0002 : BPL +	;is samus in right mappage and X = 0/1
	LDA $14 : SEC : SBC #$0402 : BRA ++		;adjust index to topleft corner of minimap and left mappage
+ : LDA $14 : SEC : SBC #$0022				;adjust index to topleft corner of minimap
++ : ASL : TAY

	LDA #$007E : STA $02 : STA $05 : STA $08	;set pointer of active RAM map for each row in minimap
	LDA.w #!RAM_ActiveMap : STA $00
	LDA.w #!RAM_ActiveMap+$40 : STA $03
	LDA.w #!RAM_ActiveMap+$80 : STA $06
	LDA #$0005 : STA $12 : STZ $14

;Row 0
- : LDA [$00],y : CMP.w #!EmptyTile : BNE +						;check if current tile is empty tile
	ORA.w #!MinimapPaletteEmptyTile<<10|$2000 : BRA ++			;set palette and priority bit
+ : AND #$1C00 : LSR : XBA : TAX								;gather palette from maptile and create index of palette for minimap
	LDA [$00],y : AND #$E3FF : ORA.w MinimapTilePaletteTable,x	;set minimap palette
++ : LDX $14 : STA $7EC63C,x
;Row 1
	LDA [$03],y : CMP.w #!EmptyTile : BNE +
	ORA.w #!MinimapPaletteEmptyTile<<10|$2000 : BRA ++
+ : AND #$1C00 : LSR : XBA : TAX
	LDA [$03],y : AND #$E3FF : ORA.w MinimapTilePaletteTable,x
++ : LDX $14 : STA $7EC67C,x
;Row 2
	LDA [$06],y : CMP.w #!EmptyTile : BNE +
	ORA.w #!MinimapPaletteEmptyTile<<10|$2000 : BRA ++
+ : AND #$1C00 : LSR : XBA : TAX
	LDA [$06],y : AND #$E3FF : ORA.w MinimapTilePaletteTable,x
++ : LDX $14 : STA $7EC6BC,x

	INC $14 : INC $14 : INY #2
	TYA : BIT #$003F : BNE +	;check for map wrap
	CLC : ADC #$07C0 : TAY		;set offset to right page
+ : DEC $12 : BNE - : BRA ApplyTileGFXtoRAM	;setting minimap tiles done?
WARNPC $90AA7C


ORG $90AA8A
ApplyTileGFXtoRAM:
	PHB
	STZ $12 : LDA $12 : LDY.w #!RAM_Minimap_GFX		;prepare loop ;[Y] maptile GFX transfer target

- : TAX : LDA $7EC63C,x : PHA : AND #$00FF : STA $14				;$14 = maptile index
	PLA : AND #$FC00 : ORA.l HUD_MapTileOffset,x : STA $7EC63C,x	;save HUD tile with palette and mirror
	LDA $14 : ASL #4 : ADC.w #!Freespace_MinimapTiles : TAX		;set source for transfer
	LDA #$000F : MVN.w (!Freespace_MinimapTiles>>8&$FF00)+$7E	;transfer maptile GFX to RAM
	LDA $12 : BIT #$0008 : BNE + : INC : INC : STA $12 : BRA -	;finish row check
+ : CLC : ADC #$0038 : STA $12 : CMP #$0090 : BMI -				;set index to next row

	INC !Update_Minimap_VRAM_Flag				;set bit for transfer to VRAM
	PLB : PLP 
	LDA $7EC681 : AND #$1C : STA !MinimapIndicatorPalette	;set origin palette for samus position indicator
	RTS

;[Y] = explored bit index of samus current position
;[X] = explored bit offset of samus current position
UpdateActiveMapWithExplored:
	SEP #$20 : LDA $07F7,y : BIT $AC04,x : BEQ + : RTS	;check if explored bit already set
+ : ORA $AC04,x : STA $07F7,y	;save bit
	STX $20 : STY $1E : REP #$30
	JSL LoadSourceMapData		;[$00] = long pointer to current area map data
	JSR UpdateMaptileInActiveMap

	SEP #$30 : PHA : AND #$07 : TAX : PLA : LSR #3 : TAY
	LDA.w SetAdjacentMaptileFlag,y : BIT $AC04,x : BNE + : RTS	;check if maptile ID flag set
;Adjust offset
+ : CLC : TXA : BIT #$04 : BEQ + : EOR #$04 : TAX : SEC
+ : TYA : ROL : TAY : LDA.w UpdateAdjacentMaptileDirection,y
- : DEX : BMI + : ASL #2 : BRA -

+ : LDX $20 : LDY $1E : ASL : BCS ++	;horizontal direction?
	ASL : BCS +		;down set?
	TYA : SEC : SBC #$04 : TAY : BRA +++		;offset one tile up
+ : TYA : CLC : ADC #$04 : TAY : BRA +++		;offset one tile down

++ : ASL : BCS +	;right set?
	DEX : BPL ++ : DEY : LDX #$07 : BRA ++		;offset one tile left
+ : INX : CPX #$08 : BMI ++ : INY : LDX #$00	;offset one tile right
++ : STX $20

+++ : LDA $07F7,y : ORA $AC04,x : STA $07F7,y : REP #$30	;set explored bit of adjacent maptile
UpdateMaptileInActiveMap:
	TYA : ASL #3 : CLC : ADC $20 : ASL : TAX : TAY	;get maptile offset of active map
	LDA [$00],y : STA !RAM_ActiveMap,x				;save origin tile to active map
	RTS
;$D bytes left
WARNPC $90AB80
;After that are the tables by adjacent maptiles


ORG $90AC0C
MinimapTilePaletteTable:
	DW !MinimapPalette0<<10|$2000, !MinimapPalette1<<10|$2000, !MinimapPalette2<<10|$2000, !MinimapPalette3<<10|$2000
	DW !MinimapPalette4<<10|$2000, !MinimapPalette5<<10|$2000, !MinimapPalette6<<10|$2000, !MinimapPalette7<<10|$2000


ORG $90E734 : JSL MinimapASM
ORG $90E801 : JSL MinimapASM
ORG $90E873 : JSL MinimapASM
ORG $90E8E5 : JSL MinimapASM
ORG $90E8F8 : JSL MinimapASM
}
