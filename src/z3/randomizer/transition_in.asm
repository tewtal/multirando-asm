; Transition into Zelda 3

print "ttz = ", pc
transition_to_zelda:
    sei                         ; Disable IRQ's
    
    %a8()
    %i16()

    phk
    plb                         ; Set data bank program bank

    lda #$00
    sta $004200                 ; Disable NMI and Joypad autoread
    sta $00420c                 ; Disable H-DMA

    lda #$8f
    sta $002100                 ; Enable PPU force blank
    
    %ai16()
    
    ldx #$01ff
    txs                         ; Adjust stack pointer

    lda #$0000                  ; Set the "game flag" to Zelda so IRQ's/NMI runs using the 
    sta !SRAM_CURRENT_GAME      ; correct game

    ; These things should already be handled by the SA-1
    ; jsr zelda_copy_sram         ; Copy SRAM back to RAM    
    ; jsl zelda_fix_checksum

    jsr zelda_spc_load          ; Load Zelda's music engine
    jsr zelda_blank_cgram       ; Blank out CGRAM
    jsr zelda_restore_dmaregs   ; Restore ALTTP DMA regs
    
    ;jsl zelda_restore_randomizer_ram

    lda !IRAM_TRANSITION_DESTINATION_ID
    sta $a0                     ; Store the transition outlet id

    %a8()
    sta $7b
    sta $4033ca
    cmp.b #$40
    bne +
    lda #$01
    sta $7e0fff
    lda #$0b
    sta $7e0aa4
    lda #$01
    sta $7e0ab3
    bra ++
+
    lda #$00
    sta $7e0fff
    sta $7e0ab3
    lda #$01
    sta $7e0aa4
++

    %a8()

    lda $7ef35a
    asl #6
    sta $7ef416                 ; Set progressive shield flag

    lda !SRAM_ALTTP_EQUIPMENT_1
    sta $000202
    lda !SRAM_ALTTP_EQUIPMENT_2
    sta $000303


    php
    jsl $0dfa78                 ; Redraw HUD
    jsl $00fc41
    %ai8()
    jsl $00e310                 ; Load default graphics
    jsl $09c499                 ; Load all overworld sprites
    plp

    jsl $1cf37a                 ; Regenerate dialog pointers

    jsl DecompSwordGfx          ; Update sword graphics
    jsl DecompShieldGfx         ; Update shield graphics
    jsl DecompressAllItemGraphics

    ; Load starting equipment, pre-open stuff
    LDA.l !SRAM_ALTTP_FRESH_FILE : BNE +
        JSL.l OnNewFile
        LDA.b #$FF : STA.l !SRAM_ALTTP_FRESH_FILE
    +

    lda #$ff
    sta $4201

    lda $1c
    sta $212c
    lda $1d
    sta $212d
    lda $1e
    sta $212e
    lda $1f
    sta $212f
    lda $94
    sta $2105
    lda $95
    sta $2106
    lda $96
    sta $2123
    lda $97
    sta $2124
    lda $98
    sta $2125

    lda #$13
    sta $2107
    lda #$03
    sta $2108
    lda #$63
    sta $2109
    lda #$22
    sta $210b
    lda #$07
    sta $210c

    lda #$02
    sta $2101

    lda #$00
    sta $2102
    sta $2103

    lda #$81
    sta $4200                   ; Turn NMI/IRQ/Autojoypad read back on

    lda #$01
    sta $420d                   ; Toggle FastROM on (used for rando banks)


    %ai16()

    cli                         ; Enable interrupts and push processor status to the stack
    ;php   

    lda $4210                   ; Acknowledge any pending IRQ's
    
    pea $0000
    plb

    lda $a0
    sta $a2

    %ai8()

    lda $0114
    jsl $02a0be
    jsl $02b81d
    lda #$08

    lda #$08
    sta $010c
    lda #$0f
    sta $10
    stz $11
    stz $b0


    %ai16()

    lda #$0000
    ldx #$00ff
    ldy #$0000

    lda.w #$0000
    sta.l NMIAux

    %ai8()

    lda #$08
    sta $10
    lda #$01
    sta $11

    lda #$48
    sta $010e
    
    lda #$00
    sta $010a

    ; lda #$05
    ; sta $10
    ; lda #$00
    ; sta $11

    jml $008034

