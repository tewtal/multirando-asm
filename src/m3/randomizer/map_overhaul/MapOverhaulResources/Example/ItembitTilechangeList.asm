
;---------------------------------------------------------------------------------------------------
;|x|                                    ITEMBIT TILECHANGE LIST                                  |x|
;---------------------------------------------------------------------------------------------------
{
MACRO ItemTile(change, area, page, y, x)
{
	DW <change><<14|<area><<11|<page><<10|<y><<5|<x>	;for asar
;	DW <change><<3|<area><<1|<page><<5|<y><<5|<x>		;for xkas
}
ENDMACRO

;Item tilecheck macro: %ItemTile(change, area, page, y, x)
; x     : X coordinate of tile to change (range: $00 - $1F, higher value will partly change Y value!)
; y     : Y coordinate of tile to change (range: $00 - $1F, higher value will affect the page bit!)
; page  : in which side of the area the tile is. Setting this bit is equal to X = +$20.
;	0 for left map page
;	1 for right map page
; area  : changes tile in the following region:
	!Cra = 0	;Crateria
	!Brn = 1	;Brinstar
	!Nor = 2	;Norfair
	!WkS = 3	;Wrecked Ship
	!Mar = 4	;Maridia
	!Tou = 5	;Tourian
	!Col = 6	;Colony (Ceres)
	!Dbg = 7	;Debug
; change: changes current tile by the next/previous tile in the GFX. (S : single tile; D : dobble tile)
	!LeftS = 0
	!LeftD = 1
	!RightS = 2
	!RightD = 3
;You can use these defines in there respective argument for better visualisation.
;
;
;When using the hex editor: this is the tilecheck bitmask:   iiaa apyy yyyx xxxx
; x = X coordinate of map
; y = Y coordinate of map
; p = page bit (0 = left half of map; 1 = right half of map)
;              (counts as X = +$20, or Y = +$20 when using vertical area)
; a = region (000 = Crateria; 001 = Brinstar; 010 = Norfair)
;            (011 = Wrecked Ship; 100 = Maridia; 101 = Tourian)
; i = tile change. Left bit (MSB): change current tile to next tile in GFX, else: change to previous tile in GFX
;                  Right bit: changes by an additional tile depending on left bit
;            (00 = <tile> -1; 01 = <tile> -2; 10 = <tile> +1; 11 = <tile> +2)
;
; Setting it all to zero will not change any tile.
; Tile overwrites in the same position are stackable!

ORG !Freespace_ItembitTilechange
ItemTileCheckList:
	%ItemTile(!RightS, !Cra, 1, $02, $01) : %ItemTile(!RightS, !Cra, 1, $06, $06) : %ItemTile(!LeftS, !Cra, 1, $01, $07) : %ItemTile(!RightS, !Cra, 1, $03, $06)	;item $000 - $003
	%ItemTile(!RightS, !Cra, 1, $05, $04) : %ItemTile(!RightS, !Cra, 0, $03, $11) : %ItemTile(!RightS, !Cra, 0, $13, $14) : %ItemTile(!LeftD, !Cra, 0, $07, $19)	;item $004 - $007
	%ItemTile(!RightS, !Cra, 0, $07, $0C) : %ItemTile(!RightS, !Cra, 0, $04, $0B) : %ItemTile(!RightS, !Cra, 0, $04, $0B) : %ItemTile(!RightS, !Cra, 0, $0A, $18)	;item $008 - $00B
	%ItemTile(!RightS, !Cra, 0, $08, $10) : %ItemTile(!RightS, !Brn, 0, $08, $0C) : %ItemTile(!RightS, !Brn, 0, $0A, $18) : %ItemTile(!RightS, !Brn, 0, $05, $0B)	;item $00C - $00F
	%ItemTile(!RightS, !Brn, 0, $04, $0A) : %ItemTile(!RightS, !Brn, 0, $05, $0D) : %ItemTile(!RightS, !Brn, 0, $05, $0E) : %ItemTile(!RightS, !Brn, 0, $05, $0E)	;item $010 - $013
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(!RightS, !Brn, 0, $08, $11) : %ItemTile(!RightS, !Brn, 0, $0B, $11) : %ItemTile(!LeftS, !Brn, 0, $0C, $11)	;item $014 - $017
	%ItemTile(!RightS, !Brn, 0, $09, $0F) : %ItemTile(!RightS, !Brn, 0, $0C, $16) : %ItemTile(!LeftD, !Brn, 0, $0B, $19) : %ItemTile(!RightS, !Brn, 0, $0B, $17)	;item $018 - $01B
	%ItemTile(!RightS, !Brn, 1, $0B, $00) : %ItemTile(!LeftS, !Brn, 0, $0B, $1F) : %ItemTile(!RightS, !Brn, 0, $0B, $06) : %ItemTile(!RightS, !Brn, 0, $0B, $05)	;item $01C - $01F
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(!RightS, !Brn, 0, $0E, $08) : %ItemTile(!RightS, !Brn, 0, $0C, $1C) : %ItemTile(!RightS, !Brn, 0, $09, $15)	;item $020 - $023
	%ItemTile(!RightS, !Brn, 0, $09, $1D) : %ItemTile(!RightS, !Brn, 0, $09, $1D) : %ItemTile(!LeftD, !Brn, 0, $10, $17) : %ItemTile(!RightS, !Brn, 1, $09, $03)	;item $024 - $027
	%ItemTile(!RightS, !Brn, 1, $0C, $03) : %ItemTile(!RightS, !Brn, 1, $0C, $02) : %ItemTile(!LeftD, !Brn, 1, $12, $06) : %ItemTile(!LeftS, !Brn, 1, $14, $0B)	;item $028 - $02B
	%ItemTile(!LeftS, !Brn, 1, $13, $0F) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $02C - $02F
	%ItemTile(!LeftD, !Brn, 1, $14, $19) : %ItemTile(!LeftS, !Nor, 0, $05, $10) : %ItemTile(!LeftD, !Nor, 0, $03, $05) : %ItemTile(!LeftS, !Nor, 0, $05, $02)	;item $030 - $033
	%ItemTile(!RightS, !Nor, 0, $0B, $13) : %ItemTile(!LeftD, !Nor, 0, $07, $07) : %ItemTile(!RightS, !Nor, 0, $07, $0B) : %ItemTile(!RightS, !Nor, 0, $06, $08)	;item $034 - $037
	%ItemTile(!RightS, !Nor, 0, $06, $09) : %ItemTile(!RightS, !Nor, 0, $0B, $09) : %ItemTile(!RightS, !Nor, 0, $10, $0E) : %ItemTile(!RightS, !Nor, 0, $10, $08)	;item $038 - $03B
	%ItemTile(!LeftD, !Nor, 0, $11, $03) : %ItemTile(!RightS, !Nor, 0, $03, $12) : %ItemTile(!RightS, !Nor, 0, $03, $12) : %ItemTile(!RightS, !Nor, 0, $03, $15)	;item $03C - $03F

	%ItemTile(!RightS, !Nor, 0, $06, $17) : %ItemTile(!LeftS, !Nor, 1, $03, $04) : %ItemTile(!LeftD, !Nor, 1, $03, $05) : %ItemTile(!RightS, !Nor, 0, $05, $1A)	;item $040 - $043
	%ItemTile(!LeftD, !Nor, 0, $05, $1D) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(!RightS, !Nor, 0, $10, $12) : %ItemTile(!LeftS, !Nor, 0, $10, $13)	;item $044 - $047
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(!RightS, !Nor, 0, $0B, $1C) : %ItemTile(!RightS, !Nor, 1, $06, $03) : %ItemTile(!RightS, !Nor, 1, $07, $05)	;item $048 - $04B
	%ItemTile(!RightS, !Nor, 1, $0F, $00) : %ItemTile(!RightS, !Nor, 0, $06, $1D) : %ItemTile(!LeftS, !Nor, 0, $12, $16) : %ItemTile(!LeftD, !Nor, 0, $11, $14)	;item $04C - $04F
	%ItemTile(!RightS, !Nor, 1, $0C, $05) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $050 - $053
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $054 - $057
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $058 - $05B
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $05C - $05F
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $060 - $063
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $064 - $067
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $068 - $06B
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $06C - $06F
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $070 - $073
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $074 - $077
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $078 - $07B
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $07C - $07F

	%ItemTile(!RightS, !WkS, 0, $11, $0C) : %ItemTile(!RightS, !WkS, 0, $0C, $0F) : %ItemTile(!RightS, !WkS, 0, $0E, $0D) : %ItemTile(!RightS, !WkS, 0, $0B, $15)	;item $080 - $083
	%ItemTile(!RightS, !WkS, 0, $0E, $12) : %ItemTile(!RightS, !WkS, 0, $12, $0F) : %ItemTile(!RightS, !WkS, 0, $12, $15) : %ItemTile(!LeftS, !WkS, 0, $0E, $0A)	;item $084 - $087
	%ItemTile(!RightS, !Mar, 0, $0D, $0A) : %ItemTile(!RightS, !Mar, 0, $0C, $0B) : %ItemTile(!RightS, !Mar, 0, $0D, $12) : %ItemTile(!LeftS, !Mar, 0, $0E, $13)	;item $088 - $08B
	%ItemTile(!RightS, !Mar, 0, $07, $0C) : %ItemTile(!RightS, !Mar, 0, $07, $0C) : %ItemTile(!RightS, !Mar, 0, $07, $14) : %ItemTile(!LeftD, !Mar, 0, $03, $1C)	;item $08C - $08F
	%ItemTile(!RightS, !Mar, 0, $0F, $14) : %ItemTile(!RightS, !Mar, 0, $0F, $14) : %ItemTile(!RightS, !Mar, 0, $0F, $17) : %ItemTile(!RightS, !Mar, 0, $10, $18)	;item $090 - $093
	%ItemTile(!RightS, !Mar, 0, $0A, $18) : %ItemTile(!RightS, !Mar, 0, $0A, $19) : %ItemTile(!LeftD, !Mar, 1, $11, $01) : %ItemTile(!LeftS, !Mar, 1, $08, $0A)	;item $094 - $097
	%ItemTile(!RightS, !Mar, 0, $09, $1D) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(!LeftD, !Mar, 1, $0B, $06) : %ItemTile(0, 0, 0, $00, $00)	;item $098 - $09B
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $09C - $09F
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0A0 - $0A3
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0A4 - $0A7
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0A8 - $0AB
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0AC - $0AF
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0B0 - $0B3
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0B4 - $0B7
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0B8 - $0BB
	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0BC - $0BF

;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0C0 - $0C3
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0C4 - $0C7
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0C8 - $0CB
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0CC - $0CF
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0D0 - $0D3
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0D4 - $0D7
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0D8 - $0DB
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0DC - $0DF
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0E0 - $0E3
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0E4 - $0E7
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0E8 - $0EB
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0EC - $0EF
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0F0 - $0F3
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0F4 - $0F7
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0F8 - $0FB
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $0FC - $0FF


;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $100 - $103
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $104 - $107
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $108 - $10B
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $10C - $10F
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $110 - $113
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $114 - $117
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $118 - $11B
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $11C - $11F
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $120 - $123
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $124 - $127
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $128 - $12B
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $12C - $12F
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $130 - $133
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $134 - $137
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $138 - $13B
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $13C - $13F

;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $140 - $143
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $144 - $147
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $148 - $14B
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $14C - $14F
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $150 - $153
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $154 - $157
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $158 - $15B
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $15C - $15F
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $160 - $163
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $164 - $167
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $168 - $16B
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $16C - $16F
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $170 - $173
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $174 - $177
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $178 - $17B
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $17C - $17F

;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $180 - $183
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $184 - $187
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $188 - $18B
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $18C - $18F
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $190 - $193
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $194 - $197
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $198 - $19B
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $19C - $19F
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1A0 - $1A3
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1A4 - $1A7
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1A8 - $1AB
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1AC - $1AF
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1B0 - $1B3
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1B4 - $1B7
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1B8 - $1BB
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1BC - $1BF

;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1C0 - $1C3
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1C4 - $1C7
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1C8 - $1CB
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1CC - $1CF
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1D0 - $1D3
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1D4 - $1D7
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1D8 - $1DB
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1DC - $1DF
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1E0 - $1E3
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1E4 - $1E7
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1E8 - $1EB
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1EC - $1EF
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1F0 - $1F3
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1F4 - $1F7
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1F8 - $1FB
;	%ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00) : %ItemTile(0, 0, 0, $00, $00)	;item $1FC - $1FF
}
