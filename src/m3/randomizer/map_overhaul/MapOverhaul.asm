;---------------------------------------------------------------------------------------------------
;|x|                                  MAP OVERHAUL v1.2.7 (asar)                                 |x|
;|x|                                       Made by MFreak                                        |x|
;---------------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------------
;|x|                                    CONFIG                                                   |x|
;---------------------------------------------------------------------------------------------------

{;-------------------------------------- GENERAL ---------------------------------------------------

;Location of map construction code for anything which require a map (minimap, pause screen, file select)
;Can be moved anywhere (size: $683)
	!Freespace_MapConstruction = $B89000

;Location for maptile GFX for minimap (size: $1000)
	!Freespace_MinimapTiles = $B8A000

;Location of code to transfer tile graphics from RAM to VRAM (restricted to bank $80) (size: $97)
	!FreespaceBank80_VRAM = $80FA00


;RAM addresses:
	!PauseScreenX_PositionMirror = $0939;used for updating map outside its range
	!PauseScreenY_PositionMirror = $093B;used for updating map outside its range
	!SamusMapPositionMirror = $0B28     ;used to not update minimap every frame
	!Update_Minimap_VRAM_Flag = $0B2A   ;flag for updating minimap GFX to VRAM
	!RAM_ActiveMap = $7EDF5C            ;map layout for minimap, originally storage for BG 2 tilemap during pause (size: $1000)
	!RAM_Minimap_GFX = $7EFE00          ;space to transfer tile graphics to then put it fittingly to VRAM later (size: $F0)
;RAM addresses for select switch area:
	!MinimapIndicatorPalette = $7EFEF0	;only used for minimap to load origin palette for samus position indicator
	!ExploredAreaBits = $7EFEF1         ;only used during pause screen, set bit of areas which have explored bits set
	!OriginAreaIndex = $7EFEF2          ;only used during pause screen, copy of $079F when loading pause screen


;Empty tile used for unexplored sections of the map (vanilla: $1F)
	!EmptyTile = $1F
;Tile in HUD graphic used to cover up the minimap during a bossfight (vanilla: $1F)
	!BossfightMinimapCovertile = $1F


;Set position for setup ASM. Similar to $C90A (set collected map for current area) seen in tourian entrance room (setup ASM)
;with the addition that it will be updated on the minimap too.
;Must be in bank $8F for it to work. Duo to SMART you have to change the setup asm pointers yourself.
;Custom setup asm for setting map station bit (size: $1D)
	!SetCollectedAreaCodePosition = $E99B
}

{;-------------------------------------- COVER TILES -----------------------------------------------

;Array of tiledata to cover with if maptile is loaded but unexplored (size: $100)
	!Freespace_CoverTiles = $B6F200
}

{;-------------------------------------- DOORBIT SPRITELOCK ----------------------------------------

;Array of tiledata to change specific tiles in depending areas if the doorbit is set (size: $400)
	!Freespace_DoorbitSpritelock = $B6F800

;Sets palette for door lock sprite (default: $05) (range: $00 - $07)
	!DoorSpritePalette = $05

;Set limit on how many door lock sprites should show at once (default: $40) (range: $00 - $64)
;You can go over range. This limit is set to not use every remaining sprite slot (if possible).
	!DoorSpriteLimit = $40
}

{;-------------------------------------- ITEMBIT TILECHANGE ----------------------------------------

;Array of tiledata to change specific tiles in depending areas if the itembit is set (size: $400)
	!Freespace_ItembitTilechange = $B6FC00

;Set total amount of item IDs which should be checked. (default: $0200) (range: $0001 - $0200)
;(Set them in multiple of $10, like $xx0)
;The whole purpose of reducing the limit is possibility to reduce the size of the item config list.
	!ItemIDCheckLimit = $0200
}

{;-------------------------------------- MAP DATA SOURCE -------------------------------------------

;Toggle rather the pointer to map tiledata is fixed or dynamic
;(default: 1 "dynamic") [dynamic = 1 ;fixed = 0]
;For SMART users this MUST be set to 1!
	!DynamicMapDataPointer = 1

;Change pointer to map tiledata table pointer in bank $82 (vanilla: $964A)
;DO NOT CHANGE unless you have moved the list somewhere else!
;This only gets used if "DynamicMapDataPointer" is set to 0.
	!MapDataTablePointer = $964A
}

