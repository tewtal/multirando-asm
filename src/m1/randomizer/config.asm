; M1 randomizer configuration flags
; Fixed addresses written directly by the C# randomizer - don't move these

; Area M1 cold-boots into when it is the initial game. This is applied by
; LoadItems (loadgame.asm) the same way a vanilla password start selects an
; area. InArea order:
;   0 = Brinstar, 1 = Norfair, 2 = Kraid, 3 = Tourian, 4 = Ridley
;
; The start cell within the area (also the death/continue respawn cell for
; that area) is the vanilla 4-byte block at NES $95D7 in the area's PRG bank:
;   $9195D7 Brinstar, $9295D7 Norfair, $9495D7 Kraid, $9395D7 Tourian,
;   $9595D7 Ridley
;   +0 = start map X, +1 = start map Y, +2 = Samus screen Y (X is fixed $80),
;   +3 = palette toggle ($01 normal, $06 alternate)
config_m1_start_area:            ; $98FF00
    db $00

; Orientation of each area's start/respawn room (same area order as above):
;   0 = horizontal room (scrolls left/right), 1 = vertical room (scrolls up/down)
; Must match the room at each area's $95D7 cell or scrolling/mirroring breaks.
; Vanilla: the Brinstar start corridor is horizontal, all other area start
; rooms are vertical elevator shafts.
config_m1_start_orientation:     ; $98FF01
    db $00, $01, $01, $01, $01
