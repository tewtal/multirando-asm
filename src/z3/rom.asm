; Super Metroid ROM mapping

macro include_alttp_lorom()
    !a #= $00
    while !a < $20
        !b #= ((!a*$10000)+$8000)
        org !b
        incbin "../../resources/zelda3.sfc":($000000+(!a*$8000))-($000000+((!a+1)*$8000))
        !a #= !a+1
    endwhile
endmacro

%include_alttp_lorom()

; Write header here to place it in the correct place
org $00ffc0
    db "MOTHER BRAIN   "

org $00ffd5
    db $23, $35, $0D, $06, $00, $33, $00

org $00ffea
    dw !IRAM_NMI

org $00ffee
    dw !IRAM_IRQ

org $00fffa
    dw !IRAM_NMI

org $00fffe
    dw !IRAM_IRQ

org $00ffec
    dw mb_snes_reset

org $00fffc
    dw mb_snes_reset