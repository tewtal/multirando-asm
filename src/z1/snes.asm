optimize dp always
optimize address ram

; This runs once per frame at the end of NMI (The whole games runs in NMI)
; So this is the last chance to execute code before the next NMI starts
SnesProcessFrame:
    jsl SnesOamPrepare
    rtl

SetupScrollHDMA:
    sep #$30
    lda #$02
    sta $4370
    lda #$0E     ; Vertical scroll
    sta $4371 
    rep #$30
    lda.w #VScrollTable
    sta $4372
    sep #$30
    lda.b #(VScrollTable>>16)
    sta $4374

    lda #$02
    sta $4360
    lda #$0D     ; Horizontal scroll
    sta $4361 
    rep #$30
    lda.w #HScrollTable
    sta $4362
    sep #$30
    lda.b #(HScrollTable>>16)
    sta $4364

    rtl

UpdateScrollHDMA:
    jsl UpdateVScrollHDMA
    jsl UpdateHScrollHDMA
    
    lda #$C0
    sta $420c

    rtl

UpdateVScrollHDMA:
    lda IsSprite0CheckActive
    beq +

    lda #$30
    sta VScrollTable_sblen
    lda #$0f
    sta VScrollTable_sbval
    lda #$bf
    sta VScrollSplit
    bra ++
+
    lda #$01
    sta VScrollTable_sblen
    lda #$ff
    sta VScrollSplit
++

    ;  Save the previous ScrollYDMA to ScrollYDMAPrev
    lda ScrollYDMA
    sta ScrollYDMAPrev

    rep #$20
    lda CurVScroll : and #$00ff : sta ScrollYDMA

    lda PPUCNT0ZP
    and #$0003
    beq +
    lda #$0001
+
    xba
    ora ScrollYDMA
    clc : adc #$000f
    and #$01ff
    sta ScrollYDMA

    lda IsSprite0CheckActive
    bne +
    lda ScrollYDMA
    sta VScrollTable_sbval

+
    sep #$30
    
    lda VScrollSplit
    sec : sbc ScrollYDMA

    cmp #$7f
    bcs .secondHalf
    cmp #$00        ;  Avoid a zero in [A] getting written to the second hdma line
    bne .nonzero    ;  counter byte [VScrollTable_len1] which disables hdma for the rest of frame
                    ;  and displays the wrong screen leading to tile-attribute flicker
    lda #$80
    sta VScrollTable_len1
    stz VScrollTable_len2
    stz VScrollTable_len3
    rep #$20
    lda ScrollYDMA
    clc : adc #$0010 : and #$01ff
    sta VScrollTable_val1
    sep #$20
    bra .end

.nonzero            ;  The standard case
    sta VScrollTable_len1
    sta VScrollTable_len2
    stz VScrollTable_len3
    rep #$20
    lda ScrollYDMA
    sta VScrollTable_val1
    clc : adc #$0010 : and #$01ff
    sta VScrollTable_val2
    sep #$20
    bra .end
.secondHalf
    sec : sbc #$7e
    sta VScrollTable_len2
    lda #$7e
    sta VScrollTable_len1
    sta VScrollTable_len3
    rep #$20
    lda ScrollYDMA

    ;  If ScrollYDMA is $0f, wait one more time before returning to nonscrolling operation since both
    ;  tilesets should be identical and the one being updated has an extra frame to
    ;  process attribute data.  Fixes N->S scroll tileset attribute flicker
    cmp #$000f
    bne .normalFrame
    lda ScrollYDMAPrev
    cmp #$0080      ;  Only use the previous value if we're scrolling N->S (avoids S->N artifact)
    bcc .notSpecialCase
    cmp #$00d1      ;  Only use the previous value if we're not doing a pause menu scroll
    bcc .delayedFrame

.notSpecialCase:
    lda ScrollYDMA  ;  Restore ScrollYDMA

.normalFrame
.delayedFrame
    sta VScrollTable_val1
    sta VScrollTable_val2
    clc : adc #$0010 : and #$01ff
    sta VScrollTable_val3
    sep #$20
.end
    rtl

UpdateHScrollHDMA:
    rep #$20

    ; Save the previous ScrollXDMA to ScrollXDMAPrev
    lda ScrollXDMA
    sta ScrollXDMAPrev

    lda CurHScroll : and #$00ff : sta ScrollXDMA
    
    lda PPUCNT0ZP
    and #$0003
    beq +
    lda #$0001
