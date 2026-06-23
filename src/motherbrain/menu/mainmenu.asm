; --------
; Helpers
; --------

macro cm_header(title)
; outlined text to be drawn above the menu items
    table ../../../resources/header.tbl
    db #$01, #$28, "<title>", #$FF
    table ../../../resources/normal.tbl
endmacro

macro cm_footer(title)
; optional outlined text below the menu items
    table ../../../resources/header.tbl
    dw #$F007 : db #$28, "<title>", #$FF
    table ../../../resources/normal.tbl
endmacro

macro cm_version_header(label)
    db #$02 : dl <label>
endmacro

macro cm_version_footer(label)
    dw #$F007
    dl <label>
endmacro

macro cm_numfield(title, addr, start, end, increment, heldincrement, jsltarget)
; Allows editing an 8-bit value at the specified address
    dw !ACTION_NUMFIELD
    dl <addr> ; 24bit RAM address to display/manipulate
    db <start>, <end> ; minimum and maximum values allowed
    db <increment> ; inc/dec amount when pressed
    db <heldincrement> ; inc/dec amount when direction is held (scroll faster)
    dw <jsltarget> ; 16bit address to code in the same bank as current menu/submenu
    db #$28, "<title>", #$FF
endmacro

macro cm_numfield_word(title, addr, start, end, increment, heldincrement, jsltarget)
; Allows editing a 16-bit value at the specified address
    dw !ACTION_NUMFIELD_WORD
    dl <addr> ; 24bit RAM address to display/manipulate
    dw <start>, <end> ; minimum and maximum values allowed
    dw <increment> ; inc/dec amount when pressed
    dw <heldincrement> ; inc/dec amount when direction is held (scroll faster)
    dw <jsltarget> ; 16bit address to code in the same bank as current menu/submenu
    db #$28, "<title>", #$FF
endmacro

macro cm_draw_numfield_word(title, addr)
; Allows editing a 16-bit value at the specified address
    dw !ACTION_NUMFIELD_WORD|!ACTION_DRAW_ONLY
    dl <addr> ; 24bit RAM address to display/manipulate
    dw $0000, $FFFF ; minimum and maximum values allowed
    dw $0000 ; inc/dec amount when pressed
    dw $0000 ; inc/dec amount when direction is held (scroll faster)
    dw $FFFF ; 16bit address to code in the same bank as current menu/submenu
    db #$28, "<title>", #$FF
endmacro

macro cm_numfield_hex(title, addr, start, end, increment, heldincrement, jsltarget)
; Allows editing an 8-bit value displayed in hexadecimal
    dw !ACTION_NUMFIELD_HEX
    dl <addr> ; 24bit RAM address to display/manipulate
    db <start>, <end> ; minimum and maximum values allowed
    db <increment> ; inc/dec amount when pressed
    db <heldincrement> ; inc/dec amount when direction is held (scroll faster)
    dw <jsltarget> ; 16bit address to code in the same bank as current menu/submenu
    db #$28, "<title>", #$FF
endmacro

macro cm_numfield_color(title, addr, jsltarget)
; Allows editing an 8-bit value in increments consistent with SNES color values
    dw !ACTION_NUMFIELD_COLOR
    dl <addr> ; 24bit RAM address to display/manipulate
    dw <jsltarget> ; 16bit address to code in the same bank as current menu/submenu
    db #$28, "<title>", #$FF
endmacro

macro cm_toggle(title, addr, value, jsltarget)
; toggle between zero (OFF) and value (ON)
    dw !ACTION_TOGGLE
    dl <addr> ; 24bit RAM address to display/manipulate
    db <value> ; value to write when toggled on
    dw <jsltarget> ; 16bit address to code in the same bank as current menu/submenu
    db #$28, "<title>", #$FF
endmacro

