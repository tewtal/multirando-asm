print "transition to m1 = ", pc

!M1_ENTRY_BASE_BANK = $90
!M1_ENTRY_ARGS_DIRECTION = $80
!M1_ENTRY_ARGS_SCROLLING = $40
!M1_ENTRY_ARGS_AREA = $07
!M1_ENTRY_DOOR_Y = $68
!M1_ENTRY_SAMUS_Y = $70
!M1_ENTRY_DOOR_TYPE = $01
!M1_ENTRY_DOOR_OPEN_FRAME = $F7
!M1_ENTRY_DOOR_CLOSE_RESET = $30
!M1_ENTRY_DOOR_CLOSE_START = $2E
!M1_ENTRY_DOOR_HOLD_DELAY = $FF
!M1_ENTRY_DOOR_EXIT_DELAY = $0F
!M1_ENTRY_VERTICAL_SCROLL_DIR = $00
!M1_ENTRY_VERTICAL_DOWN_SCROLL_DIR = $01
!M1_ENTRY_HORIZONTAL_SCROLL_DIR = $02
!M1_ENTRY_HORIZONTAL_RIGHT_SCROLL_DIR = $03
!M1_ENTRY_VERTICAL_MIRROR_CNTRL = $4F
!M1_ENTRY_HORIZONTAL_MIRROR_CNTRL = $47
!M1_TILEMAP_UPLOAD_ADDR_HIGH = $20
!M1_ATTR_UPLOAD_ADDR_HIGH = $23
!M1_ATTR_UPLOAD_ROW_TOP = $C0
!M1_ATTR_UPLOAD_ROW_BOTTOM = $E0
!M1_ATTR_UPLOAD_ROW_LENGTH = $20
!M1_BOSS_MUSIC_FLAG = $40
!M1_NO_BOSS_ROOM = $FF

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
    jsr m1_entry_apply_destination
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
    jsr m1_entry_prepare_bank_switch
    jsl $900000|(InitTransitionData&$ffff)

    %ai8()
    jsr m1_entry_apply_destination

    jsr m1_entry_clear_object_ram
    jsr m1_entry_prepare_room_load_scroll
    jsr m1_entry_load_room
    jsr m1_entry_finalize_entry_scroll
    jsr m1_entry_activate_loaded_name_table
    jsr m1_entry_seed_entry_door
    jsr m1_entry_apply_room_music

    lda $3A                         ; CartRAMPtrUB from SetupRoom.
    sta $01
    lda $39                         ; CartRAMPtrLB from SetupRoom.
    sta $00
    jsr m1_entry_upload_start_tilemap
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
    jsr m1_entry_get_program_bank
    pha : plb

    %ai16()
;   Restore gameplay
    ldx.w #$01F4 : txs
    lda.w #$C0BC
    sta.w m1_BankSwitchAddr
    %ai8()

    jsr m1_entry_get_program_bank
    sta.w m1_BankSwitchBank
    jml.w [m1_BankSwitchAddr]

m1_entry_apply_destination:
    lda.l !IRAM_TRANSITION_DESTINATION_ID
    sta $4F                         ; MapPosY = low byte of XXYY room id.
    lda.l !IRAM_TRANSITION_DESTINATION_ID+$1
    sta $50                         ; MapPosX = high byte of XXYY room id.
    jsr m1_entry_apply_destination_area
    jsr m1_entry_apply_area_palette_toggle

    lda.l !IRAM_TRANSITION_DESTINATION_ARGS
    and.b #!M1_ENTRY_ARGS_SCROLLING
    beq .horizontal
    lda.b #!M1_ENTRY_VERTICAL_SCROLL_DIR
    sta $49                         ; ScrollDir = vertical.
    sta $4A                         ; TempScrollDir.
    lda.b #!M1_ENTRY_VERTICAL_MIRROR_CNTRL
    bra .store_mirror

.horizontal
    lda.b #!M1_ENTRY_HORIZONTAL_SCROLL_DIR
    sta $49                         ; ScrollDir = horizontal.
    sta $4A                         ; TempScrollDir.
    lda.b #!M1_ENTRY_HORIZONTAL_MIRROR_CNTRL

