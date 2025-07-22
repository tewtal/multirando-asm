optimize dp always
optimize address ram

; This is executed after everything else in a frame is processed, before the NMI wait-loop.
; Here's the proper time to run code specific for the SNES port to convert data or otherwise modify things.
SnesProcessFrame:
    jsr SnesOamPrepare
    jsl SnesPPUPrepare
    
    lda #$00	
	sta NMIStatus
    print "frame done = ", pc
    rtl

SetupScrollHDMA:
    sep #$30
    lda #$02
    sta $4370
    lda #$0E     ; Vertical scroll
    sta $4371 
    rep #$30
    lda.w #ScrollTable
    sta $4372
    sep #$30
    lda.b #(ScrollTable>>16)
    sta $4374
    rtl

UpdateScrollHDMA:
    lda #$ef
    sec : sbc ScrollY
    ; beq .noDma
    ; cmp #$ef
    ; bcs .noDma
    
    cmp #$7f
    bcs .secondHalf
    sta ScrollTable_len1
    sta ScrollTable_len2
    stz ScrollTable_len3
    lda ScrollY
    sta ScrollTable_val1
    clc : adc #$10
    sta ScrollTable_val2
    bra .dma
.secondHalf
    sec : sbc #$7e
    sta ScrollTable_len2
    lda #$7e
    sta ScrollTable_len1
    sta ScrollTable_len3
    lda ScrollY
    sta ScrollTable_val1
    sta ScrollTable_val2
    clc : adc #$10
    sta ScrollTable_val3
.dma
    lda PPUCNT0ZP
    and #$01
    sta ScrollTable_val1+$1
    sta ScrollTable_val2+$1
    sta ScrollTable_val3+$1

    lda #$80
    bra .end
.noDma
    ; Handle scrolling normally
    lda ScrollY
    sta $210e
    lda PPUCNT0ZP
    and #$01
    sta $210e
    lda #$00
.end
    sta $420c
    rtl

; Convert the NES OAM buffer at $200-2FF to SNES format and DMA to the PPU
; We'll have to convert every 8x16 sprite into two 8x8 sprites since the SNES doesn't support 8x16

!VScrollOffset = $0F
!VSpriteOffset = $00

SnesOamPrepare:
    PHP : PHB : PEA $7E7E : PLB : PLB
    REP #$10
    LDA #$00 : XBA
    LDX #$0000
    LDY #$0000
.LoopSprite
    ; Y coordinate
    LDA.w OAMNES.Y, X
    CMP #$F8
    BCS .Clear
    SEC : SBC #!VSpriteOffset

    BIT.w OAMNES.Attr, X
    BMI .VFlip
    STA.w OAM.Y, Y
    ;CLC : ADC #$08
    ;STA.w OAM.Y+$4, Y
    BRA .XCoord
.VFlip
    ;STA.w OAM.Y+$4, Y
    ;CLC : ADC #$08
    STA.w OAM.Y, Y
    
.XCoord
    ; X coordinate
    LDA.w OAMNES.X, X
    STA.w OAM.X, Y
    ;STA.w OAM.X+$4, Y

    LDA.w OAMNES.Index, X
    ;AND #$F
    STA.w OAM.Index, Y
    INC
    ;STA.w OAM.Index+$4, Y

    LDA.w OAMNES.Attr, X
    PHX : TAX
    LDA.l AttributeTable, X
    PLX
    STA.w OAM.Attr, Y

    LDA.w OAMNES.Attr, X
    AND.b #$04
    BEQ .noExtended

    LDA.w OAM.Attr, Y
    ORA.b #$09
    STA.w OAM.Attr, Y

.noExtended
    BRA .Next

.Clear
    LDA.b #$F7
    STA.w OAM.Y, Y
    ;STA.w OAM.Y+$4, Y
.Next
    INY #4
    INX #4
    CPX #$0100
    BEQ +
    JMP .LoopSprite
+
    PLB
    PLP
    RTS

SnesOamDMA:
    REP #$30
    
    LDA #$0400
    STA $4300
    LDA #$2000
    STA $4302   
    LDA #$007E  ;  source address $7e2000
    STA $4304
    LDA #$0220  ;  transfer 544 bytes (full OAM table)
    STA $4305
    STZ $2102

    SEP #$20
    LDA #$01
    STA $420B


    LDA #$18
    STA $2101

    LDA #$15
    STA $212C

    SEP #$30
    RTL


