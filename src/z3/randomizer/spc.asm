spc_reset:
    pha
    php
    %a8()
    lda #$ff                    ; Send N-SPC into "upload mode"
    sta $2140

    lda.b #spc_reset_data            ; Store the location of our "exploit data"
    sta $00                     ; so that the ALTTP music upload routine
    lda.b #spc_reset_data>>8         ; uses it.
    sta $01
    lda.b #spc_reset_data>>16
    sta $02

    jsl alttp_load_music        ; Call the alttp SPC upload routine
    plp
    pla
    rtl

spc_reset_data:        ; Upload this data to the SM music engine to kill it and put it back into IPL mode
    dw $002a, $0b00
    db $8f, $6c, $f2 
    db $8f, $e0, $f3 ; Disable echo buffer writes and mute amplifier
    db $8f, $7c, $f2 
    db $8f, $ff, $f3 ; ENDX
    db $8f, $7d, $f2 
    db $8f, $00, $f3 ; Disable echo delay
    db $8f, $4d, $f2 
    db $8f, $00, $f3 ; EON
    db $8f, $5c, $f2 
    db $8f, $ff, $f3 ; KOFF
    db $8f, $5c, $f2 
    db $8f, $00, $f3 ; KOFF
    db $8f, $80, $f1 ; Enable IPL ROM
    db $5f, $c0, $ff ; jmp $ffc0
    dw $0000, $0a00

pushpc
org $00cf50
alttp_load_music:
	sei
	jsr $8888
	cli
	rtl
pullpc