.store_mirror
    sta $FA
    stz $FC                         ; ScrollY.
    stz $FD                         ; ScrollX.
    jsl SetPPUMirror
    rts

m1_entry_apply_destination_area:
    jsr m1_entry_get_area_index
    tax
    lda.l m1_entry_area_table,x
    sta $74                         ; InArea.
    lda.l m1_entry_current_bank_table,x
    sta $23                         ; CurrentBank.
    stz $24                         ; No deferred bank switch.
    rts

m1_entry_apply_area_palette_toggle:
    phb
    jsr m1_entry_get_program_bank
    pha
    plb
    lda.w $95DA                     ; Vanilla startup seeds PalToggle from area data.
    sta $76
    plb
    rts

m1_entry_prepare_bank_switch:
    jsr m1_entry_get_area_index
    tax
    lda.l m1_entry_current_bank_table,x
    sta $23
    lda.l m1_entry_bank_switch_table,x
    tay
    rts

m1_entry_get_area_index:
    lda.l !IRAM_TRANSITION_DESTINATION_ARGS
    and.b #!M1_ENTRY_ARGS_AREA
    cmp.b #$05
    bcc +
    lda.b #$00
+
    rts

m1_entry_get_program_bank:
    lda $23
    clc
    adc.b #!M1_ENTRY_BASE_BANK
    rts

m1_entry_get_door_side:
    ; Returns A = door side (0=right, 1=left).
    lda.l !IRAM_TRANSITION_DESTINATION_ARGS
    and.b #!M1_ENTRY_ARGS_DIRECTION
    beq +
    lda.b #$01
    rts
+
    lda.b #$00
    rts

m1_entry_get_door_slot:
    lda $50
    clc
    adc $4F
    pha
    jsr m1_entry_get_door_side
    lsr                             ; Carry = door side, matching vanilla LoadDoor.
    pla
    rol
    and.b #$03
    tax
    lda.l m1_entry_door_slot_table,x
    tax
    rts

m1_entry_clear_object_ram:
    ldx.b #$00
    lda.b #$00
-
    sta $0300, x
    inx
    bne -
    rts

m1_entry_prepare_room_load_scroll:
    lda.l !IRAM_TRANSITION_DESTINATION_ARGS
    and.b #!M1_ENTRY_ARGS_SCROLLING
    beq .exit

    jsr m1_entry_get_door_side
    beq .right_door
    lda.b #!M1_ENTRY_HORIZONTAL_RIGHT_SCROLL_DIR
    bra .store

.right_door
    lda.b #!M1_ENTRY_HORIZONTAL_SCROLL_DIR

.store
    sta $49                         ; Match vanilla side-door load before scroll toggle.
    sta $4A

.exit
    rts

m1_entry_finalize_entry_scroll:
    lda.l !IRAM_TRANSITION_DESTINATION_ARGS
    and.b #!M1_ENTRY_ARGS_SCROLLING
    beq .exit

    jsr m1_entry_get_door_side
    eor.b #$01                      ; Right door -> down, left door -> up.
    sta $49

.exit
    rts

m1_entry_get_loaded_name_table:
    lda $3A                         ; CartRAMPtrUB from SetupRoom.
    and.b #$04
    lsr #2
    rts

m1_entry_activate_loaded_name_table:
    lda PPUCNT0ZP
    and.b #$FE
    sta PPUCNT0ZP
    jsr m1_entry_get_loaded_name_table
    ora PPUCNT0ZP
    sta PPUCNT0ZP
    rts

m1_entry_load_room:
    lda.b #$ff
    sta $5A                         ; RoomNumber = undefined before GetRoomNum.
    jsr m1_entry_call_area_get_room_num
-
    jsr m1_entry_call_area_setup_room
    ldy $5A
    iny
    bne -
    rts

m1_entry_upload_start_tilemap:
    lda.b #$00
    sta.l $002115
    sta.l $002116
    jsr m1_entry_get_loaded_name_table
    asl #2
    clc
    adc.b #!M1_TILEMAP_UPLOAD_ADDR_HIGH
    sta.l $002117

    rep #$10
    ldx.w #$03C0
    ldy.w #$0000
