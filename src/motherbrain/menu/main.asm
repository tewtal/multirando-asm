; Main menu code, used as the boot point since we can't rely on any specific games menu being available
;
; This runs on the SA-1

; ---------
; RAM Menu
; ---------

!ram_tilemap_buffer = $40D800

!WRAM_MENU_START = $003400

!ram_cm_stack_index = $0037fc
!ram_cm_menu_stack = !WRAM_MENU_START+$00         ; 16 bytes
!ram_cm_cursor_stack = !WRAM_MENU_START+$10       ; 16 bytes

!ram_cm_cursor_max = !WRAM_MENU_START+$20
!ram_cm_input_timer = !WRAM_MENU_START+$24
!ram_cm_controller = !WRAM_MENU_START+$26
!ram_cm_menu_bank = !WRAM_MENU_START+$28

!ram_cm_etanks = !WRAM_MENU_START+$2A
!ram_cm_reserve = !WRAM_MENU_START+$2C
!ram_cm_leave = !WRAM_MENU_START+$2E
!ram_cm_input_counter = !WRAM_MENU_START+$30
!ram_cm_last_nmi_counter = !WRAM_MENU_START+$32

!ram_cm_ctrl_mode = !WRAM_MENU_START+$34
!ram_cm_ctrl_timer = !WRAM_MENU_START+$36
!ram_cm_ctrl_last_input = !WRAM_MENU_START+$38
!ram_cm_ctrl_assign = !WRAM_MENU_START+$3A
!ram_cm_ctrl_swap = !WRAM_MENU_START+$3C
!ram_cm_botwoon_rng = !WRAM_MENU_START+$3E

; ------------------
; Reusable RAM Menu
; ------------------

; The following RAM may be used multiple times,
; as long as it isn't used multiple times on the same menu page

!ram_cm_watch_left_hi = !WRAM_MENU_START+$80
!ram_cm_watch_left_lo = !WRAM_MENU_START+$82
!ram_cm_watch_right_hi = !WRAM_MENU_START+$84
!ram_cm_watch_right_lo = !WRAM_MENU_START+$86
!ram_cm_watch_left_index_lo = !WRAM_MENU_START+$88
!ram_cm_watch_left_index_hi = !WRAM_MENU_START+$8A
!ram_cm_watch_right_index_lo = !WRAM_MENU_START+$8C
!ram_cm_watch_right_index_hi = !WRAM_MENU_START+$8E
!ram_cm_watch_edit_left_hi = !WRAM_MENU_START+$90
!ram_cm_watch_edit_left_lo = !WRAM_MENU_START+$92
!ram_cm_watch_edit_right_hi = !WRAM_MENU_START+$94
!ram_cm_watch_edit_right_lo = !WRAM_MENU_START+$96
!ram_cm_watch_enemy_property = !WRAM_MENU_START+$98
!ram_cm_watch_enemy_index = !WRAM_MENU_START+$9A
!ram_cm_watch_enemy_side = !WRAM_MENU_START+$9C
!ram_cm_watch_bank = !WRAM_MENU_START+$9E
!ram_cm_watch_common_address = !WRAM_MENU_START+$A0

!ram_cm_phan_first_phase = !WRAM_MENU_START+$80
!ram_cm_phan_second_phase = !WRAM_MENU_START+$82

!ram_cm_varia = !WRAM_MENU_START+$80
!ram_cm_gravity = !WRAM_MENU_START+$82
!ram_cm_morph = !WRAM_MENU_START+$84
!ram_cm_bombs = !WRAM_MENU_START+$86
!ram_cm_spring = !WRAM_MENU_START+$88
!ram_cm_screw = !WRAM_MENU_START+$8A
!ram_cm_hijump = !WRAM_MENU_START+$8C
!ram_cm_space = !WRAM_MENU_START+$8E
!ram_cm_speed = !WRAM_MENU_START+$90
!ram_cm_charge = !WRAM_MENU_START+$92
!ram_cm_ice = !WRAM_MENU_START+$94
!ram_cm_wave = !WRAM_MENU_START+$96
!ram_cm_spazer = !WRAM_MENU_START+$98
!ram_cm_plasma = !WRAM_MENU_START+$9A

!sram_ctrl_menu = !WRAM_MENU_START+$9C

; Reserve 48 bytes for CGRAM cache
; Currently first 22 bytes and last 2 bytes are used
!ram_cgram_cache = !WRAM_MENU_START+$A0

