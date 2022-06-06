;
; Build the Metroid 1 port as a standalone HiROM game
;

!BASE_BANK = $A0

hirom

org $A08000
incbin "../../resources/metroid.nes":($0010)-($4010)
incbin "../../resources/metroid.nes":($1C010)-($20010)

org $A18000
incbin "../../resources/metroid.nes":($4010)-($8010)
incbin "../../resources/metroid.nes":($1C010)-($20010)

org $A28000
incbin "../../resources/metroid.nes":($8010)-($C010)
incbin "../../resources/metroid.nes":($1C010)-($20010)

org $A38000
incbin "../../resources/metroid.nes":($C010)-($10010)
incbin "../../resources/metroid.nes":($1C010)-($20010)

org $A48000
incbin "../../resources/metroid.nes":($10010)-($14010)
incbin "../../resources/metroid.nes":($1C010)-($20010)

org $A58000
incbin "../../resources/metroid.nes":($14010)-($18010)
incbin "../../resources/metroid.nes":($1C010)-($20010)

org $A68000
incbin "../../resources/metroid.nes":($18010)-($1C010)
incbin "../../resources/metroid.nes":($1C010)-($20010)

org $80ffc0
    db "METROID 1 SNES "

org $80ffd5
    db $31, $02, $0C, $03, $00, $33, $00

org $80ffea
IsrVector:
    dw IsrNmi
    dw $FFF0
    dw $FFF0

    dw $FFF0
    dw $FFF0
    dw $FFF0
    dw $FFF0
    dw $FFF0
    dw IsrNmi
    dw IsrReset
    dw $FFF0

org $80bf56
IsrReset:
    sei
    clc
    xce
    rep #$38
    lda #$0000
    sta $4200
    tcd
    lda #$1fff
    tcs
    phk
    plb
    jml SnesBoot

IsrNmi:
    JML [$0811]

incsrc "labels.asm"

; Include hooks
incsrc "hooks.asm"


; Include common code (will be copied to WRAM $1000-$1FFF when switching to M1)
; The reason for this is that the main "common" MMC1 bank at $C000-$FFFF is more or less full
; so instead we use this free space in WRAM for code accessible from all banks
org $A78000
base $7E1000
incsrc "common.asm"
warnpc $A72000

; Include SNES port functions that doesn't have to be in the common code area
org $A79000
incsrc "init.asm"
incsrc "snes.asm"

; Include randomizer additions
org $A89000
incsrc "../nes-spc/spc.asm"
org $AFFFFF
db $00