-
    lda m1_RoomPalette              ; Default palette; full attributes are uploaded next.
    asl #2
    sta.l $002119
    lda ($00), y
    sta.l $002118
    iny
    dex
    bne -
    sep #$10
    rts

m1_entry_upload_room_attributes:
    php
    sep #$30
    lda.b #$00
    sta.l $004200                   ; Keep NMI from racing the attribute upload.
    lda PPUCNT0ZP
    and.b #$7F
    sta PPUCNT0ZP
    lda.b #$8F
    sta.l $002100
    lda.b #%00000010
    sta PPUCNT1ZP
    stz $1B
    stz $07A0
    stz $07A1
    rep #$20
    lda.w #$0000
    sta.w m1_TransferSourceSet
    sta.l m1_SnesPPUDataStringPtr
    sta.l m1_SnesPPUDataString
    sep #$20

    lda.b #$01
    sta $1B                         ; PPUDataPending.
    ldx.b #$00
    lda.b #!M1_ATTR_UPLOAD_ROW_TOP
    jsr m1_entry_queue_attribute_row
    lda.b #!M1_ATTR_UPLOAD_ROW_BOTTOM
    jsr m1_entry_queue_attribute_row
    stz $07A1,x
    stx $07A0                       ; PPUStrIndex.
    jsl SnesPPUPrepare
    jsl SnesProcessPPUString

    stz $1B
    stz $07A0
    stz $07A1
    rep #$20
    lda.w #$0000
    sta.w m1_TransferSourceSet
    sta.l m1_SnesPPUDataStringPtr
    sta.l m1_SnesPPUDataString
    sep #$20
    plp
    rts

m1_entry_queue_attribute_row:
    sta $02                         ; Source low byte and PPU destination row.
    jsr m1_entry_get_loaded_name_table
    asl #2
    clc
    adc.b #!M1_ATTR_UPLOAD_ADDR_HIGH
    sta $07A1,x
    inx
    lda $02
    sta $07A1,x
    inx
    lda.b #!M1_ATTR_UPLOAD_ROW_LENGTH
    sta $07A1,x
    inx

    lda $02
    sta $00
    lda $3A                         ; CartRAMPtrUB from SetupRoom.
    ora.b #$03                      ; Attribute table page for $6000/$6400 room RAM.
    sta $01
    ldy.b #$00
-
    lda ($00),y
    sta $07A1,x
    inx
    iny
    cpy.b #!M1_ATTR_UPLOAD_ROW_LENGTH
    bne -
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
    jsr m1_entry_call_area_check_pal_write
    jsr m1_entry_call_area_select_samus_pal
    jsr m1_entry_call_area_check_pal_write
    rts

m1_entry_seed_entry_door:
    jsr m1_entry_get_door_slot
    stx $4B                         ; PageIndex.
    jsr m1_entry_get_loaded_name_table
    sta $030C,x                     ; Door ObjectHi.
    sta $030C                       ; Samus ObjectHi.
    jsr m1_entry_get_door_side
    beq .right_door
    lda.b #$10
    bra .store_door_x

.right_door
    lda.b #$F0