+
    xba
    ora ScrollXDMA
    sta ScrollXDMA

    jsr SpecialFixHScrollHDMA

    sta HScrollTable_val

    sep #$20

    lda IsSprite0CheckActive
    beq +
    lda #$30
    bra ++
+
    lda #$00
++
    sta HScrollTable_sblen
    rtl


;  Check special case where scrollxdma == 0000 and scrollxdmaprev === 0100,
;  then store the 0100 instead of 0000.  Next frame prev will be 0000 also so we're back to normal.
;  Fixes some (but not all) horizontal scroll tileset attribute flicker.
;  [A]: ScrollXDMA
;  Returns in [A]: HScrollTable_val
SpecialFixHScrollHDMA:
    cmp #$0000
    bne .end

    lda ScrollXDMAPrev
    cmp #$0100
    bne .end

.horizontalLayout:
    lda ScrollXDMA

.end:
rts


; The game does special magic when scrolling vertically, so we'll have to calculate the correct Y scroll position here
; and run the vertical HDMA scrolling update routine
SnesUpdateVerticalGameScroll:
    lda VScrollAddrHi
    xba
    lda VScrollAddrLo
    rep #$20

    sta VScrollAddrTmp  ; Contains the PPU address to scroll to vertically
    cmp #$2800
    bne +
    lda #$00c0
    sta CurVScroll
    bra ++

+
    and #$03ff
    lsr #2
    sec : sbc #$0038
    sta CurVScroll

++
    sep #$20
    jsl UpdateVScrollHDMA
    rtl

; Convert the NES OAM buffer at $200-2FF to SNES format and DMA to the PPU
; We'll have to convert every 8x16 sprite into two 8x8 sprites since the SNES doesn't support 8x16
SnesOamPrepare:
    PHP : PHB : PEA $7E7E : PLB : PLB

    ;  Wait until we're outside of vblank to run this honkin' thing.
    ;  NES lag frames can cause this to take up vblank time and delay
    ;  queued oam and tile data until the very end, causing some or all
    ;  of the vram dmas to fail leaving sprites and tiles in a mess.
    ;  e.g., door transition from lvl 2 entry room to the north
.awaitVblankOver:
    lda $004212       ; check HVBJOY
    and #$80        ; In vblank?
    bne .awaitVblankOver ; Wait until vblank's over

    REP #$10
    LDA #$00 : XBA
    LDX #$0000
    LDY #$0000
.LoopSprite
    ; Y coordinate
    LDA.w Z1OAMNES.Y, X
    CMP #$F8
    bne ..next
    jmp .Clear

..next
    SEC : SBC #!VSpriteOffset

    BIT.w Z1OAMNES.Attr, X
    BMI .VFlip
    STA.w Z1OAM.Y, Y
    CLC : ADC #$08
    STA.w Z1OAM.Y+$4, Y
    BRA .XCoord
.VFlip
    STA.w Z1OAM.Y+$4, Y
    CLC : ADC #$08
    STA.w Z1OAM.Y, Y
    
.XCoord
    ; X coordinate
    LDA.w Z1OAMNES.X, X
    STA.w Z1OAM.X, Y
    STA.w Z1OAM.X+$4, Y

    LDA.w Z1OAMNES.Index, X
    AND #$FE
    STA.w Z1OAM.Index, Y
    INC
    STA.w Z1OAM.Index+$4, Y

    LDA.w Z1OAMNES.Attr, X
    PHX : TAX
    LDA.l AttributeTable, X
    PLX
    STA.w Z1OAM.Attr, Y
    LDA.w Z1OAMNES.Index, X
    AND #$01
    ORA.w Z1OAM.Attr, Y
    STA.w Z1OAM.Attr, Y
    STA.w Z1OAM.Attr+$4, Y
    
    ; Check bit 2 to see if this is an "extended" sprite using
    ; 16-color sprites and custom 8x16 layout
    LDA.w Z1OAMNES.Attr, X
    AND.b #$04
    BEQ .noExtended

    LDA.w Z1OAMNES.Attr, X
    and.b #$f0  ;  Check if we've specified a different palette in the upper nibble
    beq .extPalette

    lsr #3      ;  Move palette in the upper nibble into position
    ora.b #$01  ;  Add the OAM2 selector bit
    bra .continue

