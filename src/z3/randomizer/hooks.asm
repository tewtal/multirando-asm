org $02b797     ; Hook Link entering triforce room
    jml alttp_check_ending

org $0ee645
    jml alttp_setup_credits

org $02d70f
    jml check_teleport_in

;#_02E214: STA.l $7EC017
org $02E214
    jml check_teleport_out

; org $8089be
; 	jml zelda_save_done_hook

; allows Frog sprite to spawn in LW and also allows his friend to spawn in their house
org $868a76 ; < 30a76 - sprite_prep.asm:785 (LDA $7EF3CA : AND.w #$40)
    lda.b IndoorsFlag : eor.b #1 : nop #2

; allows Frog to be accepted at Blacksmith
org $86b3ee ; < 333ee - sprite_smithy_bros.asm:347 (LDA $7EF3CC : CMP.b #$08 : BEQ .no_returning_smithy_tagalong)
    jsl OWSmithAccept : nop #2
    db #$b0 ; BCS to replace BEQ