; Emulate MMC1 PRG bank switch, bank number in A
; This instead uses the SNES banks to simulate NES PRG banking
; It also overwrites the NMI code in I-RAM so that it uses the correct bank when entering NMI
MMCWriteReg3:
    CLC : ADC #!BASE_BANK
    STA m1_NMIJumpBank
    PHA : PLB
    STA BankSwitchBank
    REP #$20
    PLA : INC A : STA BankSwitchAddr
    SEP #$20
    LDA $00
    JML.w [BankSwitchAddr]

SetPPUMirror:
    AND #$0F
    CMP #$07
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


; PPU Commands
WriteScroll:
    lda ScrollX
    sta $210d
    lda PPUCNT0ZP
    and #$01
    sta $210d

    ; Handled by H-DMA
    ; lda ScrollY
    ; sta $210e
    ; lda PPUCNT0ZP
    ; and #$01
    ; sta $210e
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
print "prepareppuproc = ", pc
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

    lda.b PPUDataPending
    bne +
    jmp .exit
+   
    rep #$30

    lda.w TransferSourceSet
    beq +
    stz.w TransferSourceSet
    bra ++  
+
    lda.w #m1_PPUDataString
    sta $00
    lda #$007E
    sta $02
++
    lda.w #SnesPPUDataString
    sta $04

    ldy.w SnesPPUDataStringPtr

.loop
    lda [$00] : xba   ; Load PPU target address, and flip the bytes into correct order
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
    and #$2400
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
    sta ATTR.TopLeft

    pla : lsr #2 : pha
    and #$03
    asl #2
    sta ATTR.TopRight
    
    pla : lsr #2 : pha
    and #$03
    asl #2
    sta ATTR.BottomLeft

    pla : lsr #2
    and #$03
    asl #2
    sta ATTR.BottomRight


    lda ATTR.TopLeft
    sta ($04), y
    iny

    lda ATTR.TopRight
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

    lda ATTR.TopLeft
    sta ($04), y
    iny

    lda ATTR.TopRight
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

    lda ATTR.BottomLeft
    sta ($04), y
    iny

    lda ATTR.BottomRight
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

    lda ATTR.BottomLeft
    sta ($04), y
    iny

    lda ATTR.BottomRight
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
    and #$2400
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
    sta ATTR.TopLeft

    pla : lsr #2 : pha
    and #$03
    asl #2
    sta ATTR.TopRight
    
    pla : lsr #2 : pha
    and #$03
    asl #2
    sta ATTR.BottomLeft

    pla : lsr #2
    and #$03
    asl #2
    sta ATTR.BottomRight

    ; Write into SNES buffer
    lda ATTR.TopLeft
    sta $0000, x
    sta $0001, x
    sta $0020, x
    sta $0021, x

    lda ATTR.TopRight
    sta $0002, x
    sta $0003, x
    sta $0022, x
    sta $0023, x

    lda ATTR.BottomLeft
    sta $0040, x
    sta $0041, x
    sta $0060, x
    sta $0061, x

    lda ATTR.BottomRight
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

; $00 = Pointer to $6000
print "uploadstart = ", pc
UploadStartTilemap:
    lda #$00
    sta $2115
    lda #$00    ;
    sta $2116   ;
    lda #$20    ;  Start at vram $2000
    sta $2117

    rep #$10
    ldx #$03C0
    ldy #$0000

