
;---------------------------------------------------------------------------------------------------
;|x|                                    ADJACENT MAPTILE TABLE                                   |x|
;---------------------------------------------------------------------------------------------------
{
;These tables determine which maptile IDs update adjacent tiles in the current map
;when samus enters the position in which the maptile is located.
;The first table is a check rather or not to explore an adjacent tile.
;The second one determines from which side it should reveal it.
;The values are sorted by the maptile ID in bits.

ORG $90AB80
;Sorted by tile ID, one bit per entry (you literally read them from left to right)
SetAdjacentMaptileFlag:
	DB %00000000, %00000000	;tile $00 - $0F
	DB %00011110, %00000000	;tile $10 - $1F
	DB %00000000, %11110000	;tile $20 - $2F
	DB %00000000, %00000000	;tile $30 - $3F
	DB %00000000, %00000000	;tile $40 - $4F
	DB %00000000, %00000000	;tile $50 - $5F
	DB %00000000, %00000000	;tile $60 - $6F
	DB %00000000, %00000000	;tile $70 - $7F
	DB %00000000, %00000000	;tile $80 - $8F
	DB %00000000, %00000000	;tile $90 - $9F
	DB %00000000, %00000000	;tile $A0 - $AF
	DB %00000000, %00000000	;tile $B0 - $BF
	DB %00000000, %00000000	;tile $C0 - $CF
	DB %00000000, %00000000	;tile $D0 - $DF
	DB %00000000, %00000000	;tile $E0 - $EF
	DB %00000000, %00000000	;tile $F0 - $FF

UpdateAdjacentMaptileDirection:
;Sorted by tile ID, two bit per entry (literally sorted from left to right)
; %aabbccdd ;aa = direction of tile $00, bb = direction of tile $01, etc.
;$00 = update above, $01 = update below, $10 = update leftside, $11 = update rightside
;	   $x0 - $x3, $x4 - $x7, $x8 - $xB, $xC - $xF
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000001, %01000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00010001, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
	DB %00000000, %00000000, %00000000, %00000000	;tile $00 - $0F
}
