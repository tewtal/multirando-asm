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
    if defined("DEBUG")
        dw #mm_goto_setup
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
  
    lda.l SNES_CMD_PTR : tax
    lda.w #$0008 : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_m3 : sta.l $000000, x : inx #2
    lda.w #mb_snes_run_m3>>16 : sta.l $000000, x : inx #2
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
    dw #sm_quickswap
    dw $FFFF
    dw #sm_controller
    dw #$0000
    %cm_header("Z1Z3M1M3 - Configuration")

sm_moonwalk:
    %cm_toggle("SM - Moonwalk", $40A01A, 1, 0)
sm_quickswap:
    %cm_toggle("Z3 - Quick Swap", $40A034, 1, 0)
sm_controller:
    %cm_draw_text("Configure Controller")

DebugMenu:
    dw #dm_boot_z1
    dw #dm_boot_z3
    dw #dm_boot_m1
    dw #dm_boot_sm
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

init_wram_based_on_sram:
{
    ; JSL init_suit_properties_ram

    ; ; Check if any less common controller shortcuts are configured
    ; JSL GameModeExtras
    RTL
}
