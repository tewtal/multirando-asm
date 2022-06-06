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