.extPalette
    LDA.w Z1OAM.Attr, Y
    ORA.b #$09

.continue
    STA.w Z1OAM.Attr, Y
    STA.w Z1OAM.Attr+$4, Y

    LDA.w Z1OAMNES.Index, X
    AND.b #$03
    BNE .odd
    ; For an extended sprite with index 0, 4, 8 etc, set the index of
    ; the other sprite to Index+2
    LDA.w Z1OAM.Index+$4, Y : INC : STA.w Z1OAM.Index+$4, Y
    BRA .noExtended
.odd
    LDA.w Z1OAM.Index, Y : DEC : STA.w Z1OAM.Index, Y

.noExtended
    BRA .Next

.Clear
    STA.w Z1OAM.Y, Y
    STA.w Z1OAM.Y+$4, Y
.Next
    INY #8
    INX #4
    CPX #$0100
    BEQ +
    JMP .LoopSprite
+
    PLB
    PLP
    RTL

;  Start NMI by clearing BG1HOFS to allow special case code
;  to fix tileset attribute flicker on horizontal scrolling.
;  See snes.asm/UpdateHScrollHDMA for details.
ResetBg1hofs:
    rep #$20
    lda.w #$0000
    sta.w $210d
    sta.w $210d
    rtl

SnesOamDMA:
    PHP    
    REP #$30
    
    LDA #$0400
    STA $4300
    LDA #$2000
    STA $4302
    LDA #$007E
    STA $4304
    LDA #$0220
    STA $4305
    STZ $2102

    SEP #$20
    LDA #$01
    STA $420B


    LDA #$00
    STA $2101

    LDA #$15
    STA $212C

    PLP
    RTL

SnesClearNameTable:
    PHX : PHY : PHP
    LDA #$8F
    STA $2100

    LDA #$80
    STA $2115

    REP #$30
    LDA #$2000
    STA $2116
    
    LDX #$1000

-
    LDA #$0024
    STA $2118
    DEX
    BNE -

    SEP #$30
    LDA #$0F
    STA $2100

    PLP : PLY : PLX
    RTL

EmulateMMC1:
    LDA CurMMC1Control
    AND #$01
    BEQ .Horizontal    
.Vertical
    LDA #$22
    STA $002107
    BRA .End
.Horizontal
    LDA #$21
    STA $002107
.End
    RTL


; Since the original game uses sprite overload to hide link in doorways we can't do the same here efficiently,
; so instead we'll flip the priority bit of the BG tiles to make Link appear behind the doorways
SnesApplyBGPriority:
    pha : phx : phy : php
    sep #$30

    lda.w NeedsBGPriorityUpdate   ; Check if we need to update the BG priority
    beq .end
    lda.b $10                     ; Load current level
    beq .end                    ; If zero, exit

    lda #$80
    sta $2115

    stz.w NeedsBGPriorityUpdate

    ; Set the two tiles above the doorways to a solid white tile with a blank palette to mask link properly
    rep #$30
    ldx #$20EF
    stx $2116
    lda #$3c25  ; special palette index $7 and priority bit 1 for all black, loaded in transition_in.asm/initSpecialPaletteEntry
    sta $2118
    sta $2118

    ; Loop through and modify the priority bit of the BG tiles in the top and bottom doorways
    ldx #$210F
-
    stx $2116
    lda $2139
    ora #$2000
    stx $2116
    sta $2118

    inx : stx $2116
    lda $2139
    ora #$2000
    stx $2116
    sta $2118

    txa : clc : adc #$001f : tax
    cpx #$214f
    bne +
    ldx #$238f
+
    cpx #$23cf
    bne -

.end:
    plp : ply : plx : pla
    rtl

; Use autojoypad-read instead of manual controller reads to read all controllers fast
; X = which controller to read

;
; ButtonsPressed := $F8
; ButtonsDown := $FA
;

SnesReadInputs:
    lda $4219
    eor $fa
    and $4219
    sta $f8
    lda $4219
    sta $fa

    lda $421b
    eor $fb
    and $421b
    sta $f9
    lda $421b
    sta $fb

    lda $4218
    eor ButtonsDownSnes
    and $4218
    sta ButtonsPressedSnes
    lda $4218
    sta ButtonsDownSnes

    rtl



; Converts NES PPU Strings to SNES PPU strings