zelda_spc_load:
    pha
    php

    %a8()

    ldx #$0000
-
    lda $00,x
    sta !SRAM_ALTTP_SPC_BUF,x
    inx
    cpx #$0100
    bne -

    lda #$00                    
    sta $00                     
    lda #$80                    
    sta $01
    lda #$19
    sta $02

    jsl alttp_load_music        ; Call the alttp SPC upload routine

    ldx #$0000
-
    lda !SRAM_ALTTP_SPC_BUF,x
    sta $00,x
    inx
    cpx #$0100
    bne -


    plp
    pla
    rts

zelda_blank_cgram:
    lda #$0000
    sta $2121
    ldx #$0000
-
    sta $2122
    inx
    cpx #$00ff
    bne -
    rts


zelda_restore_dmaregs:
    php
    %ai16()
    ldx #$0000                  ; Restore overworld area and coordinate data
-
    lda.l zelda_dmaregs,x
    sta.l $004300,x
    inx
    inx
    cpx #$0080
    bne -
    plp
    rts

zelda_save_start_hook:
    ; The save routine will be disrupted by NMI if this takes too long.
    ; Avoid doing anything time consuming here.
    lda #$01
    sta.l !SRAM_SAVING
    rtl

zelda_save_done_hook:
    lda #$0001
    jsl mb_RestoreItemBuffers      ; Restore all item buffers to proper SRAM in all games
    ; TODO: Fix when adding multiworld
    ; jsl mw_save_sram
    lda #$0000
    sta.l !SRAM_SAVING
    sep #$30
    plb
    rtl

zelda_restore_randomizer_ram:
    pha
    phx
    php
    %ai16()
    lda.l !SRAM_ALTTP_RANDOMIZER_SAVED
    beq .end

    ldx #$0000
-
    lda.l !SRAM_ALTTP_RANDOMIZER_BUF,x
    sta.l $7F5000,x
    inx
    inx
    cpx #$00d0
    bne -

.end
    plp
    plx
    pla
    rtl

;zelda_cgram:
;    incbin "../data/zelda-cgram.bin"

zelda_dmaregs:
    db $01, $18, $32, $ad, $7e, $4f, $01, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $ff
    db $01, $18, $80, $bb, $7e, $00, $00, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $ff
    db $01, $18, $c0, $bd, $7e, $00, $00, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $ff
    db $01, $18, $40, $b3, $7e, $00, $00, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $ff
    db $01, $18, $c0, $a5, $7e, $00, $00, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $ff
    db $41, $26, $f6, $f2, $00, $ff, $ff, $00, $ff, $ff, $ff, $ff, $00, $00, $00, $ff
    db $41, $26, $f6, $f2, $00, $c2, $1c, $00, $fc, $f2, $8f, $ff, $00, $00, $00, $ff    

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

    ldx #$8000
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

    ldx #$8000
    stx $2181       ; WRAM target address $8000

    
    ldx #$8000
    stx $2181       ; WRAM target address $8000
    
    lda #$00
    stx $2183       ; WRAM target bank (7e)
    
    inc $4314       ; Copy from next bank

    ldx #$8000
    stx $4315       ; Size (32768 bytes)

    ldx #$8000
    stx $4312       ; Store source address

    lda #$02
    sta $420b       ; Start DMA

    ldx #$0000
    stx $2181       ; WRAM target address $8000
    lda #$01
    sta $2183       ; WRAM bank 2 (7f)
    
    inc $4314       ; Copy from next bank
    
    ldx #$8000
    stx $4315       ; Size (32768 bytes)

    ldx #$8000
    stx $4312       ; Store source address

    lda #$02
    sta $420b       ; Start DMA

    ldx #$8000
    stx $2181       ; WRAM target address $8000
    lda #$01
    sta $2183       ; WRAM bank 2 (7f)
  
    inc $4314       ; Copy from next bank

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

    ldx #$8000
    stx $4312       ; Store source address

    ldx #$1801
    stx $4310       ; DMA A -> B (ROM -> VRAM)

    ldx #$0000      ; VRAM address
    stx $2116

    ldx #$8000
    stx $4315       ; Size (32768 bytes)

    lda #$02
    sta $420b       ; Start DMA

    inc $4314       ; Next bank
    
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