macro cm_toggle_inverted(title, addr, value, jsltarget)
; for toggles where zero = ON
    dw !ACTION_TOGGLE_INVERTED
    dl <addr> ; 24bit RAM address to display/manipulate
    db <value> ; value to write when toggled off
    dw <jsltarget> ; 16bit address to code in the same bank as current menu/submenu
    db #$28, "<title>", #$FF
endmacro

macro cm_toggle_bit(title, addr, mask, jsltarget)
; toggle specific bits, draw OFF if bits cleared
    dw !ACTION_TOGGLE_BIT
    dl <addr> ; 24bit RAM address to display/manipulate
    dw <mask> ; which bits to flip
    dw <jsltarget> ; 16bit address to code in the same bank as current menu/submenu
    db #$28, "<title>", #$FF
endmacro

macro cm_toggle_bit_inverted(title, addr, mask, jsltarget)
; toggle specific bits, draw ON if bits cleared
    dw !ACTION_TOGGLE_BIT_INVERTED
    dl <addr> ; 24bit RAM address to display/manipulate
    dw <mask> ; which bits to flip
    dw <jsltarget> ; 16bit address to code in the same bank as current menu/submenu
    db #$28, "<title>", #$FF
endmacro

macro cm_jsl(title, routine, argument)
; run code when menu item executed
    dw !ACTION_JSL
    dw <routine> ; 16bit address to code in the same bank as current menu/submenu
    dw <argument> ; value passed to routine in Y
    db #$28, "<title>", #$FF
endmacro

macro cm_draw_text(title)
    dw !ACTION_JSL|!ACTION_DRAW_ONLY
    dw $0000
    dw $0000
    db #$28, "<title>", #$FF
endmacro

macro cm_jsl_submenu(title, routine, argument)
; only used within submenu and mainmenu macros
    dw !ACTION_JSL_SUBMENU
    dw <routine> ; 16bit address to code in the same bank as current menu/submenu
    dw <argument> ; value passed to routine in Y
    db #$28, "<title>", #$FF
endmacro

