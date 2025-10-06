
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
	%DoorSprite(!Green, !Right, 0, $05, $1F, $000)
	%DoorSprite(!Yellow, !Right, 0, $02, $1F, $001)
	%DoorSprite(!Red, !Right, 0, $08, $13, $005)
	%DoorSprite(!Gray, !Right, 1, $04, $0B, $00B)
	%DoorSprite(!Green, !Right, 1, $05, $0D, $00C)
	%DoorSprite(!Yellow, !Right, 1, $05, $03, $00D)
	%DoorSprite(!Yellow, !Down, 1, $07, $02, $00E)
	%DoorSprite(!Yellow, !Down, 1, $0A, $14, $00F)
	%DoorSprite(!Yellow, !Up, 1, $08, $02, $010)
	%DoorSprite(!Gray, !Right, 0, $0A, $14, $011)
	%DoorSprite(!Gray, !Left, 0, $12, $12, $012)
	%DoorSprite(!Yellow, !Right, 0, $11, $14, $013)
	%DoorSprite(!Gray, !Left, 0, $12, $14, $01A)
	%DoorSprite(!Red, !Right, 0, $07, $18, $01D)
	%DoorSprite(!Red, !Right, 0, $09, $0B, $01E)
DoorSpriteList_Crateria_EndList:

DoorSpriteList_Brinstar:
	%DoorSprite(!Red, !Left, 0, $06, $09, $01F)
	%DoorSprite(!Red, !Left, 0, $05, $09, $020)
	%DoorSprite(!Red, !Right, 0, $05, $09, $021)
	%DoorSprite(!Red, !Right, 0, $07, $09, $022)
	%DoorSprite(!Red, !Left, 0, $07, $09, $023)
	%DoorSprite(!Gray, !Right, 0, $08, $09, $024)
	%DoorSprite(!Gray, !Right, 0, $05, $08, $025)
	%DoorSprite(!Red, !Right, 0, $05, $0C, $026)
	%DoorSprite(!Yellow, !Right, 0, $09, $12, $028)
	%DoorSprite(!Green, !Right, 0, $0B, $12, $029)
	%DoorSprite(!Red, !Right, 0, $05, $12, $02A)
	%DoorSprite(!Red, !Left, 0, $0E, $0F, $02B)
	%DoorSprite(!Gray, !Left, 0, $05, $13, $02C)
	%DoorSprite(!Gray, !Up, 0, $05, $16, $02D)
	%DoorSprite(!Green, !Down, 0, $04, $16, $02E)
	%DoorSprite(!Gray, !Right, 0, $08, $10, $02F)
	%DoorSprite(!Yellow, !Right, 0, $0B, $14, $030)
	%DoorSprite(!Gray, !Left, 0, $0B, $15, $031)
	%DoorSprite(!Red, !Right, 0, $0B, $1D, $032)
	%DoorSprite(!Green, !Right, 1, $0E, $00, $033)
	%DoorSprite(!Green, !Left, 0, $0B, $06, $034)
	%DoorSprite(!Green, !Left, 0, $0A, $14, $035)
	%DoorSprite(!Gray, !Left, 0, $09, $13, $036)
	%DoorSprite(!Gray, !Right, 0, $09, $14, $037)
	%DoorSprite(!Green, !Left, 1, $13, $01, $038)
	%DoorSprite(!Yellow, !Left, 1, $10, $01, $039)
	%DoorSprite(!Red, !Left, 0, $10, $19, $03A)
	%DoorSprite(!Green, !Left, 1, $08, $05, $03B)
	%DoorSprite(!Yellow, !Left, 1, $0A, $05, $03C)
	%DoorSprite(!Green, !Left, 1, $0C, $05, $03D)
	%DoorSprite(!Gray, !Right, 1, $08, $04, $03E)
	%DoorSprite(!Green, !Right, 1, $12, $05, $03F)
	%DoorSprite(!Gray, !Left, 1, $14, $0C, $040)
	%DoorSprite(!Gray, !Right, 1, $14, $0B, $041)
	%DoorSprite(!Gray, !Right, 1, $14, $14, $042)
	%DoorSprite(!Gray, !Left, 1, $14, $0F, $043)
	%DoorSprite(!Green, !Right, 1, $13, $15, $044)
	%DoorSprite(!Gray, !Right, 1, $14, $16, $045)
	%DoorSprite(!Gray, !Right, 1, $14, $18, $046)
	%DoorSprite(!Gray, !Left, 1, $14, $17, $047)
DoorSpriteList_Brinstar_EndList:

