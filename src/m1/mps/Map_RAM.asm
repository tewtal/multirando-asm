; The map hack places the needed code and data into RAM at $7900 ($600 bytes (max))



    
    
    
    
    
    
    

    
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
        jmp @return
        
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

        