; SM Message box patches

; Hooks
; $85:81EA 22 0C 8F 80 JSL $808F0C[$80:8F0C]  ; Handle music queue
; Hook to DMA lowercase font data into VRAM
org $8581ea
    jsl msg_copy_charset
org $85861f
    jsl msg_restore_vram : nop

table ../../data/tables/box.tbl,rtl

org $85877f
dw "______    Energy Tank    _______"

org $8587bf
dw "___          Missile         ___"

org $8588bf
dw "___      Super Missile       ___"

org $8589bf
dw "___        Power Bomb        ___"

org $858abf
dw "___      Grappling Beam      ___"

org $858bbf
dw "___        X-Ray Scope       ___"

org $858cbf
dw "______    Varia Suit     _______"
dw "______    Spring Ball    _______"
dw "______   Morphing Ball   _______"
dw "______    Screw Attack   _______"
dw "______   Hi-Jump Boots   _______"
dw "______     Space Jump    _______"

org $858e3f
dw "___       Speed Booster      ___"

org $858f3f
dw "______    Charge Beam    _______"
dw "______     Ice Beam      _______"
dw "______     Wave Beam     _______"
dw "______  ~ S p A z E r ~  _______"
dw "______    Plasma Beam    _______"

org $85907f
dw "___           Bomb           ___"

org $85917f
dw "______  Map data access  _______"
dw "______                   _______"
dw "______     Completed     _______"

dw "______  Energy recharge  _______"
dw "______                   _______"
dw "______     Completed     _______"

dw "______  Missile reload   _______"
dw "______                   _______"
dw "______     Completed     _______"

dw "______  Would you like   _______"
dw "______  to save?         _______"
dw "______                   _______"

org $8594bf
dw "______  Save completed   _______"
dw "______   Reserve Tank    _______"
dw "______   Gravity Suit    _______"

cleartable

; Routines
org $88f000
msg_copy_charset:
    rep #$30

    ; Get the correct pointer into BG3 tilemap
    lda $005d
    asl #4
    and #$f000
    clc
    adc #$0400

    sta $2116
    lda #$1801
    sta $4310
    lda.w #lowercase_charset
    sta $4312
    lda.w #lowercase_charset>>16
    sta $4314
    lda #$0300
    sta $4315
    stz $4317
    stz $4319
    sep #$20
    lda #$80
    sta $2115
    lda #$02
    sta $420b

    jsl $808F0C
    rtl
    
msg_restore_vram:
    rep #$20

    ; Get the correct pointer into BG3 tilemap
    lda $005d
    asl #4
    and #$f000
    clc
    adc #$0400
    
    sta $2116
    lda #$1801
    sta $4310
    lda.w #$ba00
    sta $4312
    lda.w #$009a
    sta $4314
    lda #$0300
    sta $4315
    stz $4317
    stz $4319
    sep #$20
    lda #$80
    sta $2115
    lda #$02
    sta $420b
    rep #$20
    lda #$5880
    rtl    

lowercase_charset:
    incbin "../../data/lowercase.bin"
