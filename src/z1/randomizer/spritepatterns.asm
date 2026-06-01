; =============================================
; Pre-converted Sprite Pattern Data
; =============================================
;
; Converts all unique Z1 underworld sprite pattern blocks
; from NES 2bpp to SNES 4bpp format at boot/transition time.
;
; NES 2bpp tile: 16 bytes (8 plane0 + 8 plane1)
; SNES 4bpp tile: 32 bytes (8 words plane0:plane1 + 8 zero words)
;

; WRAM offsets for each pre-converted block
!PCSP_UWBG     = $1000
!PCSP_UWSP     = $2040
!PCSP_SP127    = $2240
!PCSP_SP358    = $2680
!PCSP_SP469    = $2AC0
!PCSP_BOSS1257 = $2F00
!PCSP_BOSS3468 = $3700
!PCSP_BOSS9    = $3F00
!PCSP_END      = $4700

; NES ROM source addresses in SNES bank $83 (NES bank 3)
!NES_UWBG      = $83811B
!NES_UWSP      = $839CBB
!NES_SP127     = $839DBB
!NES_SP358     = $83987B
!NES_SP469     = $839A9B
!NES_BOSS1257  = $839FDB
!NES_BOSS3468  = $83A3DB
!NES_BOSS9     = $83A7DB

; =============================================
; Source table: 24-bit ROM address + 16-bit NES byte count
; 5 bytes per entry, 8 entries
; =============================================
SpritePatternSourceTable:
    dl !NES_UWBG     : dw $0820    ; 0: UW Background
    dl !NES_UWSP     : dw $0100    ; 1: UW Common Sprites
    dl !NES_SP127    : dw $0220    ; 2: Enemy sprites for levels 1,2,7
    dl !NES_SP358    : dw $0220    ; 3: Enemy sprites for levels 3,5,8
    dl !NES_SP469    : dw $0220    ; 4: Enemy sprites for levels 4,6,9
    dl !NES_BOSS1257 : dw $0400    ; 5: Boss sprites for levels 1,2,5,7
    dl !NES_BOSS3468 : dw $0400    ; 6: Boss sprites for levels 3,4,6,8
    dl !NES_BOSS9    : dw $0400    ; 7: Boss sprites for level 9
SpritePatternSourceTableEnd:

; =============================================
; Level (0-9) to set index mappings
; Index refers to PreconvertedBlockInfo entries
; =============================================
LevelToSpriteSet:
    db $02  ; Level 0 (unused/overworld, defaults to SP127)
    db $02  ; Level 1 → SP127
    db $02  ; Level 2 → SP127
    db $03  ; Level 3 → SP358
    db $04  ; Level 4 → SP469
    db $03  ; Level 5 → SP358
    db $04  ; Level 6 → SP469
    db $02  ; Level 7 → SP127
    db $03  ; Level 8 → SP358
    db $04  ; Level 9 → SP469

LevelToBossSet:
    db $05  ; Level 0 → Boss1257
    db $05  ; Level 1 → Boss1257
    db $05  ; Level 2 → Boss1257
    db $06  ; Level 3 → Boss3468
    db $06  ; Level 4 → Boss3468
    db $05  ; Level 5 → Boss1257
    db $06  ; Level 6 → Boss3468
    db $05  ; Level 7 → Boss1257
    db $06  ; Level 8 → Boss3468
    db $07  ; Level 9 → Boss9

; =============================================
; Pre-converted block info for DMA
; 6 bytes per entry: WRAM offset, SNES size, VRAM target
; =============================================
PreconvertedBlockInfo:
    dw !PCSP_UWBG,     $1040, $1700    ; 0: UW Background
    dw !PCSP_UWSP,     $0200, $08E0    ; 1: UW Common Sprites
    dw !PCSP_SP127,    $0440, $09E0    ; 2: SP127
    dw !PCSP_SP358,    $0440, $09E0    ; 3: SP358
    dw !PCSP_SP469,    $0440, $09E0    ; 4: SP469
    dw !PCSP_BOSS1257, $0800, $0C00    ; 5: Boss1257
    dw !PCSP_BOSS3468, $0800, $0C00    ; 6: Boss3468
    dw !PCSP_BOSS9,    $0800, $0C00    ; 7: Boss9

print "PreConvertSpritePatterns = ", pc

; =============================================
; PreConvertSpritePatterns
; =============================================
; Converts all NES 2bpp pattern blocks to SNES 4bpp
; and writes them sequentially to WRAM at $7F1000.
;
; Called at boot (init.asm) and on transition to Z1.
; Must be called with screen off. Uses DP $00-$07.
;
PreConvertSpritePatterns:
    phx : phy
    php

    sep #$20

    ; Reset loaded set tracking so first room always triggers DMA
    lda #$FF
    sta.w CurrentSpriteSet
    sta.w CurrentBossSet

    ; Set WRAM write address to $7F:1000
    ; WRAM port address: bit 16 = 1 (bank $7F), bits 0-15 = 1000
    stz $2181
    lda #$10
    sta $2182
    lda #$01
    sta $2183

    rep #$30
    ldx #$0000

.NextBlock:
    cpx.w #SpritePatternSourceTableEnd-SpritePatternSourceTable
    bcs .AllDone

    ; Load 24-bit source address into $00-$02
    lda.l SpritePatternSourceTable+0, x
    sta $00
    sep #$20
    lda.l SpritePatternSourceTable+2, x
    sta $02
    rep #$20

    ; Load NES byte count into $06-$07
    lda.l SpritePatternSourceTable+3, x
    sta $06

    ; Advance table index to next entry (5 bytes per entry)
    txa : clc : adc #$0005 : tax
    phx

    sep #$20