macro cm_mainmenu(title, target)
; runs action_mainmenu to set the bank of the next menu and continue into action_submenu
; can only used for submenus listed on the mainmenu
    %cm_jsl("<title>", #action_mainmenu, <target>)
endmacro

macro cm_submenu(title, target)
; run action_submenu to load the next menu from the same bank
    %cm_jsl_submenu("<title>", #action_submenu, <target>)
endmacro

macro cm_ctrl_shortcut(title, addr)
; configure controller shortcuts
    dw !ACTION_CTRL_SHORTCUT
    dl <addr> ; 24bit RAM address to display/manipulate
    db #$28, "<title>", #$FF
endmacro

macro cm_ctrl_input(title, addr, routine, argument)
; set a single controller binding
    dw !ACTION_CTRL_INPUT
    dl <addr> ; 24bit RAM address to display/manipulate
    dw <routine> ; 16bit address to code in the same bank as current menu/submenu
    dw <argument> ; value passed to routine in Y
    db #$28, "<title>", #$FF
endmacro

macro setmenubank()
; used to set the menu bank before a manual submenu jump
; assumes 16bit A
    PHK : PHK : PLA
    STA !ram_cm_menu_bank
endmacro

action_mainmenu:
{
    PHB
    ; Set bank of new menu
    LDA !ram_cm_cursor_stack : TAX
    LDA.l MainMenuBanks,X : STA !ram_cm_menu_bank
    STA !DP_MenuIndices+2 : STA !DP_CurrentMenu+2

    ; Skip stack operation in action_submenu
    BRA action_submenu_skipStackOp
}

action_submenu:
{
    PHB
  .skipStackOp
    ; Increment stack pointer by 2, then store current menu
    LDA.l !ram_cm_stack_index : INC #2 : STA.l !ram_cm_stack_index : TAX
    TYA : STA !ram_cm_menu_stack,X

    BRA action_submenu_jump
}

action_submenu_jump:
{
    ; Set cursor to top for new menus
    LDA #$0000 : STA !ram_cm_cursor_stack,X

    %sfxmove()
    JSL cm_calculate_max
    JSL cm_draw

    PLB
    RTL
}

; -----------
; Main menu
; -----------

; MainMenu must exist in the same bank as the menu code.
; From here, submenus can branch out into different banks
; as long as all of its menu items and submenus are included.

MainMenu:
    dw #sgm_start
    dw #mm_goto_setup
    if defined("DEBUG")
        dw $FFFF
        dw #mm_goto_debug
    endif

    dw #$0000
    %cm_version_header(cm_title_header)
    %cm_version_footer(cm_title_footer)

MainMenuBanks:
    dw #StartGameMenu>>16
    dw #SetupMenu>>16
    dw $FFFF
    dw #DebugMenu>>16

mm_goto_startgame:
    %cm_mainmenu("Start Game", #StartGameMenu)

mm_goto_setup:
    %cm_mainmenu("Configuration", #SetupMenu)

mm_goto_debug:
    %cm_mainmenu("Debug", #DebugMenu)

StartGameMenu:
    dw #sgm_start
    dw $FFFF
    dw sgm_m1
    dw sgm_m1_energy
    dw sgm_m1_missiles
    dw sgm_m1_bosses
    dw $FFFF
    dw sgm_sm
    dw sgm_sm_energy
    dw sgm_sm_missiles
    dw sgm_sm_supers
    dw sgm_sm_powerbombs
    dw sgm_sm_bosses
    dw $FFFF
    dw sgm_z1
    dw sgm_z1_bosses
    dw $FFFF
    dw sgm_z3
    dw sgm_z3_pendants
    dw sgm_z3_crystals
    dw #$0000
    %cm_header("Start Game")

sgm_start:
    %cm_jsl("Start Game", .startgame, #$0000)
    .startgame
  
    lda.l config_start
    cmp.w #$0000    ; SM
    bne +
        lda.w #mb_snes_run_m3>>16 : pha
        lda.w #mb_snes_run_m3 : pha
        bra .boot
+   cmp.w #$0001    ; Z3
    bne +
        lda.w #mb_snes_run_z3>>16 : pha
        lda.w #mb_snes_run_z3 : pha
        bra .boot
+   cmp.w #$0002    ; Z1
    bne +
        lda.w #mb_snes_run_z1>>16 : pha
        lda.w #mb_snes_run_z1 : pha
        bra .boot
+
    lda.w #mb_snes_run_m1>>16 : pha
    lda.w #mb_snes_run_m1 : pha

.boot

    ; SM Controls are stored in the SM item buffer as well so we need to copy them there as well
    jsr sm_copy_controls

    ; Fix SM checksum in case we changed controller settings or moonwalk
    jsr sm_fix_checksum

    lda.l SNES_CMD_PTR : tax
    lda.w #$0008 : sta.l $000000, x : inx #2
    pla : sta.l $000000, x : inx #2
    pla : sta.l $000000, x : inx #2
    lda.w #$0000 : sta.l $000000, x
    txa : sta.l SNES_CMD_PTR
    jml mb_main ; Return to main kernel loop  


    RTL
sgm_m1:
    %cm_draw_text("-- Metroid --")
sgm_m1_energy:
    %cm_draw_numfield_word("Energy", $FFFFF4)
sgm_m1_missiles:
    %cm_draw_numfield_word("Missiles", $FFFFF4)
sgm_m1_bosses:
    %cm_draw_numfield_word("Bosses", $FFFFF4)

sgm_sm:
    %cm_draw_text("-- Super Metroid --")
sgm_sm_energy:
    %cm_draw_numfield_word("Energy", $400042)
sgm_sm_missiles:
    %cm_draw_numfield_word("Missiles", $400046)
sgm_sm_supers:
    %cm_draw_numfield_word("Super Missiles", $40004A)
sgm_sm_powerbombs:
    %cm_draw_numfield_word("Power Bombs", $40004E)
sgm_sm_bosses:
    %cm_draw_numfield_word("Bosses", $400072)

sgm_z1:
    %cm_draw_text("-- Zelda 1 --")
sgm_z1_bosses:
    %cm_draw_numfield_word("Triforce Pieces", $FFFFF4)

sgm_z3:
    %cm_draw_text("-- A Link to the Past --")
sgm_z3_pendants:
    %cm_draw_numfield_word("Pendants", $FFFFF4)
sgm_z3_crystals:
    %cm_draw_numfield_word("Crystals", $FFFFF4)


SetupMenu:
    dw #sm_moonwalk
    dw $FFFF
    dw #sm_goto_controller
    dw #$0000
    %cm_header("Quad - Configuration")

sm_moonwalk:
    %cm_toggle("SM - Moonwalk", $400052, 1, 0)
sm_goto_controller:
    %cm_submenu("Configure controller", #ControllerMenu)

ControllerMenu:
    dw #controls_save_to_file
    dw #$FFFF
    dw #controls_shot
    dw #controls_jump
    dw #controls_dash
    dw #controls_item_select
    dw #controls_item_cancel
    dw #controls_angle_up
    dw #controls_angle_down
    dw #$0000
    %cm_header("CONTROLLER SETTING MODE")

controls_shot:
    %cm_ctrl_input("        SHOT", !IH_INPUT_SHOT, action_submenu, #AssignControlsMenu)

controls_jump:
    %cm_ctrl_input("        JUMP", !IH_INPUT_JUMP, action_submenu, #AssignControlsMenu)

controls_dash:
    %cm_ctrl_input("        DASH", !IH_INPUT_RUN, action_submenu, #AssignControlsMenu)

controls_item_select:
    %cm_ctrl_input(" ITEM SELECT", !IH_INPUT_ITEM_SELECT, action_submenu, #AssignControlsMenu)

controls_item_cancel:
    %cm_ctrl_input(" ITEM CANCEL", !IH_INPUT_ITEM_CANCEL, action_submenu, #AssignControlsMenu)

controls_angle_up:
    %cm_ctrl_input("    ANGLE UP", !IH_INPUT_ANGLE_UP, action_submenu, #AssignControlsMenu)

controls_angle_down:
    %cm_ctrl_input("  ANGLE DOWN", !IH_INPUT_ANGLE_DOWN, action_submenu, #AssignControlsMenu)

controls_save_to_file:
    %cm_jsl("Save to File", .routine, #0)
  .routine
    JML cm_previous_menu

AssignControlsMenu:
    dw controls_assign_A
    dw controls_assign_B
    dw controls_assign_X
    dw controls_assign_Y
    dw controls_assign_Select
    dw controls_assign_L
    dw controls_assign_R
    dw #$0000
    %cm_header("ASSIGN AN INPUT")

AssignAngleControlsMenu:
    dw #controls_assign_L
    dw #controls_assign_R
    dw #$0000
    %cm_header("ASSIGN AN INPUT")

controls_assign_A:
    %cm_jsl("A", action_assign_input, !CTRL_A)

controls_assign_B:
    %cm_jsl("B", action_assign_input, !CTRL_B)

controls_assign_X:
    %cm_jsl("X", action_assign_input, !CTRL_X)

controls_assign_Y:
    %cm_jsl("Y", action_assign_input, !CTRL_Y)

controls_assign_Select:
    %cm_jsl("Select", action_assign_input, !CTRL_SELECT)

controls_assign_L:
    %cm_jsl("L", action_assign_input, !CTRL_L)

controls_assign_R:
    %cm_jsl("R", action_assign_input, !CTRL_R)


action_assign_input:
{
    LDA !ram_cm_ctrl_assign : TAX  ; input address in $C2 and X
    TYA : STA $400000, x

    ; determine which sfx to play
    CMP #$FFFF : BEQ .undetected
    %sfxconfirm()
    BRA .done
  .undetected
  .done
    JML cm_previous_menu
}


DebugMenu:
    dw #dm_boot_z1
    dw #dm_boot_z3
    dw #dm_boot_m1
    dw #dm_boot_sm
    dw $FFFF
    dw #dm_grant_items
    dw #dm_grant_progression
    dw $FFFF
    dw #dm_boot_credits
    dw #$0000
    %cm_header("Z1Z3M1M3 - Debug")

dm_boot_z1:
    %cm_jsl("Boot Z1", .boot_z1, #$0000)
    .boot_z1

    ; Tell the main SNES cpu to jump to .boot_z1_snes
    lda.l SNES_CMD_PTR : tax
    lda.w #$0008 : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_z1 : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_z1>>16 : sta.l $000000, x : inx #2
    lda.w #$0000 : sta.l $000000, x
    txa : sta.l SNES_CMD_PTR
    jml mb_main ; Return to main kernel loop    

dm_boot_z3:
    %cm_jsl("Boot Z3", .boot_z3, #$0000)
    .boot_z3
    ; Tell the main SNES cpu to jump to .boot_z1_snes
    lda.l SNES_CMD_PTR : tax
    lda.w #$0008 : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_z3 : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_z3>>16 : sta.l $000000, x : inx #2
    lda.w #$0000 : sta.l $000000, x
    txa : sta.l SNES_CMD_PTR
    jml mb_main ; Return to main kernel loop  

dm_boot_m1:
    %cm_jsl("Boot M1", .boot_m1, #$0000)
    .boot_m1
    ; Tell the main SNES cpu to jump to .boot_z1_snes
    lda.l SNES_CMD_PTR : tax
    lda.w #$0008 : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_m1 : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_m1>>16 : sta.l $000000, x : inx #2
    lda.w #$0000 : sta.l $000000, x
    txa : sta.l SNES_CMD_PTR
    jml mb_main ; Return to main kernel loop  

dm_boot_sm:
    %cm_jsl("Boot SM", .boot_sm, #$0000)
    .boot_sm
    ; Tell the main SNES cpu to jump to .boot_z1_snes
    lda.l SNES_CMD_PTR : tax
    lda.w #$0008 : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_m3 : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_m3>>16 : sta.l $000000, x : inx #2
    lda.w #$0000 : sta.l $000000, x
    txa : sta.l SNES_CMD_PTR
    jml mb_main ; Return to main kernel loop  

dm_boot_credits:
    %cm_jsl("Boot Credits", .boot_credits, #$0000)
    .boot_credits
    ; Tell the main SNES cpu to jump to .boot_z1_snes
    lda.l SNES_CMD_PTR : tax
    lda.w #$0008 : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_credits : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_credits>>16 : sta.l $000000, x : inx #2
    lda.w #$0000 : sta.l $000000, x
    txa : sta.l SNES_CMD_PTR
    jml mb_main ; Return to main kernel loop

; Grant a full set of gear/items to every game (no pendants/crystals/triforces).
; Drives the shared mb_WriteItemToInventory routine over a curated list of global
; item ids, which writes each into the correct game's item buffer. Each game's
; transition-in restores those buffers into its SRAM/WRAM, so the items are present
; the next time a game is booted from this menu.
dm_grant_items:
    %cm_jsl("Grant All Items", .routine, #$0000)
    .routine
    php
    rep #$30
    ldx.w #$0000
    .loop
    lda.l DebugItemList, x
    and.w #$00FF
    cmp.w #$00FF                 ; $FF terminates the list
    beq .done
    phx                         ; WriteItemToInventory returns Game Id in X
    jsl mb_WriteItemToInventory
    plx
    inx
    bra .loop
    .done
    ; The grant only updated the shared item buffers. A cold boot reads each game's own
    ; inventory store, so push the buffers out to those stores:
    ;  - SM and ALTTP: copy buffer into SRAM + fix checksum (RestoreItemBuffer).
    lda.w #$0000 : jsl mb_RestoreItemBuffer   ; SM    ($400010)
    lda.w #$0001 : jsl mb_RestoreItemBuffer   ; ALTTP ($402300)
    lda.w #$0003 : jsl mb_RestoreItemBuffer   ; M1
    ;  - Z1: write the granted items into the on-cart SRAM save file + fix checksum.
    jsl mb_Z1WriteSramFile
    plp
    JML cm_previous_menu

; Grant progression rewards that the shared item routine can't deliver: ALTTP
; pendants + crystals, Z1 triforce fragments, and the SM/M1 main boss kills (the
; four SM Golden Four bosses and M1's Kraid + Ridley). Mother Brain and the final
; escape are left untriggered so the endings stay testable.
dm_grant_progression:
    %cm_jsl("Grant Progression", .routine, #$0000)
    .routine
    php
    sep #$20
    rep #$10
    ; --- ALTTP ---
    ; pendants (SRAM $7EF374 -> buffer +$74) and crystals (SRAM $7EF37A -> +$7A)
    lda.b #$07 : sta.l !ALTTP_BUFFER_START+$74     ; all three pendants
    lda.b #$3F : sta.l !ALTTP_BUFFER_START+$7A     ; all six crystals

    ; --- Zelda 1 ---
    ; triforce fragments (InvTriforce $7E0671 -> Z1 buffer +$1A): set all 8 bits
    lda.b #$FF : sta.l !Z1_BUFFER_START+$1A

    ; --- Super Metroid main bosses ---
    ; The SM item buffer mirrors WRAM $7ED7C0..; buffer offset = addr - $D7C0.
    ; Vanilla boss "dead" event bits (so the rooms stay cleared):
    lda.b #$01 : ora.l !SM_BUFFER_START+$68 : sta.l !SM_BUFFER_START+$68   ; Kraid  $7ED828.0
    lda.b #$01 : ora.l !SM_BUFFER_START+$6A : sta.l !SM_BUFFER_START+$6A   ; Ridley $7ED82A.0 (Norfair)
    lda.b #$01 : ora.l !SM_BUFFER_START+$6B : sta.l !SM_BUFFER_START+$6B   ; Phantoon $7ED82B.0
    lda.b #$01 : ora.l !SM_BUFFER_START+$6C : sta.l !SM_BUFFER_START+$6C   ; Draygon  $7ED82C.0
    ; Boss-token / credits bits at $7ED834 (+$74): counted toward the G4 gate and the
    ; goal tracker. Set all four.
    lda.b #$0F : ora.l !SM_BUFFER_START+$74 : sta.l !SM_BUFFER_START+$74
    ; G4 grey-door open flag (keydoor event $7ED832.0, +$72) so Tourian is reachable.
    lda.b #$01 : ora.l !SM_BUFFER_START+$72 : sta.l !SM_BUFFER_START+$72

    ; --- Metroid 1 main bosses ---
    ; The M1 item buffer mirrors WRAM $6876..; buffer offset = addr - $6876.
    ; KraidStatueStat $687B (+$05): bit7 = statue up, bit0 = defeated.
    ; RidlyStatueStat $687C (+$06): bit7 = statue up, bit1 = defeated.
    lda.b #$81 : ora.l !M1_BUFFER_START+$05 : sta.l !M1_BUFFER_START+$05   ; Kraid up + dead
    lda.b #$82 : ora.l !M1_BUFFER_START+$06 : sta.l !M1_BUFFER_START+$06   ; Ridley up + dead

    rep #$30
    ; Push the changed buffers into the stores each game reads on a cold boot.
    jsl mb_Z1WriteSramFile          ; Z1 -> SRAM save file (+fix checksum)
    lda.w #$0000 : jsl mb_RestoreItemBuffer   ; SM    -> SRAM ($400010) + checksum
    lda.w #$0001 : jsl mb_RestoreItemBuffer   ; ALTTP -> SRAM ($402300) + checksum
    lda.w #$0003 : jsl mb_RestoreItemBuffer   ; M1    -> SRAM ($408876)
    plp
    JML cm_previous_menu

; Curated list of global item ids granted by "Grant All Items" (see itemmap.md).
; Excludes pendants/crystals/triforces (progression) and consumables-only fillers.
; Repeated ids stack (tanks/ammo/heart containers). Terminated by $FF.
DebugItemList:
    ; --- Super Metroid (gear) ---
    db $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA   ; varia, spring, morph, screw, gravity, hijump, space, bombs, speed
    db $B0, $B1, $BB, $BC, $BD, $BE, $BF             ; grapple, xray, charge, ice, wave, spazer, plasma
    db $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0        ; energy tanks (14 total, across these two rows)
    db $C0, $C0, $C0, $C0, $C0, $C0                  ;
    db $C1, $C1, $C1, $C1                            ; 4 reserve tanks
    db $C2, $C2, $C2, $C2, $C2, $C2                  ; missiles (5 each)
    db $C3, $C3, $C3, $C3                            ; super missiles
    db $C4, $C4, $C4, $C4                            ; power bombs
    ; --- A Link to the Past (items) ---
    db $02, $06                                      ; gold sword, mirror shield
    db $0B, $0C, $2A, $0A, $0D                       ; bow, boomerangs, hookshot, powder
    db $07, $08, $09, $0F, $10, $11, $12             ; rods, hammer, medallions, lamp
    db $14, $21, $1D, $15, $18, $19, $1A             ; flute, net, book, somaria, byrna, cape, mirror
    db $1B, $1C, $1E, $1F, $4B, $23                  ; glove, mitt, flippers, pearl, boots, red tunic
    db $3B, $4F                                      ; bow & silver arrows, quarter magic
    db $16, $16, $16, $16                            ; 4 bottles
    db $52, $52, $52, $54, $54, $54                  ; +30 bombs, +30 arrows
    db $26, $26, $26, $26, $26, $26, $26             ; 7 heart containers
    db $40, $40                                      ; rupees
    ; --- Zelda 1 (items) ---
    db $D3, $EC, $DA, $D9, $D4, $D5, $D7             ; magic sword, shield, bow, silver arrows, bait, recorder, red candle
    db $E0, $E1, $E3, $E4, $E5, $DB, $DC, $DD, $EE   ; rod, book, red ring, bracelet, letter, magic key, raft, ladder, magic boomerang
    db $D0, $D0                                      ; bombs
    db $EA, $EA, $EA, $EA, $EA, $EA, $EA             ; heart containers
    db $DF, $DF                                      ; rupees
    ; --- Metroid 1 (gear) ---
    db $62, $63, $66, $67, $68, $69, $6C, $6D        ; bombs, hijump, long, screw, morph, varia, wave, ice
    db $6E, $6E, $6E, $6E, $6E, $6E                  ; energy tanks
    db $6F, $6F, $6F, $6F                            ; missiles (5 each)
    db $FF                                           ; terminator

init_wram_based_on_sram:
{
    ; JSL init_suit_properties_ram

    ; ; Check if any less common controller shortcuts are configured
    ; JSL GameModeExtras
    RTL
}

sm_copy_controls:
    pha
    phx
    ldx.w #$0020
-
    lda.l $400000,x
    sta.l !SM_BUFFER_START-$10, x
    inx #2
    cpx #$002E
    bne -

    lda.l $400052
    sta.l !SM_BUFFER_START+$42

    plx
    pla
    rts

sm_fix_checksum:
    pha
    phx
    phy
    php

    %ai16()
    
    lda $14
    pha
    stz $14
    ldx #$0010
 -
    lda.l $400000,x
    clc
    adc $14
    sta $14
    inx
    inx
    cpx #$0a00
    bne -

    ldx #$0000
    lda $14
    sta.l $400000,x
    sta.l $401ff0,x
    eor #$ffff
    sta.l $400008,x
    sta.l $401ff8,x
    pla
    sta $14

    plp
    ply
    plx
    pla
    rts