!Big = #$825A
!Small = #$8289
!EmptySmall = #$8436
!Shot = #$83C5
!Dash = #$83CC
!Jump = #$8756
!ItemCancel = #$875D
!ItemSelect = #$8764
!AimDown = #$876B
!AimUp = #$8773

!EmptyBig = #EmptyBig
!NormalBig = #NormalBig
!PlaceholderBig = #PlaceholderBig
!DungeonItemBig = #DungeonItemBig
!DungeonKeyItemBig = #DungeonKeyItemBig
!KeycardBig = #KeycardBig
!MapMarkerBig = #MapMarkerBig

!BossRewardSmall = #BossRewardSmall

org $D0A000
item_message_table:
    ; Offset = ALTTP SRAM Offset
    ; Value = Value to write/add to offset
    ; Type = Type of item (Item / Amount / ...)
    ; Message = Id of message box to show    

    ;  Message
    dw $001D       ; 00 Dummy - L1SwordAndShield 
    dw $001D       ; 01 Master Sword
    dw $001D       ; 02 Tempered Sword
    dw $001D       ; 02 Gold Sword
    dw $001D       ; 04 Shield
    dw $001D       ; 05 Red Shield
    dw $001D       ; 06 Mirror Shield
    dw $001D       ; 07 Firerod
    dw $001D       ; 08 Icerod  
    dw $001D       ; 09 Hammer
    dw $001D       ; 0A Hookshot
    dw $001D       ; 0B Bow                       
    dw $001D       ; 0C Blue Boomerang
    dw $001D       ; 0D Powder
    dw $001D       ; 0E Dummy - Bee (bottle content)
    dw $001D       ; 0F Bombos
    
    dw $001D       ; 10 Ether
    dw $001D       ; 11 Quake
    dw $001D       ; 12 Lamp
    dw $001D       ; 13 Shovel
    dw $001D       ; 14 Flute                      
    dw $001D       ; 15 Somaria
    dw $001D       ; 16 Bottle
    dw $001D       ; 17 Piece of Heart
    dw $001D       ; 18 Byrna
    dw $001D       ; 19 Cape
    dw $001D       ; 1A Mirror
    dw $001D       ; 1B Glove
    dw $001D       ; 1C Mitt
    dw $001D       ; 1D Book
    dw $001D       ; 1E Flippers
    dw $001D       ; 1F Pearl
    
    dw $001D       ; 20 Dummy 
    dw $001D       ; 21 Net
    dw $001D       ; 22 Blue Tunic
    dw $001D       ; 23 Red Tunic
    dw $001D       ; 24 Dummy - key
    dw $001D       ; 25 Dummy - compass
    dw $001D       ; 26 Heart Container - no anim
    dw $001D       ; 27 Bomb 1
    dw $001D       ; 28 3 Bombs                    
    dw $001D       ; 29 Mushroom
    dw $001D       ; 2A Red Boomerang
    dw $001D       ; 2B Red Potion
    dw $001D       ; 2C Green Potion
    dw $001D       ; 2D Blue Potion
    dw $001D       ; 2E Dummy - red
    dw $001D       ; 2F Dummy - green
    
    dw $001D       ; 30 Dummy - blue
    dw $001D       ; 31 10 Bombs
    dw $001D       ; 32 Dummy - big key
    dw $001D       ; 33 Dummy - map
    dw $001D       ; 34 1 Rupee
    dw $001D       ; 35 5 Rupees
    dw $001D       ; 36 20 Rupees
    dw $001D       ; 37 Dummy - Pendant of Courage
    dw $001D       ; 38 Dummy - Pendant of Wisdom
    dw $001D       ; 39 Dummy - Pendant of Power
    dw $001D       ; 3A Bow and arrows
    dw $001D       ; 3B Bow and silver Arrows
    dw $001D       ; 3C Bee
    dw $001D       ; 3D Fairy
    dw $001D       ; 3E Heart Container - Boss
    dw $001D       ; 3F Heart Container - Sanc
    
    dw $001D       ; 40 100 Rupees
    dw $001D       ; 41 50 Rupees
    dw $001D       ; 42 Dummy - small heart
    dw $001D       ; 43 1 Arrow
    dw $001D       ; 44 10 Arrows
    dw $001D       ; 45 Dummy - small magic
    dw $001D       ; 46 300 Rupees
    dw $001D       ; 47 20 Rupees
    dw $001D       ; 48 Good Bee
    dw $001D       ; 49 Fighter Sword
    dw $001D       ; 4A Dummy - activated flute
    dw $001D       ; 4B Boots                      
    dw $001D       ; 4C Dummy - 50+bombs
    dw $001D       ; 4D Dummy - 70+arrows
    dw $001D       ; 4E Half Magic
    dw $001D       ; 4F Quarter Magic              
    
    dw $001D       ; 50 Master Sword
    dw $001D       ; 51 +5 Bombs
    dw $001D       ; 52 +10 Bombs
    dw $001D       ; 53 +5 Arrows
    dw $001D       ; 54 +10 Arrows
    dw $001D       ; 55 Dummy - Programmable 1
    dw $001D       ; 56 Dummy - Programmable 2
    dw $001D       ; 57 Dummy - Programmable 3
    dw $001D       ; 58 Silver Arrows

    dw $001D       ; 59 - Unused (Rupoor)        
    dw $001D       ; 5A - Unused (Null Item)     
    dw $001D       ; 5B - Unused (Red Clock)     
    dw $001D       ; 5C - Unused (Blue Clock)    
    dw $001D       ; 5D - Unused (Green Clock)   
    dw $001D       ; 5E - Progressive Sword
    dw $001D       ; 5F - Progressive Shield

    dw $001D       ; 60 - Progressive Armor
    dw $001D       ; 61 - Progressive Glove
    dw $001D       ; 62 - Bombs                  (M1)
    dw $001D       ; 63 - High Jump              (M1)
    dw $001D       ; 64 - Reserved - Progressive Bow                 (Why two her
    dw $001D       ; 65 - Reserved - Progressive Bow                 (Why two her
    dw $001D       ; 66 - Long Beam              (M1)
    dw $001D       ; 67 - Screw Attack           (M1)
    dw $001D       ; 68 - Morph Ball             (M1)
    dw $001D       ; 69 - Varia Suit             (M1)
    dw $001D       ; 6A - Reserved - Goal Item (Single/Triforce)
    dw $001D       ; 6B - Reserved - Goal Item (Multi/Power Star)    (Is this use
    dw $001D       ; 6C - Wave Beam              (M1)
    dw $001D       ; 6D - Ice Beam               (M1)
    dw $001D       ; 6E - Energy Tank            (M1)
    dw $001D       ; 6F - Missiles               (M1)

    dw $001D       ; 70 - Crateria L1 Key        (SM)
    dw $001D       ; 71 - Crateria L2 Key        (SM)
    dw $001D       ; 72 - Ganons Tower Map
    dw $001D       ; 73 - Turtle Rock Map
    dw $001D       ; 74 - Thieves' Town Map
    dw $001D       ; 75 - Tower of Hera Map
    dw $001D       ; 76 - Ice Palace Map
    dw $001D       ; 77 - Skull Woods Map
    dw $001D       ; 78 - Misery Mire Map
    dw $001D       ; 79 - Palace Of Darkness Map
    dw $001D       ; 7A - Swamp Palace Map
    dw $001D       ; 7B - Crateria Boss Key      (SM)
    dw $001D       ; 7C - Desert Palace Map
    dw $001D       ; 7D - Eastern Palace Map
    dw $001D       ; 7E - Maridia Boss Key       (SM)
    dw $001D       ; 7F - Hyrule Castle Map

    dw $001D       ; 80 - Brinstar L1 Key        (SM)
    dw $001D       ; 81 - Brinstar L2 Key        (SM)
    dw $001D       ; 82 - Ganons Tower Compass
    dw $001D       ; 83 - Turtle Rock Compass
    dw $001D       ; 84 - Thieves' Town Compass
    dw $001D       ; 85 - Tower of Hera Compass
    dw $001D       ; 86 - Ice Palace Compass
    dw $001D       ; 87 - Skull Woods Compass
    dw $001D       ; 88 - Misery Mire Compass
    dw $001D       ; 89 - Palace of Darkness Compass
    dw $001D       ; 8A - Swamp Palace Compass
    dw $001D       ; 8B - Brinstar Boss Key      (SM)
    dw $001D       ; 8C - Desert Palace Compass
    dw $001D       ; 8D - Eastern Palace Compass
    dw $001D       ; 8E - Wrecked Ship L1 Key    (SM)
    dw $001D       ; 8F - Wrecked Ship Boss Key  (SM)

    dw $001D       ; 90 - Norfair L1 Key         (SM)
    dw $001D       ; 91 - Norfair L2 Key         (SM)
    dw $001D       ; 92 - Ganons Tower Big Key
    dw $001D       ; 93 - Turtle Rock Big Key
    dw $001D       ; 94 - Thieves' Town Big Key
    dw $001D       ; 95 - Tower of Hera Big Key
    dw $001D       ; 96 - Ice Palace Big Key
    dw $001D       ; 97 - Skull Woods Big Key
    dw $001D       ; 98 - Misery Mire Big Key
    dw $001D       ; 99 - Palace of Darkness Big Key
    dw $001D       ; 9A - Swamp Palace Big Key
    dw $001D       ; 9B - Norfair Boss Key       (SM)
    dw $001D       ; 9C - Desert Palace Big Key
    dw $001D       ; 9D - Eastern Palace Big Key
    dw $001D       ; 9E - Lower Norfair L1 Key   (SM)
    dw $001D       ; 9F - Lower Norfair Boss Key (SM)

    dw $001D       ; A0 - Hyrule Castle Small Key
    dw $001D       ; A1 - Sewers Small Key
    dw $001D       ; A2 - Eastern Palace Small Key
    dw $001D       ; A3 - Desert Palace Small Key
    dw $001D       ; A4 - Castle Tower Small Key
    dw $001D       ; A5 - Swamp Palace Small Key
    dw $001D       ; A6 - Palace of Darkness Small Key
    dw $001D       ; A7 - Misery Mire Small Key
    dw $001D       ; A8 - Skull Woods Small Key
    dw $001D       ; A9 - Ice Palace Small Key
    dw $001D       ; AA - Tower of Hera Small Key
    dw $001D       ; AB - Thieves' Town Small Key
    dw $001D       ; AC - Turtle Rock Small Key
    dw $001D       ; AD - Ganons Tower Small Key
    dw $001D       ; AE - Maridia L1 Key          (SM)
    dw $001D       ; AF - Maridia L2 Key          (SM)

    dw $001D       ; B0 - Grapple beam            (SM)
    dw $001D       ; B1 - X-ray scope             (SM)
    dw $001D       ; B2 - Varia suit              (SM)
    dw $001D       ; B3 - Spring ball             (SM)
    dw $001D       ; B4 - Morph ball              (SM)
    dw $001D       ; B5 - Screw attack            (SM)
    dw $001D       ; B6 - Gravity suit            (SM)
    dw $001D       ; B7 - Hi-Jump                 (SM)
    dw $001D       ; B8 - Space jump              (SM)
    dw $001D       ; B9 - Bombs                   (SM)
    dw $001D       ; BA - Speed booster           (SM)
    dw $001D       ; BB - Charge                  (SM)
    dw $001D       ; BC - Ice Beam                (SM)
    dw $001D       ; BD - Wave beam               (SM)
    dw $001D       ; BE - Spazer                  (SM)
    dw $001D       ; BF - Plasma beam             (SM)

    dw $001D       ; C0 - Energy Tank             (SM)
    dw $001D       ; C1 - Reserve tank            (SM)
    dw $001D       ; C2 - Missile                 (SM)
    dw $001D       ; C3 - Super Missile           (SM)
    dw $001D       ; C4 - Power Bomb              (SM)
    dw $001D       ; C5 - Kraid Boss Token        (SM)
    dw $001D       ; C6 - Phantoon Boss Token     (SM)
    dw $001D       ; C7 - Draygon Boss Token      (SM)
    dw $001D       ; C8 - Ridley Boss Token       (SM)
    dw $001D       ; C9 - Unused
    dw $001D       ; CA - Kraid Map               (SM)
    dw $001D       ; CB - Phantoon Map            (SM)
    dw $001D       ; CC - Draygon Map             (SM)
    dw $001D       ; CD - Ridley Map              (SM)
    dw $001D       ; CE - Unused
    dw $001D       ; CF - Unused (Reserved)

    dw $001D       ; D0 - Bombs                (Z1)
    dw $001D       ; D1 - Wooden Sword         (Z1)
    dw $001D       ; D2 - White Sword          (Z1)
    dw $001D       ; D3 - Magical Sword        (Z1)
    dw $001D       ; D4 - Bait                 (Z1)
    dw $001D       ; D5 - Recorder             (Z1)
    dw $001D       ; D6 - Blue Candle          (Z1)
    dw $001D       ; D7 - Red Candle           (Z1)
    dw $001D       ; D8 - Arrows               (Z1)
    dw $001D       ; D9 - Silver Arrows        (Z1)
    dw $001D       ; DA - Bow                  (Z1)
    dw $001D       ; DB - Magical Key          (Z1)
    dw $001D       ; DC - Raft                 (Z1)
    dw $001D       ; DD - Stepladder           (Z1)
    dw $001D       ; DE - Unused?              (Z1) ; Internal item
    dw $001D       ; DF - 5 Rupees             (Z1)

    dw $001D       ; E0 - Magical Rod          (Z1)
    dw $001D       ; E1 - Book of Magic        (Z1)
    dw $001D       ; E2 - Blue Ring            (Z1)
    dw $001D       ; E3 - Red Ring             (Z1)
    dw $001D       ; E4 - Power Bracelet       (Z1)
    dw $001D       ; E5 - Letter               (Z1)
    dw $001D       ; E6 - Compass              (Z1)  ; Bitmask per level (don't place this)
    dw $001D       ; E7 - Dungeon Map          (Z1)  ; Bitmask per level (don't place this)
    dw $001D       ; E8 - 1 Rupee              (Z1)
    dw $001D       ; E9 - Small Key            (Z1)
    dw $001D       ; EA - Heart Container      (Z1)
    dw $001D       ; EB - Triforce Fragment    (Z1)    ; TODO: Add this when shuffling rewards
    dw $001D       ; EC - Magical Shield       (Z1)
    dw $001D       ; ED - Boomerang            (Z1)
    dw $001D       ; EE - Magical Boomerang    (Z1)
    dw $001D       ; EF - Blue Potion          (Z1)

    dw $001D       ; F0 - Red Potion           (Z1)
    dw $001D       ; F1 - Clock                (Z1)  ; Internal item
    dw $001D       ; F2 - Small Heart          (Z1)  ; Internal item
    dw $001D       ; F3 - Fairy                (Z1)  ; Internal item
    dw $001D       ; F4 - Unused  (Triforce 1?)
    dw $001D       ; F5 - Unused  (Triforce 2?)
    dw $001D       ; F6 - Unused  (Triforce 3?)
    dw $001D       ; F7 - Unused  (Triforce 4?)
    dw $001D       ; F8 - Unused  (Triforce 5?)
    dw $001D       ; F9 - Unused  (Triforce 6?)
    dw $001D       ; FA - Unused  (Triforce 7?)
    dw $001D       ; FB - Unused  (Triforce 8?)
    dw $001D       ; FC - Unused
    dw $001D       ; FD - Unused
    dw $001D       ; FE - Unused
    dw $001D       ; FF - Unused (Reserved)

table ../../data/tables/box_yellow.tbl,rtl
item_names:
    dw "___                          ___"
    dw "___       Master Sword       ___"
    dw "___      Tempered Sword      ___"
    dw "___        Gold Sword        ___"
    dw "___       Small Shield       ___"
    dw "___        Red Shield        ___"
    dw "___       Mirror Shield      ___"
    dw "___         Fire Rod         ___"
    dw "___         Ice Rod          ___"
    dw "___          Hammer          ___"
    dw "___         Hookshot         ___"
    dw "___           Bow            ___"
    dw "___      Blue Boomerang      ___"
    dw "___       Magic Powder       ___"
    dw "___                          ___"
    dw "___          Bombos          ___"
    dw "___          Ether           ___"
    dw "___          Quake           ___"
    dw "___           Lamp           ___"
    dw "___          Shovel          ___"
    dw "___          Flute           ___"
    dw "___      Cane of Somaria     ___"
    dw "___          Bottle          ___"
    dw "___       Heart Piece        ___"
    dw "___       Cane of Byrna      ___"
    dw "___        Magic Cape        ___"
    dw "___          Mirror          ___"
    dw "___        Power Glove       ___"
    dw "___       Titan's Mitt       ___"
    dw "___      Book of Mudora      ___"
    dw "___      Zora's Flippers     ___"
    dw "___        Moon Pearl        ___"
    dw "___                          ___"
    dw "___     Bug-catching Net     ___"
    dw "___         Blue Mail        ___"
    dw "___          Red Mail        ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___      Heart Container     ___"
    dw "___          1 Bomb          ___"
    dw "___          3 Bombs         ___"
    dw "___         Mushroom         ___"
    dw "___       Red Boomerang      ___"
    dw "___        Red Potion        ___"
    dw "___       Green Potion       ___"
    dw "___       Blue Potion        ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___         10 Bombs         ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___          1 Rupee         ___"
    dw "___         5 Rupees         ___"
    dw "___         20 Rupees        ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___           Bow            ___"
    dw "___       Silver Arrows      ___"
    dw "___           Bee            ___"
    dw "___          Fairy           ___"
    dw "___      Heart Container     ___"
    dw "___      Heart Container     ___"
    dw "___        100 Rupees        ___"
    dw "___         50 Rupees        ___"
    dw "___                          ___"
    dw "___         1 Arrow          ___"
    dw "___         10 Arrows        ___"
    dw "___                          ___"
    dw "___        300 Rupees        ___"
    dw "___         20 Rupees        ___"
    dw "___         Good Bee         ___"
    dw "___      Fighter's Sword     ___"
    dw "___                          ___"
    dw "___       Pegasus Boots      ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___        Half Magic        ___"
    dw "___       Quarter Magic      ___"
    dw "___       Master Sword       ___"
    dw "___      5 Bomb capacity     ___"
    dw "___     10 Bomb capacity     ___"
    dw "___      5 Arrow capacity    ___"
    dw "___     10 Arrow capacity    ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___       Silver arrows      ___" ; 58
    dw "___                          ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___       Sword Upgrade      ___"
    dw "___      Shield Upgrade      ___"
    
    dw "___      Armour Upgrade      ___"  ; 60
    dw "___       Glove Upgrade      ___"
    dw "___         M1 Bombs         ___"
    dw "___       M1 High Jump       ___"
    dw "___          ProgBow         ___"
    dw "___          ProgBow         ___"
    dw "___       M1 Long Beam       ___"
    dw "___      M1 Screw Attack     ___"
    dw "___       M1 Morph Ball      ___"
    dw "___       M1 Varia Suit      ___"
    dw "___         Goal Single      ___"
    dw "___      Triforce Shard      ___"
    dw "___       M1 Wave Beam       ___"
    dw "___        M1 Ice Beam       ___"
    dw "___         M1 ETank         ___"
    dw "___        M1 Missiles       ___" ; 6F

    dw "___   Crateria L 1 Keycard   ___" ; 70
    dw "___   Crateria L 2 Keycard   ___"
    dw "___     Ganon's Tower Map    ___"
    dw "___     Turtle Rock Map      ___"
    dw "___     Thieves' Town Map    ___"
    dw "___    Tower of Hera Map     ___"
    dw "___      Ice Palace Map      ___"
    dw "___      Skull Woods Map     ___"
    dw "___      Misery Mire Map     ___"
    dw "___  Palace of Darkness Map  ___"
    dw "___      Swamp Palace Map    ___"
    dw "___  Crateria Boss Keycard   ___"
    dw "___     Desert Palace Map    ___"
    dw "___    Eastern Palace Map    ___"
    dw "___   Maridia Boss Keycard   ___"
    dw "___     Hyrule Castle Map    ___" ; 7F

    dw "___   Brinstar L 1 Keycard   ___" ; 80
    dw "___   Brinstar L 2 Keycard   ___"
    dw "___   Ganon's Tower Compass  ___"
    dw "___   Turtle Rock Compass    ___"
    dw "___   Thieves' Town Compass  ___"
    dw "___  Tower of Hera Compass   ___"
    dw "___    Ice Palace Compass    ___"
    dw "___    Skull Woods Compass   ___"
    dw "___    Misery Mire Compass   ___"
    dw "___Palace of Darkness Compass___"
    dw "___    Swamp Palace Compass  ___"
    dw "___  Brinstar Boss Keycard   ___"
    dw "___   Desert Palace Compass  ___"
    dw "___  Eastern Palace Compass  ___"
    dw "___ Wrecked Ship L 1 Keycard ___"
    dw "___ Wrecked Ship Boss Keycard___" ; 8F

    dw "___    Norfair L 1 Keycard   ___" ; 90
    dw "___    Norfair L 2 Keycard   ___"
    dw "___   Ganon's Tower Big Key  ___"
    dw "___   Turtle Rock Big Key    ___"
    dw "___  Thieves' Town Big Key   ___"
    dw "___  Tower of Hera Big Key   ___"
    dw "___    Ice Palace Big Key    ___"
    dw "___    Skull Woods Big Key   ___"
    dw "___    Misery Mire Big Key   ___"
    dw "___Palace of Darkness Big Key___"
    dw "___   Swamp Palace Big Key   ___"
    dw "___   Norfair Boss Keycard   ___"
    dw "___   Desert Palace Big Key  ___"
    dw "___  Eastern Palace Big Key  ___"
    dw "___Lower Norfair L 1 Keycard ___"
    dw "___Lower Norfair Boss Keycard___" ; 9F    

    dw "___     Hyrule Castle Key    ___" ; A0
    dw "___        Sewers Key        ___"
    dw "___    Eastern Palace Key    ___"
    dw "___     Desert Palace Key    ___"
    dw "___      Castle Tower Key    ___"
    dw "___      Swamp Palace Key    ___"
    dw "___  Palace of Darkness Key  ___"
    dw "___      Misery Mire Key     ___"
    dw "___      Skull Woods Key     ___"
    dw "___       Ice Palace Key     ___"
    dw "___     Tower of Hera Key    ___"
    dw "___     Thieves' Town Key    ___"
    dw "___      Turtle Rock Key     ___"
    dw "___      Ganon's Tower Key   ___"
    dw "___    Maridia L 1 Keycard   ___"
    dw "___    Maridia L 2 Keycard   ___" ; AF    

    dw "___      Grappling Beam      ___" ; B0
    dw "___       X-Ray Scope        ___"
    dw "___        Varia Suit        ___"
    dw "___       Spring Ball        ___"
    dw "___       Morphing Ball      ___"
    dw "___       Screw Attack       ___"
    dw "___       Gravity Suit       ___"
    dw "___       Hi-Jump Boots      ___"
    dw "___        Space Jump        ___"
    dw "___          Bombs           ___"
    dw "___       Speed Booster      ___"
    dw "___       Charge Beam        ___"
    dw "___         Ice Beam         ___"
    dw "___        Wave Beam         ___"
    dw "___     ~ S p A z E r ~      ___"
    dw "___       Plasma Beam        ___" ; Bf
    
    dw "___      An Energy Tank      ___" ; C0
    dw "___      A Reserve Tank      ___"
    dw "___         Missiles         ___"
    dw "___       Super Missiles     ___"
    dw "___        Power Bombs       ___"
    dw "___                          ___"  
    dw "___                          ___"  
    dw "___                          ___"  
    dw "___                          ___"  
    dw "___                          ___"  
    dw "___        Brinstar Map      ___"  
    dw "___      Wrecked Ship Map    ___"  
    dw "___        Maridia Map       ___"  
    dw "___     Lower Norfair Map    ___"  
    dw "___                          ___"  
    dw "___                          ___" ; CF

    dw "___         Z1 Bombs         ___" ; D0
    dw "___      Z1 Wooden Sword     ___" ;
    dw "___       Z1 White Sword     ___" ;
    dw "___      Z1 Magical Sword    ___" ;
    dw "___          Z1 Bait         ___" ;
    dw "___        Z1 Recorder       ___" ;
    dw "___       Z1 Blue Candle     ___" ;
    dw "___        Z1 Red Candle     ___" ;
    dw "___        Z1 Arrows         ___" ;
    dw "___      Z1 Silver Arrows    ___" ;
    dw "___          Z1 Bow          ___" ;
    dw "___       Z1 Magical Key     ___" ;
    dw "___          Z1 Raft         ___" ;
    dw "___       Z1 Stepladder      ___" ;
    dw "___         Z1 Unused?       ___" ;
    dw "___        Z1 5 Rupees       ___" ; DF

    dw "___      Z1 Magical Rod      ___" ; E0
    dw "___     Z1 Book of Magic     ___" ;
    dw "___       Z1 Blue Ring       ___" ;
    dw "___       Z1 Red Ring        ___" ;
    dw "___     Z1 Power Bracelet    ___" ;
    dw "___         Z1 Letter        ___" ;
    dw "___         Z1 Compass       ___" ;
    dw "___       Z1 Dungeon Map     ___" ;
    dw "___         Z1 1 Rupee       ___" ;
    dw "___        Z1 Small Key      ___" ;
    dw "___     Z1 Heart Container   ___" ;
    dw "___    Z1 Triforce Fragment  ___" ;
    dw "___     Z1 Magical Shield    ___" ;
    dw "___       Z1 Boomerang       ___" ;
    dw "___    Z1 Magical Boomerang  ___" ;
    dw "___       Z1 Blue Potion     ___" ; EF

    dw "___       Z1 Red Potion      ___" ; F0
    dw "___         Z1 Clock         ___" ;
    dw "___      Z1 Small Heart      ___" ;
    dw "___         Z1 Fairy         ___" ;
    dw "___                          ___" ;
    dw "___                          ___" ;
    dw "___                          ___" ;
    dw "___                          ___" ;
    dw "___                          ___" ;
    dw "___                          ___" ;
    dw "___                          ___" ;
    dw "___                          ___" ;
    dw "___                          ___" ;
    dw "___                          ___" ;
    dw "___                          ___" ;
    dw "___                          ___" ; FF


dungeon_names:
    dw "___          UNUSED          ___" ; 0
    dw "___          UNUSED          ___" ; 1
    dw "___       Ganon's Tower      ___" ; 2
    dw "___       Turtle Rock        ___" ; 3
    dw "___       Thieves' Town      ___" ; 4
    dw "___      Tower of Hera       ___" ; 5
    dw "___        Ice Palace        ___" ; 6
    dw "___       Skull Woods        ___" ; 7
    dw "___       Misery Mire        ___" ; 8
    dw "___    Palace of Darkness    ___" ; 9
    dw "___       Swamp Palace       ___" ; A
    dw "___          UNUSED          ___" ; B
    dw "___       Desert Palace      ___" ; C
    dw "___      Eastern Palace      ___" ; D
    dw "___          UNUSED          ___" ; E
    dw "___       Hyrule Castle      ___" ; F

dungeon_names_key:
    dw "___       Hyrule Castle      ___" ; 0
    dw "___          UNUSED          ___" ; 1
    dw "___          UNUSED          ___" ; 2
    dw "___       Desert Palace      ___" ; 3
    dw "___       Castle Tower       ___" ; 4
    dw "___       Swamp Palace       ___" ; 5
    dw "___    Palace of Darkness    ___" ; 6
    dw "___       Misery Mire        ___" ; 7
    dw "___       Skull Woods        ___" ; 8
    dw "___        Ice Palace        ___" ; 9
    dw "___      Tower of Hera       ___" ; A
    dw "___       Thieves' Town      ___" ; B
    dw "___       Turtle Rock        ___" ; C
    dw "___       Ganon's Tower      ___" ; D
    dw "___          UNUSED          ___" ; E
    dw "___          UNUSED          ___" ; F

region_names:
    dw "___         Crateria         ___" ; 0
    dw "___         Crateria         ___" ; 1
    dw "___         Crateria         ___" ; 2
    dw "___         Brinstar         ___" ; 3
    dw "___         Brinstar         ___" ; 4
    dw "___         Brinstar         ___" ; 5
    dw "___         Norfair          ___" ; 6
    dw "___         Norfair          ___" ; 7
    dw "___         Norfair          ___" ; 8
    dw "___         Maridia          ___" ; 9
    dw "___         Maridia          ___" ; A
    dw "___         Maridia          ___" ; B
    dw "___       Wrecked Ship       ___" ; C
    dw "___       Wrecked Ship       ___" ; D
    dw "___      Lower Norfair       ___" ; E
    dw "___      Lower Norfair       ___" ; F

keycard_names:
    dw "___     Level 1 Keycard      ___" ; 0
    dw "___     Level 2 Keycard      ___" ; 1
    dw "___       Boss Keycard       ___" ; 2
    dw "___     Level 1 Keycard      ___" ; 3
    dw "___     Level 2 Keycard      ___" ; 4
    dw "___       Boss Keycard       ___" ; 5
    dw "___     Level 1 Keycard      ___" ; 6
    dw "___     Level 2 Keycard      ___" ; 7
    dw "___       Boss Keycard       ___" ; 8
    dw "___     Level 1 Keycard      ___" ; 9
    dw "___     Level 2 Keycard      ___" ; A
    dw "___       Boss Keycard       ___" ; B
    dw "___     Level 1 Keycard      ___" ; C
    dw "___       Boss Keycard       ___" ; D
    dw "___     Level 1 Keycard      ___" ; E
    dw "___       Boss Keycard       ___" ; F

pendants:
table ../../data/tables/box_yellow.tbl,rtl
    dw "______     Red Pendant   _______"
    dw "______    Blue Pendant   _______"
table ../../data/tables/box_green.tbl,rtl
    dw "______   Green Pendant   _______"

crystals:
table ../../data/tables/box.tbl,rtl
    dw "______      Crystal 6    _______"
table ../../data/tables/box_yellow.tbl,rtl
    dw "______      Crystal 1    _______"
table ../../data/tables/box.tbl,rtl
    dw "______      Crystal 5    _______"
table ../../data/tables/box_yellow.tbl,rtl
    dw "______      Crystal 7    _______"
    dw "______      Crystal 2    _______"
    dw "______      Crystal 4    _______"
    dw "______      Crystal 3    _______"

bosses:
    dw "______     Kraid Boss    _______"
    dw "______   Phantoon Boss   _______"
    dw "______    Draygon Boss   _______"
    dw "______    Ridley Boss    _______"

map_markers:
    dw "___         Brinstar         ___" ; 0
    dw "___       Wrecked Ship       ___" ; 1
    dw "___         Maridia          ___" ; 2
    dw "___      Lower Norfair       ___" ; 3
cleartable
warnpc $D0FFFF

; Starts at 1D
org $859643
    dw !NormalBig,         !Big, normal_item            ; 1D
    dw !DungeonItemBig,    !Big, map                    ; 1E
    dw !DungeonItemBig,    !Big, compass                ; 1F
    dw !DungeonItemBig,    !Big, big_key                ; 20
    dw !DungeonKeyItemBig, !Big, small_key              ; 21 
    dw !KeycardBig,        !Big, keycard                ; 22
    dw !EmptySmall,        !BossRewardSmall,  reward    ; 23
    dw !MapMarkerBig,      !Big, map_marker             ; 24
    dw !PlaceholderBig,    !Big, sm_item_sent           ; 25
    dw !PlaceholderBig,    !Big, sm_item_received       ; 26

    dw !EmptySmall, !Small, btn_array

table ../../data/tables/box.tbl,rtl
normal_item:
    dw "___                          ___"
    dw "___                          ___"
    dw "___                          ___"
    dw "___                          ___"

map:
    dw "___     This is the map      ___"
    dw "___           for            ___"
    dw "___                          ___"
    dw "___          DUNGEON         ___"

compass:
    dw "___   This is the compass    ___"
    dw "___           for            ___"
    dw "___                          ___"
    dw "___          DUNGEON         ___"

big_key:
    dw "___    This is the big key   ___"
    dw "___           for            ___"
    dw "___                          ___"
    dw "___          DUNGEON         ___"

small_key:
    dw "___    This is a small key   ___"
    dw "___           for            ___"
    dw "___                          ___"
    dw "___          DUNGEON         ___"

keycard:
    dw "___       This is the        ___"
    dw "___         KEYCARD          ___"
    dw "___           for            ___"
    dw "___          REGION          ___"

reward:
    dw "______  Boss Reward PH   _______"

map_marker:
    dw "___     This is the map      ___"
    dw "___           for            ___"
    dw "___                          ___"
    dw "___          ZONE            ___"

sm_item_sent:
    dw "___         You found        ___"
    dw "___      ITEM NAME HERE      ___"
    dw "___           for            ___"
    dw "___          PLAYER          ___"

sm_item_received:
    dw "___       You received       ___"
    dw "___      ITEM NAME HERE      ___"
    dw "___           from           ___"
    dw "___          PLAYER          ___"
cleartable

btn_array:
	DW $0000, $012A, $012A, $012C, $012C, $012C, $0000, $0000, $0000, $0000, $0000, $0000, $0120, $0000, $0000
	DW $0000, $0000, $0000, $012A, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000

BossRewardSmall:
    REP #$30    
    LDA !DP_MsgRewardType     ; RewardType
    BEQ .pendant
    CMP #$0040
    BEQ .crystal
    BRA .smboss
    .pendant
        LDY #pendants
        BRA +
    .crystal
        LDY #crystals
        BRA +
    .smboss
        LDY #bosses
+
    LDA !DP_MsgBitFlag     ; Bitflag

    ; Loop until we've shifted out the bit from the mask
    ; and increase Y to point to the correct message box
-
    LSR
    BCS .found
    PHA : TYA : CLC : ADC #$0040 : TAY : PLA
    BRA -

    .found

    PHY

    ; Copy message tilemap to RAM
    LDX #$0000 
               
-
    LDA $8040,x
    STA $7E3200,x
    INX #2        
    CPX #$0040 
    BNE -    

    JSR $82B8

    PLY
    PHB : PEA $d0d0 : PLB : PLB
    LDX #$0000             ;\
-
    LDA.W $0000, y
    STA $7E3240, x
    INY #2
    INX #2
    CPX #$0040
    BNE -

    PLB
    LDX #$0080
    JMP $82A0

EmptyBig:
	REP #$30
    LDY #$0000
	JMP $841D
NormalBig:
    REP #$30
    JSR write_normal
    LDY #$0000
    JMP $841D
PlaceholderBig:
    REP #$30
    JSR write_placeholders
    LDY #$0000
    JMP $841D
DungeonItemBig:
    REP #$30
    JSR write_dungeon
    LDY #$0000
    JMP $841D
DungeonKeyItemBig:
    REP #$30
    JSR write_dungeon_key
    LDY #$0000
    JMP $841D
KeycardBig:
    REP #$30
    JSR write_keycard
    LDY #$0000
    JMP $841D
MapMarkerBig:
    REP #$30
    JSR write_map_marker
    LDA #$0000
    JMP $841D

write_dungeon:
    phx : phy
    phb : pea $d0d0 : plb : plb
    lda.l $001c1f
    cmp #$001e
    beq .adjust
    cmp #$001f
    beq .adjust
    cmp #$0020
    beq .adjust
    bra .end

.adjust
    lda.b !DP_MsgRewardType                ; Load dungeon id
    asl #6 : tay
    ldx #$0000
-
    lda.w dungeon_names, y
    sta.l $7e3300, x
    inx #2 : iny #2
    cpx #$0040
    bne -

.end
    plb : ply : plx
    lda #$0020
    rts

write_dungeon_key:
    phx : phy
    phb : pea $d0d0 : plb : plb
    lda.l $001c1f
    cmp #$0021
    beq .adjust
    bra .end

.adjust
    lda.b !DP_MsgRewardType                ; Load dungeon id
    asl #6 : tay
    ldx #$0000
-
    lda.w dungeon_names_key, y
    sta.l $7e3300, x
    inx #2 : iny #2
    cpx #$0040
    bne -

.end
    plb : ply : plx
    lda #$0020
    rts

write_keycard:
    phx : phy
    phb : pea $d0d0 : plb : plb
    lda.l $001c1f
    cmp #$0022
    beq .adjust
    bra .end

.adjust
    lda.b !DP_MsgRewardType                ; Load keycard index
    asl #6 : tay
    phy

    ldx #$0000
-
    lda.w keycard_names, y
    sta.l $7e3280, x
    inx #2 : iny #2
    cpx #$0040
    bne -

    ply
    ldx #$0000
-
    lda.w region_names, y
    sta.l $7e3300, x
    inx #2 : iny #2
    cpx #$0040
    bne -

.end
    plb : ply : plx
    lda #$0020
    rts

write_map_marker:
    phx : phy
    phb : pea $d0d0 : plb : plb
    lda.l $001c1f
    cmp #$0024
    beq .adjust
    bra .end

.adjust
    lda.b !DP_MsgRewardType                ; Load map marker id
    asl #6 : tay
    ldx #$0000
-
    lda.w map_markers, y
    sta.l $7e3300, x
    inx #2 : iny #2
    cpx #$0040
    bne -

.end
    plb : ply : plx
    lda #$0020
    rts

write_normal:
    phx : phy
    phb : pea $d0d0 : plb : plb
    lda.l $001c1f
    cmp #$001D
    beq .adjust
    bra .end    

.adjust
    lda.b !DP_MsgRewardType                ; Load item id
    asl #6 : tay
    ldx #$0000
-
    lda.w item_names, y       ; Write item name to box
    sta.l $7e32C0, x
    inx #2 : iny #2
    cpx #$0040
    bne -

.end
    plb : ply : plx
    lda #$0020
    rts

write_placeholders:
    phx : phy
    phb : pea $d0d0 : plb : plb
    lda.l $001c1f
    ; cmp #$005c
    ; beq .adjust
    ; cmp #$005d
    ; beq .adjust
    bra .end

; .adjust
;     lda.b $c1                 ; Load item id
;     cmp #$00b0              
;     bcc .alttpItem
;     sec
;     sbc #$00b0
;     bra +
; .alttpItem
;     clc
;     adc #$0030
; +
;     asl #6 : tay
;     ldx #$0000
; -
;     lda.w item_names, y       ; Write item name to box
;     sta.l $7e3280, x
;     inx #2 : iny #2
;     cpx #$0040
;     bne -

;     lda.b $c3                 ; Load player 1
;     asl #4 : tax
;     ldy #$0000
; -
;     lda.l rando_player_table, x
;     and #$00ff
;     phx
;     asl : tax               ; Put char table offset in X
;     lda.l char_table-$40, x 
;     tyx
;     sta.l $7e3314, x
;     iny #2
;     plx
;     inx
;     cpy #$0018
;     bne -
;     rep #$30

.end
    plb : ply : plx
    lda #$0020
    rts

char_table:
    ; Each unsupported value translate to "?" $38FE to raise a visual indication
    ;  <sp>   !      "      #      $      %      &      '      (      )      *      +      ,      -      .      /
    dw $384E, $38FF, $38AA, $38AE, $38FE, $380A, $38FE, $38FC, $38FE, $38FE, $38FE, $38AF, $38FB, $38CF, $38FA, $38FE
    ;  0      1      2      3      4      5      6      7      8      9      :      ;      <      =      >      ?
    dw $3889, $3880, $3881, $3882, $3883, $3884, $3885, $3886, $3887, $3888, $38AB, $38FE, $38FE, $38FE, $38FE, $38FE
    ;  @      A      B      C      D      E      F      G      H      I      J      K      L      M      N      O
    dw $38FE, $38E0, $38E1, $38E2, $38E3, $38E4, $38E5, $38E6, $38E7, $38E8, $38E9, $38EA, $38EB, $38EC, $38ED, $38EE
    ;  P      Q      R      S      T      U      V      W      X      Y      Z      [      \      ]      ^      _
    dw $38EF, $38F0, $38F1, $38F2, $38F3, $38F4, $38F5, $38F6, $38F7, $38F8, $38F9, $38FE, $38FE, $38FE, $38FE, $38FE

; Lowercase Letters, which simply translate to uppercase
    ;  `      A      B      C      D      E      F      G      H      I      J      K      L      M      N      O
    dw $38FE, $3890, $3891, $3892, $3893, $3894, $3895, $3896, $3897, $3898, $3899, $389A, $389B, $389C, $389D, $389E
    ;  P      Q      R      S      T      U      V      W      X      Y      Z      {      |      }      ~      <DEL>
    dw $389F, $38A0, $38A1, $38A2, $38A3, $38A4, $38A5, $38A6, $38A7, $38A8, $38A9, $38FE, $38FE, $38FE, $38AC, $38FE

org $858749
fix_1c1f:
    LDA !DP_MsgOverride      ; if $CE is set, it overrides the message box
    BEQ +
    STA $1C1F
    STZ !DP_MsgOverride      ; Clear $CE
+	LDA $1C1F
	CMP #$001D
	BPL +
	RTS
+
	ADC #$027F
	RTS

org $858243
	JSR fix_1c1f

org $8582E5
	JSR fix_1c1f

org $858413
	DW btn_array
