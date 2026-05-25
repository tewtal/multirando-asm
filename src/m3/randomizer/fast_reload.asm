; Fast reload on death
; Based on patch by total: https://metroidconstruction.com/resource.php?id=421
; Compile with "asar" (https://github.com/RPGHacker/asar/releases)


!deathhook82 = $82DDC7 ;$82 used for death hook (game state $19)

;free space: make sure it doesnt override anything you have
!bank_80_free_space_start = $80d800
!bank_80_free_space_end = $80d8ff
!bank_82_free_space_start = $82FE70
!bank_82_free_space_end = $82FE80
!bank_85_free_space_start = $85FF00
!bank_85_free_space_end = $85FFEF

!freespacea0 = $a0fe00 ;$A0 used for instant save reload

!QUICK_RELOAD = $1f60 ;dont need to touch this

; Hook Death Game event (19h)
org !deathhook82
deathhook:
    php
    rep #$30

    lda #$0001
    sta !QUICK_RELOAD ; Currently "quick reloading"

    jsl $82be17       ; Stop sounds
    jsl load_save_slot
    jsl $80858C       ; load map

    stz $0E1E         ; reset boss flag to avoid BG2 write (possible door transition corruption)

    ; In case we're on an elevator ride, reset this state so that Samus will have control after the reload:
    stz $0E18

    lda #$0006
    sta $0998         ; Goto game mode 6 (load game)
    plp
    rts
    
warnpc $82DDF1

; Hook main game loop
org $82897A
    jsl hook_main

org !bank_85_free_space_start
SupportedStates:
    dw #$0007  ; Main gameplay fading in
    dw #$0008  ; Main gameplay
    dw #$0009  ; Hit a door block
    dw #$000a  ; Loading next room
    dw #$000b  ; Loading next room
    dw #$000c  ; Pausing, normal gameplay but darkening
    dw #$000d  ; Pausing, loading pause menu
    dw #$000e  ; Paused, loading pause menu
    dw #$000f  ; Paused, objective/map/equipment screens
    dw #$0012  ; Unpausing, normal gameplay but brightening
    dw #$0013  ; Death sequence, start
    dw #$0014  ; Death sequence, black out surroundings
    dw #$0015  ; Death sequence, wait for music
    dw #$0016  ; Death sequence, pre-flashing
    dw #$0017  ; Death sequence, flashing
    dw #$0018  ; Death sequence, explosion white out
    dw #$001b  ; Reserve tanks auto.
    dw #$0027  ; Ending and credits. Cinematic. (reboot only)
    dw #$ffff

hook_main:
    jsl $808338  ; run hi-jacked instruction
    phb
    phk
    plb
    ldx #$0000
.next_check
    lda SupportedStates,X
    bmi .leave
    cmp $0998
    beq .check
    inx : inx
    bra .next_check
.leave    ; inapplicable game state, so skip check for quick reload inputs.
    plb
    rtl

.check
    plb
    php
    rep #$30

    ; Disable quick reload during the Samus fanfare at the start of the game (or when loading game from menu)
    lda $0A44
    cmp #$E86A
    beq .noreset

    lda $8B      ; Controller 1 input
    and.l config_reload_button_combo   ; L + R + Select + Start (or customized reset inputs)
    cmp.l config_reload_button_combo
    bne .noreset ; If any of the inputs are not currently held, then do not reset.

    ; Only check new press with gamestates 7 & 8
    lda $0998
    cmp #$0007
    beq .check_newpress
    cmp #$0008
    bne .reset
.check_newpress
    lda $8F      ; Newly pressed controller 1 input
    and.l config_reload_button_combo  ; L + R + Select + Start
    bne .reset   ; Reset only if at least one of the inputs is newly pressed
.noreset
    plp
    rtl
.reset:
    plp
    lda #$0027
    cmp $0998    ; in credits?
    bne .no_reboot

    ; stop MSU
    stz $2006
    stz $2007
        
    ; direct APU write to stop music
    stz $00
    stz $02
    jsl $808024

    jml $80841c ; reboot
    
.no_reboot
    stz $0727    ; Reset pause menu index
    stz $0797    ; Reset door transition flag
    lda #$0000
    sta $7EC400  ; clear palette change numerator, in case of reload during fade-in/fade-out
    stz $05F5    ; enable sounds
    pea $f70d    ; $82f70e = rtl
    jml !deathhook82

warnpc !bank_85_free_space_end

; Hook setting up game
org $80a088
    jsl setup_music : nop : nop

org $80A095
    jml setup_game_1

org $80a0ce
    jml setup_game_2

org $80a113
    jml setup_game_3

org $91e164
    jsl setup_samus : nop : nop

; Free space somewhere for hooked code
org !freespacea0
setup_music:
    lda !QUICK_RELOAD
    bne .quick
    stz $07f3
    stz $07f5
.quick
    rtl

setup_game_1:
    jsl $82be17       ; Stop sounds
    lda !QUICK_RELOAD
    bne .quick
    lda #$ffff      ; Do regular things
    sta $05f5
    jml $80a09b
.quick
    jsl $80835d
    jsl $80985f
    jsl $82e76b
    jml $80a0aa

setup_game_2:
    jsl $82be17       ; Stop sounds
    lda !QUICK_RELOAD
    bne .quick
    jsl $82e071
    jml $80a0d2
.quick
    jml $80a0d5

setup_game_3:
    jsl $82be17       ; Stop sounds
    pha
    lda !QUICK_RELOAD
    bne .quick
    pla
    jsl $80982a
    jml $80a117
.quick
    pla
    jsl $80982a
    stz !QUICK_RELOAD

    lda $07c9
    cmp $07f5
    bne .loadmusic
    lda $07cb
    cmp $07f3
    bne .loadmusic
    jml $80a122


.loadmusic
    lda $07c9
    sta $07f5
    lda $07cb
    sta $07f3    

    ; Stop music before starting new track. This prevents audio glitchiness in case the death track is playing.
    lda #$0000
    jsl $808FC1

    lda $07cb
    ora #$ff00
    jsl $808fc1

    lda $07c9
    jsl $808fc1

    jml $80a122

setup_samus:
    lda !QUICK_RELOAD
    beq .normal
    lda #$e695
    sta $0a42
    lda #$e725
    sta $0a44
.normal    
    lda $09c2
    sta $0a12
    rtl

; Determine which save slot to load from, and load it:
load_save_slot:
    lda $0952
    jml $818085
    rtl

warnpc $A18000

; load game room pointer hook
org $80c45e
    jsr hook_room

org !bank_80_free_space_start
hook_room:
    cmp #$A98D  ; crocomire spawn?
    bne .leave
; clear 7e2000-3000 to avoid layer 2 corruption
    pha
    phx
    ldx #$0000
    lda #$0338
.clr_lp
    sta $7E2000,x
    inx : inx
    cpx #$1000
    bmi .clr_lp
    plx
    pla
.leave
    sta $079B  ; replaced code
    rts

warnpc !bank_80_free_space_end