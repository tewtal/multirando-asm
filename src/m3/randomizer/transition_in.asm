; Handles an incoming transition into SM

; org $818003
;     jml sm_save_hook

; org $81807F
;     jml sm_save_done_hook

; org $818087
;     jml sm_load_hook

org $d04000
transition_to_sm:
    ; SPC has been reset and NMI/IRQ hooks are set to SM
    ; SA-1 banks including SRAM are also in SM-mode at this point
    ; So from here we take over the transition process from the SA-1
    ; and restore WRAM/VRAM depending on door direction and move on

    %a8()
    lda #$07 : sta $2220        ; Swap in bank 7 to banks C0-DF temporarily since we have the transition data there

    %a16()
    lda.l !IRAM_TRANSITION_DESTINATION_ID
    tax
    lda.l $830003,x	            ; Load door direction bit
	and #$0003
    beq +

    %a8()
    ldx.w #mb_sm_vram>>16          ; Put SM VRAM bank in X
    jsl copy_to_vram            ; Call the DMA routine to copy SM template VRAM from ROM

    ldx.w #mb_sm_wram>>16          ; Put SM WRAM bank in X
    jsl copy_to_wram            ; Call the DMA routine to copy SM template WRAM from ROM
    jmp ++

+
    %a8()
    ldx.w #mb_sm_vram_right>>16    ; Put SM VRAM bank in X
    jsl copy_to_vram            ; Call the DMA routine to copy SM template VRAM from ROM

    ldx.w #mb_sm_wram_right>>16    ; Put SM WRAM bank in X
    jsl copy_to_wram            ; Call the DMA routine to copy SM template WRAM from ROM

++

    %a8()
    lda #$02 : sta $2220        ; Swap bank the original SM banks to C0-CF
    
    %ai16()
    ldx #$1ff0
    txs                         ; Adjust stack pointer

    lda #$ffff                  ; Set the "game flag" to SM so IRQ's/NMI runs using the 
    sta !SRAM_CURRENT_GAME      ; correct game

    jsl sm_fix_checksum         ; Fix SRAM checksum (otherwise SM deletes the file on load)
    
    lda #$0000
    jsl $818085                 ; Load SRAM contents back into RAM

    jsl $809a79                 ; Redraw HUD

    jsr sm_spc_load             ; Load SM's music engine

    lda !IRAM_TRANSITION_DESTINATION_ID
    sta $078d                   ; Store the selected door index

    jsl sm_setup_door

    jsr update_save_station     ; Update save station to portal room and autosave

    %ai16()

    lda #$000b
    sta $0998                   ; Set game mode to loading door

    lda #$e29e
    sta $099c

    ;lda #$0001
    ;sta.l $7fff10               ; Set this transition to not count for stats

    ;lda #$001b                  ; Add transition to SM
    ;jsl inc_stat

    %a8()

    lda $84
    sta $4200                   ; Turn NMI/IRQ/Autojoypad read back on


    %ai16()

    cli                         ; Enable interrupts and push processor status to the stack
    php

    lda $4210                   ; Acknowledge any pending IRQ's
    pea $8282
    plb
    plb
    jml $82897a                 ; Put game directly into "Wait for IRQ" in the main game loop

print "update save: ", pc
update_save_station:    
    ; Get door pointer
    ldx $078d
    
    ; Get room ptr
    lda.l $830000,x : tax : tay

    ; Get area index
    lda.l $8F0001,x : and #$00ff
    sta $079f
    asl : tax

    ; Get load station pointer index
    lda.l $80C4B5,x : tax : tya

    ldy #$0006
-
    cmp.l $800054,x
    beq .found_station
    pha : txa : clc : adc #$000e : tax : pla
    iny
    cpy #$0012
    bne -
    bra .not_found

.found_station:
    tya
    sta.w $078b
    sta.l $7ed916
    lda #$0000
    ; Autosave game to the portal station
    jsl $818000

.not_found
    rts

sm_spc_load:
    jsl $80800a                 ; Call the SM SPC upload routine with the parameter set to
    dl $cf8000                  ; the whole full music engine and samples.
    rts

sm_save_hook:
    phb : phx : phy : pha
    pea $7e00
    plb
    plb

    lda #$0001
    sta.l !SRAM_SAVING

    lda #$0000
    jsl mb_RestoreItemBuffers ; Save all found items to actual SRAM
   
    ;jsl sm_save_alttp_items
    ;jsl stats_save_sram
    ;jsl mw_save_sram
    pla
    ply
    plx
    plb
    rtl