; $07A1 thru $07F0 contain a byte string of data to be written the the PPU. The first
; byte in the string is the upper address byte of the starting point in the PPU to write
; the data.  The second bye is the lower address byte. The third byte is a configuration
; byte. if the MSB of this byte is set, the PPU is incremented by 32 after each byte write
; (vertical write).  It the MSB is cleared, the PPU is incremented by 1 after each write
; (horizontal write). If bit 6 is set, the next data byte is repeated multiple times during
; successive PPU writes.  The number of times the next byte is repeated is based on bits
; 0-5 of the configuration byte.  Those bytes are a repitition counter. Any following bytes
; are the actual data bytes to be written to the PPU. #$00 separates the data chunks.

; We'll use a similar string format for the SNES, but optimized for SNES use
;
; TTTT = Data type (0000 = End of data, 0001 = TileMap, 0002 = TileAttr, 0003 = CGRAM, 0004 = Data (DMA), 0005 = Indirect VRAM DMA)
; AAAA = VRAM address or CGRAM Index
; FFFF = Flags (PPU increment etc)
; LLLL = Length (0000 = $00 terminated data)
; DDDD... = Data (format depends on type)
; .... next block

print "spps = ", pc
SnesProcessPPUString:
    phb : php
    pea $7e7e : plb : plb
    
    rep #$30

    lda.w #SnesPPUDataString
    sta $00

    ldy #$0000

.loop
    lda ($00), y    ; Load transfer type
    iny #2
    cmp #$0000
    bne +
    jmp .Exit
+   cmp #$0001
    bne +
    jmp .TileMap
+   cmp #$0002
    bne +
    jmp .TileAttr
+   cmp #$0003
    bne +
    jmp .CGRAM
+   cmp #$0004
    bne +
    jmp .Data
+   bra .IndirectDMA

.Data
    ; Data chunk ready for DMA
    lda ($00), y    ; Target
    iny #2
    sta $002116

    sep #$20
    
    lda ($00), y    ; VMAIN Flags
    iny
    sta $002115

    lda ($00), Y    ; DMA Flags
    iny
    sta $004310

    lda #$19
    sta $004311       ; DMA Target

    lda #$7e
    sta $004314       ; Source bank

    rep #$20

    lda ($00), y    ; Length
    sta TransferCount
    iny #2
    sta $004315

    tya
    clc : adc $00
    sta $004312      ; Store source address
    
    sep #$20    
    lda #$02
    sta $00420b      ; Execute DMA
    rep #$20

    tya
    clc : adc TransferCount
    tay

    rep #$30
    jmp .loop

.IndirectDMA
    print "ind = ",pc
    ; Data chunk ready for DMA
    lda ($00), y    ; Target
    iny #4
    sta $002116

    lda ($00), y    ; Length
    iny #2
    sta $004315

    lda ($00), y    ; Source addr
    iny #2
    sta $004312

    sep #$20

    lda #$80
    sta $002115

    lda #$01
    sta $004310

    lda #$18
    sta $004311       ; DMA Target

    lda ($00), y
    iny #2
    sta $004314       ; Source bank

    lda #$02
    sta $00420b      ; Execute DMA

    rep #$30
    jmp .loop

.CGRAM
    print "cg = ",pc
    iny #4
    lda ($00), y    ; Length
    iny #2
    tax

    sep #$20
-
    lda ($00), y : iny    ; Index
    sta $002121
    
    lda ($00), y : iny
    sta $002122

    lda ($00), y : iny
    sta $002122

    dex
    bne -
    
    rep #$30
    jmp .loop

print "tm = ", pc
.TileMap
    lda ($00), y   ; Target address
    iny #2
    sta $002116

    lda ($00), y   ; Flags
    iny #2
    sep #$20
    sta $002115
    rep #$20

    lda ($00), y   ; Length
    iny #2
    tax

    sep #$20
-
    lda ($00), y
    sta $002118
    iny
    dex
    bne -
    
    rep #$30
    jmp .loop

.TileAttr
    print "attr = ", pc
    lda ($00), y    ; Target address
    sta TransferAddress
    iny #4

    lda ($00), y    ; Length
    iny #2
    tax

    sep #$20
    lda #$80
    sta $002115

-
    rep #$30
    lda ($00), y
    sta $002116
    iny #2
    
    sep #$20
    lda ($00), y : iny
    sta $002119
    sta $002119
    lda ($00), y : iny
    sta $002119
    sta $002119

    dex
    beq +
    jmp -
    