.ConvertTile:
    ldy #$0008              ; Y = plane 1 offset (8 bytes ahead)
    ldx #$0008              ; X = row counter

.Row:
    lda [$00]               ; Read plane 0 byte from NES source
    sta $2180               ; Write to WRAM (auto-increment)
    lda [$00], y            ; Read plane 1 byte (source + 8)
    sta $2180               ; Write to WRAM (auto-increment)

    rep #$20
    inc $00                 ; Advance source pointer (16-bit inc of $00-$01)
    dec $06                 ; Decrement remaining NES bytes
    lda $06
    beq .BlockDone
    sep #$20

    dex
    bne .Row

    ; 8 rows done - skip 8 source bytes (plane 1 data already read via Y)
    rep #$20
    lda $00
    clc : adc #$0008
    sta $00
    lda $06
    cmp #$0008
    bcc .BlockDone
    sec : sbc #$0008
    sta $06

    ; Write 16 zero bytes for SNES planes 2-3
    sep #$20
    ldx #$0010
-
    stz $2180
    dex
    bne -

    ; Check if more tiles remain
    lda $06 : ora $07
    beq .BlockDone
    bra .ConvertTile

.BlockDone:
    rep #$30
    plx
    jmp .NextBlock

.AllDone:
    plp
    ply : plx
    rtl

print "QueueSpritePatternDMA = ", pc

; =============================================
; QueueSpritePatternDMA
; =============================================
; Queues a pre-converted pattern block for DMA to VRAM
; during the next VBlank via the PPU data string system.
;
; Input: A (8-bit) = block index (0-7) from PreconvertedBlockInfo
; Can be called at any time (not just during VBlank).
;
QueueSpritePatternDMA:
    phx : phy
    php
 
    rep #$30

    ; Calculate table offset: index * 6
    and #$00FF
    sta $08
    asl                         ; ×2
    clc : adc $08               ; ×3
    asl                         ; ×6
    tax

    ; Load block info into scratch regs before building PPU string
    lda.l PreconvertedBlockInfo+0, x
    sta $08                     ; WRAM source offset
    lda.l PreconvertedBlockInfo+2, x
    sta $0A                     ; SNES transfer size
    lda.l PreconvertedBlockInfo+4, x
    sta $0C                     ; VRAM target address

    ; Set up pointer to PPU data string buffer
    lda.l #SnesPPUDataString
    sta $F0
    lda.l #(SnesPPUDataString>>8)
    sta $F1

    ; Get current write position
    lda.l SnesPPUDataStringPtr
    tay

    ; Write Indirect DMA entry (type $0005)
    ; +0: Type
    lda #$0005
    sta [$F0], y
    iny #2

    ; +2: VRAM target address
    lda $0C
    sta [$F0], y
    iny #4                      ; Skip +4 padding (matches processor iny #4)

    ; +6: Transfer length
    lda $0A
    sta [$F0], y
    iny #2

    ; +8: Source address (WRAM offset within bank $7F)
    lda $08
    sta [$F0], y
    iny #2

    ; +10: Source bank ($7F)
    lda #$007F
    sta [$F0], y
    iny #2

    ; Write terminator
    lda #$0000
    sta [$F0], y

    ; Update write pointer
    tya
    sta.l SnesPPUDataStringPtr

    plp
    ply : plx
    rtl

print "HandleRoomSpriteSwap = ", pc

; =============================================
; HandleRoomSpriteSwap
; =============================================
; Called from InitMode_EnterRoom_SpriteHook when a new
; underworld room has been loaded and scrolled into view.
;
; Reads the current room's enemy_id from level block data:
;   EnemyCode = LevelBlockAttrsC[room] & $3F  (Table 3, bits 5:0)
;   EnemyMode = LevelBlockAttrsD[room] & $80  (Table 4, bit 7)
;   enemy_id  = (EnemyMode >> 1) | EnemyCode  (7-bit, 0-127)
;
; Looks up EnemyIdToSpriteBlock[enemy_id] to get the
; pre-converted block index to DMA:
;   2-4 = sprite set (SP127/SP358/SP469) → updates CurrentSpriteSet
;   5-7 = boss set (Boss1257/Boss3468/Boss9) → updates CurrentBossSet
;   $FF = no swap needed (common sprites only)
;
HandleRoomSpriteSwap:
    phx : phy
    php

    sep #$30

    ; Only process underworld rooms (level > 0)
    lda.b CurLevel
    beq .Exit
    cmp #$0A
    bcs .Exit

    ; Get room_id
    lda.b RoomId
    and #$7F
    tax

    ; Build enemy_id from level block data
    ; EnemyCode = Table 3 bits 5:0
    lda.w LevelBlockAttrsC, x
    and #$3F
    sta $08

    ; EnemyMode = Table 4 bit 7 → shift to bit 6
    lda.w LevelBlockAttrsD, x
    and #$80
    lsr
    ora $08                     ; enemy_id = EnemyMode[6] | EnemyCode[5:0]
    tax

    ; Look up which block this enemy needs
    lda.l EnemyIdToSpriteBlock, x
    cmp #$FF
    beq .Exit

    ; Determine if sprite set (2-4) or boss set (5-7)
    cmp #$05
    bcs .IsBossSet

    ; Sprite set (2-4): compare against CurrentSpriteSet
    cmp.w CurrentSpriteSet
    beq .Exit
    sta.w CurrentSpriteSet
    jsl QueueSpritePatternDMA
    bra .Exit

.IsBossSet:
    ; Boss set (5-7): compare against CurrentBossSet
    cmp.w CurrentBossSet
    beq .Exit
    sta.w CurrentBossSet
    jsl QueueSpritePatternDMA

.Exit:
    plp
    ply : plx
    rtl
