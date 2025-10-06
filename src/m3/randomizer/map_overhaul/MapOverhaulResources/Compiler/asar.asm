
;---------------------------------------------------------------------------------------------------
;|x|                                    ASAR                                                     |x|
;---------------------------------------------------------------------------------------------------
{
ORG $8292B0
PauseRoutineIndex:
	DW $9120, $9142, $9156, $91AB, $9231, $9186, $91D7, $9200	;same as $9110
IF !SelectSwitchArea_HexMapMethode
	DW HexMapMenuHijack
ELSE
	DW $9156, MapSwitchConstruct, $9200		;fade out / map construction / fade in
ENDIF


CheckForSelectPress:
	JSR $A5B7							;check for START press
	LDA $0998 : CMP #$000F : BNE +		;check if still in game state "paused"
	LDA $8F : BIT #$2000 : BEQ +		;check for SELECT press
	JSR NextAvailableAreaFinder : BCC +	;check if next area is valid to be loaded
IF !SelectSwitchArea_HexMapMethode == 0
	LDA #$0037 : JSL $809049			;play sound "move cursor"
ENDIF
	LDA #$0001 : STA $0723 : STA $0725	;set fading flag
	STZ $0751					;zero shoulder button pressed highlight
	LDA #$0016 : STA $0729		;set sprite timer
	LDA #$0008 : STA $0727		;set pause index to 8: show next area - fading out
+ : RTS


DrawSelectButtonSprite:
	LDA $0727 : CMP #$0008 : BNE +		;check if currently in "switch map area - fading out"
	LDA $0729 : BEQ +					;draw sprite timer zero?
	DEC $0729 : STZ $03
	LDY #$00D0 : LDX #$0070 : LDA #$000C : JSL $81891F	;draw sprite; [A] = sprite index; [X] = sprite X position; [Y] = sprite Y position
+ : JSL $82BB30 : RTS					;draw map elevator destination

IF !SelectSwitchArea_HexMapMethode
HexMapMenuHijack:
	JSL HexMapMenuMain : RTS
ENDIF

WARNPC $829324



ORG $829446
LoadSourceMapData:
	PHB : PHK : PLB
	LDA $1F5B : ASL : CLC : ADC $1F5B : TAX
IF !DynamicMapDataPointer
	SKIP $3 : STA $00 : SKIP $3 : STA $02
ELSE
	LDA.w !MapDataTablePointer,x : STA $00 : LDA.w !MapDataTablePointer+2,x : STA $02
ENDIF
	PLB : RTL


;--------------------------------------- SELECT SWITCH TO HEX MAP ----------------------------------
IF !SelectSwitchArea_HexMapMethode
{
;0753 : HexMenu Index

ORG !Freespace_HexMapSelectSwitch
HexMapMenuMain:
	PHB
	LDX $0753 : LDA.l HexMapTableBank,x : PHA : PLB : PLB
	IF !DynamicHexMapData
		LDA.l $81AB2A : STA $06		;pointer to label position table
		LDA.l $81AB57 : STA $08		;pointer to transition table
		LDA.l $81AB20 : STA $0A		;pointer to transition timer table
	ENDIF
	TXA : ASL : TAX : LDA.l HexMapSelectSwitchTable,x : STA $12
	LDA #!Freespace_HexMapSelectSwitch>>$10 : STA $14 : JML [$0012]


HexMapSelectSwitchTable:
	DW HexMapSetup, HexMapLoadTileMap, HexMapPrepareZoomOut, HexMapZoomOut
	DW HexMapSelectArea, HexMapPrepareZoomIn, HexMapZoomIn
	DW PostHexMap_MapConstruction

HexMapTableBank:
	DB $00		;pading
	DB $80, $81, $7E, $7E
	DB $81, $7E, $7E
	DB $82


HexMapSetup:	;pull bank $80
	LDA #$003C : JSL $809049		;play sound (file select map -> hexagon map) in library 1 (max queue: 6)
;Load HexMap foreground graphics
	LDX $0330 : LDA #$08E0 : STA $D0,x					;size
	LDA #$B400 : STA $D2,x : LDA #$008E : STA $D4,x		;source
	LDA #$1A00 : STA $D5,x								;destination (VRAM location)
	TXA : CLC : ADC #$0007 : TAX
;Load HexMap background graphics
	LDA #$00E0 : STA $D0,x
	LDA #$DAD0 : STA $D2,x : LDA #$008E : STA $D4,x
	LDA #$4268 : STA $D5,x
	TXA : CLC : ADC #$0007 : TAX
;Load HexMap background
	LDA #$0700 : STA $D0,x
	LDA $1F5B : XBA : ASL #3 : CLC
	IF !DynamicHexMapData
		ADC $81A599 : ADC #$0100
	ELSE
		ADC #$C01A
	ENDIF
	STA $D2,x : LDA #$0081 : STA $D4,x
	LDA #$5880 : STA $D5,x
	TXA : CLC : ADC #$0007 : STA $0330


	LDA.l $8EE43A : STA $7EC03A	;change palette 7 in BG3 to dark grey (HexMap background palette)
	LDA #$0000 : STA $7EC006	;change palette 0 in BG3 to black (HexMap background empty tile palette)
	STZ $B1 : STZ $B3			;zero BG1 screen position

	SEP #$20
	LDA #$5A : STA $5B		;BG3 tilemap address
	LDA #$02 : STA $69		;main screen layer
;Change HDMA channel 7 for zooming transition
	LDA #$01 : STA $4370
	LDA #$26 : STA $4371
	LDA #$00 : STA $4372 : STA $18E2
	LDA #$40 : STA $4373 : STA $18E3
	LDA #$7E : STA $4374 : STA $4377
	REP #$20

	INC $0753 : PLB : RTL



HexMapLoadTileMap:	;pull bank $81
;Load HexMap tilemap
	LDX $0330 : LDA #$0800 : STA $D0,x
	IF !DynamicHexMapData
		LDA $81A551 : STA $D2,x : LDA #$0081 : STA $D4,x
	ELSE
		LDA #$B71A : STA $D2,x : LDA #$0081 : STA $D4,x
	ENDIF
	LDA #$5400 : STA $D5,x
	TXA : CLC : ADC #$0007 : STA $0330

;Adjust HexMap palette depending on selected area
	LDX.w #!AccessableAreaNumber-1
--- : PHX : CPX $1F5B : BEQ +		;check index is current area
	JSR HexMapGrayedAreaPalette : BRA ++
+ : JSR HexMapColoredAreaPalette
++ : PLX : DEX : BPL ---

	INC $0753 : PLB : RTL


HexMapGrayedAreaPalette:
	TXA : ASL : TAX : LDA.w PlanetZebesGPIOGrayed,x : TAY : BRA +	;load instruction of "grayed out" area
HexMapColoredAreaPalette:
	TXA : ASL : TAX : LDA.w PlanetZebesGPIOColored,x : TAY

+ : -- : LDA.w PlanetZebesGPI,y : CMP #$FFFF : BNE + : RTS			;check if terminator
+ : PHY : PHA : LDA.w PlanetZebesGPI+2,y : TAX : PLY				;get X index of palette index
	LDA #$0004 : STA $12											;repeat counter
- : LDA $A40E,y : STA $7EC000,x : INX #2 : INY #2 : DEC $12 : BNE -	;set palette
	PLY : INY #4 : BRA --



HexMapPrepareZoomOut:	;pull bank $7E
	IF !DynamicHexMapData
		LDA $1F5B : ASL : CLC : ADC $0A : TAX : LDA.l $810000,x
		SEC : SBC #$000C : STA $4050	;zoom transition timer
		LDA $1F5B : ASL #4 : CLC : ADC $08 : TAX
	;Square transition speed
		LDA.l $810000,x : STA $4040 : LDA.l $810002,x : STA $4042	;left (subspeed, speed)
		LDA.l $810004,x : STA $4044 : LDA.l $810006,x : STA $4046	;right
		LDA.l $810008,x : STA $4048 : LDA.l $81000A,x : STA $404A	;top
		LDA.l $81000C,x : STA $404C : LDA.l $81000E,x : STA $404E	;bottom
	ELSE
		LDA $1F5B : ASL : TAX : LDA.l $81AA94,x
		SEC : SBC #$000C : STA $4050	;zoom transition timer
		TXA : ASL #3 : TAX
	;Square transition speed
		LDA.l $81AA34,x : STA $4040 : LDA.l $81AA36,x : STA $4042	;left (subspeed, speed)
		LDA.l $81AA38,x : STA $4044 : LDA.l $81AA3A,x : STA $4046	;right
		LDA.l $81AA3C,x : STA $4048 : LDA.l $81AA3E,x : STA $404A	;top
		LDA.l $81AA40,x : STA $404C : LDA.l $81AA42,x : STA $404E	;bottom
	ENDIF
;Square transition starting position
	LDA #$0008 : STA $4032	;left
	LDA #$00F8 : STA $4036	;right
	LDA #$0008 : STA $403A	;top
	LDA #$00D8 : STA $403E	;bottom
	STZ $4030 : STZ $4034 : STZ $4038 : STZ $403C	;zero subposition

	JSR HexMapSquareTransitionSetup
	JSR HexMapLoadSpriteLabelsExternal

	SEP #$20
	LDA #$54 : STA $58		;BG1 tilemap address
	LDA #$5A : STA $5B		;BG3 tilemap address
;Setup window 1: BG1, BG3, sprites and colour math set to inclusive and BG2 set to exclusive
	LDA #$32 : STA $60		;BG1, BG2 window 1 setup
	LDA #$02 : STA $61		;BG3 window 1 setup
	LDA #$22 : STA $62		;sprite, colour math window 1 setup

	LDA #$13 : STA $69 : STA $6C	;(window) main screen layer
	LDA #$04 : STA $6B : STA $6D	;(window) sub screen layer
	LDA #$02 : STA $6E				;color math setup: sublayer on
	LDA #$25 : STA $71				;enable color math on layer 1,3 and backdrop

	LDA #$80 : STA $85				;enable HDMA channel 7
	REP #$20

	STZ $B3 : STZ $B1
	INC $0753 : PLB : RTL


HexMapSquareTransitionSetup:
	PHP : SEP #$20
	LDX #$0000 : LDA $403A : LDY #$00FF			;prepare top side of transition
	JSR HexMapSquareTransitionAddEntry
	LDA $403E : SEC : SBC $403A : BNE + : LDA #$01	;check transition square height
+ : PHA : LDA $4036 : XBA : LDA $4032 : TAY : PLA	;set window position for left and right side
	JSR HexMapSquareTransitionAddEntry
	LDA #$01 : STA $4000,x : DEC : STA $4003,x	;set bottom side of transition
	REP #$20 : LDA #$00FF : STA $4001,x
	PLP : RTS

HexMapSquareTransitionAddEntry:
	PHP
	BIT #$80 : BNE + : STA $4000,x	;if height greater than $80
	REP #$20 : TYA : STA $4001,x	;set window 1 position
	INX #3 : PLP : RTS
+ : SEC : SBC #$7F : STA $4000,x : LDA #$7F : STA $4003,x	;make 2 entries for bigger transition height
	REP #$20 : TYA : STA $4001,x : STA $4004,x
	TXA : CLC : ADC #$0006 : TAX : PLP : RTS

HexMapLoadSpriteLabelsExternal:
	PHB : PEA $8100 : PLB : PLB : BRA +
HexMapLoadSpriteLabels:
	PHB
+ : LDA.l !ExploredAreaBits : AND #$00FF : STA $1A : STZ $1C	;prepare explored area bits and index
--- : LSR $1A : BCC ++											;check if area explored
	LDX #$0200 : LDA $1C : CMP $1F5B : BNE + : LDX #$0000		;set palette based on selected area
+ : STX $03 : ASL #2
	IF !DynamicHexMapData
		CLC : ADC $06 : TAX : LDA $0002,x : TAY : LDA $0000,x : TAX
	ELSE
		TAX : LDA $AA1E,x : TAY : LDA $AA1C,x : TAX				;set sprite position of area label
	ENDIF
	LDA $1C : CLC : ADC.l $82C749 : INC : JSL $81891F			;sprite index
++ : INC $1C : LDA $1C : CMP.w #!AccessableAreaNumber : BMI ---
	PLB : RTS



HexMapZoomOut:	;pull bank $7E
	REP #$30
	LDA $4030 : SEC : SBC $4040 : STA $4030 : LDA $4032 : SBC $4042 : STA $4032
	LDA $4034 : SEC : SBC $4044 : STA $4034 : LDA $4036 : SBC $4046 : STA $4036
	LDA $4038 : SEC : SBC $4048 : STA $4038 : LDA $403A : SBC $404A : STA $403A
	LDA $403C : SEC : SBC $404C : STA $403C : LDA $403E : SBC $404E : STA $403E
	JSR HexMapSquareTransitionSetup
	JSR HexMapLoadSpriteLabelsExternal
	DEC $4050 : BPL + : INC $0753
	SEP #$20
	LDA #$11 : STA $69		;main screen layer
	STZ $6C : STZ $6D		;disable window layer
	REP #$20
+ : PLB : RTL



; $00 = new area selected
; $03 = palette for sprites
; $12 = X position of current area label
; $14 = Y position of current area label
; $16 = minimal distance to new area label
; $1A = explored area bits
; $1C = area index
; $1E = compare distance

HexMapSelectArea:	;pull bank $81
	LDA $8F : BIT #$A080 : BEQ +	;confirm press (A; B; Select)
	INC $0753 : BRA ++

;Prepare values for movement check
+ : LDA #$FFFF : STA $16 : STA $00
	LDA.l !ExploredAreaBits : AND #$00FF : XBA : STA $1A
	LDA #$0007 : STA $1C
	LDA $1F5B : ASL #2
	IF !DynamicHexMapData
		CLC : ADC $06 : TAX
		LDA $0000,x : STA $12
		LDA $0002,x : STA $14
	ELSE
		TAX
		LDA $AA1C,x : STA $12
		LDA $AA1E,x : STA $14
	ENDIF
;Newly pressed direction key
	LDA $90 : AND #$000F : ASL : TAX : JSR (HexMapControllerInputTable,x)
;Check if new area selected
	LDA $00 : BMI ++ : TAX : JSR HexMapColoredAreaPalette	;pull bank has to be $81
	LDX $1F5B : JSR HexMapGrayedAreaPalette					;pull bank has to be $81
	LDA #$0036 : JSL $80903F		;play sound (scrolling map) in library 1 (max queue: 6)
;Load new HexMap background
	LDX $0330 : LDA #$0700 : STA $D0,x
	LDA $00 : STA $1F5B : XBA : ASL #3 : CLC
	IF !DynamicHexMapData
		ADC $81A599 : ADC #$0100
	ELSE
		ADC #$C01A
	ENDIF
	STA $D2,x : LDA #$0081 : STA $D4,x
	LDA #$5880 : STA $D5,x
	TXA : CLC : ADC #$0007 : STA $0330

++ : JSR HexMapLoadSpriteLabels : PLB : RTL


HexMapControllerInputTable:
	DW HexMapNoMove, HexMapMoveRight, HexMapMoveLeft, HexMapNoMove
	DW HexMapMoveDown, HexMapNoMove, HexMapNoMove, HexMapNoMove
	DW HexMapMoveUp, HexMapNoMove, HexMapNoMove, HexMapNoMove
	DW HexMapNoMove, HexMapNoMove, HexMapNoMove, HexMapNoMove

HexMapMoveUp:
	INC $16				;invert minimal distance
--- : ASL $1A : BCC +++						;check if area is explored
	LDA $1C : CMP $1F5B : BEQ +++ : ASL #2	;cancel if in current area
	IF !DynamicHexMapData
		CLC : ADC $06 : TAX
		LDA $0002,x : SEC : SBC $14 : BPL +++ : STA $1E
		LDA $0000,x : SEC : SBC $12 : BMI + : EOR #$FFFF : INC
	ELSE
		TAX
		LDA $AA1E,x : SEC : SBC $14 : BPL +++ : STA $1E			;cancel if vertical distance is negative (checked area is below current)
		LDA $AA1C,x : SEC : SBC $12 : BMI + : EOR #$FFFF : INC	;check if horizontal distance is smaller than vertical
	ENDIF
+ : CMP $1E : BMI +++ : CLC : ADC $1E : CMP $16 : BCC +++	;also if sum of both distance values are smaller than minimal distance
	STA $16 : LDA $1C : STA $00						;save next area
+++ : DEC $1C : BPL --- : RTS

HexMapMoveDown:
--- : ASL $1A : BCC +++
	LDA $1C : CMP $1F5B : BEQ +++ : ASL #2
	IF !DynamicHexMapData
		CLC : ADC $06 : TAX
		LDA $0002,x : SEC : SBC $14 : BMI +++ : STA $1E
		LDA $0000,x : SEC : SBC $12 : BPL + : EOR #$FFFF : INC
	ELSE
		TAX
		LDA $AA1E,x : SEC : SBC $14 : BMI +++ : STA $1E			;cancel if vertical distance is positive (checked area is above)
		LDA $AA1C,x : SEC : SBC $12 : BPL + : EOR #$FFFF : INC
	ENDIF
+ : CMP $1E : BPL +++ : CLC : ADC $1E : CMP $16 : BCS +++
	STA $16 : LDA $1C : STA $00
+++ : DEC $1C : BPL --- : RTS


HexMapMoveLeft:
	INC $16
--- : ASL $1A : BCC +++
	LDA $1C : CMP $071F5B9F : BEQ +++ : ASL #2
	IF !DynamicHexMapData
		CLC : ADC $06 : TAX
		LDA $0000,x : SEC : SBC $12 : BPL +++ : STA $1E
		LDA $0002,x : SEC : SBC $14 : BMI + : EOR #$FFFF : INC
	ELSE
		TAX
		LDA $AA1C,x : SEC : SBC $12 : BPL +++ : STA $1E			;cancel if horizontal distance is negative (checked area is right)
		LDA $AA1E,x : SEC : SBC $14 : BMI + : EOR #$FFFF : INC
	ENDIF
+ : CMP $1E : BMI +++ : CLC : ADC $1E : CMP $16 : BCC +++
	STA $16 : LDA $1C : STA $00
+++ : DEC $1C : BPL --- : RTS

HexMapMoveRight:
--- : ASL $1A : BCC +++
	LDA $1C : CMP $1F5B : BEQ +++ : ASL #2
	IF !DynamicHexMapData
		CLC : ADC $06 : TAX
		LDA $0000,x : SEC : SBC $12 : BMI +++ : STA $1E
		LDA $0002,x : SEC : SBC $14 : BPL + : EOR #$FFFF : INC
	ELSE
		TAX
		LDA $AA1C,x : SEC : SBC $12 : BMI +++ : STA $1E			;cancel if horizontal distance is positive (checked area is left)
		LDA $AA1E,x : SEC : SBC $14 : BPL + : EOR #$FFFF : INC
	ENDIF
+ : CMP $1E : BPL +++ : CLC : ADC $1E : CMP $16 : BCS +++
	STA $16 : LDA $1C : STA $00
+++ : DEC $1C : BPL --- : RTS

HexMapNoMove:
	RTS



HexMapPrepareZoomIn:	;pull bank $7E
	IF !DynamicHexMapData
		LDA $1F5B : ASL : CLC : ADC $0A : TAX : LDA.l $810000,x : STA $4050	;zoom transition timer
	;Square transition starting position
		LDA $1F5B : ASL #2 : CLC : ADC $06 : TAX
		LDA.l $810000,x : STA $4032 : STA $4036	;left/right
		LDA.l $810002,x : STA $403A : STA $403E	;top/bottom
		STZ $4030 : STZ $4034 : STZ $4038 : STZ $403C	;zero subposition
	;Square transition speed
		LDA $1F5B : ASL #4 : CLC : ADC $08 : TAX
		LDA.l $810000,x : STA $4040 : LDA.l $810002,x : STA $4042	;left (subspeed, speed)
		LDA.l $810004,x : STA $4044 : LDA.l $810006,x : STA $4046	;right
		LDA.l $810008,x : STA $4048 : LDA.l $81000A,x : STA $404A	;top
		LDA.l $81000C,x : STA $404C : LDA.l $81000E,x : STA $404E	;bottom
	ELSE
		LDA $1F5B : ASL : TAX : LDA.l $81AA94,x : STA $4050
	;Square transition starting position
		TXA : ASL : TAX
		LDA.l $81AA1C,x : STA $4032 : STA $4036	;left/right
		LDA.l $81AA1E,x : STA $403A : STA $403E	;top/bottom
		STZ $4030 : STZ $4034 : STZ $4038 : STZ $403C	;zero subposition
	;Square transition speed
		TXA : ASL #2 : TAX
		LDA.l $81AA34,x : STA $4040 : LDA.l $81AA36,x : STA $4042	;left (subspeed, speed)
		LDA.l $81AA38,x : STA $4044 : LDA.l $81AA3A,x : STA $4046	;right
		LDA.l $81AA3C,x : STA $4048 : LDA.l $81AA3E,x : STA $404A	;top
		LDA.l $81AA40,x : STA $404C : LDA.l $81AA42,x : STA $404E	;bottom
	ENDIF

	JSR HexMapSquareTransitionSetup
	JSR HexMapLoadSpriteLabelsExternal

;Load new area label
	LDX $0330 : LDA #$0018 : STA $D0,x
	IF !DynamicHexMapData
		PHX : LDA $1F5B : ASL : CLC : ADC.l $829429 : TAX : LDA.l $820000,x : PLX
	ELSE
		PHX : LDA $1F5B : ASL : TAX : LDA.l $82965F,x : PLX
	ENDIF
	STA $D2,x : LDA #$0082 : STA $D4,x
	LDA #$50AA : STA $D5,x
	TXA : CLC : ADC #$0007 : STA $0330

	SEP #$20
	LDA #$54 : STA $58				;BG1 tilemap address
	LDA #$13 : STA $69 : STA $6C	;(window) main screen layer
	LDA #$04 : STA $6B : STA $6D	;(window) sub screen layer
	REP #$20

	LDA #$003B : JSL $809049		;play sound (hexagon map -> file select map) in library 1 (max queue: 6)
	INC $0753 : PLB : RTL



HexMapZoomIn:	;pull bank $7E
	REP #$30
	LDA $4030 : CLC : ADC $4040 : STA $4030 : LDA $4032 : ADC $4042 : CMP #$0001 : BPL + : LDA #$0001 : + : STA $4032
	LDA $4034 : CLC : ADC $4044 : STA $4034 : LDA $4036 : ADC $4046 : CMP #$0100 : BMI + : LDA #$00FF : + : STA $4036
	LDA $4038 : CLC : ADC $4048 : STA $4038 : LDA $403A : ADC $404A : CMP #$0001 : BPL + : LDA #$0001 : + : STA $403A
	LDA $403C : CLC : ADC $404C : STA $403C : LDA $403E : ADC $404E : CMP #$00E0 : BMI + : LDA #$00E0 : + : STA $403E
	JSR HexMapSquareTransitionSetup
	JSR HexMapLoadSpriteLabelsExternal
	DEC $4050 : BMI + : PLB : RTL
+ : INC $0753

;Revert HexMap foreground graphics
	LDX $0330 : LDA #$08E0 : STA $D0,x
	LDA #$B400 : STA $D2,x : LDA #$00B6 : STA $D4,x
	LDA #$1A00 : STA $D5,x
	TXA : CLC : ADC #$0007 : TAX
;Revert HexMap background graphics
	LDA #$00E0 : STA $D0,x
	LDA #$B6D0 : STA $D2,x : LDA #$009A : STA $D4,x
	LDA #$4268 : STA $D5,x
	TXA : CLC : ADC #$0007 : TAX
;Clean HexMap background tilemap in BG3
	LDA #$0700 : STA $D0,x
	LDA #$5800 : STA $D2,x : LDA #$007E : STA $D4,x
	LDA #$5880 : STA $D5,x
	TXA : CLC : ADC #$0007 : STA $0330

	LDA #$184E : STA $5800
	LDX #$5800 : TXY : INY #2 : LDA #$06FD : MVN $7E7E

;Revert palette 5-7 back to pause screen variant
	LDX #$005E
- : LDA.l !PauseScreen_Palette_Pointer+$A0,x : STA $C0A0,x : DEX #2 : BPL -
	LDA.l !PauseScreen_Palette_Pointer+$3A : STA $C006		;change back palette 0 in BG3
	LDA.l !PauseScreen_Palette_Pointer+$3A : STA $C03A		;change back palette 7 in BG3

	SEP #$20
	LDA #$02 : STA $69			;main screen layer
	STZ $6C : STZ $6D : STZ $6E	;disable window layer; color math setup: no sublayer
	STZ $71				;disable color math
	STZ $85				;disable HDMA channel 7
	JSL MapTransitionBG1Address
	REP #$20

	JSL $88D865		;reload HDMA channel 7 object (related to HUD)
	PLB : RTL



PostHexMap_MapConstruction:	;pull bank $82
	STZ $0727 : STZ $0753	;set pause screen index and pause label index to "map"
	LDX #$005E
	LDX $1F5B : LDA $7ED908,x : AND #$00FF : STA $0789	;set flag of map station for next area
	JSL LoadMapFromPause
;transfer to VRAM
	LDX $0330
	LDA #$1000 : STA $D0,x								;size
	LDA #$4000 : STA $D2,x : LDA #$007E : STA $D4,x		;source
	LDA $58 : AND #$00FC : XBA : STA $D5,x				;destination
	TXA : CLC : ADC #$0007 : STA $0330
	JSL $829028		;set map scroll boundaries and screen starting position

	SEP #$20
	LDA #$13 : STA $69
	REP #$20

	STZ $073F : LDA $C10C : STA $072B		;set L/R highlight animation data
	PLB : RTL
}
ENDIF
}
