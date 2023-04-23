; Super Metroid ROM mapping

macro include_sm_lorom()
    !a #= $80
    while !a < $c0
        !b #= ((!a*$10000)+$8000)
        !c #= (!a-$80)
        org !b
        incbin "../../resources/sm.sfc":($000000+(!c*$8000))-($000000+((!c+1)*$8000))
        !a #= !a+1
    endwhile
endmacro

macro include_sm_hirom()
    !a #= $c0
    while !a < $d0
        !b #= (!a*$10000)
        !c #= (!a-$c0)
        org !b
        incbin "../../resources/sm.sfc":($200000+(!c*$10000))-($200000+((!c+1)*$10000))
        !a #= !a+1
    endwhile
endmacro

%include_sm_lorom()
%include_sm_hirom()

; Write header here to place it in the correct place
org $80ffc0
    db "MOTHER BRAIN   "

org $80ffd5
    db $23, $35, $0D, $06, $00, $33, $00

org $80ffea
    dw !IRAM_NMI

org $80ffee
    dw !IRAM_IRQ

org $80fffa
    dw !IRAM_NMI

org $80fffe
    dw !IRAM_IRQ

org $80ffec
    dw mb_snes_reset

org $80fffc
    dw mb_snes_reset


