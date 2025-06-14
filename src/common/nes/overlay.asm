;
; Layer 3 text overlay popups for items gotten in the NES games
;

!LAYER3_TILES = $6000   ; words
!LAYER3_TILEMAP = $5000 ; words

;
; We steal some SA-1 IRAM for this so we have access to fast unused RAM reserved just for this
;

pushpc
org !IRAM_OVERLAY_START
overlay_state: skip 2
overlay_scroll: skip 2
overlay_timer: skip 2
overlay_height:

org $7f0000
overlay_buffer:
pullpc

; Uploads the correct tileset to layer 3 and initializes it correctly
print "overlay_init = ", pc
overlay_init:
    ; Perform DMA to VRAM at $4000 to transfer tiles
    php

    ; Upload BG3 Tiles
    rep #$30
    lda #$1801
    sta $4320

    lda #(overlay_tile_data&$ffff)
    sta $4322
    lda #(overlay_tile_data>>16)
    sta $4324

    lda #(overlay_item_names-overlay_tile_data)
    sta $4325

    lda #!LAYER3_TILES
    sta $2116

    sep #$20

    lda #$80
    sta $2115

    lda #$04
    sta $420b

    ; Clear BG3
    rep #$20
    lda #(overlay_clear_byte&$ffff)
    sta $4322

    lda #$0A00
    sta $4325

    lda #!LAYER3_TILEMAP
    sta $2116

    sep #$20
    lda #$09
    sta $4320

    lda #$04
    sta $420b

    ; Upload overlay palette to color index 0C-0F
    lda #$0C
    sta $2121

    lda #$00
    sta $2122
    sta $2122

    lda #$c9
    sta $2122
    lda #$69
    sta $2122
    lda #$ff
    sta $2122
    lda #$7f
    sta $2122

    lda #$00
    sta $2122
    sta $2122

    ; Set BG3 visibility

    lda #(20<<2)+2
    sta $2109

    lda #$06
    sta $210c
    
    lda #$00
    sta $2111
    sta $2111
    sta $2112
    sta $2112

    lda #$15
    sta $212c

    lda #$09
    sta $2105

    plp
    rtl

; Run this every frame (inside NMI), this handles the animation and popup duration
overlay_handle:
    php
    rep #$30

    lda.w overlay_state     ; Exit if state is 0
    bne +
    jmp .end
+
    cmp.w #$0001            ; 1 = Initialize
    beq .init
    cmp.w #$0002            ; 2 = scroll up
    beq .scroll_up
    cmp.w #$0003            ; 3 = Wait for timer
    bne +
    jmp .wait
+
    cmp.w #$0004            ; 4 = Scroll down
    beq .scroll_down
    stz.w overlay_state       ; 5+ (reset state)
    jmp .end

.init
    ; Set up a DMA from 7f0000 to WRAM word $3380 and copy the textbox
    lda.w #$1801
    sta.w $4320

    lda.w #(overlay_buffer&$ffff)
    sta.w $4322
    lda.w #(overlay_buffer>>16)
    sta.w $4324

    lda.w #$0200
    sta.w $4325

    lda.w #(!LAYER3_TILEMAP+$380)
    sta.w $2116

    sep #$20

    lda.b #$80
    sta.w $2115

    lda.b #$04
    sta.w $420b    

    ; Set the overlay scroll to 0
    stz.w overlay_scroll
    ; Set the overlay mode to scrolling up (2)
    lda.b #$02
    sta.w overlay_state

    ; Write 0 to BG3 scroll
    stz.w $2112
    stz.w $2112

    rep #$30

    jmp .end

.scroll_up
    lda.w overlay_scroll
    cmp.w overlay_height
    beq .scroll_done
    inc
    sta.w overlay_scroll
    sep #$20
    sta.w $2112
    stz.w $2112
    rep #$20
    jmp .end

.scroll_down
    lda.w overlay_scroll
    beq .scroll_done
    dec
    sta.w overlay_scroll
    sep #$20
    sta.w $2112
    stz.w $2112
    rep #$20
    jmp .end