+   rep #$30
    jmp .loop

.Exit
    rep #$30
    lda #$0000
    sta.l SnesPPUDataStringPtr

    plp
    plb
    rtl

; This routine is called with X/Y as arguments to where the pointer to draw is located
; We'll pre-process this string into SNES format before sending commands to the PPU
PreparePPUProcess:
    phx : phy
    stx $00
    sty $01
    phb : pla : sta $02
    lda #$01
    sta.b PPUDataPending
    lda #$01
    sta.w TransferSourceSet
    jsl SnesPPUPrepare
    ply : plx
    stx $00
    sty $01
    rtl

; Convert the address and format of these strings so that they can be easily uploaded to the SNES PPU during NMI
SnesPPUPrepare:
    phb : php
    pea $7e7e : plb : plb

;     lda.b PPUDataPending
;     bne +
;     jmp .exit
; +   
    rep #$30

    lda.w TransferSourceSet
    beq +
    stz.w TransferSourceSet
    bra ++  
+
    lda.w #PPUDataString
    sta $00
    lda #$007E
    sta $02
++
    lda.w #SnesPPUDataString
    sta $04

    ldy.w SnesPPUDataStringPtr

.loop
    lda [$00] : xba ; Load PPU target address, and flip the bytes into correct order
    cmp #$8000
    bcs .end

    sta TransferAddress
    inc $00 : inc $00
    
    lda [$00] : and #$00ff
    sta TransferFlags
    inc $00
    
    and #$0040            ; Check RLE bit
    cmp #$0040
    bne +
    lda #$0001
    bra ++
+
    lda #$0000
++
    sta TransferRLE

    lda TransferFlags
    and #$003f
    sta TransferCount

    lda TransferAddress
    and #$ff00
    cmp #$3f00
    bne +
    jsr PreparePalette : bra ++

+   cmp #$2000
    bcc +
    jsr PrepareTilemap : bra ++
+
    jsr PreparePattern : bra ++
++

    lda [$00]
    and #$00ff
    beq .end
    bne .loop

.end
    lda #$0000
    sta ($04), y
    sty.w SnesPPUDataStringPtr
.exit
    plp
    plb
    rtl

print "ptm = ", pc
PrepareTilemap:
    lda TransferAddress
    cmp #$2400
    bcs .second
.first
    sta TransferTarget       ; Tilemap 1
    bra +
.second
    and #$03ff
    clc : adc #$2400         ; Force any other nametable write to be written to
    sta TransferTarget       ; Tilemap 2 (this should work if the NES game is sane)
+
    lda TransferTarget
    and #$3c0
    cmp #$3c0
    bne +
    jsr PrepareAttributes
    rep #$30
    rts
+

    lda #$0001          ; Store type
    sta ($04), y
    iny #2

    lda TransferTarget  ; Store target
    sta ($04), y
    iny #2

    lda TransferFlags   ; Store flags
    and #$0080
    beq +
    lda #$0001
+    
    sta ($04), y
    iny #2

    lda TransferCount   ; Store count
    sta ($04), y
    iny #2

    sep #$20

.loop
    lda [$00]
    sta ($04), y
    iny

    lda TransferRLE
    bne +
    rep #$20 : inc $00 : sep #$20
+
    lda TransferCount : dec : sta TransferCount
    bne .loop

.end
    lda TransferRLE
    beq +
    rep #$20 : inc $00 : sep #$20
+
    rep #$30
    rts

print "patr = ", pc
PrepareAttributes:
    ; Attribute tables are a mess, since 1 byte of NES data needs to be written into 16 byte of SNES data
    ; We'll convert this into sets of 4-byte writes separated by the target address

    ; Check for specific cases where multiples of 8 bytes of attribute data is uploaded starting at the far left of the screen.
    ; This makes it possible to DMA a whole block of data at a time to the PPU instad of slowly uploading in a loop.
    lda TransferCount
    and #$0007
    bne +
    lda TransferAddress
    and #$0007
    bne +
    jsr PrepareAttributesDMA
    rts
+
    lda #$0002
    sta ($04), y        ; Store type
    iny #2

    ; Caculate where to start updates
    lda TransferAddress
    and #$003f  
    pha
    and #$0007
    asl #2
    sta TransferTmp
    pla
    and #$fff8
    asl #4
    clc : adc TransferTmp
    sta TransferTmp
    lda TransferAddress
    and #$2800
    cmp #$2800
    bcc +
    sec : sbc #$0400
