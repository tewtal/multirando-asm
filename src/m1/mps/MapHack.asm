; The map hack places the needed code and data into RAM at $7900 ($600 bytes (max))


MapRAM      :=  $7900
MapData     :=  $9400

    .if (<MapRam) != $00
        .error MapRAM must begin on a $100 byte boundary 
    .endif


MapLeft = $64
MapTop = $32
MapWidth = 7
MapHeight = 7
SamusBlipTile = $BF


.PATCH 0e:9000


    MapLoadEntryPoint:
        ; Pointer to map data in ROM
        lda #<MapData
        sta $00
        lda #>MapData
        sta $01
        
        ; Pointer to RAM it will be copied to
        lda #<MapRAM
        sta $02
        lda #>MapRAM
        sta $03
        
        ; Copy 6 blocks of $100 bytes
        ldx #$06
        
        *
            ; Copy $100 bytes
            ldy #$00
            *
                lda ($00),Y
                sta ($02),Y
                iny
            bne -
            
            ; Advance each pointer by $100
            inc $01
            inc $03
            
            dex
        bne --
        

    ; We now return you to your normal intialization routine
    ldy #$00
    jmp RomSwitch
    
    
    
    
    
    
    
    
.PATCH 0e:9800
    ; This code is copied to RAM after map data ($7D00)
    .base $7D00
    
    MinimapX:   .dsb    $01
    MinimapY:   .dsb    $01
    BlipX:  .dsb    $01
    BlipY:  .dsb    $01

    ShowMap:
        ; Uses $00, $01, $02
    
        ; Clear sprite RAM    
        ldy #$00
        lda #$00
        *
            sta $0200,Y
            iny
        bne -
        
        jsr GetMapCords
        jsr DrawMap

        @returnFromHijack:
        lda #$05                ; Game mode - Unpaused
        jmp $C131
        

        
        
    DrawMap:
        ; Draw samus blip
        ldy #$00

        lda BlipX                           ; Calculate blip X
        bmi @skipBlip                       ; Hide blip if off map display
        cmp #MapWidth
        bcs @skipBlip        
        asl
        asl
        asl
        clc
        adc #MapLeft + 8                    ; Why is this off by one square?
        sta OAM_X,Y
        
        lda BlipY                           ; Calculate blip Y
        bmi @skipBlip                       ; Hide blip if off map display
        cmp #MapHeight
        bcs @skipBlip 
        asl
        asl
        asl
        clc
        adc #MapTop
        sta OAM_Y,Y
        
        lda #$00
        sta OAM_Att,Y
        lda #SamusBlipTile
        sta OAM_Tile,Y
        
        jmp @DrawMapTiles
        @skipBlip:                              ; Hide blip sprite
            lda #$F4
            sta OAM_Y,Y
        
        
        @DrawMapTiles:
        lda #$00
        sta $00
        ldy #$04                ; OAM ptr
        ; loop rows
        @rowLoop:
            ; Get screen Y coordinate for row
            asl                 ; Grid Y * 8
            asl
            asl
            clc
            adc #MapTop         ; + top of grid
            sta $01

            ; Get screen X coordinate
            lda #(MapLeft + MapWidth * 8)
            sta $02
            
            ldx #MapWidth - 1   ; 7 screens per row
            @cellLoop:
                lda $02
                sta OAM_X,Y
                lda $01
                sta OAM_Y,Y
                lda #$01
                sta OAM_Att,Y

                lda $00
                jsr GetMapTile
                sta OAM_Tile,Y
                
                ; Next tile 8 px to the right
                lda $02
                sec
                sbc #$08
                sta $02
                
                iny
                iny
                iny
                iny
                dex
            bpl @CellLoop

            inc $00
            lda $00
            cmp #MapHeight      ; 7 rows
        bne @rowLoop
        
        rts

        
    
        
    GetMapTile:
        ; Gets tile number to use for the given map position
        ; X MUST BE PRESERVED
        ; x [in]    Cell X position
        ; a [in]    Cell Y position
        ; a [out]   Tile number
        ;
        ; Uses $03, $04, $05, $06
        
        stx $03             ; Preserve registers
        sty $06
        ldx #$00            ; Clear a variable
        stx $04            
        
        clc
        adc MiniMapY        ; Get absolute Y
        sec
        sbc #$03            
        bcc @YOutOfRange    ; If < 0, out of range. Use blank tile
        cmp #$20
        bcs @YOutOfRange    ; If >= #$20, out of range. Use blank tile.

        ; Set 16-bit value at $04 to (y * #$20)
        lsr
        ror $04
        lsr
        ror $04
        lsr
        ror $04
        
        ; Add address of map data in RAM
        clc
        adc #>MapRAM
        sta $05

        lda $03
        clc                 ; Get absolute X
        adc MiniMapX
        sec
        sbc #$03
        bcc @XOutOfRange    ; If < 0, its out of range, use a blank tile
        cmp #$20
        bcs @XoutOfRange    ; If >= #$20, it is out of range, use a blank tile
        
        tay
        lda ($04),Y         ; Get map tile number
        
        ldx $03             ; Restore registers
        ldy $06
        rts
        
        
        @XOutOfRange:
        @YOutOfRange:
            ldx $03
        ldy $06
            lda #$FF
            rts
            
        
    GetMapCords:
        lda MapPosX
        sta MiniMapX
        lda MapPosY
        sta MiniMapY

        lda ScrollDir
        and #$02
        bne @horiz
        
        @vert:        
        lda ScrollY
        beq @return
        
        lda ScrollDir
        cmp #$01
        bne +   
            dec MinimapY
        *
        lda ScrollY
        bpl +
            inc MinimapY
        *
        rts                                             
        
        @horiz:
        lda ScrollX
        beq @return

        lda ScrollDir
        cmp #$03
        bne +
            dec MinimapX
        *
        lda ScrollX
        bpl +
            inc MinimapX
        *
        
        @return
        ; Place blip
        lda #$03
        sta BlipX
        sta BlipY
        
        rts
        
        
    MapInputHandler:
        lda Joy1Change
        and #(Joy_Up | Joy_Down | Joy_Left | Joy_Right)
        beq @return
        
        cmp #Joy_Up
        bne +
            ldx MinimapY        ; Don't move up past edge of map
            beq +
            dec MinimapY
            inc BlipY
        *
        cmp #Joy_Down
        bne +
            ldx MiniMapY        ; Don't move right past edge of map
            cpx #$1F
            beq +
            inc MinimapY
            dec BlipY
        *
        cmp #Joy_Left
        bne +
            ldx MinimapX        ; Don't move up past edge of map
            beq +
            dec MinimapX
            inc BlipX
        *
        cmp #Joy_Right
        bne +
            ldx MiniMapX        ; Don't move right past edge of map
            cpx #$1F
            beq +
            inc MinimapX
            dec BlipX
        *
        
        jsr DrawMap
    
        @return
        ; Displaced
        lda Joy2Status			;Load buttons currently being pressed on joypad 2.
        and #$88			;
        rts

        
        
    WavyIce_NewBehavior:
        LDA $6878    ; Check equipment
        AND #$40     ; Has wave?
        BEQ @NoWave
        JMP $D52C    ; Yes: UpdateWaveBullet
        ;(normally UpdateWaveBullet isn't called when you have ice, even if you do have wave)

        @NoWave:
        JMP $D4EB    ; No: UpdateBullet
        

    WavyIce_NewDamage:
        ; Y: Weapon type
        ;   1 = Normal
        ;   2 = Wave
        ;   3 = Ice or Wavy-ice
        ;   A = Bomb
        ;   B = Missile (I think)
        ; X: Enemy index
        ; 40B,X: enemy health

        LDY $040E,X        ; Get projectile that hit enemy
        LDA $6878          ; Get current equipment

        CPY #$03           ; If Ice...
        BNE @NotIce

        @Ice:
        AND #$C0           ;     Does the player have wave and ice beams?
        BNE Damage4        ;     If so, 4 damage
        BEQ Damage2        ;     Else, 2 damage

        @NotIce:
        ; Includes vanilla-beam, bomb, wave, and missile
        CPY #$0A           ; Bomb = 4 Damage
        BEQ Damage4
        CPY #$02           ; Wave = 2 Damage
        BEQ Damage2

        BIT $0A            ; Not-a-boss = 1 Damage
        BVC Damage1

    IsABoss:
        CPY #$0B           ; Vanilla-beam = 1 damage
        BNE Damage1        ; (missile will fall thru and do 4 damage)

    Damage4:
        DEC $040B,X
        BEQ exitRoutine
    Damage3:
        DEC $040B,X
        BEQ exitRoutine
    Damage2:
        DEC $040B,X
        BEQ exitRoutine
    Damage1:
        DEC $040B,X

    exitRoutine:
        ; Return to F60F (this is the code that checks if enemies has
        ; 0 HP and if so, kills him)
        JMP $F60F        
        
    endOfRAMCode:
        .if endOfRAMCode > $7F00
            .error Too much code in RAMp9\
        .endif
        
.PATCH 0F:C123
    ;; This hijack runs our map setup when start is pressed
    ;    LC123: cmp #$05            ; Are we currently paused?
    ;    LC125: bne +
    ;    LC127:     lda #$03        ;   Then unpause
    ;    LC129:     bne $C131
    ;           *
    ;    LC12B: cmp #$05            ; Are we currently unpaused (as opposed to "fading in", elevator, death animation, etc)
    ;    LC12D: bne $C13C           ;   Then ignore start button
    ;    LC12F: jmp Showmap
    ;    LC132: ; fin
        
        BC123: cmp #$03
        BC125: bne +
        BC127:    jmp ShowMap
               *
        BC12A: cmp #$05
        BC12C: bne $C13C
        BC12E: lda #$03
        BC130: nop
        ;GoMainRoutine:
        ;LC114:	lda GameMode			;0 if game is running, 1 if at intro screen.
        ;LC116:	beq +				;Branch if mode=Play.
        ;LC118:	jmp $8000			;Jump to $8000, where a routine similar to the one-->
        ;            					;below is executed, only using TitleRoutine instead
        ;            					;of MainRoutine as index into a jump table.
        ;LC11B:*	lda Joy1Change			;
        ;LC11D:	and #$10			;Has START been pressed?-->
        ;LC11F:	beq +++				;if not, execute current routine as normal.
        ;
        ;LC121:	lda MainRoutine			;
        ;LC123:	cmp #$03			;Is game engine running?-->
        ;LC125:	beq +				;If yes, check for routine #5 (pause game).
        ;LC127:	cmp #$05			;Is game paused?-->
        ;LC129:	bne +++				;If not routine #5 either, don't care about START being pressed.
        ;LC12B:	lda #$03			;Otherwise, switch to routine #3 (game engine).
        ;LC12D:	bne ++				;Branch always.
        ;LC12F:*	lda #$05			;Switch to pause routine.
        ;LC131:*	sta MainRoutine			;(MainRoutine = 5 if game paused, 3 if game engine running).
        ;LC133:	lda GamePaused			;
        ;LC135:	eor #$01			;Toggle game paused.
        ;LC137:	sta GamePaused			;
        ;LC139:	jsr PauseMusic			;($CB92)Silences music while game paused.

.PATCH 0f:C9B1
    jsr MapInputHandler
    nop
    ;PauseMode:        
    ;LC9B1:	lda Joy2Status			;Load buttons currently being pressed on joypad 2.
    ;LC9B3:	and #$88			;
    ;LC9B5:	eor #$88			;both A & UP pressed?-->        


; THIS CODE IS PLACED IN FileSaveLoad.asm, BUT IS PART OF THE MAP HACK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;.PATCH 00:A960
    ;
    ;LoadMapHijack:
    ;    ; Push map loading routine address to stack
    ;    lda #>(MapLoadEntryPoint - 1)
    ;    pha
    ;    lda #<(MapLoadEntryPoint - 1)
    ;    pha
    ;    ldy #$0E
    ;    jmp RomSwitch