.scroll_done
    inc.w overlay_state
    jmp .end

.wait
    lda.w overlay_timer
    dec
    sta.w overlay_timer
    cmp.w #$0000
    bne .end
    inc.w overlay_state
.end
    plp
    rtl    


; Shows a single item name in the overlay (and scrolls the overlay up as needed)
overlay_show_item:
    pha
    phx
    phy
    php
    rep #$30
    pha     ; Item index in A

    ; Copy box outline to buffer
    ldx.w #$0000
-
    lda.l overlay_box, x
    sta.l overlay_buffer, x
    inx #2
    cpx.w #$0180
    bne -

    ; Get item table offset
    pla         ; Item index
    and.w #$00ff  ; Mask it off
    sep #$20    
    sta.w $4202
    lda.b #$34
    sta.w $4203   ; Multiply by 26 (text width)
    nop #2
    rep #$20
    ldx.w $4216   ; Table offset

    ; Write item name to buffer

    phb : pea $7f7f : plb : plb

    ldy.w #$0000
-
    lda.l overlay_item_names, x
    sta.w overlay_buffer+$46, y
    inx #2
    iny #2
    cpy.w #$0034
    bne -

    plb

    ; Set up overlay handler
    lda.w #$0014 : sta overlay_height ; Scroll 20 pixels
    lda.w #$0080 : sta overlay_timer  ; Wait for 0x80 frames (128)
    lda.w #$0001 : sta overlay_state  ; Set overlay init state

    plp
    ply
    plx
    pla
    rtl

overlay_clear_byte:
    db $00

overlay_tile_data:
    incbin ../../data/ovl_gfx.bin