.store_door_x
    sta $030E,x                     ; Door ObjectX.
    sta $030E                       ; Samus ObjectX.
    sta $51                         ; SamusScrX.
    lda.b #!M1_ENTRY_DOOR_Y
    sta $030D,x                     ; Door ObjectY.
    lda.b #!M1_ENTRY_SAMUS_Y
    sta $030D                       ; Samus ObjectY.
    sta $52                         ; SamusScrY.
    lda.b #$01
    sta $030B,x                     ; Door on screen.
    sta $030B                       ; Samus on screen.
    lda.b #!M1_ENTRY_DOOR_TYPE
    sta $0307,x                     ; Standard blue door, even when no room door exists.
    jsr m1_entry_call_area_open_door_tiles

    ldx $4B                         ; Door tile routine uses X; restore door slot.
    lda.b #$06
    sta $0300,x                     ; Door exit/close state.
    lda.b #!M1_ENTRY_DOOR_OPEN_FRAME
    sta $0303,x                     ; Door starts fully open/no bubble sprite.
    lda.b #!M1_ENTRY_DOOR_HOLD_DELAY
    sta $0304,x                     ; Hold open until DoorStatus clears.
    lda.b #!M1_ENTRY_DOOR_CLOSE_RESET
    sta $0305,x
    lda.b #!M1_ENTRY_DOOR_CLOSE_START
    sta $0306,x
    stz $030A,x

    lda.b #$05
    sta $56                         ; DoorStatus = exit door, no scrolling.
    sta $0300                       ; Samus ObjAction = sa_Door.
    lda.b #$04
    sta $57                         ; DoorScrollStatus = skip post-load scroll toggle.
    lda.b #$11
    sta $58                         ; Restore running when door exit finishes.
    lda.b #!M1_ENTRY_DOOR_EXIT_DELAY
    sta $59                         ; Door-exit distance.
    jsr m1_entry_get_door_side
    eor.b #$01
    sta $4D                         ; SamusDir faces into the loaded room.
    sta $4E                         ; SamusDoorDir moves out of the door.
    stz $0308
    stz $0309
    stz $0310
    stz $0311
    stz $0312
    stz $0313
    stz $0314
    rts

m1_entry_apply_room_music:
    lda $6987                       ; KrdRdlyPresent from SetupRoom.
    bne .queue_boss_music
    jsr m1_entry_destination_is_live_boss_room
    bcc .exit

.queue_boss_music
    lda.b #!M1_BOSS_MUSIC_FLAG
    sta $0685                       ; Replace area music queued by StartMusic.
    stz $6987                       ; Music is queued; do not restart it after door exit.

.exit
    rts

m1_entry_destination_is_live_boss_room:
    jsr m1_entry_get_area_index
    tax
    lda.l m1_entry_boss_room_table,x
    cmp.b #!M1_NO_BOSS_ROOM
    beq .no_match
    pha
    jsr m1_entry_call_area_get_room_num
    pla
    cmp $5A
    php
    lda.b #$FF
    sta $5A
    plp
    bne .no_match

    lda $74                         ; Match GetEnemyType's live Kraid/Ridley check.
    and.b #$06
    lsr
    tay
    lda $687A,y
    bne .no_match
    sec
    rts

.no_match
    clc
    rts

m1_entry_area_table:
    db $10, $11, $12, $13, $14

m1_entry_current_bank_table:
    db $01, $02, $04, $03, $05

m1_entry_bank_switch_table:
    db $02, $03, $05, $04, $06

m1_entry_boss_room_table:
    db $FF, $FF, $1D, $FF, $12

m1_entry_door_slot_table:
    db $80, $B0, $A0, $90

m1_entry_call_area_get_room_num:
    jsl m1_entry_call_area_routine
    dw $E720                        ; GetRoomNum.
    rts

m1_entry_call_area_setup_room:
    jsl m1_entry_call_area_routine
    dw $EA2B                        ; SetupRoom.
    rts

m1_entry_call_area_write_ppu_attrib_tbl:
    jsl m1_entry_call_area_routine
    dw $E5E2                        ; WritePPUAttribTbl.
    rts

m1_entry_call_area_check_pal_write:
    jsl m1_entry_call_area_routine
    dw $C1E0                        ; CheckPalWrite.
    rts

m1_entry_call_area_select_samus_pal:
    jsl m1_entry_call_area_routine
    dw $CB73                        ; SelectSamusPal.
    rts

m1_entry_call_area_open_door_tiles:
    jsl m1_entry_call_area_routine
    dw $8CFB                        ; Open entry-door tiles.
    rts

m1_entry_call_area_routine:
    php
    rep #$20
    sta.w m1_TableBankTemp
    sep #$30
    phx
    jsr m1_entry_get_area_index
    tax
    lda.l m1_entry_current_bank_table,x
    clc
    adc.b #!M1_ENTRY_BASE_BANK
    sta.w m1_BankSwitchBank
    rep #$20
    lda.w #$1000
    sta.w m1_BankSwitchAddr
    sep #$20
    plx
    rep #$20
    lda.w m1_TableBankTemp
    plp
    jml.w [m1_BankSwitchAddr]
