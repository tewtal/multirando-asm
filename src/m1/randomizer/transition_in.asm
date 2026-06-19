print "transition to m1 = ", pc

!M1_ENTRY_BANK = $91
!M1_ENTRY_BANK_INDEX = $01
!M1_ENTRY_BANK_SWITCH = $02
!M1_ENTRY_AREA = $10
!M1_ENTRY_MAP_X = $0B
!M1_ENTRY_MAP_Y = $0C
!M1_ENTRY_DOOR_SLOT = $A0
!M1_ENTRY_DOOR_X = $F0
!M1_ENTRY_DOOR_Y = $68
!M1_ENTRY_SAMUS_Y = $70
!M1_ENTRY_DOOR_HI = $00
!M1_ENTRY_DOOR_OPEN_FRAME = $33
!M1_ENTRY_DOOR_CLOSE_RESET = $30
!M1_ENTRY_DOOR_CLOSE_START = $2E
!M1_ENTRY_DOOR_HOLD_DELAY = $FF
!M1_ENTRY_SCROLL_DIR = $00
!M1_ENTRY_MIRROR_CNTRL = $4F

transition_to_m1:
    ; At this point, we have WRAM restored from backup
    ; and the common routines copied back to $1000

    ;
    ; Any items found for this game is also already copied to RAM/SRAM by the SA-1 during the transition
    ; 

    %ai16()
    sei
    phk : plb
    ; Scratch stack in IRAM to avoid corrupting WRAM during transition-in
    ; (reset to the NES stack $01f4 further down before the game loop runs).
    ldx.w #!IRAM_TRANSITION_STACK : txs

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

    ; Perform a bank switch and load the correct graphics.
    %ai8()
    lda #$00
    sta $1D                         ; GameMode = gameplay.
    lda #$03
    sta $1E                         ; MainRoutine = GameEngine.
    lda #!M1_ENTRY_BANK_INDEX
    sta $23                         ; CurrentBank = Brinstar.
    stz $24                         ; No deferred bank switch.
    lda #!M1_ENTRY_AREA
    sta $74                         ; InArea = Brinstar.
    lda #!M1_ENTRY_MAP_Y
    sta $4F                         ; MapPosY.
    lda #!M1_ENTRY_MAP_X
    sta $50                         ; MapPosX.
    lda #!M1_ENTRY_SCROLL_DIR
    sta $49                         ; ScrollDir = vertical.
    sta $4A                         ; TempScrollDir.
    stz $FC                         ; ScrollY.
    stz $FD                         ; ScrollX.
    lda #!M1_ENTRY_MIRROR_CNTRL
    sta $FA                         ; Bit 3 set = vertical scrolling mirroring.
    jsl SetPPUMirror
    stz $6C                         ; DoorOnNameTable3.
    stz $6D                         ; DoorOnNameTable0.
    stz $1B                         ; PPUDataPending.
    stz $07A0                       ; PPUStrIndex.

    lda #%00010000                  ; BG pattern table $1000, nametable 0, NMI off.
    sta PPUCNT0ZP
    lda #%00000010
    sta PPUCNT1ZP

    stz $1c                         ; PalDataPending.

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
    ldy #!M1_ENTRY_BANK_SWITCH
    lda #!M1_ENTRY_BANK_INDEX : sta $23
    jsl $900000|(InitTransitionData&$ffff)

    %ai8()
    lda #!M1_ENTRY_AREA
    sta $74
    lda #!M1_ENTRY_MAP_Y
    sta $4F
    lda #!M1_ENTRY_MAP_X
    sta $50
    lda #!M1_ENTRY_SCROLL_DIR
    sta $49
    sta $4A
    stz $FC
    stz $FD
    lda #!M1_ENTRY_MIRROR_CNTRL
    sta $FA
    jsl SetPPUMirror

    jsr m1_entry_clear_object_ram
    jsr m1_entry_load_room
    jsr m1_entry_seed_right_door

    lda $3A                         ; CartRAMPtrUB from SetupRoom.
    sta $01
    lda $39                         ; CartRAMPtrLB from SetupRoom.
    sta $00
    jsl UploadStartTilemap
    jsr m1_entry_upload_room_attributes
    jsr m1_entry_upload_initial_palettes

    lda #$1f
    sta PPUCNT1ZP
    lda #$0f
    sta.l $002100
    lda PPUCNT0ZP
    ora #$80
    sta PPUCNT0ZP
    lda #$81
    sta.l $004200
    lda #$01
    sta $1A
    lda #!M1_ENTRY_BANK
    pha : plb

    %ai16()
;   Restore gameplay
    ldx.w #$01F4 : txs
    %ai8()

    jml $91C0BC

m1_entry_clear_object_ram:
    ldx.b #$00
    lda.b #$00
-
    sta $0300, x
    inx
    bne -
    rts

m1_entry_load_room:
    lda.b #$ff
    sta $5A                         ; RoomNumber = undefined before GetRoomNum.
    jsl $911000 : dw $E720          ; GetRoomNum.
-
    jsl $911000 : dw $EA2B          ; SetupRoom.
    ldy $5A
    iny
    bne -
    rts

m1_entry_upload_room_attributes:
    php
    sep #$20
    rep #$10
    lda.b #$00
    sta.l $004200                   ; Keep NMI from racing the direct VRAM upload.
    lda PPUCNT0ZP
    and.b #$7F
    sta PPUCNT0ZP
    lda.b #$8F
    sta.l $002100

    lda.b #$80
    sta.l $002115                   ; Increment after VMDATAH writes.
    lda $3A                         ; CartRAMPtrUB from SetupRoom.
    clc
    adc.b #$03
    sta $01
    lda.b #$C0                      ; RoomRAM attribute table starts at +$03C0.
    sta $00

    rep #$20
    lda.w #$2000
    sta $02                         ; Current SNES tilemap block address.
    lda.w #$0000
    sta.l m1_SnesPPUDataStringPtr
    sep #$20

    ldy.w #$0000
    lda.b #$08
    sta $09                         ; NES attribute rows.