+    
    clc : adc TransferTmp
    sta TransferTmp
    sta TransferAddress
    
    sta ($04), y        ; Store addr
    iny #2

    lda TransferFlags   ; Store flags
    sta ($04), y
    iny #2

    lda TransferCount   ; Store count
    asl #2
    sta ($04), y
    iny #2

.loop
    rep #$30
    lda TransferAddress  ; Store target address
    sta ($04), y
    iny #2
    
    sep #$20

    lda [$00]
    pha

    and #$03
    asl #2
    sta Z1ATTR.TopLeft

    pla : lsr #2 : pha
    and #$03
    asl #2
    sta Z1ATTR.TopRight
    
    pla : lsr #2 : pha
    and #$03
    asl #2
    sta Z1ATTR.BottomLeft

    pla : lsr #2
    and #$03
    asl #2
    sta Z1ATTR.BottomRight


    lda Z1ATTR.TopLeft
    sta ($04), y
    iny

    lda Z1ATTR.TopRight
    sta ($04), y
    iny
    ; Stored first string of 4 bytes (Upper row of upper quadrants)
    
    rep #$30
    lda TransferAddress
    clc : adc #$0020
    sta TransferTmp
    sta ($04), y        ; Store address for next set of writes
    iny #2
    sep #$20

    lda Z1ATTR.TopLeft
    sta ($04), y
    iny

    lda Z1ATTR.TopRight
    sta ($04), y
    iny
    ; Stored next string of 4 bytes (Lower row of upper quadrant)

    rep #$30
    lda TransferTmp
    clc : adc #$0020
    sta TransferTmp
    sta ($04), y        ; Store address for next set of writes
    iny #2
    sep #$20

    lda Z1ATTR.BottomLeft
    sta ($04), y
    iny

    lda Z1ATTR.BottomRight
    sta ($04), y
    iny
    ; Stored next string of 4 bytes (Upper row of lower quadrant)

    rep #$30
    lda TransferTmp
    clc : adc #$0020
    sta TransferTmp
    sta ($04), y        ; Store address for next set of writes
    iny #2
    sep #$20

    lda Z1ATTR.BottomLeft
    sta ($04), y
    iny

    lda Z1ATTR.BottomRight
    sta ($04), y
    iny
    ; Stored next string of 4 bytes (Lower row of lower quadrant)

    ; Increment VRAM Temp address
    rep #$30
    lda TransferAddress
    clc : adc #$0004 : sta TransferAddress
    and #$0020
    cmp #$0020
    bne +
    ; New row, adjust downwards
    lda TransferAddress : clc : adc #$0060 : sta TransferAddress
+
    sep #$20

    lda TransferRLE
    bne +
    rep #$20 : inc $00 : sep #$20
+
    lda TransferCount : dec : sta TransferCount
    beq +
    jmp .loop
+
.end
    lda TransferRLE
    beq +
    rep #$20 : inc $00 : sep #$20
+
    rep #$30
    rts 

print "ppad = ", pc
PrepareAttributesDMA:
    
    lda #$0004
    sta ($04), y        ; Store type (data)
    iny #2

    ; Caculate where to start updates
    lda TransferAddress
    and #$003f  
    pha
    and #$0007
    asl #2
    sta TransferTmp
    pla
    and #$fff8
    asl #4
    clc : adc TransferTmp
    sta TransferTmp
    lda TransferAddress
    and #$2800
    cmp #$2800
    bcc +
    sec : sbc #$0400
+
    clc : adc TransferTmp
    sta TransferTmp
    sta TransferAddress
    
    sta ($04), y        ; Store addr
    iny #2

    lda #$0080          ; DMA / VMAIN
    sta ($04), y
    iny #2

    lda TransferCount   ; Store count (*16 for SNES bytes)
    asl #4
    sta ($04), y
    pha
    iny #2

    ; y has offset from ($04) to target, but we'll have to be more efficient here
    rep #$30
    lda $04
    sta TransferTmp
    tya
    clc : adc TransferTmp
    tax
    phy

    ; Now X contains the current offset to the buffer in bank 7E
    ldy #$0000

