
;---------------------------------------------------------------------------------------------------
;|x|                                    MAP DECORATION                                           |x|
;---------------------------------------------------------------------------------------------------
{
ORG !Freespace_MapDecoration

;Pointer to deco tilegroups for each area
MapDecoration_AreaPointer:
	DW MapDecoration_List_Crateria, MapDecoration_List_Brinstar, MapDecoration_List_Norfair, MapDecoration_List_WreckedShip
	DW MapDecoration_List_Maridia, MapDecoration_List_Tourian, MapDecoration_List_Colony, MapDecoration_NoDecoration

;Tilegroup: draw no deco tiles
MapDecoration_NoDecoration: DW $0000


MapDecoration_List_Crateria: {
	DW Deco_Crateria_Cloudstart : DB $16, $00
	DW Deco_Crateria_Cloud : DB $18, $00
	DW Deco_Crateria_Cloud : DB $1C, $00
	DW Deco_Crateria_Cloudend : DB $21, $00
	DW Deco_Crateria_Cloudstart : DB $24, $00
	DW Deco_Crateria_Cloud : DB $26, $00
	DW Deco_Crateria_Cloudend : DB $2C, $00
	DW Deco_Crateria_Cloud : DB $30, $02
	DW Deco_Crateria_Cloudend : DB $36, $02

	DW Deco_Crateria_Waterstart : DB $23, $06
	DW Deco_Crateria_Water : DB $25, $06
	DW Deco_Crateria_Water : DB $29, $06
	DW Deco_Crateria_Water : DB $30, $06
	DW Deco_Crateria_Water : DB $34, $06
	DW Deco_Crateria_Waterend : DB $38, $06

	DW Deco_Crateria_Shippart : DB $2D, $1F
	DW Deco_Crateria_Shippart : DB $2D, $00
	DW Deco_Crateria_Shippart_DamagedRight : DB $2D, $01
	DW Deco_Crateria_Shippart_DamagedLeft : DB $2D, $03
	DW Deco_Crateria_Shippart : DB $2D, $05
	DW Deco_Crateria_Shippart_DamagedMiddle : DB $2D, $06
	DW Deco_Crateria_Shippart : DB $2D, $07
	DW Deco_Crateria_Shipground : DB $2D, $08

	DW Deco_Crateria_Brick : DB $15, $06
	DW Deco_Crateria_Brick : DB $14, $07
	DW Deco_Crateria_Brick : DB $17, $07
	DW Deco_Crateria_Brick : DB $18, $08

	DW Deco_Crateria_Brick : DB $0C, $05
	DW Deco_Crateria_Brick : DB $0B, $06
	DW Deco_Crateria_Brick : DB $0C, $07
	DW Deco_Crateria_Brick : DB $10, $07
	DW Deco_Crateria_Brick : DB $0F, $08
	DW Deco_Crateria_Brick : DB $0D, $08
	DW Deco_Crateria_Brick : DB $0C, $09
	DW Deco_Crateria_Brick : DB $10, $09

	DW Deco_Crateria_Mushroom : DB $07, $07
	DW Deco_Crateria_Mushroom : DB $09, $06
	DW Deco_Crateria_Brick : DB $06, $09
	DW Deco_Crateria_Brick : DB $08, $09
	DW Deco_Crateria_Brick : DB $0A, $09

	DW Deco_Crateria_Maptile_MainAreaTop : DB $19, $01
	DW Deco_Crateria_Maptile_MainAreaMiddle : DB $19, $02
	DW Deco_Crateria_Maptile_MainAreaMiddle : DB $19, $03
	DW Deco_Crateria_Maptile_MainAreaMiddle : DB $19, $04
	DW Deco_Crateria_Maptile_MainAreaBottom : DB $19, $05
	DW Deco_Crateria_Maptile_Shaft : DB $13, $05
	DW Deco_Crateria_Maptile_Elevator : DB $17, $13
	DW $0000
}

MapDecoration_List_Brinstar: {
	DW Deco_Brinstar_Vine_Left : DB $06, $01
	DW Deco_Brinstar_Vine_Left : DB $05, $03
	DW Deco_Brinstar_Vine_Left : DB $04, $06
	DW Deco_Brinstar_Vine_Left : DB $04, $09
	DW Deco_Brinstar_Vine_Left : DB $05, $0C

	DW Deco_Brinstar_Ground_Start : DB $07, $08
	DW Deco_Brinstar_Ground_Long : DB $08, $08
	DW Deco_Brinstar_Ground_Long : DB $0B, $08
	DW Deco_Brinstar_Corner_DownLeft : DB $10, $08
	DW Deco_Brinstar_Wall_Left : DB $10, $09
	DW Deco_Brinstar_Ground_Start : DB $0F, $0D
	DW Deco_Brinstar_Ground_Long : DB $10, $0D
	DW Deco_Brinstar_Ground_End : DB $15, $0D

	DW Deco_Brinstar_Grass : DB $08, $07
	DW Deco_Brinstar_Pillar_Long : DB $0B, $05
	DW Deco_Brinstar_Grass : DB $0C, $07
	DW Deco_Brinstar_Pillar_Small : DB $0E, $06
	DW Deco_Brinstar_Grass : DB $0F, $07
	DW Deco_Brinstar_Pillar_Small : DB $11, $0B
	DW Deco_Brinstar_Grass : DB $13, $0C

	DW Deco_Brinstar_Block_Big_Left : DB $1F, $0C
	DW Deco_Brinstar_Block_Small_Left : DB $1F, $0F
	DW Deco_Brinstar_Block_Big_Left : DB $1F, $11
	DW Deco_Brinstar_Block_Left : DB $1F, $13
	DW Deco_Brinstar_Block_Small_Left : DB $20, $15
	DW Deco_Brinstar_Block_Big_Right : DB $22, $0B
	DW Deco_Brinstar_Block_Small_Right : DB $22, $0D
	DW Deco_Brinstar_Block_Right : DB $23, $0E
	DW Deco_Brinstar_Block_Small_Right : DB $22, $0F
	DW Deco_Brinstar_Block_Big_Right : DB $22, $11

	DW Deco_Brinstar_Block_Small_Left : DB $23, $09
	DW Deco_Brinstar_Block_Small_Right : DB $26, $0A
	DW Deco_Brinstar_Block_Right : DB $27, $0C
	DW Deco_Brinstar_Block_Small_Right : DB $24, $14
	DW Deco_Brinstar_Block_Small_Right : DB $28, $12

	DW Deco_Brinstar_Vine : DB $2B, $12
	DW Deco_Brinstar_Maptile_Main : DB $19, $08
	DW $0000
}

MapDecoration_List_Norfair: {
	DW Deco_Norfair_Ground_Ceiling_Long : DB $02, $01
	DW Deco_Norfair_Ground_Ceiling_Stalagmite : DB $05, $01
	DW Deco_Norfair_Ground_Up_SlopeDiagonalLeft : DB $07, $01
	DW Deco_Norfair_Ground_Ceiling_Stalagmite : DB $09, $02
	DW Deco_Norfair_Ground_Ceiling : DB $0A, $02
	DW Deco_Norfair_Ground_Ceiling : DB $0B, $02
	DW Deco_Norfair_Ground_Up_SlopeDiagonalLeft : DB $0C, $02
	DW Deco_Norfair_Ground_Ceiling : DB $0E, $03
	DW Deco_Norfair_Ground_Ceiling_Stalagmite : DB $0F, $03
	DW Deco_Norfair_Ground_Ceiling : DB $10, $03
	DW Deco_Norfair_Ground_Up_SlopeDiagonalLeft : DB $11, $03
	DW Deco_Norfair_Ground_Ceiling : DB $13, $04
	DW Deco_Norfair_Corner_UpLeft : DB $14, $04
	DW Deco_Norfair_Wall_Left : DB $14, $03
	DW Deco_Norfair_Ground_Ceiling : DB $14, $02
	DW Deco_Norfair_Ground_Ceiling : DB $15, $02
	DW Deco_Norfair_Ground_Ceiling_Bubble : DB $16, $02
	DW Deco_Norfair_Ground_Up_SlopeDiagonalRight : DB $17, $01
	DW Deco_Norfair_Ground_Ceiling_Long : DB $19, $01
	DW Deco_Norfair_Ground_Ceiling_Bubble : DB $19, $01
	DW Deco_Norfair_Ground_Up_SlopeDiagonalLeft : DB $1E, $01
	DW Deco_Norfair_Ground_Ceiling_Long : DB $20, $02
	DW Deco_Norfair_Ground_Ceiling_Bubble : DB $24, $02
	DW Deco_Norfair_Ground_Ceiling : DB $25, $02
	DW Deco_Norfair_Ground_Ceiling : DB $26, $02

	DW Deco_Norfair_Wall_Right : DB $26, $03
	DW Deco_Norfair_Wall_Right : DB $26, $04
	DW Deco_Norfair_Wall_Right : DB $26, $05
	DW Deco_Norfair_Wall_Right_SlopeDiagonalRight : DB $25, $06
	DW Deco_Norfair_Ground_Floor : DB $25, $08
	DW Deco_Norfair_Ground_Floor : DB $24, $08
	DW Deco_Norfair_Ground_Floor : DB $23, $08
	DW Deco_Norfair_Corner_DownRight : DB $22, $08
	DW Deco_Norfair_Corner_UpRight : DB $22, $09
	DW Deco_Norfair_Ground_Ceiling : DB $23, $09
	DW Deco_Norfair_Ground_Ceiling : DB $24, $09
	DW Deco_Norfair_Ground_Ceiling : DB $25, $09
	DW Deco_Norfair_Wall_Right_SlopeDiagonalLeft : DB $25, $0A
	DW Deco_Norfair_Wall_Right : DB $26, $0C
	DW Deco_Norfair_Wall_Right : DB $26, $0D
	DW Deco_Norfair_Wall_Right : DB $26, $0E
	DW Deco_Norfair_Wall_Right_SlopeDiagonalRight : DB $25, $0F
	DW Deco_Norfair_Wall_Right : DB $25, $11
	DW Deco_Norfair_Wall_Right : DB $25, $12

	DW Deco_Norfair_Wall_Left : DB $02, $02
	DW Deco_Norfair_Wall_Left : DB $02, $03
	DW Deco_Norfair_Wall_Left : DB $02, $04
	DW Deco_Norfair_Wall_Left : DB $02, $05
	DW Deco_Norfair_Wall_Left_SlopeDiagonalRight : DB $01, $06
	DW Deco_Norfair_Wall_Left : DB $01, $08
	DW Deco_Norfair_Ground_Floor : DB $01, $09
	DW Deco_Norfair_Ground_Floor : DB $02, $09
	DW Deco_Norfair_Ground_Floor : DB $03, $09
	DW Deco_Norfair_Ground_Down_SlopeDiagonalLeft : DB $04, $09
	DW Deco_Norfair_Ground_Down_SlopeDiagonalLeft : DB $06, $0A
	DW Deco_Norfair_Ground_Floor : DB $08, $0B
	DW Deco_Norfair_Corner_DownLeft : DB $09, $0B
	DW Deco_Norfair_Corner_UpLeft : DB $09, $0C
	DW Deco_Norfair_Ground_Ceiling : DB $08, $0C
	DW Deco_Norfair_Ground_Ceiling_Stalagmite : DB $07, $0C
	DW Deco_Norfair_Ground_Ceiling : DB $06, $0C
	DW Deco_Norfair_Ground_Up_SlopeDiagonalRight : DB $04, $0C
	DW Deco_Norfair_Ground_Ceiling : DB $03, $0D
	DW Deco_Norfair_Ground_Ceiling : DB $02, $0D
	DW Deco_Norfair_Wall_Left_SlopeDiagonalRight : DB $01, $0E
	DW Deco_Norfair_Wall_Left : DB $01, $10
	DW Deco_Norfair_Wall_Left : DB $01, $11
	DW Deco_Norfair_Wall_Left : DB $01, $12

	DW Deco_Norfair_Bubble_Part1 : DB $15, $04
	DW Deco_Norfair_Bubble_Part2 : DB $16, $05
	DW Deco_Norfair_Bubble_Full : DB $17, $03
	DW Deco_Norfair_Bubble_Part2 : DB $17, $04
	DW Deco_Norfair_Bubble_Part1 : DB $17, $05
	DW Deco_Norfair_Bubble_Part2 : DB $17, $06
	DW Deco_Norfair_Bubble_Part1 : DB $18, $04
	DW Deco_Norfair_Bubble_Full : DB $18, $05
	DW Deco_Norfair_Bubble_Part2 : DB $19, $03
	DW Deco_Norfair_Bubble_Part1 : DB $19, $04
	DW Deco_Norfair_Bubble_Part1 : DB $19, $05
	DW Deco_Norfair_Bubble_Part1 : DB $1A, $02
	DW Deco_Norfair_Bubble_Part1 : DB $23, $03
	DW Deco_Norfair_Bubble_Part2 : DB $24, $04
	DW Deco_Norfair_Bubble_Part1 : DB $25, $03
	DW Deco_Norfair_Bubble_Full : DB $25, $04

	DW Deco_Norfair_Pillar_Top : DB $15, $0E
	DW Deco_Norfair_Pillar_Left : DB $14, $11
	DW Deco_Norfair_Pillar_Left : DB $13, $12
	DW Deco_Norfair_Pillar_Right : DB $17, $11
	DW Deco_Norfair_Pillar_Right : DB $18, $12
	DW Deco_Norfair_Pillar_Small : DB $1F, $10

	DW Deco_Norfair_Acid : DB $00, $13
	DW Deco_Norfair_Acid : DB $04, $13
	DW Deco_Norfair_Acid : DB $08, $13
	DW Deco_Norfair_Acid : DB $0C, $13
	DW Deco_Norfair_Acid : DB $10, $13
	DW Deco_Norfair_Acid : DB $14, $13
	DW Deco_Norfair_Acid : DB $18, $13
	DW Deco_Norfair_Acid : DB $1C, $13
	DW Deco_Norfair_Acid : DB $20, $13
	DW Deco_Norfair_Acid : DB $24, $13

	DW Deco_Norfair_Maptile_West : DB $03, $02
	DW Deco_Norfair_Maptile_Main : DB $09, $01
	DW $0000
}

MapDecoration_List_WreckedShip: {
	DW Deco_WreckedShip_End_Left : DB $0C, $0C
	DW Deco_WreckedShip_End_Left : DB $0A, $0D
	DW Deco_WreckedShip_End_Left : DB $0C, $0F
	DW Deco_WreckedShip_End_Left : DB $0C, $10
	DW Deco_WreckedShip_End_Left : DB $0C, $12
	DW Deco_WreckedShip_Wall_Left : DB $0D, $0C
	DW Deco_WreckedShip_Wall_Left : DB $0D, $0E
	DW Deco_WreckedShip_Wall_Left : DB $0D, $10
	DW Deco_WreckedShip_Wall_Left : DB $0D, $12
	DW Deco_WreckedShip_Wall_Lamp : DB $0B, $0D
	DW Deco_WreckedShip_Wall_Single : DB $0C, $0D
	DW Deco_WreckedShip_Wall_Lamp : DB $0B, $0E
	DW Deco_WreckedShip_Wall_Single : DB $0C, $0E

	DW Deco_WreckedShip_Wall_Right : DB $11, $0C
	DW Deco_WreckedShip_Wall_Right : DB $11, $0E
	DW Deco_WreckedShip_Wall_Right : DB $11, $10
	DW Deco_WreckedShip_Wall_Right : DB $11, $12
	DW Deco_WreckedShip_End_Right : DB $15, $0C
	DW Deco_WreckedShip_End_Right : DB $15, $0E
	DW Deco_WreckedShip_End_Right : DB $15, $10
	DW Deco_WreckedShip_End_Right : DB $15, $12

	DW Deco_WreckedShip_Wall_Dirty : DB $0D, $0C
	DW Deco_WreckedShip_Wall_Dirty : DB $0E, $0F
	DW Deco_WreckedShip_Wall_Dirty : DB $0D, $10
	DW Deco_WreckedShip_Wall_Dirty : DB $0E, $12
	DW Deco_WreckedShip_Wall_Dirty : DB $0F, $13
	DW Deco_WreckedShip_Wall_Dirty : DB $10, $0E
	DW Deco_WreckedShip_Wall_Dirty : DB $10, $11

	DW Deco_WreckedShip_Wall_Dirty : DB $11, $0D
	DW Deco_WreckedShip_Wall_Dirty : DB $13, $0D
	DW Deco_WreckedShip_Wall_Dirty : DB $14, $0C
	DW Deco_WreckedShip_Wall_Dirty : DB $12, $10
	DW Deco_WreckedShip_Wall_Dirty : DB $14, $10
	DW Deco_WreckedShip_Wall_Dirty : DB $12, $13
	DW Deco_WreckedShip_Wall_Dirty : DB $13, $11
	DW Deco_WreckedShip_Wall_Dirty : DB $14, $12

	DW Deco_WreckedShip_StepLeft : DB $09, $0F
	DW Deco_WreckedShip_StepRight : DB $16, $0F

	DW Deco_WreckedShip_Maptile_Top : DB $0C, $0B
	DW Deco_WreckedShip_Maptile_Shaft : DB $10, $0E
	DW Deco_WreckedShip_Maptile_Entrance : DB $0C, $0F
	DW Deco_WreckedShip_Maptile_Bottom : DB $0D, $14
	DW $0000
}

MapDecoration_List_Maridia: {
	DW Deco_Maridia_Ground_Ceiling : DB $1B, $03
	DW Deco_Maridia_Ground_Ceiling : DB $1A, $03
	DW Deco_Maridia_Ground_Up_SlopeDiagonalRight : DB $18, $03
	DW Deco_Maridia_Ground_Ceiling : DB $17, $04
	DW Deco_Maridia_Ground_Ceiling : DB $16, $04
	DW Deco_Maridia_Ground_Ceiling : DB $15, $04
	DW Deco_Maridia_Ground_Ceiling : DB $14, $04
	DW Deco_Maridia_Ground_Up_SlopeDiagonalLeft : DB $12, $03
	DW Deco_Maridia_Ground_Ceiling : DB $11, $03
	DW Deco_Maridia_Ground_Ceiling : DB $10, $03
	DW Deco_Maridia_Ground_Ceiling : DB $0F, $03
	DW Deco_Maridia_Ground_Up_SlopeDiagonalRight : DB $0D, $03
	DW Deco_Maridia_Wall_Left_SlopeDiagonalRight : DB $0B, $05
	DW Deco_Maridia_Wall_Left : DB $0B, $07
	DW Deco_Maridia_Wall_Left : DB $0B, $08
	DW Deco_Maridia_Wall_Left : DB $0B, $09
	DW Deco_Maridia_Wall_Left_SlopeDiagonalLeft : DB $0B, $0A
	DW Deco_Maridia_Wall_Left : DB $0C, $0C
	DW Deco_Maridia_Wall_Left_SlopeDiagonalLeft : DB $0C, $0D
	DW Deco_Maridia_Ground_Down_SlopeDiagonalLeft : DB $0E, $0F
	DW Deco_Maridia_Ground_Floor : DB $10, $10
	DW Deco_Maridia_Wall_Left_SlopeDiagonalLeft : DB $10, $11

	DW Deco_Maridia_Crystal_Small : DB $0D, $09
	DW Deco_Maridia_Crystal_Large : DB $0E, $08
	DW Deco_Maridia_Crystal_Small : DB $0E, $0B
	DW Deco_Maridia_Crystal_Large : DB $0F, $09
	DW Deco_Maridia_Crystal_Small : DB $0F, $0D
	DW Deco_Maridia_Crystal_Small : DB $10, $0A
	DW Deco_Maridia_Crystal_Small : DB $10, $0C
	DW Deco_Maridia_Crystal_Large : DB $11, $0B
	DW Deco_Maridia_Crystal_Small : DB $12, $09
	DW Deco_Maridia_Crystal_Small : DB $12, $0E

	DW Deco_Maridia_Tube_Horizontal : DB $0F, $07
	DW Deco_Maridia_Tube_Horizontal : DB $0C, $07
	DW Deco_Maridia_Tube_Curve_DownLeft : DB $13, $07
	DW Deco_Maridia_Tube_Vertical : DB $13, $08
	DW Deco_Maridia_Tube_Curve_UpRight : DB $13, $0C
	DW Deco_Maridia_Tube_Horizontal : DB $14, $0C
	DW Deco_Maridia_Tube_Curve_UpLeft : DB $19, $0C
	DW Deco_Maridia_Tube_Vertical : DB $19, $07
	DW Deco_Maridia_Tube_Curve_DownRight : DB $19, $06
	DW Deco_Maridia_Tube_Horizontal : DB $1A, $06
	DW Deco_Maridia_Tube_Horizontal : DB $1E, $06
	DW Deco_Maridia_Tube_Horizontal : DB $23, $06
	DW Deco_Maridia_Tube_Horizontal : DB $27, $06
	DW Deco_Maridia_Tube_Curve_DownLeft : DB $2B, $06
	DW Deco_Maridia_Tube_FancyCurved : DB $20, $07
	DW Deco_Maridia_Tube_Horizontal : DB $1A, $0A
	DW Deco_Maridia_Tube_Horizontal : DB $1D, $0A
	DW Deco_Maridia_Tube_Horizontal : DB $22, $0A
	DW Deco_Maridia_Tube_Horizontal : DB $27, $0A
	DW Deco_Maridia_Tube_Vertical : DB $2B, $07
	DW Deco_Maridia_Tube_Curve_UpLeft : DB $2B, $0C
	DW Deco_Maridia_Tube_Horizontal : DB $26, $0C
	DW Deco_Maridia_Tube_Curve_DownRight : DB $25, $0C
	DW Deco_Maridia_Tube_Vertical : DB $25, $0D

	DW Deco_Maridia_Quicksand : DB $12, $12
	DW Deco_Maridia_Quicksand : DB $15, $12
	DW Deco_Maridia_Quicksand : DB $18, $12
	DW Deco_Maridia_Quicksand : DB $1B, $12
	DW Deco_Maridia_Quicksand : DB $1E, $12
	DW Deco_Maridia_Quicksand : DB $21, $12
	DW Deco_Maridia_Quicksand : DB $24, $12
	DW Deco_Maridia_Quicksand : DB $27, $12
	DW Deco_Maridia_Quicksand : DB $2A, $12

	DW Deco_Maridia_Tube_Damaged : DB $15, $0C
	DW Deco_Maridia_Tube_Damaged : DB $17, $0C
	DW Deco_Maridia_TransportTube : DB $16, $05
	
	DW Deco_Maridia_Maptile_Corridor : DB $0A, $13
	DW $0000
}

MapDecoration_List_Tourian: {
	DW Deco_Tourian_Pipe_End_Left : DB $12, $0C
	DW Deco_Tourian_Pipe_Horizontal : DB $0D, $0C
	DW Deco_Maridia_Tube_Curve_DownRight : DB $0C, $0C
	DW Deco_Tourian_Pipe_Vertical : DB $0C, $0D
	DW Deco_Tourian_Pipe_T_Up : DB $0C, $0F
	DW Deco_Tourian_Pipe_Horizontal : DB $0D, $0F
	DW Deco_Tourian_Pipe_Horizontal_Single : DB $12, $0F
	DW Deco_Tourian_Pipe_End_Left : DB $13, $0F
	DW Deco_Tourian_Pipe_Horizontal_Single : DB $0B, $0F
	DW Deco_Maridia_Tube_Curve_DownRight : DB $0A, $0F
	DW Deco_Tourian_Pipe_Vertical : DB $0A, $10
	DW Deco_Maridia_Tube_Curve_UpRight : DB $0A, $12
	DW Deco_Tourian_Pipe_Horizontal : DB $0B, $12

	DW Deco_Tourian_Pipe_End_Right : DB $16, $0C
	DW Deco_Maridia_Tube_Curve_DownLeft : DB $17, $0C
	DW Deco_Tourian_Pipe_Vertical : DB $17, $0D
	DW Deco_Tourian_Pipe_Vertical : DB $17, $0F
	DW Deco_Maridia_Tube_Curve_UpLeft : DB $17, $11
	DW Deco_Tourian_Pipe_End_Right : DB $16, $11

	DW Deco_Tourian_Lense : DB $0B, $10
	DW Deco_Tourian_SmallBlocks : DB $0B, $0E
	DW Deco_Tourian_Block : DB $0A, $0C
	DW Deco_Tourian_Block : DB $09, $0F
	DW Deco_Tourian_SmallBlocks : DB $09, $11
	DW Deco_Tourian_Lense : DB $0D, $0B
	DW Deco_Tourian_Block : DB $0E, $0B
	DW Deco_Tourian_SmallBlocks : DB $0F, $0B
	DW Deco_Tourian_Block : DB $10, $0B
	DW Deco_Tourian_Block : DB $11, $0B
	DW Deco_Tourian_Lense : DB $12, $0B
	DW Deco_Tourian_Block : DB $0A, $13
	DW Deco_Tourian_SmallBlocks : DB $0C, $13

	DW Deco_Tourian_Lense : DB $15, $0C
	DW Deco_Tourian_SmallBlocks : DB $16, $0D
	DW Deco_Tourian_Block : DB $16, $0E
	DW Deco_Tourian_Lense : DB $15, $0F
	DW Deco_Tourian_Block : DB $15, $10
	DW Deco_Tourian_Lense : DB $13, $11
	DW Deco_Tourian_SmallBlocks : DB $14, $11
	DW Deco_Tourian_SmallBlocks : DB $12, $12
	DW Deco_Tourian_Block : DB $13, $12
	DW Deco_Tourian_SmallBlocks : DB $15, $12
	DW Deco_Tourian_Block : DB $16, $12
	DW Deco_Tourian_SmallBlocks : DB $14, $13
	DW $0000
}

MapDecoration_List_Colony: {
	DW Deco_Colony_Maptile : DB $0C, $0B
	DW $0000
}


;Crateria {
Deco_Crateria_Cloudstart:
	DB $02 : DW $4B01, $4B00
	DB $02 : DW $CB01, $8B00
	DB $FF
Deco_Crateria_Cloud:
	DB $06 : DW $0B00, $0B00, $4B00, $0B00, $4B00, $4B00
	DB $06 : DW $8B00, $CB00, $8B00, $8B00, $CB00, $8B00
	DB $FF
Deco_Crateria_Cloudend:
	DB $02 : DW $4B00, $0B01
	DB $02 : DW $8B00, $8B01
	DB $FF

Deco_Crateria_Waterstart:
	DB $02 : DW $4B17, $0B05
	DB $02 : DW $CB17, $8B08
	DB $02 : DW $4B17, $8B06
	DB $02 : DW $4B16, $0B15
	DB $FF
Deco_Crateria_Water:
	DB $04 : DW $0B05, $0B05, $0B05, $0B05
	DB $04 : DW $8B09, $0B06, $0B07, $8B08
	DB $04 : DW $8B07, $0B08, $0B09, $8B06
	DB $04 : DW $0B15, $0B15, $0B15, $0B15
	DB $FF
Deco_Crateria_Waterend:
	DB $02 : DW $0B05, $0B17
	DB $02 : DW $8B09, $8B17
	DB $02 : DW $8B07, $0B17
	DB $02 : DW $0B15, $0B16
	DB $FF

Deco_Crateria_Shippart:
	DB $05 : DW $0B02, $0B03, $0B04, $4B03, $4B02
	DB $FF
Deco_Crateria_Shippart_DamagedLeft:
	DB $05 : DW $0B12, $0B13, $0B04, $4B03, $4B02
	DB $05 : DW $0B12, $0B03, $0B04, $4B03, $4B02
	DB $FF
Deco_Crateria_Shippart_DamagedMiddle:
	DB $05 : DW $0B02, $0B13, $0B14, $4B03, $4B02
	DB $FF
Deco_Crateria_Shippart_DamagedRight:
	DB $05 : DW $0B12, $0B03, $0B04, $4B03, $4B12
	DB $05 : DW $0B02, $0B03, $0B04, $4B13, $4B12
	DB $FF
Deco_Crateria_Shipground:
	DB $05 : DW $0B12, $0B13, $0B14, $4B13, $4B12
	DB $05 : DW $0B10, $0B11, $4B11, $0B11, $4B10
	DB $FF

Deco_Crateria_Brick:
	DB $02 : DW $0B18, $CB18
	DB $FF
Deco_Crateria_Mushroom:
	DB $02 : DW $0B0A, $4B0A
	DB $02 : DW $0B0B, $CB0B
	DB $02 : DW $0B0B, $CB0B
	DB $FF

Deco_Crateria_Maptile_MainAreaTop:
	DB $07 : DW $1C25, $1C62, $1C62, $1C62, $1C62, $1C62, $5C25
	DB $FF
Deco_Crateria_Maptile_MainAreaMiddle:
	DB $07 : DW $1C72, $1C02, $1C02, $1C02, $1C02, $1C02, $5C72
	DB $FF
Deco_Crateria_Maptile_MainAreaBottom:
	DB $07 : DW $9C74, $9C62, $9C62, $9C62, $9C62, $9C62, $DC25
	DB $FF
Deco_Crateria_Maptile_Shaft:
	DB $06 : DW $1C21, $1C52, $1C75, $5C15, $1C15, $1C52
	DB $03 : DW $1C1A, $0000, $1C1A
	DB $03 : DW $1C1A, $0000, $9C0A
	DB $01 : DW $1C1A
	DB $01 : DW $9C0A
	DB $01 : DW $1C0A
	DB $01 : DW $1C1A
	DB $01 : DW $1C1A
	DB $01 : DW $1C1A
	DB $01 : DW $1C1A
	DB $01 : DW $1C1A
	DB $01 : DW $1C1A
	DB $01 : DW $1C1A
	DB $05 : DW $9C0A, $1C15, $1C52, $5C15, $1C5C
	DB $FF
Deco_Crateria_Maptile_Elevator:
	DB $01 : DW $1C7E
	DB $01 : DW $1C7E
	DB $01 : DW $1C7F
	DB $FF
}

;Brinstar {
Deco_Brinstar_Vine_Left:
	DB $02 : DW $0B20, $0B21
	DB $02 : DW $0B30, $0B31
	DB $FF

Deco_Brinstar_Ground_Start:
	DB $01 : DW $0B32
	DB $FF
Deco_Brinstar_Ground_End:
	DB $01 : DW $4B32
	DB $FF

Deco_Brinstar_Ground_Down:
	DB $01 : DW $0B22
	DB $FF
Deco_Brinstar_Ground_Long:
	DB $05 : DW $0B22, $0B22, $0B22, $0B22, $0B22
	DB $FF

Deco_Brinstar_Wall_Left:
	DB $01 : DW $0B33
	DB $01 : DW $0B33
	DB $01 : DW $0B33
	DB $01 : DW $0B33
	DB $FF

Deco_Brinstar_Corner_DownLeft:
	DB $01 : DW $0B23
	DB $FF

Deco_Brinstar_Grass:
	DB $02 : DW $0B26, $0B27
	DB $FF

Deco_Brinstar_Pillar_Small:
	DB $01 : DW $0B25
	DB $01 : DW $0B24
	DB $01 : DW $0B34
	DB $FF
Deco_Brinstar_Pillar_Long:
	DB $01 : DW $0B25
	DB $01 : DW $0B24
	DB $01 : DW $0B24
	DB $01 : DW $0B34
	DB $FF

Deco_Brinstar_Block_Big_Left:
	DB $02 : DW $0B28, $0B29
	DB $02 : DW $0B38, $0B39
	DB $FF
Deco_Brinstar_Block_Small_Left:
	DB $02 : DW $0B35, $0B36
	DB $FF
Deco_Brinstar_Block_Left:
	DB $01 : DW $0B37
	DB $FF
Deco_Brinstar_Block_Big_Right:
	DB $02 : DW $4B29, $4B28
	DB $02 : DW $4B39, $4B38
	DB $FF
Deco_Brinstar_Block_Small_Right:
	DB $02 : DW $4B36, $4B35
	DB $FF
Deco_Brinstar_Block_Right:
	DB $01 : DW $4B37
	DB $FF

Deco_Brinstar_Vine:
	DB $06 : DW $0B2B, $4B2A, $4B3A, $0000, $CB3A, $4B2A
	DB $03 : DW $0000, $8B3A, $4B2A
	DB $07 : DW $0000, $0000, $0B2B, $CB3A, $0000, $0000, $4B2A
	DB $08 : DW $4B2B, $0B2A, $0B3A, $0000, $8B3A, $0B3A, $0000, $4B2B
	DB $FF

Deco_Brinstar_Maptile_Main:
	DB $02 : DW $0000, $9C7F
	DB $02 : DW $0000, $1C7E
	DB $02 : DW $0000, $1C7E
	DB $08 : DW $1C15, $1C52, $1C52, $5C15, $1C0A, $1C15, $1C52, $5C15
	DB $05 : DW $0000, $0000, $0000, $1C5C, $9C0A
	DB $FF
}

;Norfair {
Deco_Norfair_Ground_Floor:
	DB $01 : DW $0B54
	DB $FF
Deco_Norfair_Ground_Down_SlopeDiagonalLeft:
	DB $02 : DW $0B40, $0B41
	DB $02 : DW $0B50, $0B51
	DB $FF
Deco_Norfair_Ground_Down_SlopeDiagonalRight:
	DB $02 : DW $4B41, $4B40
	DB $02 : DW $4B51, $4B50
	DB $FF

Deco_Norfair_Ground_Ceiling:
	DB $01 : DW $8B54
	DB $FF
Deco_Norfair_Ground_Ceiling_Long:
	DB $05 : DW $8B54, $8B54, $8B54, $8B54, $8B54
	DB $FF
Deco_Norfair_Ground_Ceiling_Bubble:
	DB $01 : DW $8B54
	DB $01 : DW $0B47
	DB $FF
Deco_Norfair_Ground_Ceiling_Stalagmite:
	DB $01 : DW $8B54
	DB $01 : DW $0B55
	DB $FF
Deco_Norfair_Ground_Up_SlopeDiagonalLeft:
	DB $02 : DW $CB51, $CB50
	DB $02 : DW $CB41, $CB40
	DB $FF
Deco_Norfair_Ground_Up_SlopeDiagonalRight:
	DB $02 : DW $8B50, $8B51
	DB $02 : DW $8B40, $8B41
	DB $FF

Deco_Norfair_Wall_Left:
	DB $01 : DW $0B44
	DB $FF
Deco_Norfair_Wall_Left_SlopeDiagonalLeft:
	DB $02 : DW $8B52, $8B53
	DB $02 : DW $8B42, $8B43
	DB $FF
Deco_Norfair_Wall_Left_SlopeDiagonalRight:
	DB $02 : DW $0B42, $0B43
	DB $02 : DW $0B52, $0B53
	DB $FF

Deco_Norfair_Wall_Right:
	DB $01 : DW $4B44
	DB $FF
Deco_Norfair_Wall_Right_SlopeDiagonalLeft:
	DB $02 : DW $4B43, $4B42
	DB $02 : DW $4B53, $4B52
	DB $FF
Deco_Norfair_Wall_Right_SlopeDiagonalRight:
	DB $02 : DW $CB53, $CB52
	DB $02 : DW $CB43, $CB42
	DB $FF

Deco_Norfair_Corner_UpLeft:
	DB $01 : DW $8B45
	DB $FF
Deco_Norfair_Corner_DownLeft:
	DB $01 : DW $0B45
	DB $FF
Deco_Norfair_Corner_UpRight:
	DB $01 : DW $CB45
	DB $FF
Deco_Norfair_Corner_DownRight:
	DB $01 : DW $4B45
	DB $FF

Deco_Norfair_Bubble_Part1:
	DB $01 : DW $0B48
	DB $FF
Deco_Norfair_Bubble_Part2:
	DB $01 : DW $4B48
	DB $FF
Deco_Norfair_Bubble_Full:
	DB $01 : DW $0B49
	DB $FF

Deco_Norfair_Pillar_Top:
	DB $04 : DW $0000, $0000, $0B4A, $0B4B
	DB $04 : DW $0000, $0B57, $0B5A, $0B59
	DB $04 : DW $0B57, $0B58, $0B5B, $4B57
	DB $FF
Deco_Norfair_Pillar_Left:
	DB $03 : DW $0B57, $0B58, $0B59
	DB $FF
Deco_Norfair_Pillar_Right:
	DB $03 : DW $4B59, $4B58, $4B57
	DB $FF
Deco_Norfair_Pillar_Small:
	DB $04 : DW $4B4B, $4B4A, $0000, $0000
	DB $04 : DW $4B59, $4B5A, $4B57, $0000
	DB $04 : DW $0B57, $4B5B, $4B58, $4B57
	DB $FF

Deco_Norfair_Acid:
	DB $04 : DW $0B46, $0B46, $0B46, $0B46
	DB $04 : DW $0B56, $0B56, $0B56, $0B56
	DB $FF

Deco_Norfair_Maptile_West:
	DB $04 : DW $1C0A, $1C15, $5C15, $1C0A
	DB $04 : DW $1C1A, $0000, $0000, $1C1A
	DB $07 : DW $9C0A, $1C15, $5C15, $9C21, $1C52, $1C52, $5C15
	DB $FF
Deco_Norfair_Maptile_Main:
	DB $02 : DW $0000, $9C7F
	DB $02 : DW $0000, $1C7E
	DB $02 : DW $0000, $1C0A
	DB $08 : DW $0000, $1C1A, $1C25, $1C62, $5C25, $1C25, $1C62, $5C25
	DB $08 : DW $1C5C, $1C1A, $9C25, $9C62, $DC25, $9C25, $9C62, $DC25
	DB $03 : DW $1C5C, $1C1A, $1C5C
	DB $02 : DW $0000, $9C0A
	DB $FF
}

;Wrecked Ship {
Deco_WreckedShip_Wall_Left:
	DB $04 : DW $0B61, $0B61, $0B71, $0B61
	DB $04 : DW $0B61, $0B61, $0B61, $0B61
	DB $FF
Deco_WreckedShip_Wall_Right:
	DB $04 : DW $0B71, $0B61, $0B61, $0B61
	DB $04 : DW $0B61, $0B61, $0B61, $0B61
	DB $FF

Deco_WreckedShip_Wall_Single:
	DB $01 : DW $0B61
	DB $FF
Deco_WreckedShip_Wall_Dirty:
	DB $01 : DW $0B70
	DB $FF
Deco_WreckedShip_Wall_Lamp:
	DB $01 : DW $0B71
	DB $FF

Deco_WreckedShip_End_Left:
	DB $01 : DW $0B60
	DB $01 : DW $0B60
	DB $FF
Deco_WreckedShip_End_Right:
	DB $01 : DW $4B60
	DB $01 : DW $4B60
	DB $FF

Deco_WreckedShip_StepLeft:
	DB $03 : DW $0B64, $0B65, $0B66
	DB $03 : DW $0000, $0B75, $0B76
	DB $FF
Deco_WreckedShip_StepRight:
	DB $02 : DW $0B62, $0B63
	DB $03 : DW $0B72, $0B73, $0B74
	DB $FF

Deco_WreckedShip_Maptile_Top:
	DB $0A : DW $1C15, $1C52, $1C52, $1C52, $1C52, $1C52, $5C15, $1C15, $1C52, $5C15
	DB $FF
Deco_WreckedShip_Maptile_Shaft:
	DB $01 : DW $1C0A
	DB $01 : DW $1C1A
	DB $01 : DW $1C1A
	DB $01 : DW $1C1A
	DB $01 : DW $9C0A
	DB $01 : DW $9C0A
	DB $FF
Deco_WreckedShip_Maptile_Entrance:
	DB $04 : DW $1C15, $1C52, $1C52, $5C15
	DB $FF
Deco_WreckedShip_Maptile_Bottom:
	DB $07 : DW $1C5C, $1C15, $1C52, $1C52, $1C52, $5C15, $1C5C
	DB $FF
}

;Maridia {
Deco_Maridia_Ground_Floor:
	DB $01 : DW $0BA0
	DB $FF
Deco_Maridia_Ground_Down_SlopeDiagonalLeft:
	DB $02 : DW $0B90, $0B91
	DB $02 : DW $0000, $0BA1
	DB $FF
Deco_Maridia_Ground_Down_SlopeDiagonalRight:
	DB $02 : DW $4B91, $4B90
	DB $02 : DW $4BA1, $0000
	DB $FF

Deco_Maridia_Ground_Ceiling:
	DB $01 : DW $8BA0
	DB $FF
Deco_Maridia_Ground_Up_SlopeDiagonalLeft:
	DB $02 : DW $CBA1, $0000
	DB $02 : DW $CB91, $CB90
	DB $FF
Deco_Maridia_Ground_Up_SlopeDiagonalRight:
	DB $02 : DW $0000, $8BA1
	DB $02 : DW $8B90, $8B91
	DB $FF

Deco_Maridia_Wall_Left:
	DB $01 : DW $0B92
	DB $FF
Deco_Maridia_Wall_Left_SlopeDiagonalLeft:
	DB $02 : DW $8BA2, $8BA3
	DB $02 : DW $0000, $8B93
	DB $FF
Deco_Maridia_Wall_Left_SlopeDiagonalRight:
	DB $02 : DW $0000, $0B93
	DB $02 : DW $0BA2, $0BA3
	DB $FF


Deco_Maridia_Quicksand:
	DB $03 : DW $0B9A, $0B9A, $0B9A
	DB $03 : DW $0BAA, $0BAA, $0BAA
	DB $FF


Deco_Maridia_Crystal_Small:
	DB $01 : DW $0B97
	DB $01 : DW $0B99
	DB $FF
Deco_Maridia_Crystal_Large:
	DB $01 : DW $0B97
	DB $01 : DW $0B98
	DB $01 : DW $0B99
	DB $FF


Deco_Maridia_Tube_Horizontal:
	DB $05 : DW $0B95, $0B95, $0BA5, $0B95, $0B95
	DB $FF
Deco_Maridia_Tube_Damaged:
	DB $01 : DW $0BA7
	DB $01 : DW $0BA8
	DB $01 : DW $0BA8
	DB $01 : DW $0BA8
	DB $01 : DW $0BA8
	DB $01 : DW $0BA8
	DB $FF
Deco_Maridia_Tube_Vertical:
	DB $01 : DW $0BA6
	DB $01 : DW $0B96
	DB $01 : DW $0B96
	DB $01 : DW $0BA6
	DB $01 : DW $0B96
	DB $FF
Deco_Maridia_Tube_Curve_DownLeft:
	DB $01 : DW $0BA4
	DB $FF
Deco_Maridia_Tube_Curve_DownRight:
	DB $01 : DW $4BA4
	DB $FF
Deco_Maridia_Tube_Curve_UpLeft:
	DB $01 : DW $8BA4
	DB $FF
Deco_Maridia_Tube_Curve_UpRight:
	DB $01 : DW $CBA4
	DB $FF

Deco_Maridia_Tube_FancyCurved:
	DB $03 : DW $0000, $0000, $0B96
	DB $03 : DW $4BA4, $0BA5, $8BA4
	DB $01 : DW $0B96
	DB $FF

Deco_Maridia_TransportTube:
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DB $01 : DW $0B94
	DW $FF

Deco_Maridia_Maptile_Corridor:
	DB $03 : DW $1C54, $1C5C, $1C54
	DB $FF
}

;Tourian {
Deco_Tourian_Pipe_Horizontal:
	DB $05 : DW $0B95, $0B95, $0B95, $0B95, $0B95
	DB $FF
Deco_Tourian_Pipe_Horizontal_Single:
	DB $01 : DW $0B95
	DB $FF
Deco_Tourian_Pipe_Vertical:
	DB $01 : DW $0B96
	DB $01 : DW $0B96
	DB $FF
Deco_Tourian_Pipe_T_Up:
	DB $01 : DW $0BB1
	DB $FF
Deco_Tourian_Pipe_End_Left:
	DB $01 : DW $4BB0
	DB $FF
Deco_Tourian_Pipe_End_Right:
	DB $01 : DW $0BB0
	DB $FF

Deco_Tourian_SmallBlocks:
	DB $01 : DW $0BC0
	DB $FF
Deco_Tourian_Lense:
	DB $01 : DW $0BC1
	DB $FF
Deco_Tourian_Block:
	DB $01 : DW $0BC2
	DB $FF
}

;Colony {
Deco_Colony_Maptile:
	DB $01 : DW $9C7F
	DB $01 : DW $1C7E
	DB $01 : DW $1C7E
	DB $01 : DW $1C0A
	DB $01 : DW $1C1A
	DB $04 : DW $9C0A, $1C15, $5C15, $1C0A
	DB $09 : DW $0000, $0000, $0000, $9C0A, $1C15, $5C15, $1C15, $5C15, $1C5C
	DB $FF
}
}
