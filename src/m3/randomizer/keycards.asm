;
; SM Keycard system (used for Keysanity)
;

!frame_tile = $A8BE  ; Tile to use for the frame around the keycards

; Hook initial drawing of pause screen to draw keycards status on BG3
; and make sure it draws only on the map screen and not equipment screen
org $828D47
    jsl keycard_draw_maptext

; org $8291AD
;     jsl keycard_hide_maptext

; org $8291D9
;     jsl keycard_show_maptext

; org $82933A
;     jsl keycard_restore_vars

; Redirect the grey door preinstruction list so we can customize it
org $84be43
    jsr keycard_greydoor_preinstruction_hook

; Pick out some unused space into the PLM bank for any custom things we might need
org $84d410
keycard_plm:
    dw keycard_plm_setup, keycard_plm_instructions
keycard_door_plms:
    dw keycard_greydoor_setup, $BE70, $BE59
    dw keycard_greydoor_setup, $BED9, $BEC2
    dw keycard_greydoor_setup, $BF42, $BF2B
    dw keycard_greydoor_setup, $BFAB, $BF94

keycard_greydoor_preinstruction_hook:
    cpy #$0020      ; If grey door type is > E0, it's a keycard door
    bcs .keydoor
    lda.w $BE4B, y
    rts
.keydoor
    lda #keycard_greydoor_preinstruction
    rts

keycard_greydoor_preinstruction:
    lda $1e17, x        ; Load special argument
    clc : adc #$0060    ; Turn it into an index start at $D830 (event 128 and up)
    jsl $808233         ; Check if event has happened and go to linked instruction if it has
    bcc .nope
    jmp $bdb2
.nope
    jmp $bdc4

keycard_plm_load:
    phy : phx 
    lda $1dc7, x            ; Load room argument (keycard item id)

    %a8()
    sta $4202
    lda #$0A
    sta $4203
    nop : nop : %ai16()
    lda $4216               ; Multiply it by 0x0A
    clc
    adc #item_graphics
    tay                     ; Add it to the graphics table and transfer into Y
    lda $0000, y
    jsr $8764               ; Jump to original PLM graphics loading routine
    plx
    ply
    rts

keycard_plm_instructions:
    dw keycard_plm_load     ; Load graphics
    dw $e04f                ; Draw
    dw $86bc                ; Delete

keycard_plm_setup:
    ldx $1C87,y             ;\
    lda #$0800              ;} Make PLM block a solid block with no BTS value
    jsr $82B4               ;/
    lda $7ED91A             ;\
    inc a                   ;} Increment global number of items loaded counter
    sta $7ED91A             ;/
    rts
warnpc $84d490

org $8486d1
keycard_greydoor_setup:
    lda $1DC8, y
    and #$00FF
    clc : adc #$0020       ; Add $20 to mark this as a Keycard grey door
    sta $1E17, y

    lda $1DC7, y   
    and #$00FF
    clc : adc #$0100       ; Add $100 so we start at door 256 and up (unused)
    sta $1DC7, y   
    
    ldx $1C87, y   ;\
    lda #$C044     ;} Make PLM shotblock with BTS 44h (generic shot trigger)
    jsr $82B4      ;/
    rts    

warnpc $84870b

; Use free space in bank 8e for any code that doesn't have to be in the PLM bank
org $8ef000

; Draw keycards on layer 2 tilemap
keycard_draw_maptext:
    phx : phy : phb
    phk : plb

    lda.l config_keycards
    bne .keycards
    jmp .exit

.keycards
    ; Use a few bytes of RAM from $7FFE00 to create our tilemap
    ldx #$fe00
    ldy #$0000
    lda #!frame_tile
-
    sta $7F0000, x
    inx #2
    cpx #$fe36
    bne -

    ldx #$fe00
    lda #$0080
    sta $14

.loop_three
    ; Draw a region
    lda .regions, y
    sta $7F0000, x
    inx #2
    
    ; Draw the three keys for the region
    phy
    ldy #$0000
-
    lda $14
    jsl $808233
    bcc +
    lda .cards, y
    sta $7F0000, x
    bra ++
+
    lda #!frame_tile
    sta $7F0000, x
++
    inx #2
    iny #2
    inc $14
    cpy #$0006
    bne -
    ply

    inx #2
    iny #2
    cpy #$0008
    bne .loop_three

.loop_two
    ; Draw a region
    lda .regions, y
    sta $7F0000, x
    inx #2
    
    ; Draw the two keys for the region
    phy
    ldy #$0000
-
    lda $14
    jsl $808233
    bcc +
    lda .cards, y
    sta $7F0000, x
    bra ++
+
    lda #!frame_tile
    sta $7F0000, x
++
    inx #2
    iny #4
    inc $14
    cpy #$0008
    bne -
    ply

    inx #2
    iny #2
    cpy #$000c
    bne .loop_two

    ; DMA to VRAM A604
    sep #$30
    lda #$02
    sta $2116
    lda #$53
    sta $2117
    lda #$80
    sta $2115
    jsl $8091A9
    db $01, $01, $18
    dl $7FFE00
    dw $0036
    lda #$02
    sta $420b
    rep #$30

.exit
    plb : ply : plx
    jsl $80A211
    rtl


.regions
; table ../../data/tables/box.tbl,rtl
;     dw "CBNMWL"
    dw $2432
    dw $2431
    dw $243D
    dw $243C
    dw $2446
    dw $243B
.cards
    dw $2805
    dw $2806
; table ../../data/tables/box_yellow.tbl,rtl
    dw $2831
; cleartable

warnpc $8effff
