; Expanded dungeons support
; This allows dungeons to use level blocks from banks other than bank 6.
; Meaning we can have a full set of unique dungeon level blocks for all 9 dungeons.

; Params:
; [$00:01]: source address
; [$02:03]: destination address
; [$04:05]: end destination address
;
; Also increments submode.
;
CopyBlock_LevelData:
    PHX : PHP
    REP #$30
    LDY #$0000
    LDX #$0000
    
    LDA $04
    SEC : SBC $02 : INC
    STA.w DungeonCopyLength
    LDA $02 : STA $04

    LDA.w CurLevel : AND #$00FF : TAX
    LDA.l LevelBlockBanksQ1, x

    SEP #$20
    STA $02

.loop
    LDA.b [$00], Y
    STA.b ($04), Y
    INY
    CPY.w DungeonCopyLength
    BNE .loop
    PLP : PLX
    INC GameSubmode
    RTL