.loop
    sep #$20

    ; Extract attribute data from NES byte
    lda [$00]
    pha

    and #$03
    asl #2
    sta Z1ATTR.TopLeft

    pla : lsr #2 : pha
    and #$03
    asl #2
    sta Z1ATTR.TopRight
    
    pla : lsr #2 : pha
    and #$03
    asl #2
    sta Z1ATTR.BottomLeft

    pla : lsr #2
    and #$03
    asl #2
    sta Z1ATTR.BottomRight

    ; Write into SNES buffer
    lda Z1ATTR.TopLeft
    sta $0000, x
    sta $0001, x
    sta $0020, x
    sta $0021, x

    lda Z1ATTR.TopRight
    sta $0002, x
    sta $0003, x
    sta $0022, x
    sta $0023, x

    lda Z1ATTR.BottomLeft
    sta $0040, x
    sta $0041, x
    sta $0060, x
    sta $0061, x

    lda Z1ATTR.BottomRight
    sta $0042, x
    sta $0043, x
    sta $0062, x
    sta $0063, x

    ; Increment VRAM Temp address
    rep #$30
    
    inx #4
    iny #4
    cpy #$0020
    bne +
    txa : clc : adc #$0060 : tax
    ldy #$0000
+
    sep #$20

    lda TransferRLE
    bne +
    rep #$20 : inc $00 : sep #$20
+
    lda TransferCount : dec : sta TransferCount
    beq +
    jmp .loop
+
.end
    lda TransferRLE
    beq +
    rep #$20 : inc $00 : sep #$20
+
    rep #$30
    
    ; Re-adjust Y
    ply
    pla
    sta TransferTmp
    tya
    clc
    adc TransferTmp
    tay

    rts

PreparePattern:
    lda #$0004
    sta ($04), y
    iny #2
    lda #$0000
    sta ($04), y
    iny #2
    lda #$0000
    sta ($04), y
    iny #2
    lda TransferCount
    sta ($04), y
    tax
    iny #2

    sep #$20

.loop
    lda [$00]
    sta ($04), y
    rep #$20 : inc $00 : sep #$20 : iny : dex
    bne .loop
    
    rep #$30
    rts


print "ppal = ", pc
PreparePalette:
    lda #$0003
    sta ($04), y     ; Store type
    iny #2

    lda #$0000
    sta ($04), y     ; Store address
    iny #2

    lda #$0000
    sta ($04), y     ; Store flags
    iny #2

    lda TransferAddress
    and #$001c
    asl #2
    cmp #$0040
    bcc +
    clc : adc #$0040
+
    sta TransferTmp  ; Palette offset
    lda TransferAddress
    and #$0003
    clc : adc TransferTmp
    sta PalIdx

    lda TransferCount
    and #$003f
    sta TransferCount
    tax
    sta ($04), y    ; Store length
    iny #2
    sep #$20

.loop
    lda PalIdx
    sta ($04), y
    iny    
    lda [$00]
    phx : asl : tax
    lda.l NesPalTable, x
    sta ($04), y
    iny
    lda.l NesPalTable+1, x
    sta ($04), y
    iny

    lda PalIdx
    inc
    sta PalIdx
    and #$0f
    cmp #$04
    bne +
    lda PalIdx : clc : adc #$0C : sta PalIdx
    cmp #$40
    bne +
    clc : adc #$40 : sta PalIdx
+
    plx
    rep #$20 : inc $00 : sep #$20 : dex
    bne .loop
    
    rep #$30
    rts

; Takes a PPU-data string, parses it and converts it into SNES PPU commands
ProcessPPUString:
    lda #$00 : sta $4200
    lda #$8F : sta $2100
    jsl SnesProcessPPUString
    lda PPUCNT0ZP : jsr WritePPUCTRL
    lda PPUCNT1ZP : jsr WritePPUCTRL1
    rtl

print "soundemu = ", pc
SoundEmulateLengthCounters:
    sep #$30
    lda $0915
    ora #$04
    tay

    bit #$01
    beq .sq1

    lda $0900
    and #$20
    bne ++
    ldx.w APUSq0Length
    bne +
    tya
    and #$fe
    tay
    bra .sq1
+
    dex
    stx.w APUSq0Length
++
    tya

.sq1

    bit #$02
    beq .noise

    lda $0904
    and #$20
    bne ++
    ldx.w APUSq1Length
    bne +
    tya
    and #$fd
    tay
    bra .sq1