overlay_item_names:
    table ../../data/tables/small_overlay.tbl,rtl
    dw "                          "
    dw "       Master Sword       "
    dw "      Tempered Sword      "
    dw "        Gold Sword        "
    dw "       Small Shield       "
    dw "        Red Shield        "
    dw "       Mirror Shield      "
    dw "         Fire Rod         "
    dw "         Ice Rod          "
    dw "          Hammer          "
    dw "         Hookshot         "
    dw "           Bow            "
    dw "      Blue Boomerang      "
    dw "       Magic Powder       "
    dw "                          "
    dw "          Bombos          "
    dw "          Ether           "
    dw "          Quake           "
    dw "           Lamp           "
    dw "          Shovel          "
    dw "          Flute           "
    dw "      Cane of Somaria     "
    dw "          Bottle          "
    dw "       Heart Piece        "
    dw "       Cane of Byrna      "
    dw "        Magic Cape        "
    dw "          Mirror          "
    dw "        Power Glove       "
    dw "       Titan's Mitt       "
    dw "      Book of Mudora      "
    dw "      Zora's Flippers     "
    dw "        Moon Pearl        "
    dw "                          "
    dw "     Bug-catching Net     "
    dw "         Blue Mail        "
    dw "          Red Mail        "
    dw "                          "
    dw "                          "
    dw "      Heart Container     "
    dw "          1 Bomb          "
    dw "          3 Bombs         "
    dw "         Mushroom         "
    dw "       Red Boomerang      "
    dw "        Red Potion        "
    dw "       Green Potion       "
    dw "       Blue Potion        "
    dw "                          "
    dw "                          "
    dw "                          "
    dw "         10 Bombs         "
    dw "                          "
    dw "                          "
    dw "          1 Rupee         "
    dw "         5 Rupees         "
    dw "         20 Rupees        "
    dw "                          "
    dw "                          "
    dw "                          "
    dw "           Bow            "
    dw "       Silver Arrows      "
    dw "           Bee            "
    dw "          Fairy           "
    dw "      Heart Container     "
    dw "      Heart Container     "
    dw "        100 Rupees        "
    dw "         50 Rupees        "
    dw "                          "
    dw "         1 Arrow          "
    dw "         10 Arrows        "
    dw "                          "
    dw "        300 Rupees        "
    dw "         20 Rupees        "
    dw "         Good Bee         "
    dw "      Fighter's Sword     "
    dw "                          "
    dw "       Pegasus Boots      "
    dw "                          "
    dw "                          "
    dw "        Half Magic        "
    dw "       Quarter Magic      "
    dw "       Master Sword       "
    dw "      5 Bomb capacity     "
    dw "     10 Bomb capacity     "
    dw "      5 Arrow capacity    "
    dw "     10 Arrow capacity    "
    dw "                          "
    dw "                          "
    dw "                          "
    dw "       Silver arrows      " ; 58
    dw "                          "
    dw "                          "
    dw "                          "
    dw "                          "
    dw "                          "
    dw "       Sword Upgrade      "
    dw "      Shield Upgrade      "
    
    dw "      Armour Upgrade      "  ; 60
    dw "       Glove Upgrade      "
    dw "         M1 Bombs         "
    dw "       M1 High Jump       "
    dw "          ProgBow         "
    dw "          ProgBow         "
    dw "       M1 Long Beam       "
    dw "      M1 Screw Attack     "
    dw "       M1 Morph Ball      "
    dw "       M1 Varia Suit      "
    dw "         Goal Single      "
    dw "      Triforce Shard      "
    dw "       M1 Wave Beam       "
    dw "        M1 Ice Beam       "
    dw "         M1 ETank         "
    dw "        M1 Missiles       " ; 6F

    dw "   Crateria L 1 Keycard   " ; 70
    dw "   Crateria L 2 Keycard   "
    dw "     Ganon's Tower Map    "
    dw "     Turtle Rock Map      "
    dw "     Thieves' Town Map    "
    dw "    Tower of Hera Map     "
    dw "      Ice Palace Map      "
    dw "      Skull Woods Map     "
    dw "      Misery Mire Map     "
    dw "  Palace of Darkness Map  "
    dw "      Swamp Palace Map    "
    dw "  Crateria Boss Keycard   "
    dw "     Desert Palace Map    "
    dw "    Eastern Palace Map    "
    dw "   Maridia Boss Keycard   "
    dw "     HYRULE CASTLE Map    " ; 7F

    dw "   Brinstar L 1 Keycard   " ; 80
    dw "   Brinstar L 2 Keycard   "
    dw "   Ganon's Tower Compass  "
    dw "   Turtle Rock Compass    "
    dw "   Thieves' Town Compass  "
    dw "  Tower of Hera Compass   "
    dw "    Ice Palace Compass    "
    dw "    Skull Woods Compass   "
    dw "    Misery Mire Compass   "
    dw "Palace of Darkness Compass"
    dw "    Swamp Palace Compass  "
    dw "  Brinstar Boss Keycard   "
    dw "   Desert Palace Compass  "
    dw "  Eastern Palace Compass  "
    dw " Wrecked Ship L 1 Keycard "
    dw " Wrecked Ship Boss Keycard" ; 8F

    dw "    Norfair L 1 Keycard   " ; 90
    dw "    Norfair L 2 Keycard   "
    dw "   Ganon's Tower Big Key  "
    dw "   Turtle Rock Big Key    "
    dw "  Thieves' Town Big Key   "
    dw "  Tower of Hera Big Key   "
    dw "    Ice Palace Big Key    "
    dw "    Skull Woods Big Key   "
    dw "    Misery Mire Big Key   "
    dw "Palace of Darkness Big Key"
    dw "   Swamp Palace Big Key   "
    dw "   Norfair Boss Keycard   "
    dw "   Desert Palace Big Key  "
    dw "  Eastern Palace Big Key  "
    dw "Lower Norfair L 1 Keycard "
    dw "Lower Norfair Boss Keycard" ; 9F    

    dw "     Hyrule Castle Key    " ; A0
    dw "        Sewers Key        "
    dw "    Eastern Palace Key    "
    dw "     Desert Palace Key    "
    dw "      Castle Tower Key    "
    dw "      Swamp Palace Key    "
    dw "  Palace of Darkness Key  "
    dw "      Misery Mire Key     "
    dw "      Skull Woods Key     "
    dw "       Ice Palace Key     "
    dw "     Tower of Hera Key    "
    dw "     Thieves' Town Key    "
    dw "      Turtle Rock Key     "
    dw "      Ganon's Tower Key   "
    dw "    Maridia L 1 Keycard   "
    dw "    Maridia L 2 Keycard   " ; AF    

    dw "      Grappling Beam      " ; B0
    dw "       X-Ray Scope        "
    dw "        Varia Suit        "
    dw "       Spring Ball        "
    dw "       Morphing Ball      "
    dw "       Screw Attack       "
    dw "       Gravity Suit       "
    dw "       Hi-Jump Boots      "
    dw "        Space Jump        "
    dw "          Bombs           "
    dw "       Speed Booster      "
    dw "       Charge Beam        "
    dw "         Ice Beam         "
    dw "        Wave Beam         "
    dw "     ~ S p A z E r ~      "
    dw "       Plasma Beam        " ; Bf
    
    dw "      An Energy Tank      " ; C0
    dw "      A Reserve Tank      "
    dw "         Missiles         "
    dw "       Super Missiles     "
    dw "        Power Bombs       "
    dw "                          "  
    dw "                          "  
    dw "                          "  
    dw "                          "  
    dw "                          "  
    dw "        Brinstar Map      "  
    dw "      Wrecked Ship Map    "  
    dw "        Maridia Map       "  
    dw "     Lower Norfair Map    "  
    dw "                          "  
    dw "                          " ; CF

    dw "         Z1 Bombs         " ; D0
    dw "      Z1 Wooden Sword     " ;
    dw "       Z1 White Sword     " ;
    dw "      Z1 Magical Sword    " ;
    dw "          Z1 Bait         " ;
    dw "        Z1 Recorder       " ;
    dw "       Z1 Blue Candle     " ;
    dw "        Z1 Red Candle     " ;
    dw "        Z1 Arrows         " ;
    dw "      Z1 Silver Arrows    " ;
    dw "          Z1 Bow          " ;
    dw "       Z1 Magical Key     " ;
    dw "          Z1 Raft         " ;
    dw "       Z1 Stepladder      " ;
    dw "         Z1 Unused?       " ;
    dw "        Z1 5 Rupees       " ; DF

    dw "      Z1 Magical Rod      " ; E0
    dw "     Z1 Book of Magic     " ;
    dw "       Z1 Blue Ring       " ;
    dw "       Z1 Red Ring        " ;
    dw "     Z1 Power Bracelet    " ;
    dw "         Z1 Letter        " ;
    dw "         Z1 Compass       " ;
    dw "       Z1 Dungeon Map     " ;
    dw "         Z1 1 Rupee       " ;
    dw "        Z1 Small Key      " ;
    dw "     Z1 Heart Container   " ;
    dw "    Z1 Triforce Fragment  " ;
    dw "     Z1 Magical Shield    " ;
    dw "       Z1 Boomerang       " ;
    dw "    Z1 Magical Boomerang  " ;
    dw "       Z1 Blue Potion     " ; EF

    dw "       Z1 Red Potion      " ; F0
    dw "         Z1 Clock         " ;
    dw "      Z1 Small Heart      " ;
    dw "         Z1 Fairy         " ;
    dw "                          " ;
    dw "                          " ;
    dw "                          " ;
    dw "                          " ;
    dw "                          " ;
    dw "                          " ;
    dw "                          " ;
    dw "                          " ;
    dw "                          " ;
    dw "                          " ;
    dw "                          " ;
    dw "                          " ; FF

overlay_box:
    table ../../data/tables/box_overlay.tbl,rtl
    dw "~~/--------------------------\~~"
    dw "~~[                          ]~~"
    dw "~~[                          ]~~"
    dw "~~[                          ]~~"
    dw "~~[                          ]~~"
    cleartable