-
    ; Calculate tile attribute byte to load into VMDATAH
    ; TODO: Proper implementation (see notes below)
    lda m1_RoomPalette  ;  The palette number that applies to the vast majority of tiles in the current room
    asl #2      ;  Shift the palette into the VMDATAH palette bits
    sta $2119   ;  Attribute data to VMDATAH
    lda ($00), y
    sta $2118   ;  Tile data to VMDATAL

    iny
    dex
    bne -    

    ;  Handle non-room palette tiles
    ;  This section is a hack which hardcodes the handful of bytes
    ;  in each of the 5 respawn screens that require different palette numbers
    ;  than the room palette stored in m1 zero page at $68.
    ;  The proper way to handle this is to find out why SnesProcessPPUString
    ;  is not called after up+A/death restart sequences even though the NES ppu string data
    ;  is being populated at $7a0-$7ff.  Perhaps one or more hook locations is missing in hooks.asm.

    ;  Load Current level from m1 zero page ($10 = Brinstar, $11 = Norfair, $12 = Kraid, $13 = Tourian, $14 = Ridley)
    ldy #$0000  ;  Reset indexes; [X] is already #$0000
    lda m1_CurrentArea
    ;  No .brinstar label needed.  The wrong palette $00 is being used, but as a happy coincidence,
    ;  the bg tile colors in palette $00 and $03 are identical in brinstar.
    cmp #$11
    beq .norfair
    cmp #$12
    beq .gokraidslair
    cmp #$13
    beq .gotourian
    cmp #$14
    beq .goridleyslair

    ldx #$0000
    sep #$30
    rtl

.gokraidslair:
    jmp .kraidslair
.gotourian:
    jmp .tourian
.goridleyslair:
    jmp .ridleyslair

.norfairHorizSequenceLengths: db $08
.norfairHorizSequencePalette: db $00
.norfairHorizSequenceAddrs:
    dw $224c
    dw $226c
..end
.norfairVertSequenceLengths: db $04
.norfairVertSequencePalette: db $04
.norfairVertSequenceAddrs:
    dw $21cc
    dw $21cd
    dw $21d2
    dw $21d3
..end
.norfair:
..horizSequences
    ;  First set VMAIN and vram write location:
    lda #$80    ;  For horizontal sequences
    sta $2115

..loop:
    lda.l .norfairHorizSequenceAddrs, x
    sta $2116 : inx
    lda.l .norfairHorizSequenceAddrs, x
    sta $2117 : inx

    lda.l .norfairHorizSequenceLengths
    rep #$20 : and.w #$00ff  ;  
    tay : sep #$20           ;  Clear junk in [B]
    lda.l .norfairHorizSequencePalette

-
    sta $2119   ;  Attribute data to VMDATAH
    dey
    bne -

    ;  End-of-loop test
    cpx.w #(.norfairHorizSequenceAddrs_end-.norfairHorizSequenceAddrs)
    beq ..vertSequences
    jmp ..loop

..vertSequences:
    ;  First set VMAIN and vram write location:
    lda #$81    ;  For vertical sequences
    sta $2115
    ldx #$0000

..vloop:
    lda.l .norfairVertSequenceAddrs, x
    sta $2116 : inx
    lda.l .norfairVertSequenceAddrs, x
    sta $2117 : inx

    lda.l .norfairVertSequenceLengths
    rep #$20 : and.w #$00ff  ;
    tay : sep #$20           ;  Clear junk in [B]
    lda.l .norfairVertSequencePalette;, x

-
    sta $2119   ;  Attribute data to VMDATAH
    dey
    bne -

    ;  End-of-loop test
    cpx.w #(.norfairVertSequenceAddrs_end-.norfairVertSequenceAddrs)
    beq ..done
    jmp ..vloop

..done:
    ldx #$0000
    sep #$30
    rtl


.kraidsVertSequenceLengths: db $04
.kraidsVertSequencePalette: db $04
.kraidsVertSequenceAddrs:
    dw $2104
    dw $219b
..end
.kraidslair:
..vertSequences:
    ;  First set VMAIN and vram write location:
    lda #$81    ;  For vertical sequences
    sta $2115
    ldx #$0000

..vloop:
    lda.l .kraidsVertSequenceAddrs, x
    sta $2116 : inx
    lda.l .kraidsVertSequenceAddrs, x
    sta $2117 : inx

    lda.l .kraidsVertSequenceLengths
    rep #$20 : and.w #$00ff  ;
    tay : sep #$20           ;  Clear junk in [B]
    lda.l .kraidsVertSequencePalette;, x

-
    sta $2119   ;  Attribute data to VMDATAH
    dey
    bne -

    ;  End-of-loop test
    cpx.w #(.kraidsVertSequenceAddrs_end-.kraidsVertSequenceAddrs)
    beq ..done
    jmp ..vloop

..done:
    ldx #$0000
    sep #$30
    rtl

