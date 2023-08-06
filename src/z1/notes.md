# Notes for transitions


; Entering a Cave
; $EB = RoomId (of the overworld room we're coming from, and will exit to)
; LDA $AB45, X : STA $02
org $85AB4F
    lda $AB45, X

; Exiting a Cave
; $EB = RoomId (of the overworld room we're coming from, and will exit to)
; JMP $EA2B
org $85B157
    jmp $ea2b

; Entering or exiting dungeon - hook this, this also runs when exiting a dungeon
; $10 (current level) will be $00 when exiting (and $01+ when entering depending on dungeon)
; $EB = Previous RoomId (for the room we're entering from)
; $6BAD = New RoomId (for the room we're going to)
; LDA $6BAD (hook this with a JSR to common code)
org $85EA1C
    jsr check_dungeon_transition


# APU
Sending $F5 to port $2140 will put the SPC back in IPL mode
