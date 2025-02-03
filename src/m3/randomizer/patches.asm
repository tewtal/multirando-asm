; Fix the crash that occurs when you kill an eye door whilst a eye door projectile is alive
; See the comments in the bank logs for $86:B6B9 for details on the bug
; The fix here is setting the X register to the enemy projectile index,
; which can be done without free space due to an unnecessary RTS in the original code
org $86B704
BEQ gadora_fix_ret
TYX

org $86B713
gadora_fix_ret:

; Removes Gravity Suit heat protection
org $8de37d
    db $01
org $90e9dd
    db $01

; Suit acquisition animation skip
org $848717
    db $ea, $ea, $ea, $ea

; Fix Morph & Missiles room state
; org $cfe652
; morph_missiles:
;     lda.l $7ed873
;     beq .no_items
;     bra .items
; org $cfe65f
; .items
; org $cfe666
; .no_items

; Set morph and missiles room state to always active
org $8fe658
    db $ea, $ea

org $8fe65d
    db $ea, $ea

; Fix heat damage speed echoes bug
org $91b629
    db $01

; Disable GT Code
org $aac91c
    db $80

; Disable Space/time
org $82b175
    db $01

; Fix Morph Ball Hidden/Chozo PLM's
org $84e8ce
    db $04
org $84ee02
    db $04

; Fix Screw Attack selection in menu
org $82b4c5
    db $0c

; Use door direction ($0791) to check in Big Boy room if we are coming in from the left vs. right.
; The vanilla game instead uses layer 1 X position ($0911) in a way that doesn't work if
; door scrolling finishes before enemy initialization, a race condition which doesn't
; happen to occur in the vanilla game but can in the randomizer, for example due to a combination of 
; fast doors and longer room load time (from reloading CRE) in case we enter from Kraid's Room.
org $A9EF6C
fix_big_boy:
	LDA $0791              ; door direction
	BNE .spawn_big_boy
	LDA #$2D00			   ;\ Set enemy as intangible and invisible
	STA $0F86,x            ;/
	LDA #$EFDF             ; Enemy function = $EFDF (disappeared)
	BRA .done
.spawn_big_boy
	LDA #$EFE6             ; Enemy function = $EFE6
	NOP
org $A9EF80 
.done

; Graphical fix for loading to start location with camera not aligned to screen boundary, by strotlog:
; (See discussion in Metconst: https://discord.com/channels/127475613073145858/371734116955193354/1010003248981225572)
org $80C473
	stz $091d

org $80C47C
	stz $091f

; Fix 32 sprite bug/crash that can occur during door transition
; Possible when leaving Kraid mid-fight, killing Shaktool with wave-plasma, etc.
; Documented by PJBoy: https://patrickjohnston.org/bank/B4#fBD97
org $b4bda3
    bpl $f8 ; was bne $f8


; Originally from https://forum.metroidconstruction.com/index.php/topic,145.msg73993.html#msg73993

; From PJ: (https://patrickjohnston.org/bank/82#fE4A9)
; Because scrolling updates take precedence over PLM draw updates, and because the scrolling updates were carried out prior to any PLM level data modifications,
; PLM draw updates that affect the top row of (the visible part of) the room for upwards doors or the bottom row of the room for downwards doors aren't visible
; This is the cause of the "red and green doors appear blue in the Crateria -> Red Brinstar room" bug

org $82E53C : JSL $808338 : JSL $8485B4 ; Waits for scrolling updates to happen before drawing the PLMs


; Mother Brain Cutscene Edits
org $a98824
    db $01, $00
org $a98848
    db $01, $00
org $a98867
    db $01, $00
org $a9887f
    db $01, $00
org $a98bdb
    db $04, $00
org $a9897d
    db $10, $00
org $a989af
    db $10, $00
org $a989e1
    db $10, $00
org $a98a09
    db $10, $00
org $a98a31
    db $10, $00
org $a98a63
    db $10, $00
org $a98a95
    db $10, $00
org $a98b33
    db $10, $00
org $a98dc6
    db $b0
org $a98b8d
    db $12, $00
org $a98d74
    db $00, $00
org $a98d86
    db $00, $00
org $a98daf
    db $00, $01
org $a98e51
    db $01, $00
org $a9b93a
    db $00, $01
org $a98eef
    db $0a, $00
org $a98f0f
    db $60, $00
org $a9af4e
    db $0a, $00
org $a9af0d
    db $0a, $00
org $a9b00d
    db $00, $00
org $a9b132
    db $40, $00
org $a9b16d
    db $00, $00
org $a9b19f
    db $20, $00
org $a9b1b2
    db $30, $00
org $a9b20c
    db $03, $00

; Fix door event bits
org $838bd0
    db $40

org $8397c4
    db $40

org $8398a8
    db $40

org $83a896
    db $40

org $8f86ec
    db $23, $EF, $45, $29, $1A, $00

org $c2def0
    incbin "../../data/morphroom.bin"

org $c2e2e4
    db $ff, $ff, $ff, $ff

