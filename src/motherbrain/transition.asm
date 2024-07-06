; Handles transitions between two games
; This code will always live in BW-RAM and can't be swapped out by SA-1 MMC bank switching
; so it's always safe to execute in
print "handle transition = ", pc
handle_transition:
    rep #$30
    pea $4040 : plb : plb

    lda !IRAM_TRANSITION_GAME_ID
    asl : tax
    lda.w transition_tables, x : tay       ; y = pointer to transition table
    inx #2
    lda.w transition_tables, x : sta $00   ; $00 = beginning of next table

    ldx #$0000
-
    lda.w $0000, y
    sta.l SNES_CMD_QUEUE, x
    inx #2 : iny #2
    cpy.b $00
    bne -

    txa : clc : adc.w #SNES_CMD_QUEUE : sta.l SNES_CMD_PTR

    ; Here's a chance to execute SA-1 only things at a faster rate
    ; before handling control over to the SNES where it'll execute the
    ; command list and start the next game

    ; Copy all items to the actual SRAM buffers (except for the game we just left)
    ; and fix checksums if needed
    lda.l !IRAM_TRANSITION_GAME_PREV_ID
    jsl RestoreItemBuffers

    ; Take a snapshot of all games SRAM/WRAM and save it to our temporary item buffers
    jsl CopyItemBuffers

    ; Wait for SNES to be ready
-
    lda.l $0037fe
    cmp #$CAFE
    bne -

    ; Execute commands
    lda.w #$BABE
    sta.l $0037fe

    rts

; Commands
; $0001 .vram_dma ; <source addr>, <source bank>, <dest addr>, <size>
; $0002 .vram_write ; <value>, <dest addr>
; $0003 .wram_dma ; <source addr>, <source bank>, <dest addr>, <dest bank>, <size>
; $0004 .bus_write ; <value>, <dest addr>
; $0005 .bus_write_long ; <value>, <dest addr>, <bank>
; $0006 .bus_write_byte ; <value>, <dest addr>
; $0007 .cgram_dma ; <source addr>, <source bank>, <size>
; $0008 .jml_target ; <target addr>

transition_tables:
    dw sm_transition_table
    dw z3_transition_table
    dw z1_transition_table
    dw m1_transition_table
    dw credits_transition_table
    dw transition_tables_end

sm_transition_table:
    ; Update SA-1 bank registers
    dw $0006, $0002, $2220
    dw $0006, $0003, $2221
    dw $0006, $0080, $2222
    dw $0006, $0081, $2223

    ; Set BW-RAM mapping at 6000-7FFF
    dw $0006, $0000, $2224

    ; Don't restore SRAM, VRAM or WRAM here (dependant on door direction bit for now)
    ; So it has to be done on the SNES cpu after loading WRAM and game state
    ; TODO: Fix this so that we can use a universal VRAM dump

    ; Set up IRQ/NMI handlers
    dw $0004, $835c, !IRAM_NMI
    dw $0004, $0095, !IRAM_NMI+2

    dw $0004, $6a5c, !IRAM_IRQ
    dw $0004, $0098, !IRAM_IRQ+2

    ; Done with transition setup, jump to entry point on the SNES side
    dw $0008, m3_transition_to_sm&$ffff, m3_transition_to_sm>>16

    dw $0000

z3_transition_table:
    ; Update SA-1 bank registers
    dw $0006, $0084, $2220
    dw $0006, $0084, $2222
    dw $0006, $0085, $2221
    dw $0006, $0085, $2223

    ; Set BW-RAM mapping at 6000-7FFF
    dw $0006, $0001, $2224

    ; Restore VRAM
    dw $0001, z3_zelda_vram&$ffff, z3_zelda_vram>>16, $0000, $8000
    dw $0001, z3_zelda_vram&$ffff, (z3_zelda_vram>>16)+1, $4000, $8000

    ; Restore WRAM
    dw $0003, z3_zelda_wram&$ffff, z3_zelda_wram>>16, $0000, $0000, $8000
    dw $0003, z3_zelda_wram&$ffff, (z3_zelda_wram>>16)+1, $8000, $0000, $8000
    dw $0003, z3_zelda_wram&$ffff, (z3_zelda_wram>>16)+2, $0000, $0001, $8000
    dw $0003, z3_zelda_wram&$ffff, (z3_zelda_wram>>16)+3, $8000, $0001, $8000

    ; Copy SRAM -> WRAM
    dw $0003, !SRAM_ALTTP_START&$ffff, !SRAM_ALTTP_START>>16, $f000, $0000, $0500
    dw $0003, (!SRAM_ALTTP_START+$0500)&$ffff, !SRAM_ALTTP_START>>16, $6000, $0001, $1000

    ; Set WRIO.7 to 1 (required by ALTTP)
    dw $0006, $0080, $4201

    ; Set up IRQ/NMI handlers
    dw $0004, $c95c, !IRAM_NMI
    dw $0004, $0080, !IRAM_NMI+2

    dw $0004, $d85c, !IRAM_IRQ
    dw $0004, $0082, !IRAM_IRQ+2

    ; Done with transition setup, jump to entry point on the SNES side
    dw $0008, z3_transition_to_zelda&$ffff, z3_transition_to_zelda>>16

    dw $0000

z1_transition_table:
    ; Update SA-1 bank registers
    dw $0006, $0080, $2220
    dw $0006, $0086, $2222
    dw $0006, $0080, $2221
    dw $0006, $0007, $2223

    ; Set BW-RAM mapping at 6000-7FFF
    dw $0006, $0003, $2224

    ; Restore WRAM from BW-RAM backup
    dw $0003, $C800, $0040, $0000, $0000, $0800

    ; Copy common routines from ROM -> RAM
    dw $0003, $8000, $0087, $1000, $0000, $1000

    ; Set up IRQ/NMI handlers
    dw $0004, $105c, !IRAM_NMI
    dw $0004, $8008, !IRAM_NMI+2

    ; Done with transition setup, jump to entry point on the SNES side
    dw $0008, z1_transition_to_z1&$ffff, z1_transition_to_z1>>16

    dw $0000

m1_transition_table:
    ; Update SA-1 bank registers
    dw $0006, $0080, $2220
    dw $0006, $0086, $2222
    dw $0006, $0080, $2221
    dw $0006, $0007, $2223

    ; Set BW-RAM mapping at 6000-7FFF
    dw $0006, $0004, $2224

    ; Restore WRAM from BW-RAM backup
    dw $0003, $D000, $0040, $0000, $0000, $0800

    ; Copy common routines from ROM -> RAM
    dw $0003, $8000, $0097, $1000, $0000, $1000

    ; Set up IRQ/NMI handlers
    dw $0004, $105c, !IRAM_NMI
    dw $0004, $9008, !IRAM_NMI+2

    ; Done with transition setup, jump to entry point on the SNES side
    dw $0008, m1_transition_to_m1&$ffff, m1_transition_to_m1>>16

    dw $0000

credits_transition_table:
    ; Update SA-1 bank registers
    dw $0006, $0007, $2220
    dw $0006, $0007, $2222
    dw $0006, $0007, $2221
    dw $0006, $0007, $2223

    ; Set up IRQ/NMI handlers
    dw $0004, (((credits_nmi&$ff)<<8)|$005c), !IRAM_NMI
    dw $0004, ((credits_nmi>>8)&$FFFF), !IRAM_NMI+2

    ; Done with transition setup, jump to entry point on the SNES side
    dw $0008, credits_init&$ffff, credits_init>>16

    dw $0000

transition_tables_end: