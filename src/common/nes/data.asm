new_item_graphics:
    incbin "../../data/newitems_nes.bin"

new_item_palettes:
;  Extend custom colors to upper 12 colors of sprite palettes #1 -> 3 to cover red, blue, and green z3 items
    ;  Sprite palette e1:
	db $ff, $7f, $ff, $7f, $ff, $7f, $ff, $7f, $00, $00, $dc, $39, $b6, $14, $96, $10
    db $ff, $7f, $df, $19, $d9, $00, $a5, $14, $79, $15, $a5, $14, $f7, $66, $00, $00
    ;  Sprite palette e2:
	db $ff, $7f, $ff, $7f, $ff, $7f, $ff, $7f, $00, $00, $b2, $76, $aa, $55, $c9, $69
    db $ff, $7f, $ff, $7f, $a5, $14, $a5, $14, $ff, $7f, $a5, $14, $f7, $66, $00, $00
    ;  Sprite palette e3:
	db $ff, $7f, $ff, $7f, $ff, $7f, $ff, $7f, $00, $00, $53, $3b, $49, $1a, $49, $1a
    db $ff, $7f, $59, $1e, $b0, $10, $a5, $14, $ff, $7f, $a5, $14, $f7, $66, $a5, $14

;  Original SM-ish palette colors
    db $00, $00, $DF, $02, $D7, $01, $AC, $00, $F5, $5D, $0E, $3D, $AA, $28, $23, $14
    db $B1, $0B, $FB, $48, $FF, $7F, $00, $00, $FF, $7F, $E5, $44, $FF, $7F, $00, $00
    db $63, $44, $B1, $0B, $A9, $1E, $45, $01, $BB, $5E, $B3, $3D, $2E, $29, $86, $14
    db $18, $63, $E7, $1C, $84, $10, $00, $00, $FF, $7F, $DF, $02, $1F, $00, $00, $00
    db $63, $44, $BC, $72, $FB, $48, $16, $18, $84, $14, $63, $10, $21, $08, $00, $04
    db $EF, $01, $AD, $01, $6B, $01, $29, $01, $E7, $04, $A5, $04, $FF, $7F, $00, $00
    db $63, $44, $B2, $72, $C7, $71, $03, $4D, $95, $52, $F0, $3D, $6C, $2D, $09, $21
    db $18, $63, $18, $63, $18, $63, $18, $63, $18, $63, $18, $63, $18, $63, $00, $00