org $02b797     ; Hook Link entering triforce room
    jml alttp_check_ending

org $0ee645
    jml alttp_setup_credits

org $00e7b2 ; - bank00.asm : 5847
    jml Decomp_spr_high_extended

org $00e7de
    Decomp_spr_high_extended_return:
