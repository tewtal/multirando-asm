
;---------------------------------------------------------------------------------------------------
;|x|                                    MAPTILE GLOW                                             |x|
;---------------------------------------------------------------------------------------------------
{
ORG !Freespace_MaptileGlow
;Palettes for maptile glow:

;"blue" tilemap palette:
;Loaded_MapGlow: DW $44E5, $40C4, $3CA3, $3882, $3461, $3882, $3CA3, $40C4

;"pink" tilemap palette:
;Explored_MapGlow: DW $48FB, $44DA, $40B9, $3C98, $3877, $3C98, $40B9, $44DA

;"green" tilemap palette:
;Secret_MapGlow: DW $1EA9, $1A88, $1667, $1246, $0E25, $1246, $1667, $1A88

;"yellow" tilemap palette:
;Important_MapGlow: DW $02DF, $02BE, $029D, $027C, $025B, $027C, $029D, $02BE

;"orange" tilemap palette:
;Heated_MapGlow: DW $0E3F, $0A1E, $05FD, $01DC, $01BB, $01DC, $05FD, $0A1E

;"gray" tilemap palette:
;Inactive_MapGlow: DW $4631, $4210, $3DEF, $39CE, $35AD, $39CE, $3DEF, $4210



;Time in frames for one color (amount of values get set in the config under "TimerAmount")
MaptileGlow_GlobalTimer:
	DB $40, $08, $04, $08, $0C, $08, $04, $08

;Pointers to these maptile glow palettes (amount of values get set in the config under "PaletteAmount")
MaptileGlow_PalettePointer:
	;DW Explored_MapGlow, Secret_MapGlow
	;DW Heated_MapGlow

;Position of palette for maptile glow [<palette position> * 2] (amount of values same as above)
MaptileGlow_PaletteOffset:
	;DW $0062, $0082
	;DW $00C2
}
