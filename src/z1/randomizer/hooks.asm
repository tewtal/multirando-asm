; Entering a Cave
; $EB = RoomId (of the overworld room we're coming from, and will exit to)
; LDA $AB45, X : STA $02
org $85AB4F
    ;lda $AB45, X
    jsl check_cave_transition_in : nop

; Exiting a Cave
; $EB = RoomId (of the overworld room we're coming from, and will exit to)
; JMP $EA2B
org $85B157
    jmp CheckCaveTransitionOut_common

; Entering or exiting dungeon - hook this, this also runs when exiting a dungeon
; $10 (current level) will be $00 when exiting (and $01+ when entering depending on dungeon)
; $EB = Previous RoomId (for the room we're entering from)
; $6BAD = New RoomId (for the room we're going to)
; LDA $10
; BNE $85EA1C
org $85EA11
    jml check_dungeon_transition