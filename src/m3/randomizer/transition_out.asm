; Check for specific door and transition to another game
;
base off
org $82e2fa
    jsl sm_check_transition

org $d01000
sm_check_transition:
    phx
    pha
    php
    %ai16()

    ldx #$0000
-
    lda.l sm_transition_table,x
    beq ++
    cmp $078d
    beq +
    txa
    clc
    adc #$0008
    tax
    bne -
    jmp ++
+
    jmp sm_do_transition
++
    plp
    pla
    plx
    jsl $8882ac
    rtl

sm_do_transition:
    lda.l sm_transition_table+$2,x
    sta !IRAM_TRANSITION_GAME_ID
    lda.l sm_transition_table+$4,x
    STA !IRAM_TRANSITION_DESTINATION_ID
    lda.l sm_transition_table+$6,x
    sta !IRAM_TRANSITION_DESTINATION_ARGS    
    
    jsl $8085c6                     ; Save map data

    lda #$0000
    jsl $818000                     ; Save SRAM

    lda #$0000
    sta.l $806166
    sta.l $806168                   ; Set these values to 0 to force load from the ship if samus dies
    jsl sm_fix_checksum             ; Fix SRAM checksum (otherwise SM deletes the file on load)

    ; TODO: Copy temporary item buffers to the other games respective SRAM (this needs to be done on save as well)
    ; TODO: Do any other maintenance that needs to be done to properly clear SM state and prepare for the next game

    sei                         ; Disable IRQ's
    
    %a8()
    %i16()

    phk
    plb                           ; Set data bank program bank

    lda #$00
    sta.l $004200                 ; Disable NMI and Joypad autoread
    sta.l $00420c                 ; Disable H-DMA

    lda #$8f
    sta.l $002100                 ; Enable PPU force blank

    jsl sm_reset_spc_engine       ; Kill the SM music engine and put the SPC in IPL upload mode
                                  ; Gotta do this before switching RAM contents

    ; At this point we're ready to swap out SM and load another game
    
    lda #$81                  
    sta.l $002200             ; Trigger IRQ with message 1 to SA-1 (transition to new game)
    jml mb_snes_transition    ; Jump the SNES CPU into BW-RAM routines that let the SA-1 control it

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
    lda.l $806000,x
    clc
    adc $14
    sta $14
    inx
    inx
    cpx #$065c
    bne -

    ldx #$0000
    lda $14
    sta.l $806000,x
    sta.l $807ff0,x
    eor #$ffff
    sta.l $806008,x
    sta.l $807ff8,x
    pla
    sta $14

    plp
    ply
    plx
    pla
    rtl


sm_reset_spc_engine:
    pha
    php
    %a8()
    
    lda #$ff                    ; Send N-SPC into "upload mode"
    sta.l $002140

    rep #$30
    lda #$0000
    sta $12
    sta $14

    jsl $80800a
    db sm_reset_spc_data, (sm_reset_spc_data>>8)+$80, sm_reset_spc_data>>16

    plp
    pla
    rtl


; When starting a new game, run this code
;
; Only copies the "new file" SRAM into the ALTTP SRAM slot right now (only file 1 works)

sm_alttp_new_game:
    pha
    phx
    phy
    php
    %ai16()

    ldx #$0000
-
    lda.l sm_alttp_sram,x
    sta.l !SRAM_ALTTP_START,x
    inx
    inx
    cpx #$2000
    bne -

    jsl sm_fix_z3_checksum
    
    plp
    ply
    plx
    pla
    rtl

sm_alttp_sram:
    incbin "../../data/zelda-sram.bin"

sm_fix_z3_checksum:
    pha
    phx
    php
    %ai16()
    lda $00
    pha

    ldx #$0000              ; Copy main SRAM to backup SRAM
-
    lda.l $402000,x
    sta.l $402f00,x
    inx : inx
    cpx #$04fe
    bne -

    ldx #$0000
    lda #$0000
-
    clc
    adc $402000,x
    inx
    inx
    cpx #$04fe
    bne -

    sta $00
    lda #$5a5a
    sec
    sbc $00
    ;sta $7EF4fe
    sta $4024fe
    sta $4033fe
    pla
    plp
    plx
    pla
    rtl
warnpc $d04000

org $d07f00
base $e0ff00
sm_reset_spc_data:        ; Upload this data to the SM music engine to kill it and put it back into IPL mode
    dw $002a, $15a0
    db $8f, $6c, $f2 
    db $8f, $e0, $f3 ; Disable echo buffer writes and mute amplifier
    db $8f, $7c, $f2 
    db $8f, $ff, $f3 ; ENDX
    db $8f, $7d, $f2 
    db $8f, $00, $f3 ; Disable echo delay
    db $8f, $4d, $f2 
    db $8f, $00, $f3 ; EON
    db $8f, $5c, $f2 
    db $8f, $ff, $f3 ; KOFF
    db $8f, $5c, $f2 
    db $8f, $00, $f3 ; KOFF
    db $8f, $80, $f1 ; Enable IPL ROM
    db $5f, $c0, $ff ; jmp $ffc0
    dw $0000, $1500