{;-------------------------------------- MAP DECORATION --------------------------------------------

;Location of map decoration data (original size: $C8)
	!Freespace_MapDecoration = $89E000

;Map deco tiles only appears when map station is activated (default: !AlwaysActive)
	!MapDecorationAppearence = !AlwaysActive
;!AlwaysActive    : map decoration always appears in pause map screen
;!MapStationActive: map decoration only appears in pause map screen when mapstation has been activated


;Should map decoration be considered for setting up map screen boundaries? (default: !Involve)
	!InvolveMapDecorationForBoundary = !Involve
;!Involve: map decoration contribute in map screen boundaries
;!Ignore : map decoration get ignored when setting map screen boundaries
}

{;-------------------------------------- MAPTILE GLOW ----------------------------------------------

;Location of palette data for maptiles to change color (original size: $C8)
	!Freespace_MaptileGlow = $8EE600

;RAM address for maptile glow timer and index (default: $0759)
	!MaptileGlowRAM = $0759


;How many color steps should maptile glow have, before it repeat? (default: $08)
	!MaptileGlow_TimerAmount = $08

;How many palettes should have maptile glow? (default: $06)
	!MaptileGlow_PaletteAmount = $06
}

{;-------------------------------------- MINIMAP ---------------------------------------------------

;Sets palettes for tiles in minimap depending on the initial palette of the tile in the map (range: $00 - $07)
	!MinimapPalette0 = $00
	!MinimapPalette1 = $04
	!MinimapPalette2 = $03
	!MinimapPalette3 = $02
	!MinimapPalette4 = $02
	!MinimapPalette5 = $07
	!MinimapPalette6 = $02
	!MinimapPalette7 = $03

;Which minimap palette should empty tiles have? (vanilla: $03) (range: $00 - $07)
	!MinimapPaletteEmptyTile = $03

;Set palette for samus position indication in minimap (vanilla: $07) (range: $00 - $07)
	!SamusMinimapPositionPalette = $07

;Adjust blinking timer for samus position indication. Formula is 2^n in frames.
;At 8 and above the indicator will not blink at all (default: $03) (range $00 - $08)
	!SamusMinimapPositionTimer = $03
}

{;-------------------------------------- PAUSE SCREEN MAP SCROLL BOUNDARY --------------------------

;Map scroll boundaries are values where the screen stops at a certain position.
;This value is defined by the outest exposed tile in the area map.
;An additional offset is used to extend the map scroll boundary to a certain extent,
;so the entire map cannot and will not be obscured by the pause screen frame.

;How many empty tiles beyond the outest exposed tile before screen boundary hits
;(Offset values are defined in tiles) (default: $08 in all directions)
	!Left_MapBorderOffset = $08
	!Right_MapBorderOffset = $08
	!Top_MapBorderOffset = $08
	!Bottom_MapBorderOffset = $08

;How many tiles should be spaced between samus's cursor and the map frame of the mapscreen,
;if the cursor is not around the center of the exposed map. (default: $02)
;(The value should be smaller or equal to the lowest map border offset value)
	!CursorOffscreenOffset = $02

;Defined offset for the frame in the pause screen tilemap (offset values are defined in tiles)
;(This should not be changed unless you edited the size of the frame from the pause screen tilemap)
	!Left_MapFrameOffset = $01
	!Right_MapFrameOffset = $01
	!Top_MapFrameOffset = $06
	!Bottom_MapFrameOffset = $08
}

{;-------------------------------------- PAUSE SCREEN TILEMAP/PALETTE POINTERS ---------------------

;Here you can change the pointers to the tilemap data and palette of the pause screen.
;Only the reference point gets changed. The actual data does not get moved.
;(When moving pause screen related data, some patches related to this may break!)
	!PauseScreen_Map_Tilemap_Pointer = $B6E000       ;(vanilla: $B6E000 (PC: $1B6000) ;size: $800)
	!PauseScreen_Equipment_Tilemap_Pointer = $B6E800 ;(vanilla: $B6E800 (PC: $1B6800) ;size: $800)
	!PauseScreen_Palette_Pointer = $B6F000           ;(vanilla: $B6F000 (PC: $1B7000) ;size: $200)
}

