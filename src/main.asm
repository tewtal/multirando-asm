sa1rom

; Macros
incsrc "macros.asm"

; Zelda 1
incsrc "z1/main.asm"

; Metroid 1
incsrc "m1/main.asm"

; Super Metroid
incsrc "m3/main.asm"

; A Link to the Past
incsrc "z3/main.asm"

; Mother Brain
incsrc "motherbrain/main.asm"

sa1rom 0,0,7,0
org $9fffff
db $ff