.tourianHorizSequenceLengths: db $04
.tourianHorizSequencePalette: db $04
.tourianHorizSequenceAddrs:
    dw $2306
    dw $22d6
..end
.tourian:
..horizSequences
    ;  First set VMAIN and vram write location:
    lda #$80    ;  For horizontal sequences
    sta $2115

..loop:
    lda.l .tourianHorizSequenceAddrs, x
    sta $2116 : inx
    lda.l .tourianHorizSequenceAddrs, x
    sta $2117 : inx

    lda.l .tourianHorizSequenceLengths
    rep #$20 : and.w #$00ff  ;  
    tay : sep #$20           ;  Clear junk in [B]
    lda.l .tourianHorizSequencePalette

-
    sta $2119   ;  Attribute data to VMDATAH
    dey
    bne -

    ;  End-of-loop test
    cpx.w #(.tourianHorizSequenceAddrs_end-.tourianHorizSequenceAddrs)
    beq ..done
    jmp ..loop

..done:
    ldx #$0000
    sep #$30
    rtl

.ridleysVertSequenceLengths: db $0a
.ridleysVertSequencePalette: db $00
.ridleysVertSequenceAddrs:
    dw $2246
    dw $2247
    dw $2258
    dw $2259
..end
.ridleyslair:
..vertSequences:
    ;  First set VMAIN and vram write location:
    lda #$81    ;  For vertical sequences
    sta $2115
    ldx #$0000

..vloop:
    lda.l .ridleysVertSequenceAddrs, x
    sta $2116 : inx
    lda.l .ridleysVertSequenceAddrs, x
    sta $2117 : inx

    lda.l .ridleysVertSequenceLengths
    rep #$20 : and.w #$00ff  ;
    tay : sep #$20           ;  Clear junk in [B]
    lda.l .ridleysVertSequencePalette;, x

-
    sta $2119   ;  Attribute data to VMDATAH
    dey
    bne -

    ;  End-of-loop test
    cpx.w #(.ridleysVertSequenceAddrs_end-.ridleysVertSequenceAddrs)
    beq ..done
    jmp ..vloop

..done:
    ldx #$0000
    sep #$30
    rtl


; $03 = target address
; $01 = source address
; $05 = length
GFXCopyLoop:
    lda #$8f
    sta $2100

    lda $03
    sta $2116

    lda $04
    sta $2117

    lda #$80
    sta $2115

.Loop
    ; Do some trickery to convert NES 2bpp -> SNES 4bpp

    LDY #$08
    LDX #$08

-
    LDA ($01)
    STA $2118
    LDA ($01), Y
    STA $2119

    REP #$20
    INC $01
    DEC $05
    LDA $05
    BEQ .Exit
    SEP #$20

    DEX
    BNE -

    REP #$20
    LDA $01
    CLC : ADC #$0008
    STA $01
    LDA $05
    SEC : SBC #$0008
    STA $05
    LDX #$08
-
    STZ $2118
    DEX
    BNE -

    LDA $05
    BEQ .Exit

    SEP #$20
    BRA .Loop

.Exit
    SEP #$20
    lda PPUCNT1ZP : jsr WritePPUCTRL1
    rtl

ClearNameTable:
    PHX : PHY : PHP
    LDA #$8F
    STA $2100
    LDA #$00
    STA $4200

    LDA #$80
    STA $2115

    REP #$30
    LDA #$2000
    STA $2116
    
    LDX #$1000

-
    LDA #$00FF
    STA $2118
    DEX
    BNE -

    SEP #$30
    lda PPUCNT0ZP : jsr WritePPUCTRL
    lda PPUCNT1ZP : jsr WritePPUCTRL1

    PLP : PLY : PLX
    RTL

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
    bmi ++
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
db $80, $82, $84, $86, $80, $82, $84, $86, $80, $82, $84, $86, $E0, $E2, $E4, $E6, $E0, $E2, $E4, $E6, $E0, $E2, $E4, $E6, $E0, $E2, $E4, $E6, $E0, $E2, $E4, $E6, $E0, $E2, $E4, $E6, $E0, $E2, $E4
db $E6, $E0, $E2, $E4, $E6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C0, $C2, $C4    