{;-------------------------------------- SELECT SWITCH AREA ----------------------------------------

;Allows you to switch to other area maps by pressing SELECT on the pause screen.
;Set how many areas should be shown with SELECT switch. (default: $06 / range: $01 - $08)
	!AccessableAreaNumber = $06


;ASAR EXCLUSIVE!
;Change methode of transition to other areas: When pressing select, the screen will transition into
;a hex map view like in the file select screen. There you can choose your area instead of cycling through
;each one after time. Requires extra freespace if active (default: 0) [disable = 0 ;enable = 1]
	!SelectSwitchArea_HexMapMethode = 0
;Things to note however:
;- The area labels in the pause screen must be set to another palette other than
;  palette 5 - 7, as these get used for the hex map areas.
;- The yellow color used for the position indicator of the minimap as well as AUTO activation indicator of
;  reserve tank (HUD palette 7) will be force set to "dark blue" for the transparent hex pillars.
;- The dark yellow color in palette 0 (which usually gets used CRE tiles) will be force set to "black".

;Location for select switch to hex map code, only used if "!SelectSwitchArea_HexMapMethode" is enabled
;(size: $6CF)
	!Freespace_HexMapSelectSwitch = $89C000

;Toggle rather the data position for hex map transition is fixed or dynamic
;(default: 0 "fixed") [dynamic = 1 ;fixed = 0]
;Setting it to 1 (dynamic) increases the size requirement!
;For SMART users this MUST be set to 1!
	!DynamicHexMapData = 0
}

{;-------------------------------------- SMOOTH MAP SCREEN CONTROLS --------------------------------

;Allows you to freely control the map screen in all 8 directions.
;Map screen scroll speed cap (value is pixel per frame) (default: $02)
	!MapScrollSpeedCap = $02
}

{;-------------------------------------- UNEXPLORED TILE PALETTE -----------------------------------

;Changes the palette of loaded unexplored tiles.
;If the original tile isn't explored yet, the palette get changed to the defined palette here
;(range: $00 - $07) (default: all $02 "vanilla unexplored blue")
	!UnexploredTilePalette0 = $02  ; yellow (bad) 00
	!UnexploredTilePalette1 = $02  ; green (bad) 04
	!UnexploredTilePalette2 = $02  ; blue (08)
	!UnexploredTilePalette3 = $07  ; red (0C)
	!UnexploredTilePalette4 = $02  ; green (10)
	!UnexploredTilePalette5 = $05  ; yellow (14)
	!UnexploredTilePalette6 = $05  ; orange (18)
	!UnexploredTilePalette7 = $02  ; gray (1C)
}

{;-------------------------------------- VERTICAL AREA MAP -----------------------------------------

;You can control which area should display the area map vertically instead of horizontally.
;The right page of the map will be moved below the left page of the map.
;Rooms and icons of that area must be adjusted for vertical area (see README for more info).

;Set to 1 for this area to be displayed vertically.
;Sorted in this order: (Debug), (Ceres), (Tourian), (Maridia), (WShip), (Norfair), (Brinstar), (Crateria)
	!VerticalAreaMapBits = %00000000
}


;---------------------------------------------------------------------------------------------------
;|x|                                    MAIN                                                     |x|
;---------------------------------------------------------------------------------------------------
{
;Clean up
ORG $82925D : PADBYTE $FF : PAD $829324		;delete original map scrolling code ($C7)
ORG $82943D : PADBYTE $FF : PAD $829452		;\
ORG $82945A : PADBYTE $FF : PAD $82953E		;delete original map construction code ($1EB)
ORG $829547 : PADBYTE $FF : PAD $829628		;/
ORG $829E27 : PADBYTE $FF : PAD $82A09A		;delete redundant map scroll setup/original scroll boundary set routines ($273)

ORG $90A8EF : PADBYTE $FF : PAD $90AB78		;delete original minimap code ($315)

;Config files
INCSRC MapOverhaulResources/CoverTileList.asm
INCSRC MapOverhaulResources/DoorbitSpritelockList.asm
INCSRC MapOverhaulResources/ItembitTilechangeList.asm
INCSRC MapOverhaulResources/AdjacentMaptileTable.asm
INCSRC MapOverhaulResources/MaptileGlow.asm
INCSRC MapOverhaulResources/MapDecoration.asm

;Code files
INCSRC MapOverhaulResources/ASM/Misc_Banks.asm
INCSRC MapOverhaulResources/ASM/PauseScreenRoutines.asm
INCSRC MapOverhaulResources/Compiler/asar.asm
INCSRC MapOverhaulResources/ASM/MapConstruction.asm
INCSRC MapOverhaulResources/ASM/Minimap.asm

;Bin file
ORG !Freespace_MinimapTiles : INCBIN MapTiles.bin	;maptile storage for HUD map
}
