
;---------------------------------------------------------------------------------------------------
;|x|                                    BANK $82        Pause Screen Routines                    |x|
;---------------------------------------------------------------------------------------------------
{
;---------------------------------------------------------------------------------------------------
;|x|                                    GENERAL                                                  |x|
;---------------------------------------------------------------------------------------------------
{
{;-------------------------------------- HIJACKS ---------------------------------------------------

;ORG $828067 : JSL ConstructMapFromGameStart	;on game start up

;Routine during pause transition, originally used $7EDF5C for storage of BG 2 tilemap, now $7E6000 gets used instead
;$7E6000 - $7E6FFF gets used for x-ray, door transitions and non-gameplay routines so it should be safe.
ORG $828D6A : LDA #$00			;low byte of: transfer tilemap of BG 2 to RAM
ORG $828D6F : LDA #$60			;high byte of: transfer tilemap of BG 2 to RAM
ORG $828DB1 : DL $7E6000		;source of: transfer tilemap of BG 2 from RAM back to VRAM

ORG $828EB1 : DW $3C00			;increase size for equipment screen tiles
ORG $828ED1 : DW $1000			;half size of HUD graphic tiles loading
ORG $828EE2 : LDA #$50			;change position for map border
ORG $828EF3 : DL !PauseScreen_Map_Tilemap_Pointer
ORG $828F13 : DL !PauseScreen_Map_Tilemap_Pointer+$400
ORG $828F33 : DL !PauseScreen_Equipment_Tilemap_Pointer
ORG $828F3F : LDY #$D741		;new pointer to samus wireframe tilemap
ORG $828FF8 : LDA.l !PauseScreen_Palette_Pointer,x
ORG $82902B : JSR SetMapScrollBoundaries

ORG $8291DD : JSL SetBG1ScreenPositionDuringTransition
ORG $8293D8 : LDA #$48			;change position for tilemap "map"
ORG $8293E2 : JSR LoadMapHijack
ORG $8293FB : LDA #$50			;change position for area name text
ORG $829400 : JSL MapTransitionBG1Address : NOP

ORG $82A0B6 : JSL SetBG1AddressDuringPausing
ORG $82A0BD : LDA #$50			;change background address of BG 2 (border)

;Change pause screen button palette from 5 to 3 (this looks better tbh), reason: to midigate discoloring when using hex map transition
ORG $82A6B2 : ORA #$0C00		;change SAMUS button
ORG $82A6D0 : ORA #$0C00		;change SAMUS button
ORG $82A72D : ORA #$0C00		;change MAP button
ORG $82A74B : ORA #$0C00		;change MAP button
ORG $82A769 : ORA #$0C00		;change SAMUS button
ORG $82A787 : ORA #$0C00		;change SAMUS button
ORG $82A820 : ORA #$0C00		;change MAP button
ORG $82A83E : ORA #$0C00		;change MAP button

ORG $82AC2D : LDA #$54			;change background address of equipment screen
ORG $82AC48 : JSL EquipmentTransitionBG1Address

;Adjust VRAM transfer of equipment screen
ORG $82B1E9 : LDA #$0800		;transfer size
ORG $82B1F0 : LDA #$3800		;decompressed equipment tilemap RAM location
ORG $82B200 : LDA #$5400		;VRAM position

ORG $82B6D7 : JSL CheckIconInMapArea		;samus's gunship (pausescreen map)
ORG $82B747 : JSL CheckIconInMapArea		;samus icon
ORG $82B74E : JSL CheckIconInMapArea		;samus position indicator
ORG $82B792 : JSL CheckIconInMapArea		;samus's gunship

ORG $82B849 : JSL CheckIconInMapArea		;map icons (energy/missile/map/save station)
ORG $82B8DC : JSL CheckIconInMapArea		;boss icon
ORG $82B8FE : JSL CheckIconInMapArea		;boss dead icon (cross out)
;Map screen border offset
ORG $82B942 : SBC.w #!Left_MapFrameOffset+!Left_MapBorderOffset<<3
ORG $82B954 : ADC.w #(!Right_MapFrameOffset+!Right_MapBorderOffset<<3)-1
ORG $82B96A : SBC.w #!Top_MapFrameOffset+!Top_MapBorderOffset<<3
ORG $82B97C : SBC.w #($20-!Bottom_MapFrameOffset-!Bottom_MapBorderOffset<<3)+1

ORG $82B9F7 : JSL CheckIconInMapArea		;samus position indicator
ORG $82BB67 : JSL CheckIconInMapArea		;elevator destination
ORG $82DFC2 : JSL ConstructMapFromAreaTransition
ORG $82E488 : BRA $08 : NOP #8	;skip operation "overwrite BG3 tiles" in special graphics bit rooms
ORG $82E643 : JSL ForceUpdateHUDMapInKraid		;part of background routine, triggered during kraid room transition
ORG $82EA6B : JSL ForceUpdateHUDMapInKraid		;part of background routine, triggered when unpausing in kraid's room
}

{;--------------------------------------- VARIOUS OPTIONS ------------------------------------------
ORG $82943D
LoadMapHijack: JSL LoadMapFromPause : RTS

;$829442
VerticalAreaMapBit: DB !VerticalAreaMapBits
}
}
;---------------------------------------------------------------------------------------------------
;|x|                                    MAP SCREEN BOUNDARIES                                    |x|
;---------------------------------------------------------------------------------------------------
{
ORG $82945E
;---------------------------------------- SET MAP SCREEN BOUNDARY ----------------------------------
;Uses different methode to define boundaries: checks for non-empty tiles after map construction
;instead of using explored/loaded map bits.
SetMapScrollBoundaries:
	PHP
	LDA #$007E : STA $02 : STA $05	;bank pointer in direct page (7E: RAM)
	LDA #$4000 : STA $00			;$00 = left map page pointer
	LDA #$4800 : STA $03			;$03 = right map page pointer
;Check if vertical area map bit is set for current area
	SEP #$30 : LDY #$00 : LDX $1F5B : LDA.l VerticalAreaMapBit
	AND $82B7C9,x : REP #$30
	BNE VerticalMapBoundary	;$82B7C9 = selective bit index
	JMP HorizontalMapBoundary

VerticalMapBoundary:
;	REP #$30
;Top border
	;LDY #$0000
- : JSR MainPageBorderCheck : BNE ++
	INY #2 : CPY #$1000 : BMI -
	LDY #$0040								;fix border value if map completely empty
++ : TYA : AND #$FFC0 : STA $05B0
;Bottom border
	LDY #$0FFE
- : JSR MainPageBorderCheck : BNE ++
	DEY #2 : BPL -
	LDY #$02C0								;fix border value if map completely empty
++ : TYA : ORA #$003F : INC : STA $05B2
;Left border
	LDX #$0000
-- : TXA : AND #$003F : CLC : ADC $05B0 : TAY			;maptile offset
- : JSR MainPageBorderCheck : BNE ++
	TYA : CLC : ADC #$0040 : TAY : CMP $05B2 : BMI -	;next tile in column
	INX #2 : CPX #$0080 : BMI --
	LDX #$003E								;fix border value if map completely empty
++ : TXA : ASL #2 : STA $05AC
;Right border
	LDX #$003E
-- : TXA : AND #$003F : CLC : ADC $05B0 : TAY			;maptile offset
- : JSR MainPageBorderCheck : BNE ++
	TYA : CLC : ADC #$0040 : TAY : CMP $05B2 : BMI -	;next tile in column
	DEX #2 : BPL --
	LDX #$0042								;fix border value if map completely empty
++ : JMP FinalAdjustmentBoundary
	;TXA : INC #2 : ASL #2 : STA $05AE

!Involve = "AND #$00FF"	;filter out map deco tiles, so boundary considers decotiles
!Ignore = "AND #$03FF"	;only tile data, if decotile gets detected -> skip tile

FullPageBorderCheck:
	LDA [$03],y : !InvolveMapDecorationForBoundary : BIT #$0300 : BNE +	;check if tile is deco tile in right mappage
	CMP.w #!EmptyTile : BEQ + : RTS		;check if tile is empty tile
+ : MainPageBorderCheck:
	LDA [$00],y : !InvolveMapDecorationForBoundary : BIT #$0300 : BNE +	;check if tile is deco tile in left mappage
	CMP.w #!EmptyTile : RTS
+ : LDA #$0000 : RTS					;continue boundary search
;2 bytes left

ORG $829547
HorizontalMapBoundary:
;	REP #$30
;Top border
	;LDY #$0000
- : JSR FullPageBorderCheck : BNE ++
	INY #2 : CPY #$0800 : BMI -
	LDY #$0040								;fix border value if map completely empty
++ : TYA : AND #$FFC0 : STA $05B0
;Bottom border
	LDY #$07FE
- : JSR FullPageBorderCheck : BNE ++
	DEY #2 : BPL -
	LDY #$02C0								;fix border value if map completely empty
++ : TYA : ORA #$003F : INC : STA $05B2
;Left border
	LDX #$0000
-- : TXA : AND #$003F : CLC : ADC $05B0 : TAY			;maptile offset
- : JSR MainPageBorderCheck : BNE ++
	TYA : CLC : ADC #$0040 : TAY : CMP $05B2 : BMI -	;next tile in column
	INX #2 : CPX #$0080 : BPL +
	CPX #$0040 : BNE --						;if map page border reached
	LDA $03 : STA $00 : BRA --				;left page completely empty -> set pointer to right map page
+ : LDX #$0034								;fix border value if map completely empty
++ : TXA : ASL #2 : STA $05AC
;Right border
	LDX #$007E
-- : TXA : AND #$003F : CLC : ADC $05B0 : TAY			;maptile offset
- : LDA [$03],y : !InvolveMapDecorationForBoundary : BIT #$0300 : BNE +
	CMP.w #!EmptyTile : BNE ++
+ : TYA : CLC : ADC #$0040 : TAY : CMP $05B2 : BMI -	;next tile in column
	DEX #2 : BMI +
	CPX #$0040 : BNE --						;if map page border reached
	LDA $00 : STA $03 : BRA --				;right page completely empty -> set pointer to left map page
+ : LDX #$0038								;fix border value if map completely empty
++ : FinalAdjustmentBoundary:
	TXA : INC #2 : ASL #2 : STA $05AE
;Adjust top/bottom borders
	LDA $05B0 : LSR #3 : STA $05B0
	LDA $05B2 : LSR #3 : STA $05B2
	PLP : RTS
;$1F byte left
WARNPC $829628

;---------------------------------------- SET PAUSE SCREEN STARTING POSITION -----------------------

!LeftScreenOffset = "!Left_MapFrameOffset+!CursorOffscreenOffset<<3"
!RightScreenOffset = "$20-!Right_MapFrameOffset-!CursorOffscreenOffset-1<<3"
!TopScreenOffset = "!Top_MapFrameOffset+!CursorOffscreenOffset<<3"
!BottomScreenOffset = "$20-!Bottom_MapFrameOffset-!CursorOffscreenOffset-1<<3"

ORG $82902E
;Determine the X midpoint of the map
	LDA $05AE : SEC : SBC $05AC : LSR : CLC : ADC $05AC
	SEC : SBC.w #($20-!Left_MapFrameOffset-!Right_MapFrameOffset>>1)+!Left_MapFrameOffset<<3 : STA $B1
;Determine the Y midpoint of the map
	LDA $05B2 : SEC : SBC $05B0 : LSR : CLC : ADC $05B0
	SEC : SBC.w #($20-!Top_MapFrameOffset-!Bottom_MapFrameOffset>>1)+!Top_MapFrameOffset<<3 : STA $B3

	LDA !OriginAreaIndex : CMP $1F5B : BEQ + : RTL	;check if in current area for samus cursor
+ : LDA $0AF7 : AND #$00FF : CLC : ADC $07A1 : ASL #3 : STA $12 : SEC : SBC $B1	;$12 = samus X position from map
	CMP.w #!LeftScreenOffset : BMI +				;branch if samus is to far left from map midpoint
	CMP.w #!RightScreenOffset : BPL ++ : BRA +++	;branch if samus is to far right from map midpoint
+ : LDA $12 : SEC : SBC.w #!LeftScreenOffset : STA $B1 : BRA +++	;adjust screen for cursor position
++ : LDA $12 : SEC : SBC.w #!RightScreenOffset : STA $B1			;adjust screen for cursor position
+++ : LDA $0AFB : AND #$00FF : CLC : ADC $07A3 : INC : ASL #3 : STA $12 : SEC : SBC $B3	;same for Y position
	CMP.w #!TopScreenOffset : BMI +
	CMP.w #!BottomScreenOffset : BPL ++ : RTL
+ : LDA $12 : SEC : SBC.w #!TopScreenOffset : STA $B3 : RTL
++ : LDA $12 : SEC : SBC.w #!BottomScreenOffset : STA $B3 : RTL

;$C byte left
WARNPC $8290C8
}
;---------------------------------------------------------------------------------------------------
;|x|                                    MAPTILE GLOW                                             |x|
;---------------------------------------------------------------------------------------------------
{
;Hijacks
ORG $8290FA : JSR MaptileGlowRoutine
ORG $82B6E2 : JSR MaptileGlowRoutine


!MaptileGlowTimer = !MaptileGlowRAM
!MaptileGlowIndex = !MaptileGlowRAM+1

ORG $82925D
MaptileGlowRoutine:
	JSR $A92B			;pause screen animation
	PHP : SEP #$30
	LDA.w !MaptileGlowTimer : BEQ ++				;draw mapglow palette on first frame of mapscreen
	DEC !MaptileGlowTimer : BNE +					;decrease timer
	INC !MaptileGlowIndex : LDA.w !MaptileGlowIndex	;next index
	CMP.b #!MaptileGlow_TimerAmount : BCC +			;check if end of index reached
	STZ !MaptileGlowIndex : + : PLP : RTS			;reset index ;return
++ : PHB : PEA.w !Freespace_MaptileGlow>>8 : PLB : PLB			;set bank to where maptile glow data is
	LDX !MaptileGlowIndex : LDA.w MaptileGlow_GlobalTimer,x		;load timer data by next index
	INC : STA.w !MaptileGlowTimer : LDY #$00 : REP #$30			;set timer, prepare loop
;[X] = pointer of current maptile glow data + index*2
- : LDA.w !MaptileGlowIndex : AND #$00FF : ASL : CLC : ADC.w MaptileGlow_PalettePointer,y : TAX
	LDA $0000,x : LDX.w MaptileGlow_PaletteOffset,y : STA $7EC000,x		;set palette
+ : INY #2 : CPY.w #!MaptileGlow_PaletteAmount<<1 : BCC -
	PLB : PLP : RTS

;WARNPC $8292B0
}
;---------------------------------------------------------------------------------------------------
;|x|                                    SELECT SWITCH AREA                                       |x|
;---------------------------------------------------------------------------------------------------
{
;--------------------------------------- HIJACKS ---------------------------------------------------

ORG $828D1A : JSR PrepareAreaIndex
ORG $828D38 : STZ $074D				;undo hijack
ORG $82910A : JSR (PauseRoutineIndex,x)
ORG $829125 : JSR CheckForSelectPress
ORG $829130 : JSR DrawIndicatorIfInCurrentArea
ORG $829156 : JSR DrawSelectButtonSprite : NOP
ORG $82915A : JSR DrawIndicatorIfInCurrentArea
ORG $829200 : JSR DrawIndicatorIfInCurrentArea
ORG $82935B : JMP DrawIndicatorIfInCurrentArea

ORG $82B881 : JSR CheckToDrawMapIcons
ORG $82C581 : DW SelectButtonSprite, $C22B, $C22B, $C22B	;changed sprite data pointer ($0C - $0F)
ORG $82C599 : DW $C22B										;changed sprite data pointer ($18)
ORG $82C3AF						;overwrite (garbage?) sprite data
SelectButtonSprite: DW $0008	;how many OAM tiles to draw
					DW $0008 : DB $00 : DW $34CA : DW $0000 : DB $00 : DW $34BA : DW $01F8 : DB $00 : DW $34C3 : DW $01F0 : DB $00 : DW $34C2
					DW $0008 : DB $F8 : DW $74B4 : DW $0000 : DB $F8 : DW $34B6 : DW $01F8 : DB $F8 : DW $34B5 : DW $01F0 : DB $F8 : DW $34B4
					;[X offset] : [Y offset] : [tile details] : repeat...


;--------------------------------------- FREESPACE -------------------------------------------------

;ORG $8292B0 - $829324
;Code relocated! Check the "Compiler" file for details of
;PauseRoutineIndex:
;CheckForSelectPress:
;DrawSelectButtonSprite:


ORG $829533
DrawIndicatorIfInCurrentArea:
	LDA !OriginAreaIndex : CMP $1F5B : BNE +		;check if area shown is the same area as samus
	JSR $B9C8 : + : RTS



ORG $829F50
PrepareAreaIndex:
	JSR $8DBD : LDA $1F5B : STA !OriginAreaIndex
	PHP : SEP #$20 : TAX : XBA : LDA.w $B7C9,x		;$B7C9 = selective bit index
	REP #$30 : STA !ExploredAreaBits : LDA #$0000	;set bit from origin area
;check every area for explored bits
.arealoop : PHA : XBA : TAX : LDY #$0080	;setup
;check this area for explored bits, if none: go to next area.
- : LDA $7ECD52,x : BNE + : INX #2 : DEY : BNE - : BRA ++
;if area has a explored bit: set bit in !ExploredAreaBits for this area and go to the next one
+ : SEP #$30 : LDA $01,s : TAX
	LDA !ExploredAreaBits : ORA.w $B7C9,x : STA !ExploredAreaBits : REP #$30
++ : PLA : INC : CMP.w #!AccessableAreaNumber : BCC .arealoop	;check as many areas as set
	PLP : RTS


;Construct next explored map during switch routine
MapSwitchConstruct:
	REP #$30
	JSL $82BB30		;display map elevator destinations
	JSR NextAvailableAreaFinder : STX $1F5B	;save next area number
	LDA $7ED908,x : AND #$00FF : STA $0789	;set flag of map station for next area
	JSL $8293C3		;update area label and construct new area map
	JSL $829028		;set map scroll boundaries and screen starting position
++ : STZ $073F : LDA $C10C : STA $072B		;set L/R highlight animation data
	LDA #$0001 : STA $0723 : STA $0725
	STZ $0763 : INC $0727 : RTS


;Get offset of current explored area bit or different area
;for where and which icons should be drawn
CheckToDrawMapIcons:
	LDA $1F5B : CMP !OriginAreaIndex : BEQ +		;check if in current area
	PHP : REP #$20 : PHX
	XBA : CLC : ADC #$CD52 : ADC $12 : TAX : LDA $7E0000,x	;load explored bit of different area
	PLX : PLP : RTS
+ : LDA $07F7,y : RTS						;load explored bit of current area


;Returns value of next area (X), carry set if next area is valid, otherwise carry clear
NextAvailableAreaFinder:
	PHP : SEP #$30
	LDA !ExploredAreaBits : LDX $1F5B : INX	;search for next explored area bit
- : BIT $B7C9,x : BNE +						;branch if area bit is set ;$B7C9 = selective bit index
.continue
	INX : CPX #$08 : BCC - : LDX #$00 : BRA -
;if another area is available
+ : CPX $1F5B : BEQ .return							;check if it is the same area as active currently
	CPX.b #!AccessableAreaNumber : BCS .continue	;continue search if not the signed range
	PLP : SEC : RTS				;valid area to switch to, set carry, return
.return : PLP : CLC : RTS		;no valid areas available, clear carry, return


CheckIconInMapArea:			;draw icon if it's in the confined map area
	STA $22 : TYA : AND #$FF00 : BNE +	;check Y position
	TXA : AND #$FE00 : BNE +			;check X position
	LDA $22 : JSL $81891F	;if onscreen position: draw sprite
+ : RTL						;else return

WARNPC $82A09A

}
;---------------------------------------------------------------------------------------------------
;|x|                                    DOORBIT SPRITEDATA                                       |x|
;---------------------------------------------------------------------------------------------------
{
ORG $82B6AE : JSR DoorSpriteHijack	;colored doors on pause screen map
ORG $82B752 : JSR DoorSpriteHijack	;colored doors on file select map


;Extend sprite pointers for map screen (starting at $68)
;Freespace created by moving dummy samus wireframe tiledata pointer somewhere else
ORG $82C639
	DW RedDoor_TopSingle, RedDoor_BottomSingle, RedDoor_LeftSingle, RedDoor_RightSingle
	DW GreenDoor_TopSingle, GreenDoor_BottomSingle, GreenDoor_LeftSingle, GreenDoor_RightSingle
	DW YellowDoor_TopSingle, YellowDoor_BottomSingle, YellowDoor_LeftSingle, YellowDoor_RightSingle
	DW GreyDoor_TopSingle, GreyDoor_BottomSingle, GreyDoor_LeftSingle, GreyDoor_RightSingle

;Sprite data of colored doors
RedDoor_TopSingle: DW $0001, $0000 : DB $FB : DW $2490
RedDoor_BottomSingle: DW $0001, $0000 : DB $03 : DW $A490
RedDoor_LeftSingle: DW $0001, $01FC : DB $FF : DW $24A0
RedDoor_RightSingle: DW $0001, $0004 : DB $FF : DW $64A0

GreenDoor_TopSingle: DW $0001, $0000 : DB $FB : DW $2491
GreenDoor_BottomSingle: DW $0001, $0000 : DB $03 : DW $A491
GreenDoor_LeftSingle: DW $0001, $01FC : DB $FF : DW $24A1
GreenDoor_RightSingle: DW $0001, $0004 : DB $FF : DW $64A1

YellowDoor_TopSingle: DW $0001, $0000 : DB $FB : DW $2492
YellowDoor_BottomSingle: DW $0001, $0000 : DB $03 : DW $A492
YellowDoor_LeftSingle: DW $0001, $01FC : DB $FF : DW $24A2
YellowDoor_RightSingle: DW $0001, $0004 : DB $FF : DW $64A2

GreyDoor_TopSingle: DW $0001, $0000 : DB $FB : DW $2493
GreyDoor_BottomSingle: DW $0001, $0000 : DB $03 : DW $A493
GreyDoor_LeftSingle: DW $0001, $01FC : DB $FF : DW $24A3
GreyDoor_RightSingle: DW $0001, $0004 : DB $FF : DW $64A3


DoorSpriteAreaList:
	DW DoorSpriteList_Crateria, DoorSpriteList_Brinstar, DoorSpriteList_Norfair, DoorSpriteList_WreckedShip
	DW DoorSpriteList_Maridia, DoorSpriteList_Tourian, DoorSpriteList_Ceres, DoorSpriteList_Debug

DoorSpriteAreaCount:
	DW (DoorSpriteList_Crateria_EndList-DoorSpriteList_Crateria)/3, (DoorSpriteList_Brinstar_EndList-DoorSpriteList_Brinstar)/3
	DW (DoorSpriteList_Norfair_EndList-DoorSpriteList_Norfair)/3, (DoorSpriteList_WreckedShip_EndList-DoorSpriteList_WreckedShip)/3
	DW (DoorSpriteList_Maridia_EndList-DoorSpriteList_Maridia)/3, (DoorSpriteList_Tourian_EndList-DoorSpriteList_Tourian)/3
	DW (DoorSpriteList_Ceres_EndList-DoorSpriteList_Ceres)/3, (DoorSpriteList_Debug_EndList-DoorSpriteList_Debug)/3


DoorSpriteHijack:
	JSL ConstructDoorSpriteMain : RTS


WARNPC $82C74A
}
;---------------------------------------------------------------------------------------------------
;|x|                                    SMOOTH MAP SCREEN CONTROLS                               |x|
;---------------------------------------------------------------------------------------------------
{
;New definition in RAM
;$05FB = map screen available direction
;$05FD = left scroll speed
;$05FE = right scroll speed
;$05FF = up scroll speed
;$0600 = down scroll speed


;--------------------------------------- BANK $81 --------------------------------------------------

ORG $81AD88 : JSL MapScrollMain
ORG $81AF13 : BMI $07
ORG $81AF1F : PADBYTE $FF : PAD $81AF32


;--------------------------------------- BANK $82 --------------------------------------------------

ORG $82912C : JSL MapScrollMain
ORG $82B91F : LDA $05FB : ORA $0006,x : STA $05FB : RTL
;9 bytes left

ORG $82B981 : BMI $07
ORG $82B98D : PADBYTE $FF : PAD $82B9A0


;--------------------------------------- FREESPACE -------------------------------------------------

ORG $829E27
MapScrollMain:
	PHP : SEP #$30
	LDA $05FC : ASL : AND #$06 : TAX : JSR (HorizontalScreenMovementTable,x)	;move screen in horizontal axes
	LDA $05FC : LSR : AND #$06 : TAX : JSR (VerticalScreenMovementTable,x)		;move screen in vertical axes
	LDA $05B6 : BIT #$01 : BNE +												;set scroll speed every 2nd frame
	LDA $8C : AND $05FC : ASL : AND #$06 : TAX : JSR (HorizontalScreenSpeedTable,x)	;set horizontal scroll speed depending on controller input
	LDA $8C : AND $05FC : LSR : AND #$06 : TAX : JSR (VerticalScreenSpeedTable,x)	;set vertical scroll speed depending on controller input
+ : PLP : JML ContinueScrolling


HorizontalScreenMovementTable:
	DW NoMovement, ScreenMovement_OnlyRight, ScreenMovement_OnlyLeft, ScreenMovement_Horizontal
VerticalScreenMovementTable:
	DW NoMovement, ScreenMovement_OnlyDown, ScreenMovement_OnlyUp, ScreenMovement_Vertical

HorizontalScreenSpeedTable:
	DW PauseScreen_HorizontalNeutral, PauseScreen_MoveRight, PauseScreen_MoveLeft, PauseScreen_HorizontalNeutral
VerticalScreenSpeedTable:
	DW PauseScreen_VerticalNeutral, PauseScreen_MoveDown, PauseScreen_MoveUp, PauseScreen_VerticalNeutral


NoMovement: RTS


ScreenMovement_OnlyRight:				;if screen bumps on left boundary of map screen
	LDA $05FD : BEQ +					;check if still momentum
	STZ $05FD : LDA #$36 : JSL $80903F	;zero speed and play sound (scrolling map) in library 1 (max queue: 6)
+ : BRA ScreenMovement_Right			;goto right map scroll

ScreenMovement_OnlyLeft:				;if screen bumps on right boundary of map screen
	LDA $05FE : BEQ +
	STZ $05FE : LDA #$36 : JSL $80903F
+

ScreenMovement_Left:
	LDA $B1 : SEC : SBC $05FD : STA $B1 : BCS +	;move BG1 left by n pixel
	DEC $B2 : + : RTS							;if underflow: decrement screen page
ScreenMovement_Horizontal:
	JSR ScreenMovement_Left
ScreenMovement_Right:
	LDA $B1 : CLC : ADC $05FE : STA $B1 : BCC +	;move BG1 right by n pixel
	INC $B2 : + : RTS							;if overflow: increment screen page


ScreenMovement_OnlyDown:				;if screen bumps on up boundary of map screen
	LDA $05FF : BEQ +
	STZ $05FF : LDA #$36 : JSL $80903F
+ : BRA ScreenMovement_Down

ScreenMovement_OnlyUp:					;if screen bumps on down boundary of map screen		
	LDA $0600 : BEQ +
	STZ $0600 : LDA #$36 : JSL $80903F
+

ScreenMovement_Up:
	LDA $B3 : SEC : SBC $05FF : STA $B3 : BCS +	;move BG1 up by n pixel
	DEC $B4 : + : RTS
ScreenMovement_Vertical:
	JSR ScreenMovement_Up
ScreenMovement_Down:
	LDA $B3 : CLC : ADC $0600 : STA $B3 : BCC +	;move BG1 down by n pixel
	INC $B4 : + : RTS


PauseScreen_MoveUp:
	LDA $05FF : CMP.b #!MapScrollSpeedCap : BPL + : INC $05FF : + : BRA PauseScreen_Decelerate_Down		;increase up scroll speed and jump to decrease down scroll speed
PauseScreen_MoveDown:
	LDA $0600 : CMP.b #!MapScrollSpeedCap : BPL + : INC $0600 : +	;increase down scroll speed

PauseScreen_Decelerate_Up:
	LDA $05FF : BEQ + : DEC $05FF : + : RTS			;decrease up scroll speed
PauseScreen_VerticalNeutral:
	JSR PauseScreen_Decelerate_Up
PauseScreen_Decelerate_Down:
	LDA $0600 : BEQ + : DEC $0600 : + : RTS			;decrease down scroll speed


PauseScreen_MoveLeft:
	LDA $05FD : CMP.b #!MapScrollSpeedCap : BPL + : INC $05FD : + : BRA PauseScreen_Decelerate_Right	;increase left scroll speed and jump to decrease right scroll speed
PauseScreen_MoveRight:
	LDA $05FE : CMP.b #!MapScrollSpeedCap : BPL + : INC $05FE : +	;increase right scroll speed

PauseScreen_Decelerate_Left:
	LDA $05FD : BEQ + : DEC $05FD : + : RTS			;decrease left scroll speed
PauseScreen_HorizontalNeutral:
	JSR PauseScreen_Decelerate_Left
PauseScreen_Decelerate_Right:
	LDA $05FE : BEQ + : DEC $05FE : + : RTS			;decrease right scroll speed

WARNPC $82A09A
}
;---------------------------------------------------------------------------------------------------
;|x|                                    PRESERVE SCREEN INDEX                                    |x|
;---------------------------------------------------------------------------------------------------
{
ORG $829009		;during pause screen loading
	PHP
	JSR $A09A	;set up PPU for pause menu
	JSR $A12B	;load equipment screen tilemaps
	JSR $A615	;load button palette
	JSR $A84D	;update pause menu buttons
	JSL $829028	;set up general map scrolling (pause menu animation reset ; map scroll limit/position)
	LDA $0727 : BEQ +	;return if in map screen
	JSR $AB47	;set screen position for equipment section
	JSR $B1E0	;equipment screen VRAM transfer
+ : PLP : RTS
;1 byte left


ORG $82A106 : BRA $01 : NOP		;delete zero $0753	(button label index)
ORG $82A383 : BRA $01 : NOP		;delete zero $0727	(screen index)
ORG $82A3BF : BRA $01 : NOP		;delete zero $0753	(button label index)
ORG $82A3C2 : BRA $01 : NOP		;delete zero $0755	(equipment cursor index)


ORG $82A512		;make priority button check (so pause menu index doesn't get screwed if L/R + start button get pressed together)
	BIT #$1000 : BNE $54	;return if start is pressed
	BIT #$0020 : BNE $2B	;check for L button (same as vanilla)
	BIT #$0010 : BNE $04	;check for R button
	BRA $48					;return


ORG $82AB56					;optimized code of "set up reserve mode" + additions
	LDA $09C0 : BEQ ++				;check if reserve activated (in auto/manual mode)
	LDX #$0082 : STX $02
	LDX #$BF2A : CMP #$0001 : BEQ +	;AUTO tile offset
	LDX #$BF22 : + : STX $00		;load MANUAL offset instead if in manual mode
	LDX #$0006 : TXY
- : LDA $7E3A8E,x : AND #$FC00 : ORA [$00],y : STA $7E3A8E,x	;tile transfer
	DEX : DEX : TXY : BPL -			;loop
++ : STZ $0741 : STZ $0743				;\
	LDA $C10C : AND #$00FF : STA $072D	;animation resets
	LDA $C165 : AND #$00FF : STA $072F	;/

	LDA $0A76 : BNE +						;check if hyper beam active
	LDA $0755 : BNE ReturnNewCursorIndex	;check for new cursor position if not set/in reserve section
	LDA $09D4 : BEQ FindNewCursorIndex		;continue if no reserve
	STZ $0755 : BRA ReturnNewCursorIndex
;look for new cursor position if cursor still is in beam section after hyper beam activation, else return
+ : LDA $0755 : AND #$000F : DEC : BNE ReturnNewCursorIndex : BRA FindHyperBeamCursorReplacement
;5 bytes left


ORG $82ABBF : FindNewCursorIndex:
ORG $82ABDE : FindHyperBeamCursorReplacement:
ORG $82AC15 : ReturnNewCursorIndex:
}
}