+
    dex
    stx.w APUSq1Length
++
    tya

.noise
    bit #$08
    beq .tri

    lda $090c
    and #$20
    bne ++
    ldx.w APUNoiLength
    bne +
    tya
    and #$f7
    tay
    bra .sq1
+
    dex
    stx.w APUNoiLength
++
    tya

.tri
    ldx $0908
    bpl ++

    ldx.w APUTriLength
    bne +
    and #$fb
    bra .end
+
    dex
    stx.w APUTriLength
++
.end

    sta $0915
    rts

SnesUpdateAudio:
    PHX : PHY : PHA : PHP
    SEP #$30

    ; This isn't great but fixes some SFX
    ; but makes the triangle channel never stop
    ; LDA $908
    ; ORA #$80
    ; STA $908

    JSR SoundEmulateLengthCounters

    LDA $915
    BNE +
    ; Silence everything
    LDX #$00
-
    STZ $900, x
    INX
    CPX #$17
    BNE -

+


    LDA $2140
    CMP #$7D
    BEQ +
    JMP .End
+
    
    LDA #$D7
    STA $2140

-
    LDA $2140
    CMP #$D7
    BNE -

;;  Loop which transfers the ~22 bytes of audio status data (see labels:460)
;;  to the spc-700 receiving loop in ../nes-spc/spc.asm:355-366
    LDX #$00

--
    LDA $0900, X
    STA $2141
    STX $2140

    INX

-   CPX $2141
    BNE -

    CPX #$17
    BNE --

    ; LDA #$0F
    ; STA $915

    stz $0916

.End
    PLP : PLA : PLY : PLX
    RTL

NesPalTable:
dw $294A, $2860, $3021, $3004, $2406, $1008, $0027, $0046, $0083, $00A1, $00A0, $04A0, $1480, $0000, $0000, $0000, $5294, $4D23, $5CC7, $5CAB, $488E, $2C90, $10B0, $00ED, $014A, $0186, $01A3, $15A1, $3562, $0000, $0000, $0000, $7FFF, $7E6D, $7E11, $7DD5, $79B9, $59DC, $39FB, $1E59, $1294, $16F0, $230C, $3F0A, $62CA, $1CE7, $0000, $0000, $7FFF, $7F57, $7F39, $7F1B, $7F1D, $6F1E, $631E, $575D, $4F7B, $4F99, $5797, $6396, $7376, $56B5, $0000, $0000

AttributeTable:
db $20, $22, $24, $26, $20, $22, $24, $26, $20, $22, $24, $26, $20, $22, $24, $26, $20, $22, $24, $26, $20, $22, $24, $26, $20, $22, $24, $26, $20, $22, $24, $26, $00, $02, $04, $06 
db $00, $02, $04, $06, $00, $02, $04, $06, $00, $02, $04, $06, $00, $02, $04, $06, $00, $02, $04, $06, $00, $02, $04, $06, $00, $02, $04, $06, $60, $62, $64, $66, $60, $62, $64, $66 
db $60, $62, $64, $66, $60, $62, $64, $66, $60, $62, $64, $66, $60, $62, $64, $66, $60, $62, $64, $66, $60, $62, $64, $66, $40, $42, $44, $46, $40, $42, $44, $46, $40, $42, $44, $46 
db $40, $42, $44, $46, $40, $42, $44, $46, $40, $42, $44, $46, $40, $42, $44, $46, $40, $42, $44, $46, $A0, $A2, $A4, $A6, $A0, $A2, $A4, $A6, $A0, $A2, $A4, $A6, $A0, $A2, $A4, $A6 
db $A0, $A2, $A4, $A6, $A0, $A2, $A4, $A6, $A0, $A2, $A4, $A6, $A0, $A2, $A4, $A6, $80, $82, $84, $86, $80, $82, $84, $86, $80, $82, $84, $86, $80, $82, $84, $86, $80, $82, $84, $86 
db $80, $82, $84, $86, $80, $82, $84, $86, $80, $82, $84, $86, $E0, $E2, $E4, $E6, $E0, $E2, $E4, $E6, $E0, $E2, $E4, $E6, $E0, $E2, $E4, $E6, $E0, $E2, $E4, $E6, $E0, $E2, $E4, $E6; , $E0, $E2, $E4
db $E6, $E0, $E2, $E4, $E6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4    