.row
    lda.b #$08
    sta $0A                         ; NES attribute columns.
.column
    lda ($00), y
    jsr m1_entry_write_attr_block
    iny

    rep #$20
    lda $02
    clc
    adc.w #$0004
    sta $02
    sep #$20

    dec $0A
    bne .column

    rep #$20
    lda $02
    clc
    adc.w #$0060
    sta $02
    sep #$20

    dec $09
    bne .row

    stz $1B
    stz $07A0
    plp
    rts

m1_entry_write_attr_block:
    sta $04
    and.b #$03
    asl #2
    sta $05                         ; Top-left quadrant.
    lda $04
    lsr #2
    and.b #$03
    asl #2
    sta $06                         ; Top-right quadrant.
    lda $04
    lsr #4
    and.b #$03
    asl #2
    sta $07                         ; Bottom-left quadrant.
    lda $04
    lsr #6
    asl #2
    sta $08                         ; Bottom-right quadrant.

    rep #$20
    lda $02
    sta.l $002116
    sep #$20
    lda $05
    sta.l $002119
    sta.l $002119
    lda $06
    sta.l $002119
    sta.l $002119

    rep #$20
    lda $02
    clc
    adc.w #$0020
    sta.l $002116
    sep #$20
    lda $05
    sta.l $002119
    sta.l $002119
    lda $06
    sta.l $002119
    sta.l $002119

    rep #$20
    lda $02
    clc
    adc.w #$0040
    sta.l $002116
    sep #$20
    lda $07
    sta.l $002119
    sta.l $002119
    lda $08
    sta.l $002119
    sta.l $002119

    rep #$20
    lda $02
    clc
    adc.w #$0060
    sta.l $002116
    sep #$20
    lda $07
    sta.l $002119
    sta.l $002119
    lda $08
    sta.l $002119
    sta.l $002119
    rts

m1_entry_upload_initial_palettes:
    lda.b #$00
    sta.l $004200                   ; Keep NMI from racing the direct palette upload.
    lda PPUCNT0ZP
    and.b #$7F
    sta PPUCNT0ZP
    lda.b #$8F
    sta.l $002100
    lda.b #%00000010
    sta PPUCNT1ZP
    rep #$20
    lda.w #$0000
    sta.l m1_SnesPPUDataStringPtr
    sep #$20
    lda.b #$01
    sta $1C                         ; Full room palette.
    jsl $911000 : dw $C1E0          ; CheckPalWrite.
    jsl $911000 : dw $CB73          ; SelectSamusPal.
    jsl $911000 : dw $C1E0          ; CheckPalWrite.
    rts

m1_entry_seed_right_door:
    ldx.b #!M1_ENTRY_DOOR_SLOT
    stx $4B                         ; PageIndex.
    lda.b #!M1_ENTRY_DOOR_HI
    sta $030C+!M1_ENTRY_DOOR_SLOT   ; Door ObjectHi.
    sta $030C                       ; Samus ObjectHi.
    lda.b #!M1_ENTRY_DOOR_X
    sta $030E+!M1_ENTRY_DOOR_SLOT   ; Door ObjectX.
    sta $030E                       ; Samus ObjectX.
    sta $51                         ; SamusScrX.
    lda.b #!M1_ENTRY_DOOR_Y
    sta $030D+!M1_ENTRY_DOOR_SLOT   ; Door ObjectY.
    lda.b #!M1_ENTRY_SAMUS_Y
    sta $030D                       ; Samus ObjectY.
    sta $52                         ; SamusScrY.
    lda.b #$01
    sta $030B+!M1_ENTRY_DOOR_SLOT   ; Door on screen.
    sta $030B                       ; Samus on screen.
    jsl $911000 : dw $8CFB          ; Open right-door tiles in RoomRAM.

    lda.b #$06
    sta $0300+!M1_ENTRY_DOOR_SLOT   ; Door exit/close state.
    lda.b #!M1_ENTRY_DOOR_OPEN_FRAME
    sta $0303+!M1_ENTRY_DOOR_SLOT   ; Door starts visually open.
    lda.b #!M1_ENTRY_DOOR_HOLD_DELAY
    sta $0304+!M1_ENTRY_DOOR_SLOT   ; Hold open until DoorStatus clears.
    lda.b #!M1_ENTRY_DOOR_CLOSE_RESET
    sta $0305+!M1_ENTRY_DOOR_SLOT
    lda.b #!M1_ENTRY_DOOR_CLOSE_START
    sta $0306+!M1_ENTRY_DOOR_SLOT
    stz $030A+!M1_ENTRY_DOOR_SLOT

    lda.b #$05
    sta $56                         ; DoorStatus = exit door, no scrolling.
    sta $0300                       ; Samus ObjAction = sa_Door.
    lda.b #$04
    sta $57                         ; DoorScrollStatus = vertical room centered.
    lda.b #$11
    sta $58                         ; Restore running when door exit finishes.
    lda.b #$20
    sta $59                         ; Vanilla door-exit distance.
    lda.b #$01
    sta $4D                         ; SamusDir = left.
    sta $4E                         ; SamusDoorDir = left.
    stz $0308
    stz $0309
    stz $0310
    stz $0311
    stz $0312
    stz $0313
    stz $0314
    rts