!DP_MenuIndices = $00 ; 0x4
!DP_CurrentMenu = $04 ; 0x4
!DP_Address = $08 ; 0x4
!DP_JSLTarget = $0C ; 0x4
!DP_CtrlInput = $10 ; 0x4
!DP_Palette = $14
!DP_Temp = $16
; v these repeat v
!DP_ToggleValue = $18
!DP_Increment = $1A
!DP_Minimum = $1C
!DP_Maximum = $1E
!DP_DrawValue = $18
!DP_FirstDigit = $1A
!DP_SecondDigit = $1C
!DP_ThirdDigit = $1E

!DP_TextLo = $20
!DP_TextHi = $22

!ACTION_TOGGLE              = #$0000
!ACTION_TOGGLE_BIT          = #$0002
!ACTION_TOGGLE_INVERTED     = #$0004
!ACTION_TOGGLE_BIT_INVERTED = #$0006
!ACTION_NUMFIELD            = #$0008
!ACTION_NUMFIELD_HEX        = #$000A
!ACTION_NUMFIELD_WORD       = #$000C
!ACTION_NUMFIELD_COLOR      = #$000E
!ACTION_CHOICE              = #$0010
!ACTION_CTRL_SHORTCUT       = #$0012
!ACTION_CTRL_INPUT          = #$0014
!ACTION_JSL                 = #$0016
!ACTION_JSL_SUBMENU         = #$0018
!ACTION_DRAW_ONLY           = $8000

!IH_CONTROLLER_PRI = $0037e8
!IH_CONTROLLER_PRI_NEW = $0037ec
!IH_CONTROLLER_PRI_PREV = $0037ea

!MENU_BLANK = #$281F
!IH_BLANK = #$2C0F
!IH_PERCENT = #$0C0A
!IH_DECIMAL = #$0CCB
!IH_HYPHEN = #$0C55
!IH_RESERVE_AUTO = #$0C0C
!IH_RESERVE_EMPTY = #$0C0D
!IH_HEALTHBOMB = #$085A
!IH_LETTER_A = #$0C64
!IH_LETTER_B = #$0C65
!IH_LETTER_C = #$0C58
!IH_LETTER_D = #$0C59
!IH_LETTER_E = #$0C5A
!IH_LETTER_F = #$0C5B
!IH_LETTER_H = #$0C6C
!IH_LETTER_L = #$0C68
!IH_LETTER_N = #$0C56
!IH_LETTER_R = #$0C69
!IH_LETTER_X = #$0C66
!IH_LETTER_Y = #$0C67
!IH_ELEVATOR = #$1C0B
!IH_SHINETIMER = #$0032

!IH_PAUSE = #$0100 ; right
!IH_SLOWDOWN = #$0400 ; down
!IH_SPEEDUP = #$0800 ; up
!IH_RESET = #$0200 ; left
!IH_STATUS_R = #$0010 ; r
!IH_STATUS_L = #$0020 ; l

!IH_INPUT_START = #$1000
!IH_INPUT_UP = #$0800
!IH_INPUT_DOWN = #$0400
!IH_INPUT_LEFTRIGHT = #$0300
!IH_INPUT_LEFT = #$0200
!IH_INPUT_RIGHT = #$0100
!IH_INPUT_HELD = #$0001 ; used by menu

!CTRL_B = #$8000
!CTRL_Y = #$4000
!CTRL_SELECT = #$2000
!CTRL_A = #$0080
!CTRL_X = #$0040
!CTRL_L = #$0020
!CTRL_R = #$0010

!INPUT_BIND_UP = $400018
!INPUT_BIND_DOWN = $40001A
!INPUT_BIND_LEFT = $40001C
!INPUT_BIND_RIGHT = $40002E
!IH_INPUT_SHOT = $400020
!IH_INPUT_JUMP = $400022
!IH_INPUT_RUN = $400024
!IH_INPUT_ITEM_CANCEL = $400026
!IH_INPUT_ITEM_SELECT = $400028
!IH_INPUT_ANGLE_DOWN = $40002A
!IH_INPUT_ANGLE_UP = $40002C

!CTRL_BINDING_UP = $400018
!CTRL_BINDING_DOWN = $40001A
!CTRL_BINDING_LEFT = $40001C
!CTRL_BINDING_RIGHT = $40002E
!CTRL_BINDING_SHOT = $400020
!CTRL_BINDING_JUMP = $400022
!CTRL_BINDING_DASH = $400024
!CTRL_BINDING_CANCEL = $400026
!CTRL_BINDING_SELECT = $400028
!CTRL_BINDING_ANGLEDOWN = $40002A
!CTRL_BINDING_ANGLEUP = $40002C

incsrc "macros.asm"
incsrc "menu.asm"

init:
    phk : plb
    jml cm_start

