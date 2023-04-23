sa1rom

!VERSION_MAJOR = 0
!VERSION_MINOR = 1
!VERSION_BUILD = 0
!VERSION_REV_1 = 0
!VERSION_REV_2 = 0

!PRERELEASE = 1

; Defines
incsrc "defines.asm"

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