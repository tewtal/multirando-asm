;
; Build the Zelda 1 port as a standalone HiROM game
;

!BASE_BANK = $A0

hirom

; PRG-ROM
org $A08000
incbin "../../resources/zelda2.nes":($0010)-($4010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $A18000
incbin "../../resources/zelda2.nes":($4010)-($8010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $A28000
incbin "../../resources/zelda2.nes":($8010)-($C010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $A38000
incbin "../../resources/zelda2.nes":($C010)-($10010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $A48000
incbin "../../resources/zelda2.nes":($10010)-($14010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $A58000
incbin "../../resources/zelda2.nes":($14010)-($18010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $A68000
incbin "../../resources/zelda2.nes":($18010)-($1C010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $A7C000
incbin "../../resources/zelda2.nes":($1C010)-($20010)

; CHR-ROM
org $A88000
chr_rom_0:
incbin "../data/z2chr_0.bin"

org $A98000
chr_rom_1:
incbin "../data/z2chr_1.bin"

org $AA8000
chr_rom_2:
incbin "../data/z2chr_2.bin"

org $AB8000
chr_rom_3:
incbin "../data/z2chr_3.bin"


org $80ffc0
    db "ZELDA 1 SNES   "

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

org $80bfc0
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

;  Non-rom dependencies
incsrc "../macros.asm"
incsrc "../defines.asm"

incsrc "labels.asm"

; Include hooks
incsrc "hooks.asm"

; Include common code (will be copied to WRAM $1000-$1FFF when switching to M1)
; The reason for this is that the main "common" MMC1 bank at $C000-$FFFF is more or less full
; so instead we use this free space in WRAM for code accessible from all banks
org $A78000
base $7E1000
incsrc "common.asm"
warnpc $A7C000

; Include SNES port functions that doesn't have to be in the common code area
org $AC8000
incsrc "init.asm"
incsrc "snes.asm"
; Include randomizer additions
; incsrc "randomizer/main.asm"

; Common NES code/data
namespace nes
org $9F8000
incsrc "../common/nes/overlay.asm"
warnpc $9FFFFF
namespace off

; Include randomizer additions
org $AD9000
incsrc "../nes-spc/spc.asm"
