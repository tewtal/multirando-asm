
; New and repurposed vars
SmallStringRAM      := $C9          ; Small piece of prev. unused RAM (~ $C bytes) will be used for small PPU strings
SaveFileIndex       := $6875        ; $00, $20, or $40, "pointer" to selected save file             
SaveFileNum         := $6876        ; $00, $01, or $02, index of selected save file
StartContinue       =  $0325        ; (original usage) Whether start or continue is selected at title screen
MenuSelection       := $0325        ; (New usage) Menu selection (0 = file 0, 1 = file 1, 2 = file 2, 3 = ERASE, or for game over, 0 = continue, 1 = save, 2 = quit)

; Save memory + some vars
.ENUM $7500

    SaveFiles:
        ; Note that File_PassData hold all of the actual save data (except for health). This variable holds the password,
        ; which is handed off the the already-present password system to resume gameplay. Other variables present in the
        ; file are either there (A) to manage the file or (B) as an easily-accesible variable used to render the file menu
        ; since it is difficult to extract this info from the password.

    File_1:
        File_InUse:         .DSB $1             ; 0 = empty, 1 = in use
        File_PassData:      .DSB $12            ; Password data (see PasswordBytes). This holds all the important save data. 
        File_UnusedBytes:   .DSB $4             ; Not currently used. (Feel free to use this to save extra data if you're making a hack!)
        File_Health:        .DSB $2             ; Health (from HealthHi and HealthLo)
        File_SamusGear:     .DSB $1             ; Equipment (from SamusGear) (for File Menu drawing only)
        File_Missiles:      .DSB $1             ; Missiles (for File Menu drawing only)
        File_MissileMax:    .DSB $1             ; Missile Capacity (for File Menu drawing only)
        File_Area:          .DSB $1             ; The area the player saved in. This value is written upon save, but never used anywhere else. Displaying the area the player saved in was considered.
        File_Tanks:         .DSB $1             ; The number of tanks the player has. (for File Menu drawing only)
        File_Checksum:      .DSB $1             ; The sum (truncated) of all previous file variables, used to verify the file.
        File_Checkxor:      .DSB $1             ; The value produced by xoring all file bytes together, excluding Checksum and Checkxor, used to verify the file.
        EndFile1:
        
        FileSize            = <(EndFile1 - File_1)
        FileSize_NoChecksum = Filesize - 2
    File_2:
        .DSB FileSize
    File_3:
        .DSB FileSize
        
    ; General purpose vars
        localVar:           .DSB 1              ; General use
        localVar2:          .DSB 1              ; General use
        localVar3:          .DSB 1              ; General use
        
    ; Menu Cursor
        CursorDisplayX:     .DSB 1      ; Shown cursor position (cursor will 'slide' toward actual position)
        CursorDisplayY:     .DSB 1
        CursorX:            .DSB 1      ; Actual cursor position
        CursorY:            .DSB 1
        DeleteMode:         .DSB 1      ; 0 = no, 1 = yes
.ENDE

FileIndex_1 = $00
FileIndex_2 = FileSize
FileIndex_3 = FileSize * 2


; -----------------------------------------
; Section 1
; -----------------------------------------
    ; free space: $BDCD - $BE76
    .PATCH 00:BDCD
    Section1:
    Section1Limit = $BE76
    
    
    FileIndexList:
        ; Used to retrieve file index for a given save file number
        .db FileIndex_1
        .db FileIndex_2
        .db FileIndex_3
    

        
    InitFileDisplay:
        ; Verifies files are valid, then draws the file menu.
        
        ; verify files
        ldy #0
        jsr VerifyFile
        ldy #1
        jsr VerifyFile
        ldy #2
        jsr VerifyFile
        
        ; render files
        ldy #0
        jsr RenderFile
        ldy #1
        jsr RenderFile
        ldy #2
        jsr RenderFile
    
        ; Init menu variables
        ldy #$00                    ;
        sty MenuSelection           ; MenuSelection = 0
        sty DeleteMode              ; DeleteMode = false
        dey
        sty CursorDisplayX          ; CursorDisplayX/Y are set to FF (lower-right
        sty CursorDisplayY          ; corner). This causes the cursor to zip into
                                    ; place when the menu is shown.
        ;return from hijack
        jmp ScreenOn
        
        
        
    VerifyFile:
        ; Verifies a single file, sets it to empty if the file is not valid.
        ; This is needed the first time the game is booted to clear garbage in RAM.
        ; y [in] file num
        
        lda FileIndexList,Y
        tax
        stx SaveFileIndex
        
        ; If file is not in use, don't bother verifying
        lda File_InUse,X
        beq @exit

        ; Verify checksum        
        jsr GetFileSum          ; Get checksum
        ldx SaveFileIndex       ; Get file index
        cmp File_Checksum,X     ; Compare to stored checksum
        bne @ClearFile          ; Mark file unused if checksum invalid              
        
        ; Verift checkxor
        jsr GetFileXor          ; Get checkxor
        ldx SaveFileIndex       ; Get file index
        cmp File_Checkxor,X     ; Compare to stored checkxor
        beq @exit               ; Mark file unused if checkxor invalid
        
        @ClearFile:
        lda #$00
        sta File_InUse,X
        
        @exit:
        rts
        
        
        
    GetFileSum:
        ; Add all save file bytes together
        ; Destroys X and Y
        ; x [in]    File index
        ; a [out]   Sum
        lda #$00
        ldy #FileSize_NoChecksum
        *
            clc
            adc SaveFiles,X
            inx
            dey
            bne -
        rts
            
        
        
    GetFileXor:
        ; XOR all save file bytes together
        ; Destroys X and Y
        ; x [in]    File index
        ; a [out]   xor result
        lda #$00
        ldy #FileSize_NoChecksum
        *
            clc
            eor SaveFiles,X
            inx
            dey
            bne -
        rts

        
        
    InitializeStats_InitHealth:
        ; Extends InitializeStats to set initial health value to 30
        ; (This used to be done in SamusInit which is called by GoMainRoutine)
        lda #$03
        sta HealthHi
        lda #$00
        sta HealthLo
        
        ; displaced code:
        ;LDA #$00			        ;A already 0
        STA $6876           ;SamusStat00			
        rts
            
        
        
    FileBlankStrings:
        ; Pointers to PPU strings to blank out the energy tank and missile display for empty file
        .dw FileBlank_1
        .dw FileBlank_2
        .dw FileBlank_3
        
        
        
    FileItemStrings:
        ; Pointers to PPU strings for each file's equipment display
        .dw FileItems_1
        .dw FileItems_2
        .dw FileItems_3
        
        
        
    ItemPPUAddresses:
        ; Base address for each file's equipment display. Used for blanking items the player does not posess.
        .dw $2545
        .dw $25E5
        .dw $2685
        
        
        
    TankPPUAddresses:
        ; Base address for each file's tank display. Used for blanking tanks the player does not have.
        .dw $250B
        .dw $25AB
        .dw $264B
        
        
    EquipmentFlags:
        ; This is the order items appear on the file screen (corresponds to SamusGear values)
        .db $10, $01, $02, $20, $08, $04, $40, $80    

        
        
    endSection1:
        .if endSection1 > Section1Limit
            .error CODE EXCEEDED AVAILABLE SIZE
        .endif
            
; -----------------------------------------
; Section 2
; -----------------------------------------
    .PATCH 00:A960
    ; Free space: $A961 - $ABFF
    Section2:
    Section2Limit = $ABFF
    
    LoadMapHijack:
        ; Push map loading routine address to stack
        lda #>(MapLoadEntryPoint - 1)
        pha
        lda #<(MapLoadEntryPoint - 1)
        pha
        ldy #$0E
        jmp RomSwitch
    
    RenderFile:
        ; Draws a save file to the file menu
        ; y [in] file number
        
        ; Usage of locals
        ; localVar = loop counter
        ; localVar2 = File number * 2 (used to load 2-byte value from tables) (in retrospect, it would be smarter to split these tables in two, one for high byte and one for low)
        ; localVar3 = Player's equipment
        
        lda FileIndexList,Y                 ; Get and store file index
        tax
        stx SaveFileIndex
        sty SaveFileNum
        
        ;y *= 2 (pointer table index)
        tya
        asl
        tay
        sty localVar2
        
        lda File_InUse,X                    ; If file is empty, blank it out 
        bne +
            jmp @RenderEmptyFile
        *
        
        @RenderUsedFile:
            ; Start by drawing all possible equipment, then blank out equipment player doesn't have

            ldx FileItemStrings,Y           ; Draw all items
            lda FileItemStrings + 1,Y
            tay
            jsr PreparePPUProcess_
            
            ldy localVar2
            ldx SaveFileIndex
            lda File_SamusGear,X
            sta localVar3
            
            lda #$07                        ; process 8 bits
            sta localVar
            @loop
                lda localVar3                   ; Get equipment
                ldx localVar                    ; Which item are we checking?
                and EquipmentFlags,x            ; Check it.
                bne @skipItem                   ; Don't blank it out if player has it.
                
                    ldy localVar2               ; Get ptr table index
                                
                    ; Create PPU string to clear top 2 tiles
                    lda ItemPPUAddresses + 1,Y  ; PPU Dest Hi
                    sta SmallStringRAM
                    lda localVar                ; PPu Dest Lo (3 * item_index + base_address)
                    asl                         ;   item index * 2
                    clc
                    adc localVar                ;   + item index
                    adc ItemPPUAddresses,Y      ;   + base address
                    sta SmallStringRam + 1
                    lda #$42                    ; PPU Length byte (two tiles, RLE)
                    sta SmallStringRam + 2
                    lda #$FF                    ; PPU tiles: FF (blank)
                    sta SmallStringRam + 3
                    lda #$00                    ; End of data
                    sta SmallStringRam + 4
                    
                    ; Load to PPU
                    ldx #SmallStringRam
                    ldy #$00
                    jsr PreparePPUProcess_
                    
                    ; Create PPU string to clear bottom 2 tiles
                    ; (use same string, but add $20 to ppu dest for next row)
                    lda #$20
                    clc
                    adc SmallStringRam + 1
                    sta SmallStringRam + 1
                    bcc+                        ; Carry
                        inc SmallStringRam
                    *
                    
                    ; Load to PPU
                    ldx #SmallStringRam
                    ldy #$00
                    jsr PreparePPUProcess_

                    
                @skipItem:
                dec localVar
            bpl @loop
        
            
            @BlankTanks:
            ; 8 tanks are currently shown. Blank enough to show correct amt
            
            ldx SaveFileIndex           ; Get tank count
            lda File_Tanks,X
            sta localVar
            
            ldy localVar2               ; Get PPU address of tanks
            lda TankPPUAddresses+1,Y    ;   PPU dest hi
            sta SmallStringRam
            lda TankPPUAddresses,Y      ;   PPU dest lo
            clc
            adc localVar                ;     + tank count (leave this many tanks)
            sta SmallStringRam+1
            
            lda #$48                    ; 8 tiles, RLE
            sec
            sbc localVar                ;   - tank count
            sta SmallStringRam+2
            
            lda #$FF                    ; FF = blank tiles
            sta SmallStringRam+3
            
            cmp #$40                    ; If player has 8 tanks, there is nothing to blank out. Move on to next thing.
            beq @DontBlankTanks
                                
            ; Send to PPU
            ldx #SmallStringRam
            ldy #$00
            jsr PreparePPUProcess_
            @DontBlankTanks:


            @ShowMissiles:
            ldy localVar2               ; Calculate PPU address of missiles (to right of tanks)
            lda TankPPUAddresses,Y
            clc
            adc #$0B
            sta SmallStringRam+1
            
            ldx SaveFileIndex           ; Get missile count, convert to decimal
            lda File_Missiles,X
            jsr HexToDec
            
            ldx #$03                    ; Insert into PPU string
            jsr @AddDecimalToPpuString
            
            lda #$F6                    ; Insert slash
            sta SmallStringRam,X
            inx
            
            txa                         ; Remember our place
            pha
            
            ldx SaveFileIndex           ; Get missile capacity, convert to decumal
            lda File_MissileMax,X
            jsr HexToDec
            
            pla                         ; Back to our PPU string
            tax
            
            jsr @AddDecimalToPpuString  ; Insert missile capacity into string
            
            lda #$00                    ; Add our zero terminator
            sta SmallStringRam,X

            lda #$07                    ; string size is 7 (two 3-digit nums + slas)
            sta SmallStringRam+2
        
            ; Load to PPU
            ldx #SmallStringRam
            ldy #$00
            jsr PreparePPUProcess_

            rts 
            
        @RenderEmptyFile:
            ;Blank out energy tanks and missile count with ready-made PPU string
            ldx FileBlankStrings,Y
            lda FileBlankStrings + 1,Y
            tay
            jsr PreparePPUProcess_
            rts 
            
        @AddDecimalToPpuString:
            ; x   [in]  position within string to output
            ; $00 [in]  1s place
            ; $01 [in]  10s place
            ; $02 [in]  100s place
            ; x   [out] position within string after output

            lda $02                     ; 100 place
            bne +                       
                lda #$FF                ; Don't show digit if 0
            *
            sta SmallStringRam,X    
            
            lda $01                     ; 10 place
            bne +                       ; Show if not zero
            tay                         ; Show if zero but 100s place is non-zero
            bne +
                lda #$FF                ; Don't show digit 
            *
            sta SmallStringRam+1,X
            
            lda $00                     ; 1 place (always show, even if 0)
            sta SmallStringRam+2,X
            
            ; Update ptr to name table string
            inx
            inx
            inx

            rts

            
        
        
    SaveGame:
        jsr CalculatePassword           ; Create save data
        
        ldx SaveFileIndex               ; Mark file as in-use
        lda #$01                    
        sta File_InUse,X
        
        lda SamusGear                   ; Save equipment, area, health for menu display 
        sta File_SamusGear,X
        lda TankCount
        sta File_Tanks,X
        lda MissileCount
        sta File_Missiles,X
        lda MaxMissiles
        sta File_MissileMax,X
        lda InArea
        and #$0F                        ; Only need lower nibble of area
        sta File_Area,X
        lda HealthLo
        sta File_Health,X
        lda HealthHi
        sta File_Health+1,X
        
        lda #$11                        ; Copy the $12 bytes of password data
        tay                             ; ($11 to $00)
        clc
        adc SaveFileIndex
        tax                             ; Index into corresponding save file bytes
        
        ldy #$11
        *
            lda PasswordBytes,Y
            sta File_PassData,X
            dex
            dey
        bpl -
        
        ldx SaveFileIndex               ; Calculate and save checksums
        jsr GetFileSum
        ldx SaveFileIndex               ; (X overwritten by checksum routine)
        sta File_Checksum,X
        jsr GetFileXor
        ldx SaveFileIndex               ; (X overwritten by checkxor routine)
        sta File_Checkxor,X        
        
        rts

        
        
    LoadGame:
        ldx SaveFileIndex               ; If file is empty, start a new game
        lda File_InUse,X
        bne +
            jmp InitializeStats
        *
    
        lda File_Health,X               ; Load player health
        sta HealthLo
        lda File_Health+1,X
        sta HealthHi

        txa                             ; Copy 12 password data bytes
        clc
        adc #$11
        tax
        ldy #$11
        *
            lda File_PassData,X     
            sta PasswordBytes,Y
            dex
            dey
        bpl -
        
        
        lda PPU2000_Cache               ; Switch to nametable 0 (or else glitches)
        and #$FE
        sta PPU2000_Cache
        
        jmp InitializeGame              ; Continue (initialize game with password data)

        
        
    BeepSound:
        ; Beeps
        LDA TriangleSFXFlag		
        ORA #$08			
        STA TriangleSFXFlag		
        rts
    
    GulpSound:
        ; Gulps
        LDA TriangleSFXFlag	
        ORA #$04
        STA TriangleSFXFlag
        rts
    
    CheckMenuUpDown:
        ; Processes menu item selection (up, down, delete mode activation/cancelation)
        lda Joy1Change
        and #$0C
        beq @NoUpDown
        
        cmp #$04                ; Down?
        bne +
        inc MenuSelection       ;   Move to next selection (wrap from 3 to 0)
        jsr BeepSound
        jmp @TruncateAndReturn
        
        *                       ; Up
        inc MenuSelection       ;   Move forward 3 menu selections
        inc MenuSelection       ;   (Since there are 4 options, we'll have
        inc MenuSelection       ;   wrapped back to previous selection)
        jsr BeepSound
        
        
        @TruncateAndReturn:
        lda #$03                ; Wrap around (from last item to first or vice-versa)
        and MenuSelection
        sta MenuSelection
        
        @NoUpDown:
        
        ; Pressing A, B, or select cancels erase mode and moves cursor off "ERASE"
        lda Joy1Change
        and #$E0
        beq ++
            lda #$00
            sta DeleteMode

            lda MenuSelection   ; If "ERASE" selected, move to irst item
            cmp #$03
            bne +
                lda #$00
                sta MenuSelection
            *
            
        *
        
        ; Pressing start while "ERASE" is selected enters erase mode
        lda Joy1Change
        and #$10                ; Was start pressed?
        beq +
        lda MenuSelection       ; Was "ERASE" selected?
        cmp #$03
        bne +
            lda #$00            ;   Select File 1
            sta MenuSelection
            lda #$03
            eor DeleteMode      ;   Toggle Deletion mode
            sta DeleteMode
            jsr GulpSound       ;   Play sound

        *
        
        rts
    
        
        
    UpdateFileCursor:
        ; Updates cursor display position for "gliding" effect
        
        ldy MenuSelection       ; Get cursor position based on currently selected item
        lda CursorPositionX,Y
        sta CursorX
        lda CursorPositionY,Y
        sta CursorY
    
        ; Updates display position of cursor to glide to actual position
        lda #$00                ; High byte for 16-bit math (use A for low byte)
        sta localVar
        
        lda CursorX             ; Cursor X
        cmp CursorDisplayX      ; (add 1 extra (via carry flag) if actual pos is greater, to round up when we divide)
        adc CursorDisplayX      ; + display x
        bcc+
            inc localVar        ; Carry to high byte
        *
        lsr localVar            ; 16-bit divide by 2
        ror
        sta CursorDisplayX
                                ; Don't need to reset localVar, it was cleared when we divided
        lda CursorY             ; Cursor Y
        cmp CursorDisplayY      ; (+ 1 (via carry) if actual pos is greater, to round up when we divide)
        adc CursorDisplayY      ; + display Y
        bcc +
            inc localVar        ; Carry to high byte
        *
        lsr localVar            ; 16-bit divide by 2
        ror
        sta CursorDisplayY
        
        rts
    
        
        
    DrawFileCursor:
        ; Draws the file menu cursor sprites
        ldy #$00
        ldx #$00

        lda CursorDisplayX
        sta localVar
        
        *
            lda CursorTiles,Y       ; Get tile number
            beq @DoneDrawing        ; If zero, we are done
            sta $201,X              ; Spr Y
            lda CursorDisplayY      
            sta $200,X
            lda #$21                ; Spr Attr (Behind text, pal 1)
            eor DeleteMode          ;          (pal 0 if erase mode)
            sta $202,X
            lda localVar            ; Spr X 
            sta $203,X
            clc                     ; Next tile 8 px to the right
            adc #$08                
            sta localVar
            
            inx                     ; Next sprite
            inx            
            inx
            inx
            
            iny                     ; Next tile
            
        bne -                       ; Branch always
        
        @DoneDrawing:
        rts
        
        
        
    ResetTitleAnimation:
        ; Resets title screen animation instead of displaying your "mission"
        lda #$04
        sta TitleRoutine
        lda #$20			;Set timer delay for METROID flash effect.-->
        sta Timer3			;Delays flash by 320 frames (5.3 seconds).
        rts



        
        
    endSection2:
    .if endSection2 > Section2Limit
        .error CODE EXCEEDED MAX SIZE (section 2)
    .endif


             
; -----------------------------------------
; Section 3
; -----------------------------------------
    ;$945F - $955F
    .PATCH 00:945F
    Section3Start:
    Section3Limit = $955F
    
    
    
    CursorTiles:
        ; Sprite tiles used to make the cursor
        .db $D0, $D1, $D1, $D1, $D1, $D1, $D1, $D2, $00
    
    
        
    CursorPositionX:
        ; Cursor X position for each file menu item
        .db $10, $10, $10, $B3


        
    CursorPositionY:
        ; Cursor y position for each file menu item
        .db $3f, $67, $8F, $1F
    
    
    
    UpdateGameOverScreen:
    
        lda Joy1Change
        and #$0C
        beq @EndUpDown              ; Is the player pressing up or down?
            cmp #$08                ; 
            bne+                    ;   Up:
                dec MenuSelection   ;     Previous item
                
                bpl @Beep           ;     Wrap from first to last
                lda #$02
                sta MenuSelection
                bne @Beep           ;     (branch always)
                
            *                       ;   Down:
                inc MenuSelection   ;     Next item
                
                lda MenuSelection

                cmp #$03            ;     Wrap from last to first
                bne @Beep
                lda #$00
                sta MenuSelection
        @Beep:
        jsr BeepSound
        
        @EndUpDown:
        lda Joy1Change
        and #$10                    ; Pressing Start?
        beq @ShowCursor
            dec MenuSelection       ;   Continue?
            bpl +
                jMP InitializeGame  ;     Continue. (Not sure whether I should jmp or jsr, but either one seams to leave stack balanced)
            *
            dec MenuSelection       ;   Save or Quit:
            bpl +                   ;     Don't save if player selected quit
                jsr SaveGame
                *
                jmp RESET           ;     Soft reset if player picked save or quit
    
        @ShowCursor:
        lda #$68
        sta $0203                   ; X
        ldy MenuSelection
        lda GameOverCursorY,y       ; Y
        sta $0200
        lda #$6f                    ; Tile
        sta $0201
        lda #$03
        sta $0202                   ; Palette
        
        rts
        
        
        
    GameOverCursorY:
        .db $0d * $08 - 1, $10 * $08 - 1, $13 * $08 - 1


        
    GameOverMenuStrings:
        ; Samus row 1
        .db $20, $8A, $03
        .db $F7, $F8, $F9
        
        ; GAME OVER, Samus row 2
        .db $20, $AA, $0d
        .db $FA, $FB, $FC, $FF, $10, $0a, $16, $0e, $ff, $18, $1f, $0e, $1b
    
        ; Samus row 3
        .db $20, $CA, $03
        .db $FD, $F4, $F5
        
        ;Defeat the Mother Brain and the Metroid threat!
        .db  $21, $05, $17
        .db $0d, $0e, $0f, $0e, $0a, $1D, $FF, $16, $18, $1d, $11, $0e, $1b, $FF
        .db $0b, $1b, $0a, $12, $17, $FF, $0A, $17, $0d
        .db $21, $27, $13
        .db $1d, $11, $0e, $FF, $16, $0e, $1d, $1b, $18, $12, $0d, $FF, $1d, $11, $1b, $0e, $0a, $1d, $CF
        
        ; CONTINUE
        .db $21, $AD, $0A
        .db $FE, $FF, $0c, $18, $17, $1d, $12, $17, $1e, $0e
        
        ; SAVE
        .db $22, $0D, $06
        .db $FE, $FF, $1c, $0a, $1f, $0e
    
        ; QUIT
        .db $22, $6D, $06
        .db $FE, $FF, $1a, $1e, $12, $1d
        
        ; Attributes (for samus)
        .db $23, $CA, $02, $55, $99
        .db $23, $D0, $08, $55, $55,$55, $55,$55, $55,$55, $55
        ;.db $23, $D2, $02, $55, $F9
        
        ; END OF DATA
        .db  $00
    
    Section3End:
    nop
    .if Section3End > Section3Limit
        .error Section 3 too big
    .endif

   
 
; -----------------------------------------
; Section 4
; -----------------------------------------        
    PATCH 0F:FFD5
    Section4:
        ;FFD5 - FFF9
        
        
        
    CheckMinHealth:
        lda HealthHi    ; Exit if health (including full tanks) >= 30
        cmp #$03
        bcs +

        lda #$03
        sta HealthHi
        lda #$00
        sta HealthLo
        
        *
        rts

    EndSection4:
        .if EndSection4 - Section4 > $FFF9 - $FFD5
            .error Section 4 too big
        .endif
                
        .PATCH 0F:c1f7
        ; This hack causes the stars to flicker while a file is being selected
;        LC1F7:	cmp #$15			;Is intro playing? If not, branch.
        cmp #$17
    
    
; -----------------------------------------
; Section 5
; -----------------------------------------        
    .PATCH 00:B135
    MaxSize2 = $B200 - $B135
    FileSCreenItemStrings:


    FileItems_1:
        .byte $25, $45
        .byte $18
        .byte $D0, $D1, $FF, $D2, $D3, $FF, $D4, $D5, $FF, $D6, $D7, $FF, $D8, $D9, $FF, $DA, $DB, $FF, $DC, $DD, $FF, $DE, $DF, $FF
        .byte $25, $65
        .byte $18
        .byte $E0, $E1, $FF, $E2, $E3, $FF, $E4, $E5, $FF, $E6, $E7, $FF, $E8, $E9, $FF, $EA, $EB, $FF, $EC, $ED, $FF, $EE, $EF, $FF
        ; END PPU DATA
        .byte $00 
        
        
    FileItems_2:
        .byte $25, $E5
        .byte $18
        .byte $D0, $D1, $FF, $D2, $D3, $FF, $D4, $D5, $FF, $D6, $D7, $FF, $D8, $D9, $FF, $DA, $DB, $FF, $DC, $DD, $FF, $DE, $DF, $FF
        .byte $26, $05
        .byte $18
        .byte $E0, $E1, $FF, $E2, $E3, $FF, $E4, $E5, $FF, $E6, $E7, $FF, $E8, $E9, $FF, $EA, $EB, $FF, $EC, $ED, $FF, $EE, $EF, $FF
        ; END PPU DATA
        .byte $00 
        
        
    FileItems_3:
        .byte $2E, $85
        .byte $18
        .byte $D0, $D1, $FF, $D2, $D3, $FF, $D4, $D5, $FF, $D6, $D7, $FF, $D8, $D9, $FF, $DA, $DB, $FF, $DC, $DD, $FF, $DE, $DF, $FF
        .byte $2E, $A5
        .byte $18
        .byte $E0, $E1, $FF, $E2, $E3, $FF, $E4, $E5, $FF, $E6, $E7, $FF, $E8, $E9, $FF, $EA, $EB, $FF, $EC, $ED, $FF, $EE, $EF, $FF
        ; END PPU DATA
        .byte $00 


        
    FileBlank_1:
        .byte $25, $0B
        .byte ($12 | $40) ; $12 bytes, RLE
        .byte $FF
        ; END PPU DATA
        .byte $00 
        
    FileBlank_2:
        .byte $25, $AB
        .byte ($12 | $40) ; $12 bytes, RLE
        .byte $FF
        ; END PPU DATA
        .byte $00 
        
    FileBlank_3:
        .byte $26, $4B
        .byte ($12 | $40) ; $12 bytes, RLE
        .byte $FF
        ; END PPU DATA
        .byte $00 
        
EndFileSCreenItemStrings:

.if EndFileSCreenItemStrings - FileSCreenItemStrings > MaxSize2
    .error DATA TOO BIG 2
.endif



        
; -----------------------------------------
; Hijacks 
; -----------------------------------------
;   and modifications to existing code

     
    .PATCH 0F:C057
        ; Update memory clearing routine to leave save file SRAM alone
        ldy #$74			;High byte of start address.
        sty $01				;
        ldy #$00			;Low byte of start address.
        sty $00				;$0000 points to $7F00
        ;LC057:*	ldy #$7F			;High byte of start address.


    .PATCH 00:90BA
        ; Initialize file selection mode
        ; (this replaces the routine that used to clear screen and draw
        ;  "START" and "CONTINUE")
        ldy #$00
        sta MenuSelection
        sta SaveFileNum
        sta saveFileIndex
        lda #$16
        sta TitleRoutine
        rts
        ;StartContinueScreen:
        ;L90BA:	jsr ClearAll			;($909F)Turn off screen, erase sprites and nametables.
        ;L90BD:	ldx #$84			;Low address for PPU write.
        ;L90BF:	ldy #$99			;High address for PPU write.
        ;L90C1:	jsr PreparePPUProcess		;($9449)Clears screen and writes "START CONTINUE".
        ;L90C4:	LDY #$00			;
        ;L90C6:	STY StartContinue		;Set selection sprite at START.
        ;L90C9:	LDA #$0D			;
        ;L90CB:	STA PalDataPending		;Change palette and title routine.
        ;L90CD:	LDA #$16			;Next routine is ChooseStartContinue.
        ;L90CF:	STA TitleRoutine		;
        ;TurnOnDisplay:
        ;L90D1:	JSR NMIOn			;($C487)Turn on the nonmaskable interrupt.
        ;L90D4:	JMP ScreenOn			;($C447)Turn screen on.

        
    .PATCH 00:90D7
        ; Rewrite of the start-button-handler (prev. for "START"/"CONTINUE") to
        ; load/erase a file
        ChooseStartContinue:
            lda joy1Change
            AND #$10
            beq +                   ; Start pressed?
                lda MenuSelection   ; Get file num and index
                tay
                sty SaveFileNum
                ldx FileIndexList,Y
                stx SaveFileIndex

                cmp #$03            ; If "ERASE" is selected, never mind (we handle that elsewhere)
                beq+
                
                ldy DeleteMode      ; delete mode?
                bne @EraseFile
                
                JMP LoadGame
                
                @EraseFile
                lda #$00
                sta File_InUse,X
                jmp RESET
            *
            jsr CheckMenuUpDown
            jsr UpdateFileCursor
            jsr DrawFileCursor
            rts
            
            endChooseStartContinue:
            .if endChooseStartContinue > $9117
                .error ChooseStartContinue too big
            .endif
            
        ;ChooseStartContinue:
        ;L90D7:	LDA Joy1Change			;
        ;L90D9:	AND #$30			;Checks both select and start buttons.
        ;L90DB:	CMP #$10			;Check if START has been pressed.
        ;L90DD:	BNE ++				;Branch if START not pressed.
        ;L90DF:	LDY StartContinue		;
        ;L90E2:	BNE +				;if CONTINUE selected, branch.
        ;L90E4:	JMP InitializeStats		;($932B)Zero out all stats.
        ;L90E7:*	LDY #$17			;Next routine is LoadPasswordScreen.
        ;L90E9:	STY TitleRoutine		;
        ;L90EB:*	CMP #$20			;check if SELECT has been pressed.
        ;L90ED:	BNE +				;Branch if SELECT not pressed.
        ;L90EF:	LDA StartContinue		;
        ;L90F2:	EOR #$01			;Chooses between START and CONTINUE-->
        ;L90F4:	STA StartContinue		;on game select screen.
        ;L90F7:	LDA TriangleSFXFlag		;
        ;L90FA:	ORA #$08			;Set SFX flag for select being pressed.-->
        ;L90FC:	STA TriangleSFXFlag		;Uses triangle channel.
        ;L90FF:*	LDY StartContinue		;
        ;L9102:	LDA StartContTbl,Y		;Get y pos of selection sprite.
        ;L9105:	STA Sprite00RAM			;
        ;L9108:	LDA #$6E			;Load sprite info for square selection sprite.
        ;L910A:	STA Sprite00RAM+1		;
        ;L910D:	LDA #$03			;
        ;L910F:	STA Sprite00RAM+2		;
        ;L9112:	LDA #$50			;Set data for selection sprite.
        ;L9114:	STA Sprite00RAM+3		;
        ;L9117:	RTS				;

    .PATCH 00:80F6
        ; Jump to our routine that draws the file screen before turning the screen on
        
        JMP InitFileDisplay
        ;DrawIntroBackground:
        ; ...
        ;L80F6:	JMP ScreenOn			;($C447)Turn screen on.


    .PATCH 00:815B
        ; Loop back to the delay then flash "METROID" routine instead of proceeding to crosshair animation
        jmp ResetTitleAnimation
    
        ;METROIDSparkle:
        ;L814D:	LDA Timer3			;Wait until 3 seconds have passed since-->
        ;L814F:	BNE ++				;last routine before continuing.
        ;L8151:	LDA IntroSpr0Complete		;Check if sparkle sprites are done moving.
        ;L8154:	AND IntroSpr1Complete		;
        ;L8157:	CMP #$01			;Is sparkle routine finished? If so,-->
        ;L8159:	BNE +				;go to next title routine, else continue-->
        ;L815B:	INC TitleRoutine		;with sparkle routine.
        ;L815D:	BNE ++				;
        ;L815F:*	JSR UpdateSparkleSprites	;($87CF)Update sparkle sprites on the screen.
        ;L8162:*	RTS
    

    .PATCH 00:8002
        ; Only listen for start-button BEFORE crosshair animation (a new routine handles input for file menu)
        cmp #$07
        ; Change the branch target to include the call to RemoveIntroSprites
        ; when start is pressed. This needs to be called now since the sparkle
        ; animation may be in progress when start is pressed
        bcs $8022
    .PATCH 00:801C
        ; When start is pressed, begin the crosshair animation, which will then move on to file menu
        lda #$07
        sta TitleRoutine
        NOP
        NOP
        
        ;MainTitleRoutine:
        ;L8000:	lda TitleRoutine		;
        ;L8002:	cmp #$15			;If intro routines not running, branch.
        ;L8004:	bcs ++				;
        ;L8006:	lda Joy1Change			;
        ;L8008:	and #$10			;if start has not been pressed, branch.
        ;L800A:	beq +				;
        ; ...
        ;L801C:	lda #$1B			;If start pressed, load START/CONTINUE screen.
        ;L801E:	sta TitleRoutine		;
        ;L8020:	bne ++				;Branch always.
        ;L8022:*	jsr RemoveIntroSprites		;($C1BC)Remove sparkle and crosshair sprites from screen.
        ;L8025:	lda TitleRoutine		;
        ;L8027:*	jsr ChooseRoutine		;($C27C)Jump to proper routine below.
    

    .PATCH 00:8257
        ; Instead of fading out the story (now the file menu) after a delay, we want to go to file selection mode
        lda #$16
        sta TitleRoutine
        rts
        
        ;MessageFadeIn:
        ;L8243:	LDA Timer3			;Check if delay timer has expired.  If not, branch-->
        ;L8245:	BNE ++				;to exit, else run this rouine.
        ;L8247:	LDA FrameCount			;
        ;L8249:	AND #$07			;Perform next step of fade every 8th frame.
        ;L824B:	BNE ++				;
        ;L824D:	LDA FadeDataIndex		;
        ;L824F:	CMP #$0B			;Has end of fade in palette data been reached?-->
        ;L8251:	BNE +				;If not, branch.
        ;L8253:	LDA #$00			;
        ;L8255:	STA FadeDataIndex		;Clear FadeDataIndex.
        ;L8257:	LDA #$30			;
        ;L8259:	STA Timer3			;Set Timer3 to 480 frames(8 seconds).
        ;L825B:	INC TitleRoutine		;Next routine is MessageFadeOut.
        ;L825D:	BNE ++				;Branch always.
        ;L825F:*	JSR DoFadeOut			;($8B5F)Fade message onto screen.
        ;L8262:*	RTS				;
    
    
    .PATCH 00:9359
        DisplayPassword:            ; Repurposed to draw the game over menu.
            jsr $8C7A               ; Calculate Password
            jsr $909F               ; ClearAll
            
            ldx #<GameOverMenuStrings
            ldy #>GameOverMenuStrings
            jsr $9449               ; PreparePpuProcess
            
            jsr $C601               ; LoadGFX7 (THE NEW VERSION for enhanced ROMs) 
            jsr $c487               ; NmiOn
            jsr $C32C               ; WaitNMIPass
            lda #$0c
            sta $1C                 ; PalDataPending
            inc TitleRoutine
            
            lda #$00
            sta MenuSelection
            
            jmp $C447               ; ScreenOn
            
        ; Ensure this routine re-write doesn't exceed the size of the original
        EndOfDisplayPassword:
        .if EndOfDisplayPassword-DisplayPassword > $937F - $9359
            .error DisplayPassword too big
        .endif
    
        ;DisplayPassword:
        ;L9359:	LDA Timer3			;Wait for "GAME OVER" to be displayed-->
        ;L935B:	BNE $9324			;for 160 frames (2.6 seconds).
        ;L935D:	JSR ClearAll			;($909F)Turn off screen, erase sprites and nametables.
        ;L9360:	LDX #$7F			;Low byte of start of PPU data.
        ;L9362:	LDY #$93			;High byte of start of PPU data.
        ;L9364:	JSR PreparePPUProcess		;($9449)Clears screen and writes "PASS WORD".
        ;L9367:	JSR InitGFX7			;($C6D6)Loads the font for the password.
        ;L936A:	JSR CalculatePassword		;($8C7A)Calculates the password.
        ;L936D:	JSR NmiOn			;($C487)Turn on the nonmaskable interrupt.
        ;L9370:	JSR PasswordToScreen		;($93C6)Displays password on screen.
        ;L9373:	JSR WaitNMIPass			;($C42C)Wait for NMI to end.
        ;L9376:	LDA #$13			;
        ;L9378:	STA PalDataPending		;Change palette.
        ;L937A:	INC TitleRoutine		;
        ;L937C:	JMP ScreenOn			;($C447)Turn screen on.
        ;next byte 937F

        
    .PATCH 00:805E
        ;Update title routine pointer from game-over password screen to game over save menu
        .word UpdateGameOverScreen
        
        ;L805E:	.word WaitForSTART		;($9394)Wait for START when showing password.

        
    .PATCH 0F:C578
        ; Modify ClearSamusStats so that player health is not cleared. This allows 
        ; the health value assigned by LoadGame to remain intact.
        ClearSamusStats:
            ldy #$07
            lda #$00
            *
                sta $0108,y
                dey
                bpl -
            rts
        
        ;ClearSamusStats:
        ;LC578:	ldy #$0F			;
        ;LC57A:	lda #$00			;Clears Samus stats(Health, full tanks, game timer, etc.).
        ;LC57C:*	sta $0100,y			;Load $100 thru $10F with #$00.
        ;LC57F:	dey				;
        ;LC580:	bpl -				;Loop 16 times.
        ;LC582:	rts				;
    

    .PATCH 00:932B
        ; Hijack - Set health to 030.0 for new game (this used to be done in SamusInit for both new game and continue)
        jsr InitializeStats_InitHealth
        ;InitializeStats:
        ;L932B:	LDA #$00			;
        ;L932D:	STA SamusStat00			;

    .PATCH 0F:c920
        ; Hijack - Instead of initializing health to 030.0 every game, only set to 030.0 if it is less (i.e. player has died, or saved with very low health)
        jmp CheckMinHealth
        ;From SamusInit...    
        ;0F:C920:A9 00     LDA #$00
        ;0F:C922:8D 06 01  STA HealthLo = #$FF
        ;0F:C925:A9 03     LDA #$03
        ;0F:C927:8D 07 01  STA HealthHi = #$FF
        ;0F:C92A:60        RTS
    
    .PATCH 00:939E
        ; Nix "game over" screen, since the password screen (which is now our game over menu) already informs you the game is over
        GameOver:
            lda #$19
            sta TitleRoutine
            rts
        ;GameOver:
        ;L939E:	JSR ClearAll			;($909F)Turn off screen, erase sprites and nametables.
        ;L93A1:	LDX #$B9			;Low byte of start of PPU data.
        ;L93A3:	LDY #$93			;High byte of start of PPU data.
        ;L93A5:	JSR PreparePPUProcess		;($9449)Clears screen and writes "GAME OVER".
        ;L93A8:	JSR InitGFX7			;($C6D6)Loads the font for the password.
        ;L93AB:	JSR NmiOn			;($C487)Turn on the nonmaskable interrupt.
        ;L93AE:	LDA #$10			;Load Timer3 with a delay of 160 frames-->
        ;L93B0:	STA Timer3			;(2.6 seconds) for displaying "GAME OVER".
        ;L93B2:	LDA #$19			;Loads TitleRoutine with -->
        ;L93B4:	STA TitleRoutine		;DisplayPassword.
        ;L93B6:	JMP ScreenOn			;($C447)Turn screen on.


    .PATCH 00:8E17
        ; Remove password scrambling
        PasswordChecksumAndScramble:
            JSR $8E21               ;PasswordChecksum
            STA $6999               ;PasswordByte11
            RTS                     ; NO Scrambling
            ;L8E17:	JSR PasswordChecksum		;($8E21)Store the combined added value of-->
            ;L8E1A:	STA PasswordByte11		;addresses $6988 thu $6998 in $6999.
            ;L8E1D:	JSR PasswordScramble		;($8E2D)Scramble password. (REMOVE)
            ;L8E20:	RTS
        
    .PATCH 00:8D0C
        ; Remove call to LoadPasswordChar
        jmp PasswordChecksumAndScramble        
        ;CalculatePassword:
        ;L8C7A:	LDA #$00			;
        ;L8C7C:	LDY #$0F			;Clears values at addresses -->
        ;	...
        ;L8D07:	BEQ -				;When any of the 4 LSB are set. (Does not-->
        ;L8D09:	STA PasswordByte10		;allow RandomNumber1 to be a multiple of 16).
        ;L8D0C:	JSR PasswordChecksumAndScramble	;($8E17)Calculate checksum and scramble password.
        ;L8D0F:	JMP LoadPasswordChar		;($8E6C)Calculate password chars (REMOVE)    

    .PATCH 00:8132
        ;Doubling the speed of the METROID fade in here
        AND #$08
        ;METROIDFadeIn:
        ;L812C:	LDA Timer3			;
        ;L812E:	BNE +				;
        ;L8130:	LDA FrameCount			;Every 16th FrameCount, Change palette.-->
        ;L8132:	AND #$0F			;Causes the fade in effect.
    
    .PATCH 00:80FF
        ; Reduce the delay before METROID fades in
        LDA #$04
        STA Timer3
        NOP             ; This NOP replaces LSR that is meant to change A from 8 to 4
        ;FadeInDelay:
        ;L80F9:	LDA PPUCNT0ZP			;
        ;L80FB:	AND #$FE			;Switch to name table 0 or 2.
        ;L80FD:	STA PPUCNT0ZP			;
        ;L80FF:	LDA #$08			;Loads Timer3 with #$08. Delays Fade in routine.-->
        ;L8101:	STA Timer3			;Delays fade in by 80 frames (1.3 seconds).
        ;L8103:	LSR				;
        ;L8104:	STA PalDataIndex		;Loads PalDataIndex with #$04
        
    .PATCH 00:8172
        ; Reduce the delay before the crosshair animation
        LDA #$08
        sta $BC                 ;First4SlowCntr
        LDA #$00
        STA Timer3
        
    .PATCH 00:8165
        ; Double the speed of the METROID fade out
        AND #$03
        ;METROIDFadeOut:
        ;L8163:	LDA FrameCount			;Wait until the frame count is a multiple-->
        ;L8165:	AND #$07			;of eight before proceeding.  
        ;L8167:	BNE ++				;
        ;L8169:	LDA FadeDataIndex		;If FadeDataIndex is less than #$04, keep-->
        ;L816B:	CMP #$04			;doing the palette changing routine.
        ;L816D:	BNE +				;
        ;L816F:	JSR LoadInitialSpriteData	;($8897)Load initial sprite values for crosshair routine.
        ;L8172:	LDA #$08			;
        ;L8174:	STA Timer3			;Load Timer3 with a delay of 80 frames(1.3 seconds).
        ;L8176:	STA First4SlowCntr		;Set counter for slow sprite movement for 8 frames,
        ;L8178:	LDA #$00			;
        ;L817A:	STA SecondCrosshairSprites	;Set SecondCrosshairSprites = #$00
        
    .PATCH 00:8236
        ;Reduce delay before file screen fade in
        lda #$01
        ;ChangeIntroNameTable:
        ;L822E:	LDA PPUCNT0ZP			;
        ;L8230:	ORA #$01			;Change to name table 1.
        ;L8232:	STA PPUCNT0ZP			;
        ;L8234:	INC TitleRoutine		;Next routine to run is MessageFadeIn.
        ;L8236:	LDA #$08			;
        ;L8238:	STA Timer3			;Set Timer3 for 80 frames(1.33 seconds).
        ;L823A:	LDA #$06			;Index to FadeInPalData.
        ;L823C:	STA FadeDataIndex		;
        ;L823E:	LDA #$00			;
        ;L8240:	STA SpareMemC9			;Not accessed by game.
        ;L8242:	RTS				;
    
    .PATCH 00:8249    
        ; Double speed of file menu fade in
        and #$03
        ;MessageFadeIn:
        ;L8243:	LDA Timer3			;Check if delay timer has expired.  If not, branch-->
        ;L8245:	BNE ++				;to exit, else run this rouine.
        ;L8247:	LDA FrameCount			;
        ;L8249:	AND #$07			;Perform next step of fade every 8th frame.
        ;L824B:	BNE ++				;
        
    .PATCH 00:8668
        ; Replaces "EMERGENCY ORDER" text with file menu
        MaxSize = $9B
        
        FileScreenStrings:
            .byte $24, $86 
            .byte $0B 
            
            ;     S    E    L    E    C    T    _    F    I    L    E
            .byte $1C, $0E, $15, $0E, $0C, $1D, $FF, $0F, $12, $15, $0E
            
            .byte $24, $98 
            .byte $05 
            
            ;     E    R    A    S    E
            .byte $0E, $1B, $0A, $1C, $0E
            
            
            ; File 1
            .byte $2D, $03
            .byte $1A
            .byte $0F, $12, $15, $0E, $FF, $01, $FF, $FF, $F1, $F1, $F1, $F1, $F1, $F1, $F1, $F1, $FF, $F2, $F3, $01, $01, $01, $F6, $01,$01,$01
            
            ; (file 1) EMPTY
            .byte $2D, $45
            .byte $07
            .byte $3F, $0E, $16, $19, $1D, $22, $3F
            
            
            ; File 2
            .byte $2D, $A3
            .byte $1A
            .byte $0F, $12, $15, $0E, $FF, $02, $FF, $FF, $F1, $F1, $F1, $F1, $F1, $F1, $F1, $F1, $FF, $F2, $F3, $01, $01, $01, $F6, $01,$01,$01
            
            
            ; (file 2) EMPTY
            .byte $25, $E5
            .byte $07
            .byte $3F, $0E, $16, $19, $1D, $22, $3F
            
            ; File 3
            .byte $2E, $43
            .byte $1A
            .byte $0F, $12, $15, $0E, $FF, $03, $FF, $FF, $F1, $F1, $F1, $F1, $F1, $F1, $F1, $F1, $FF, $F2, $F3, $01, $01, $01, $F6, $01,$01,$01
            
            ; (file 3) EMPTY
            .byte $2E, $85
            .byte $07
            .byte $3F, $0E, $16, $19, $1D, $22, $3F
            
            ; END PPU DATA
            .byte $00 
        
            EndFileScreenStrings:
            
            .if EndFileScreenStrings - FileScreenStrings > MaxSize
                .error DATA TOO BIG
            .endif
            

    .PATCH 00:852D
        ;Attributes for file menu
        L852D:	.byte $27			;PPU memory high byte.
        L852E:	.byte $C0			;PPU memory low byte.
        L852F:	.byte $20			;PPU string length.
        L8530:	.byte $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        L8540:	.byte $FF, $5F, $5F, $5F, $5F, $5D, $5F, $5F, $FF, $5F, $5F, $5F, $5F, $5D, $5F, $FF
        
        L8550:	.byte $27			;PPU memory high byte.
        L8551:	.byte $E0			;PPU memory low byte.
        L8552:	.byte $20			;PPU string length.
        L8553:	.byte $FF, $F5, $F5, $F5, $F5, $D5, $F5, $FF, $00, $05, $05, $05, $05, $05, $05, $00
        L8563:	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        
        
    ; Palettes
    .PATCH 00:9739
        L9739:	.byte $0F, $28, $18, $08, $0F, $06, $17, $27, $0F, $27, $28, $29, $0F, $31, $31, $01
        L9749:	.byte $0F, $16, $2A, $27, $0F, $12, $30, $21, $0F, $27, $24, $2C, $0F, $15, $21, $38
    .PATCH 00:9589
        L9589:	.byte $0F, $28, $18, $08, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
    .PATCH 00:975D
        L975D:	.byte $0F, $28, $18, $08, $0F, $0F, $06, $17, $0F, $12, $12, $01, $0F, $12, $02, $01
    .PATCH 00:9781
        L9781:	.byte $0F, $28, $18, $08, $0F, $0f, $07, $06, $0F, $02, $02, $0F, $0F, $02, $01, $0F
    .PATCH 00:97A5
        L97A5:	.byte $0F, $28, $18, $08, $0F, $0F, $0F, $07, $0F, $01, $01, $0F, $0F, $01, $0F, $0F
    .PATCH 00:9715
        ; Game over pal
        L9715:	.byte $0F, $28, $18, $08, $0F, $16, $1A, $27, $0F, $31, $31, $01, $0F, $31, $11, $01