incbin "data/gfx_main_dma.bin":(0*$8000)-(1*$8000)   -> $9C8000
incbin "data/gfx_main_dma.bin":(1*$8000)-(2*$8000)   -> $9D8000
incbin "data/gfx_main_dma.bin":(2*$8000)-(3*$8000)   -> $9E8000
incbin "data/gfx_main_dma.bin":(3*$8000)-(4*$8000)   -> $9F8000
incbin "data/gfx_main_dma.bin":(4*$8000)-(5*$8000)   -> $D10000
incbin "data/gfx_main_dma.bin":(5*$8000)-(6*$8000)   -> $D18000
incbin "data/gfx_main_dma.bin":(6*$8000)-(7*$8000)   -> $D20000
incbin "data/gfx_main_dma.bin":(7*$8000)-(8*$8000)   -> $D28000
incbin "data/gfx_main_dma.bin":(8*$8000)-(9*$8000)   -> $D30000
incbin "data/gfx_main_dma.bin":(9*$8000)-(10*$8000)  -> $D38000
incbin "data/gfx_main_dma.bin":(10*$8000)-(11*$8000) -> $D40000
incbin "data/gfx_main_dma.bin":(11*$8000)-(12*$8000) -> $D48000
incbin "data/gfx_main_dma.bin":(12*$8000)-(13*$8000) -> $D50000
incbin "data/gfx_main_dma.bin":(13*$8000)-0          -> $D58000

; All death dma data need to stay in the same bank

incbin "data/gfx_death_dma_left.bin"  -> $D60000
incbin "data/gfx_death_dma_right.bin" -> $D64000

; New gun port gfx is needed since the mirror symmetry is broken up

incbin "data/gfx_gunport.bin" -> $9A9A00

; The revised samus sprite uses an updated crystal flash palette

incbin "data/palette_crystal_flash.bin":(0*30)-(1*30) -> $9B96C0+2+(0*$20)
incbin "data/palette_crystal_flash.bin":(1*30)-(2*30) -> $9B96C0+2+(1*$20)
incbin "data/palette_crystal_flash.bin":(2*30)-(3*30) -> $9B96C0+2+(2*$20)
incbin "data/palette_crystal_flash.bin":(3*30)-(4*30) -> $9B96C0+2+(3*$20)
incbin "data/palette_crystal_flash.bin":(4*30)-(5*30) -> $9B96C0+2+(4*$20)
incbin "data/palette_crystal_flash.bin":(5*30)-0      -> $9B96C0+2+(5*$20)
