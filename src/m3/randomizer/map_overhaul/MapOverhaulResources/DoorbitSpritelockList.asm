
;---------------------------------------------------------------------------------------------------
;|x|                                    DOORBIT CAPSRRITE LIST                                   |x|
;---------------------------------------------------------------------------------------------------
{
MACRO DoorSprite(variant, direction, page, y, x, index)
{
;Please comment out the line for the compiler you are using

	DL <variant><<22|<direction><<20|<page><<19|<y><<14|<x><<9|<index>	;for asar
;	DL <variant><<2|<direction><<1|<page><<5|<y><<5|<x><<9|<index>		;for xkas
}
ENDMACRO

;Door tilecheck macro: %DoorSprite(variant, direction, page, y, x, index)
; index     : door index defined to the door sprite
; x         : X coordinate of tile to change (range: $00 - $1F, higher value will partly change Y value!)
; y         : Y coordinate of tile to change (range: $00 - $1F, higher value will affect the page bit!)
; page      : in which side of the area the tile is. Setting this bit is equal to X = +$20.
;	0 for left map page
;	1 for right map page
; direction : changes in which side of the tile the door sprite gets set
	!Up = 0
	!Down = 1
	!Left = 2
	!Right = 3
; variant   : type of door to display
	!Red = 0
	!Green = 1
	!Yellow = 2
	!Gray = 3
;You can use these defines in their respective argument for better visualisation.
;
;
;When using the hex editor: this is the doorsprite check bitmask:   iiiiiiii yyxxxxxi ttddpyyy
; i = door bit index defined to the door sprite
; x = X coordinate of map
; y = Y coordinate of map
; p = page bit (0 = left half of map; 1 = right half of map)
;              (counts as X = +$20, or Y = +$20 when using vertical area)
; d = direction (00 = top; 01 = bottom; 10 = left; 11 = right)
; t = variant (00 = red door; 01 = green door; 10 = yellow door; 11 = grey door)
; Setting the last door sprite on the list to all zero or writing "DW $0000" will end the list of that area.

ORG !Freespace_DoorbitSpritelock
DoorSpriteList_Crateria:
	%DoorSprite(0, 0, 0, $00, $00, $000)
DoorSpriteList_Crateria_EndList:

DoorSpriteList_Brinstar:
	%DoorSprite(0, 0, 0, $00, $00, $000)
DoorSpriteList_Brinstar_EndList:

DoorSpriteList_Norfair:
	%DoorSprite(0, 0, 0, $00, $00, $000)
DoorSpriteList_Norfair_EndList:

DoorSpriteList_WreckedShip:
	%DoorSprite(0, 0, 0, $00, $00, $000)
DoorSpriteList_WreckedShip_EndList:

DoorSpriteList_Maridia:
	%DoorSprite(0, 0, 0, $00, $00, $000)
DoorSpriteList_Maridia_EndList:

DoorSpriteList_Tourian:
	%DoorSprite(0, 0, 0, $00, $00, $000)
DoorSpriteList_Tourian_EndList:

DoorSpriteList_Ceres:
	%DoorSprite(0, 0, 0, $00, $00, $000)
DoorSpriteList_Ceres_EndList:

DoorSpriteList_Debug:
	%DoorSprite(0, 0, 0, $00, $00, $000)
DoorSpriteList_Debug_EndList:
}