sm_save_done_hook:
    pha
    lda #$0000
    sta.l !SRAM_SAVING
    lda #$0000
    jsl mb_CopyItemBuffer     ; Copy SM buffer back to prevent item loss on reset    
    pla
    ;ply : plx : clc : plb : plp
    rtl

sm_load_hook:
    phb : phx : phy : pha
    pea $7e00
    plb
    plb

    jsl mb_CopyItemBuffers   ; Copy back original item buffers (overwriting any items we found without saving)
    ;jsl sm_copy_alttp_items
    ;jsl stats_load_sram
    ;jsl mw_load_sram

    pla
    ply
    plx
    plb
    ;jml $81808f
    rtl

copy_to_wram:       ; Copies 4 banks of ROM data to WRAM (start bank in X)

    %a8()           ; Make sure that NMI/IRQ's are off and PPU is off before calling this
    %i16()

    pla             ; Grab the return address from the stack and store it in SRAM    
    sta !SRAM_DMA_RET+$2

    pla
    sta !SRAM_DMA_RET+$1
    
    pla
    sta !SRAM_DMA_RET

    pea $0000       ; Set DB to $00 
    plb
    plb

    txa
    sta $4314       ; Store bank to DMA registers

    ldx #$0000
    stx $4312       ; Store source address

    ldx #$8000
    stx $4310       ; DMA A -> B (ROM -> WRAM)

    ldx #$8000
    stx $4315       ; Size (32768 bytes)

    ldx #$0000
    stx $2181       ; WRAM target address $0000

    lda #$00
    stx $2183       ; WRAM target bank (7e)

    lda #$02
    sta $420b       ; Start DMA

    ; ---------------

    ldx #$8000
    stx $2181       ; WRAM target address $8000
    
    ldx #$8000
    stx $2181       ; WRAM target address $8000
    
    lda #$00
    stx $2183       ; WRAM target bank (7e)
    
    ldx #$8000
    stx $4315       ; Size (32768 bytes)

    ldx #$8000
    stx $4312       ; Store source address

    lda #$02
    sta $420b       ; Start DMA

    ; ----------------
    
    ldx #$0000
    stx $2181       ; WRAM target address $8000
    lda #$01
    sta $2183       ; WRAM bank 2 (7f)
    
    inc $4314       ; Copy from next bank
    
    ldx #$8000
    stx $4315       ; Size (32768 bytes)

    ldx #$0000
    stx $4312       ; Store source address

    lda #$02
    sta $420b       ; Start DMA

    ; -----------

    ldx #$8000
    stx $2181       ; WRAM target address $8000
    lda #$01
    sta $2183       ; WRAM bank 2 (7f)
  
    ldx #$8000
    stx $4315       ; Size (32768 bytes)

    ldx #$8000
    stx $4312       ; Store source address

    lda #$02
    sta $420b       ; Start DMA


    lda !SRAM_DMA_RET     ; Push return address to the "new" stack
    pha

    lda !SRAM_DMA_RET+$1     ; Push return address to the "new" stack
    pha
    
    lda !SRAM_DMA_RET+$2
    pha

    rtl             ; Return


copy_to_vram:       ; Copies 2 banks of ROM to VRAM (starting bank in X)
    pha
    phx
    php
    phb

    %a8()           ; Make sure that NMI/IRQ's are off and PPU is off before calling this
    %i16()

    pea $0000       ; Set DB to $00 
    plb
    plb

    lda #$01
    sta $2105
    
    lda #$80
    sta $2115

    txa
    sta $4314       ; Store bank to DMA registers

    ldx #$0000
    stx $4312       ; Store source address

    ldx #$1801
    stx $4310       ; DMA A -> B (ROM -> VRAM)

    ldx #$0000      ; VRAM address
    stx $2116

    ldx #$8000
    stx $4315       ; Size (32768 bytes)

    lda #$02
    sta $420b       ; Start DMA

    ; ----
    
    ldx #$4000
    stx $2116       ; WRAM address

    ldx #$8000
    stx $4315       ; Size (32768 bytes)

    ldx #$8000
    stx $4312       ; Store source address

    lda #$02
    sta $420b       ; Start DMA

    plb
    plp
    plx
    pla
    rtl


warnpc $d07f00
org $82f710
sm_setup_door:
    php                         ; This runs some important routines to update the RAM with
    phb                         ; needed values for the door transition to work at all
    rep #$30            
    pea $8f00
    plb
    plb
    jsr $dfc7
    jsr $ddf1
    jsr $de12
    jsr $de6f  ; ADDING this call here. it will set the region number. this is called every door transition
    jsr $def2
    jsr $d961
    jsl $80858c  ; and then we're adding in the map restoration here

    plb
    plp
    rtl



