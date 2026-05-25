;
; Game fixes and patches
;
incsrc "g4_skip.asm"
incsrc "wake_zebes.asm"
incsrc "patches.asm"
incsrc "shaktool.asm"
; incsrc "seed_display.asm"
incsrc "bomb_torizo.asm"
incsrc "aim_any_button.asm"
; incsrc "decompression.asm"
incsrc "elevators_speed.asm"
incsrc "fast_doors.asm"
incsrc "fast_pause_menu.asm"
incsrc "fast_saves.asm"
incsrc "reserve_hud.asm"
;incsrc "scrolling_sky.asm"

incsrc "map_overhaul/BasicGraphicPatch.asm"
incsrc "map_overhaul/MapOverhaul.asm"

; 
; Randomizer things
;

incsrc "nofanfare.asm"        ; Super Metroid Remove Item fanfares
incsrc "newitems.asm"         ; Super Metroid New Items patch
incsrc "item_messages.asm"    ; Super Metroid Item Messages
incsrc "ending.asm"           ; Super Metroid Ending conditions
incsrc "newgame.asm"          ; Super Metroid New Game Initialization
incsrc "minorfixes.asm"       ; Super Metroid some softlock removals etc
incsrc "newrooms.asm"         ; Super Metroid New Rooms (double door refill/map/saves)
incsrc "demofix.asm"          ; Super Metroid Stop demos from playing
; incsrc "maps.asm"             ; Super Metroid map pause screen and HUD changes
; incsrc "map_icons.asm"        ; Super Metroid door icons for keysanity map
incsrc "max_ammo.asm"         ; Super Metroid max ammo patch by personitis, adapted by Leno for Crossover
incsrc "keycards.asm"         ; Super Metroid Keycard system
incsrc "plminject.asm"        ; Super Metroid PLM Injection
incsrc "messagebox.asm"       ; Super Metroid Messagebox improvements
incsrc "rewards.asm"          ; Super Metroid Custom Boss Rewards


incsrc "tables.asm"           ; Super Metroid Data Tables
incsrc "titlescreen.asm"      ; Super Metroid Title Screen
incsrc "skiptitle.asm"        ; Super Metroid Skip Title Screen
incsrc "saveload.asm"         ; Super Metroid Save/Load improvements
incsrc "map_area.asm"         ; Super Metroid Map-specific Areas
incsrc "fast_reload.asm"      ; Super Metroid Fast Reload


;
; Cross-game transitions
;

incsrc "transition_out.asm"
incsrc "transition_in.asm"
incsrc "transition_tables.asm"