DoorSpriteList_Norfair:
	%DoorSprite(!Green, !Right, 0, $05, $10, $049)
	%DoorSprite(!Red, !Right, 0, $04, $0D, $04A)
	%DoorSprite(!Green, !Left, 0, $04, $0A, $04B)
	%DoorSprite(!Yellow, !Left, 0, $05, $0A, $04C)
	%DoorSprite(!Red, !Left, 0, $06, $0A, $04D)
	%DoorSprite(!Green, !Down, 0, $0A, $0F, $04E)
	%DoorSprite(!Gray, !Up, 0, $0B, $0F, $04F)
	%DoorSprite(!Gray, !Right, 0, $06, $09, $050)
	%DoorSprite(!Red, !Left, 0, $0B, $0A, $051)
	%DoorSprite(!Red, !Right, 0, $10, $0A, $052)
	%DoorSprite(!Green, !Left, 0, $03, $16, $053)
	%DoorSprite(!Green, !Right, 0, $03, $17, $054)
	%DoorSprite(!Red, !Right, 1, $03, $04, $055)
	%DoorSprite(!Red, !Right, 0, $05, $18, $056)
	%DoorSprite(!Red, !Right, 0, $05, $1C, $057)
	%DoorSprite(!Yellow, !Left, 0, $0B, $1A, $058)
	%DoorSprite(!Gray, !Right, 0, $11, $13, $059)
	%DoorSprite(!Gray, !Right, 0, $11, $17, $05A)
	%DoorSprite(!Gray, !Left, 0, $12, $17, $05B)
	%DoorSprite(!Gray, !Left, 0, $11, $18, $05C)
	%DoorSprite(!Gray, !Left, 0, $0D, $1A, $05D)
	%DoorSprite(!Yellow, !Down, 1, $0E, $05, $05E)
	%DoorSprite(!Green, !Left, 1, $11, $01, $05F)
	%DoorSprite(!Gray, !Left, 0, $11, $1E, $060)
DoorSpriteList_Norfair_EndList:

DoorSpriteList_WreckedShip:
	%DoorSprite(!Gray, !Left, 0, $12, $10, $082)
	%DoorSprite(!Gray, !Right, 0, $10, $10, $083)
	%DoorSprite(!Green, !Down, 0, $13, $10, $084)
	%DoorSprite(!Gray, !Right, 0, $14, $12, $085)
	%DoorSprite(!Gray, !Left, 0, $14, $13, $086)
	%DoorSprite(!Gray, !Left, 0, $0D, $0A, $087)
	%DoorSprite(!Gray, !Left, 0, $0B, $0C, $088)
	%DoorSprite(!Gray, !Right, 0, $0B, $12, $089)
	%DoorSprite(!Gray, !Down, 0, $0B, $10, $08A)
	%DoorSprite(!Red, !Left, 0, $0E, $15, $08B)
DoorSpriteList_WreckedShip_EndList:

DoorSpriteList_Maridia:
	%DoorSprite(!Red, !Right, 0, $14, $0B, $08C)
	%DoorSprite(!Red, !Right, 0, $11, $0B, $08D)
	%DoorSprite(!Red, !Right, 0, $10, $10, $08E)
	%DoorSprite(!Green, !Right, 0, $0B, $13, $08F)
	%DoorSprite(!Red, !Right, 0, $12, $10, $090)
	%DoorSprite(!Gray, !Left, 0, $01, $1B, $091)
	%DoorSprite(!Red, !Right, 1, $05, $02, $092)
	%DoorSprite(!Gray, !Right, 0, $04, $18, $093)
	%DoorSprite(!Green, !Down, 0, $05, $16, $094)
	%DoorSprite(!Green, !Up, 0, $10, $16, $095)
	%DoorSprite(!Red, !Left, 0, $0C, $14, $096)
	%DoorSprite(!Gray, !Right, 0, $08, $1A, $097)
	%DoorSprite(!Red, !Right, 1, $07, $08, $098)
	%DoorSprite(!Green, !Right, 1, $08, $08, $09A)
	%DoorSprite(!Gray, !Left, 1, $0A, $09, $09B)
	%DoorSprite(!Gray, !Left, 1, $08, $01, $09C)
	%DoorSprite(!Gray, !Left, 0, $09, $18, $09D)
	%DoorSprite(!Gray, !Right, 1, $0A, $08, $09E)
	%DoorSprite(!Gray, !Left, 1, $0B, $07, $09F)
DoorSpriteList_Maridia_EndList:

DoorSpriteList_Tourian:
	%DoorSprite(!Gray, !Left, 0, $0D, $0E, $0A0)
	%DoorSprite(!Gray, !Right, 0, $0E, $0D, $0A1)
	%DoorSprite(!Gray, !Right, 0, $0E, $13, $0A2)
	%DoorSprite(!Gray, !Down, 0, $0F, $14, $0A3)
	%DoorSprite(!Gray, !Right, 0, $10, $12, $0A4)
	%DoorSprite(!Gray, !Left, 0, $10, $11, $0A5)
	%DoorSprite(!Gray, !Right, 0, $10, $10, $0A6)
	%DoorSprite(!Red, !Right, 0, $11, $0C, $0A7)
	%DoorSprite(!Gray, !Right, 0, $11, $10, $0A8)
	%DoorSprite(!Red, !Left, 0, $13, $11, $0A9)
	%DoorSprite(!Gray, !Up, 0, $14, $0B, $0AA)
	%DoorSprite(!Gray, !Left, 0, $15, $0C, $0AB)
	%DoorSprite(!Gray, !Left, 0, $14, $12, $0AC)
DoorSpriteList_Tourian_EndList:

DoorSpriteList_Ceres:
	%DoorSprite(0, 0, 0, $00, $00, $000)
DoorSpriteList_Ceres_EndList:

DoorSpriteList_Debug:
	%DoorSprite(0, 0, 0, $00, $00, $000)
DoorSpriteList_Debug_EndList:
}
