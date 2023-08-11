org $02b797     ; Hook Link entering triforce room
    jml alttp_check_ending

org $0ee645
    jml alttp_setup_credits

org $00e7b2 ; - bank00.asm : 5847
    jml Decomp_spr_high_extended

org $00e7de
    Decomp_spr_high_extended_return:

org $02d70f
    jml check_teleport_in

;#_02E214: STA.l $7EC017
org $02E214
    jml check_teleport_out

org $0089be
	jml zelda_save_done_hook

org $00d552
    jsl GetAnimatedSpriteBufferPointer_CopyId