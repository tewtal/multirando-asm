print "Randomizer init = ", pc
randomizer_init:
    %a16()
    lda #$00ff
    sta !SRAM_CURRENT_GAME
    lda #$0000
    sta !SRAM_SAVING

    ; Check if there's an existing active save file
    jsr check_and_create_file
    rtl

check_and_create_file:
    %ai16()
    if defined("DEBUG")
        bra .no_file
    endif

    lda.l !SRAM_FILE_MARKER ; Compare against big-endian "DEAD5EED" marker
    cmp.w #$ADDE
    bne .no_file
    lda.l !SRAM_FILE_MARKER+$2
    cmp.w #$ED5E
    bne .no_file
    bra .file_exists
.no_file

    ; Initialize randomizer SRAM
    jsr clear_randomizer_ram
    jsr copy_initial_ram
    jsl CopyItemBuffers
    
    ; Write file marker
    lda.w #$ADDE
    sta.l !SRAM_FILE_MARKER
    lda.w #$ED5E
    sta.l !SRAM_FILE_MARKER+$2
.file_exists
.end
    rts

clear_randomizer_ram:
    ldx.w #$0000
    lda.w #$0000
-
    sta.l $400000, x
    inx #2
    cpx #$E000
    bne -
    
    rts

copy_initial_ram:
    ; Copy Z1 initram to BW-RAM buffer
    ldx.w #$0000
-
    lda.l z1_initram, x
    sta.l $40C800, x
    inx #2
    cpx.w #$0800
    bne -

    ; Copy Z1 initsram to BW-RAM buffer
    ldx.w #$0000
-
    lda.l z1_initsram, x
    sta.l $406000, x
    inx #2
    cpx.w #$2000
    bne -    

    ; Copy M1 initram to BW-RAM buffer
    ldx.w #$0000
-
    lda.l m1_initram, x
    sta.l $40D000, x
    inx #2
    cpx.w #$0800
    bne -

    ; Copy M1 initsram to BW-RAM buffer
    ldx.w #$0000
-
    lda.l m1_initsram, x
    sta.l $408000, x
    inx #2
    cpx.w #$2000
    bne -

    ; Copy ALTTP initram to BW-RAM buffer
    ldx.w #$0000
-
    lda.l alttp_initsram,x
    sta.l !SRAM_ALTTP_START,x
    inx #2
    cpx.w #$4000
    bne -
    
    jsr fix_alttp_checksum

    ; Copy SM initram to BW-RAM buffer
    ldx.w #$0000
-
    lda.l sm_initsram,x
    sta.l $400000,x
    inx #2
    cpx.w #$2000
    bne -
    
    rts    



fix_alttp_checksum:
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
    sta $4024fe
    sta $4033fe
    pla
    plp
    plx
    pla
    rts