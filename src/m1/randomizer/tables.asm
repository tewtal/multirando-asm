org $888000
brinstar_item_table:
.row_2
    ;Elevator to Tourian.
    db $02
    dw .row_3
    db $03, $05, $04, $03, $00
    
    ;Varia suit.
    db $0F, $FF, $02, $05, $37, $00

.row_3
    ;Missiles.
    db $03
    dw .row_5
    db $18, $06, $02, $09, $67, $00

    ;Energy tank.
    db $1B, $FF, $02, $08, $87, $00

.row_5
    ;Long beam.
    db $05
    dw .row_7
    db $07, $06, $02, $02, $37, $00

    ;Bombs.
    db $19, $FF, $02, $00, $37, $00

.row_7
    ;Palette change room.
    db $07
    dw .row_9
    db $0C, $04, $0A, $00

    ;Energy tank.
    db $19, $FF, $02, $08, $87, $00

.row_9
    ;Ice beam.
    db $09
    dw .row_b
    db $13, $06, $02, $07, $37, $00

    ;Mellows.
    db $15, $FF, $03, $00

.row_b
    ;Missiles.
    db $0B
    dw .row_e
    db $12, $06, $02, $09, $67, $00

    ;Elevator to Norfair.  
    db $16, $FF, $04, $01, $00

.row_e
    ;Maru Mari.
    db $0E
    dw .row_12
    db $02, $06, $02, $01, $96, $00

    ;Energy tank.
    db $09, $FF, $02, $08, $12, $00

.row_12
    ;Elevator to Kraid.
    db $12
    dw $FFFF
    db $07, $FF, $04, $02, $00

warnpc $888200
org $888200
norfair_item_table:
.row_a
    ;Missiles.
    db $0A                           ; Row number
    dw .row_b                        ; Address to the label of the next row
    db $1B, $06, $02, $09, $34, $00  ; Item data

    ;Missiles.
    db $1C, $FF, $02, $09, $34, $00  ; Item data

.row_b
    ;Elevator from Brinstar.
    db $0B                           ; Row number
    dw .row_c                        ; Address to the label of the next row
    db $16, $05, $04, $81, $00       ; Item data

    ;Missiles.
    db $1A, $06, $02, $09, $34, $00

    ;Missiles.
    db $1B, $06, $02, $09, $34, $00

    ;Missiles.
    db $1C, $FF, $02, $09, $34, $00

.row_c
    ;Ice beam.
    db $0C
    dw .row_d
    db $1A, $FF, $02, $07, $37, $00

.row_d
    ;Elevator to Brinstar.
	db $0D
	dw .row_e
	db $16, $FF, $04, $81, $00

.row_e
    ;Missiles.
	db $0E
	dw .row_f
	db $12, $FF, $02, $09, $34, $00

.row_f
    ;Missiles and Melias.
	db $0F
	dw .row_10
	db $11, $07, $02, $09, $34, $03, $00

    ;Missiles.
	db $13, $06, $02, $09, $34, $00

    ;Missiles.
	db $14, $06, $02, $09, $34, $00

    ;Squeept.
	db $15, $FF, $41, $8B, $E9, $51, $02, $9B, $00

.row_10
    ;Screw attack.
	db $10
	dw .row_11
	db $0F, $FF, $02, $03, $37, $00

.row_11
    ;Palette change room.
	db $11
	dw .row_13
	db $16, $04, $0A, $00

    ;Squeept.
	db $18, $09, $31, $0B, $E9, $41, $02, $9A, $00

    ;Squeept.
	db $19, $09, $21, $8B, $E9, $51, $02, $9A, $00

    ;High jump.
	db $1B, $06, $02, $01, $37, $00

    ;Right door.
	db $1D, $05, $09, $A0, $00

    ;Left door.
	db $1E, $FF, $09, $B0, $00

.row_13
    ;Energy tank.
	db $13
	dw .row_14
	db $1A, $FF, $02, $08, $42, $00

.row_14
    ;Right door.
	db $14
	dw .row_15
	db $0D, $05, $09, $A0, $00

    ;Left door.
	db $0E, $05, $09, $B0, $00

    ;Missiles.
	db $1C, $FF, $02, $09, $34, $00

.row_15
    ;Wave beam.
	db $15
	dw .row_16
	db $12, $06, $02, $06, $37, $00

    ;Right door(undefined room).
	db $17, $FF, $09, $A0, $00

.row_16
    ;Missiles.
	db $16
	dw $FFFF
	db $13, $06, $02, $09, $34, $00

    ;Missiles.
	db $14, $06, $02, $09, $34, $00

    ;Elevator to Ridley hideout.
	db $19, $FF, $04, $04, $00

warnpc $888400
org $888400
tourian_item_table:
.row_3
    ;Elevator to end.
	db $03
	dw .row_4
	db $01, $FF, $04, $8F, $00 

.row_4
    ;Elevator to Brinstar.
	db $04
	dw .row_7
	db $03, $FF, $04, $83, $00

.row_7
    ;10 missile door.
	db $07
	dw .row_8
	db $03, $05, $09, $A2, $00

    ;Rinkas
	db $04, $04, $08, $00

    ;Rinkas
	db $09, $FF, $08, $00

.row_8
    ;Rinkas
	db $08
	dw .row_9
	db $0A, $FF, $18, $00

.row_9
    ;Rinkas
	db $09
	dw .row_a
	db $0A, $FF, $08, $00

.row_a
    ;Rinkas
	db $0A
	dw .row_b
	db $0A, $FF, $18, $00

.row_b
    ;Door at bottom of escape shaft.
	db $0B
	dw $FFFF
	db $01, $05, $09, $A3, $00

    ;Mother brain, Zeebetite, 3 cannons and Rinkas.
	db $02, $0C, $06, $47, $18, $05, $49, $15, $4B, $25, $3E, $00

    ;2 Zeebetites, 6 cannons and Rinkas.
	db $03, $12, $37, $27, $08, $05, $41, $15, $43, $25, $36, $05, $49, $15, $4B, $35
	db $3E, $00

    ;Right door, 2 Zeebetites, 6 cannons and Rinkas.
	db $04, $14, $09, $A3, $17, $07, $08, $05, $41, $15, $43, $25, $36, $05, $49, $15
	db $4B, $35, $3E, $00

    ;Left door.
	db $05, $FF, $09, $B3, $00 

warnpc $888600
org $888600
kraid_item_table:
.row_12
    ;Elevator from Brinstar.
	db $12
	dw .row_14
	db $07, $FF, $04, $81, $00

.row_14
    ;Elevator to Brinstar.
	db $14
	dw .row_15
	db $07, $FF, $04, $82, $00

.row_15
    ;Missiles.
	db $15
	dw .row_16
	db $04, $06, $02, $09, $47, $00

    ;Missiles.
	db $09, $FF, $02, $09, $47, $00

.row_16
    ;Energy tank.
	db $16
	dw .row_19
	db $0A, $FF, $02, $08, $66, $00

.row_19
    ;Missiles.
	db $19
	dw .row_1b
	db $0A, $FF, $02, $09, $47, $00

.row_1b
    ;Missiles.
	db $1B
	dw .row_1c
	db $05, $FF, $02, $09, $47, $00

.row_1c
    ;Memus.
	db $1C
	dw .row_1d
	db $07, $FF, $03, $00

.row_1d
    ;Energy tank.
	db $1D
	dw $FFFF
	db $08, $FF, $02, $08, $BE, $00

warnpc $888800
org $888800
ridley_item_table:

.row_18
    ;Missiles.
	db $18
	dw .row_19
	db $12, $06, $02, $09, $6D, $00

    ;Elevator to Norfair.
	db $19, $FF, $04, $84, $00

.row_19
    ;Energy tank.
	db $19
	dw .row_1b
	db $11, $FF, $02, $08, $74, $0

.row_1b
    ;Missiles.
	db $1B
	dw .row_1d
	db $18, $FF, $02, $09, $6D, $00

.row_1d
    ;Energy tank.
	db $1D
	dw .row_1e
	db $0F, $FF, $02, $08, $66, $00

.row_1e
    ;Missiles.
	db $1E
	dw $FFFF
	db $14, $FF, $02, $09, $6D, $00


; Reserve space From A000-FFFF for eventual expansion of item tables.
warnpc $889000
org $889000
next_thing:

