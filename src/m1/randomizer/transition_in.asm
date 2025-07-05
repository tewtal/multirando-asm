print "transition to m1 = ", pc
transition_to_m1:
    ; At this point, we have WRAM restored from backup
    ; and the common routines copied back to $1000

    ;
    ; Any items found for this game is also already copied to RAM/SRAM by the SA-1 during the transition
    ; 

    %ai16()
    sei
    phk : plb
    ldx.w #$1FFF : txs

    jsl spc_init_driver

    sep #$30
    lda #$20 : sta $2107
    lda #$01 : sta $210B
    lda #$01 : sta $2105
    lda #$00 : sta $2101
    lda #$15 : sta $212C
    lda #$00 : sta $212d
    lda #$8f : sta $2100
    jsl SetupScrollHDMA

    jsl nes_initOAMBuffer  ; Clear SNES OAM Buffer

    ; Clear SNES port buffers
    rep #$30
    ldx #$0000
    lda #$0000

-
    sta.l $7e2200, x
    inx #2
    cpx #$1e00
    bne -

    ldx #$0000
-
    sta.l $7e0800, x
    inx #2
    cpx #$0400
    bne -    

    sep #$30
    jsl UploadItemPalettes
    jsl nes_overlay_init

    %ai16()

    lda #$D95C : sta $000810
    lda #$80C0 : sta $000812



    ; Destination args =
    ; DSxxxAAA
    ; D = Direction (1 = left, 0 = right)
    ; S = Scrolling (1 = vertical, 0 = horizontal)
    ; AAA = Area (0-4)
    lda.l !IRAM_TRANSITION_DESTINATION_ARGS
    and #$0007
    beq +
    ora #$0010
+
    sta $74        ; Set the area we're going to

    lda.l !IRAM_TRANSITION_DESTINATION_ARGS     ;  wrong for z3->m1 portal: is $0000 but should be something like $0100?
    and.w #$8000    ; if bit 8000 is clear it's a right-to-left transition
    beq .right_to_left

    lda.l !IRAM_TRANSITION_DESTINATION_ARGS
    and.w #$4000    ; check scrolling direction
    bne +
    lda.w #$0482 : sta $56
    bra ++
+
    lda.w #$0282 : sta $56
++

    lda.w #$0101 : sta $49
    lda.w #$0101 : sta $4D
    lda.w #$7112 : sta $51
    lda.w #$0171 : sta $30D
    
    lda.l !IRAM_TRANSITION_DESTINATION_ID
    ; Change the room to the room left of where we are
    xba : inc : xba
    bra .set_room

.right_to_left
    lda.l !IRAM_TRANSITION_DESTINATION_ARGS
    and.w #$4000    ; check scrolling direction
    bne +
    lda.w #$0481 : sta $56
    ; lda.w #$0482 : sta $56  ;  TESTING DOOR TRANSITION TO LEFT
    bra ++
+
    lda.w #$0181 : sta $56
++

    lda.w #$0303 : sta $49
    ; lda.w #$0202 : sta $49  ;  TESTING SCROLL DIRECTION CHANGE HERE
    ; lda.w #$0101 : sta $4d  ;  facing left, scrolling left
    ; lda.w #$7113 : sta $51  ;  set samus pos entering left doorway (game doesn't update samus pos until door exit)
    
    ;lda.w #$0000 : sta $4D
    ;lda.w #$71ED : sta $51
    ;lda.w #$FE71 : sta $30D
    lda.l !IRAM_TRANSITION_DESTINATION_ID
    ; Change the room to the room right of where we are
    xba : dec : xba

.set_room
    sta.b $4F
    

    ; Get what bank we need to switch to and put in A
    lda $74 : and #$000f : asl : tax
    lda door_bank, x
    
    pha
    and #$000f : inc : tay

    ; Perform a bank switch and load the correct graphics
    %ai8()
    phy

    lda PPUCNT0ZP : AND #$7F : STA PPUCNT0ZP
    lda #%00000010 : STA PPUCNT1ZP

    lda #$01 : sta $1c

    ; Restore World map
    jsl $901000 : dw $A93E

    ; Load samus GFX
    lda #$00 : sta $23
    jsl $901000 : dw $C5DC

    ; Enable NMI since some routines require it
    cli : lda.l $004210
    lda.b #$81 : sta.l $004200
    lda PPUCNT0ZP : ora #$80 : sta PPUCNT0ZP

    ; Get bank and perform a bank switch 
    ply : tya : dec : sta $23
    jsl $900000|(InitTransitionData&$ffff)

    %a16()
    lda.l door_entrypoint : sta.b $d0
    pla : sta.b $d2

    %ai8()
    pha : plb
    and #$0f : sta $23
    lda #$1f : sta PPUCNT1ZP

    ldx.b #$00
-
    lda.l door_stack, x
    sta $1f0, x
    inx
    cpx.b #$10
    bne -

    %ai16()
;   Restore gameplay
    ldx.w #$01F4 : txs
    %ai8()

    jml [$00d0]

door_entrypoint:
    dw $8b79
door_bank:
    dw $0091  ;    brinstar
    dw $0092  ;    norfair
    dw $0094  ;    kraid
    dw $0093  ;    tourian
    dw $0095  ;    ridley

door_stack:
    db $E6, $01, $77, $8B, $81, $58, $8B, $4D, $CB, $47, $C9, $C4, $C0, $56, $90, $87
