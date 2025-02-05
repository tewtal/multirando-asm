; Maps the NES rom into the proper SNES banks and address space
; We're using multiple banks here to simulate MMC1 bank switching

; HiRom Banks: (PRG)

; 37:0000 - 3B:FFFF (8F:8000 - 99:FFFF) (10 banks)  (End-ish of SM)
; 5B:0000 - 5F:FFFF (B6:8000 - BF:FFFF) (10 banks)  (End of ALTTP)
; 6D:0000 - 6F:7FFF (9A:8000 - 9E:FFFF) (5 banks)   (End of Z1/M1)
; 7A:0000 - 7C:FFFF (B4:8000 - B9:FFFF) (6 banks)   (Common data)


; Z2 Data:
; 7 x 32kb banks of LoRom (PRG-ROM)
; 2 x 64kb banks of HiRom (CHR-ROM)

; ~1-2 x 32kb banks of randomizer data


; Assignment:
; Bank E -> Slot 6 (Z1M1) -> LoRom - 9D:8000 - 9E:FFFF (Z2 SNES/Randomizer Code + Common NES (9F))
; Bank F -> Slot 5 (ALTTP #2) -> LoRom - B8:8000 - BF:FFFF (Z2 PRG-ROM)
; Bank C -> Slot 7 (Common/Menu) -> HiRom - CA:0000 - CB:FFFF (Z2 CHR-ROM)



org $B88000
incbin "../../resources/zelda2.nes":($0010)-($4010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $B98000
incbin "../../resources/zelda2.nes":($4010)-($8010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $BA8000
incbin "../../resources/zelda2.nes":($8010)-($C010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $BB8000
incbin "../../resources/zelda2.nes":($C010)-($10010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $BC8000
incbin "../../resources/zelda2.nes":($10010)-($14010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $BD8000
incbin "../../resources/zelda2.nes":($14010)-($18010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $BE8000
incbin "../../resources/zelda2.nes":($18010)-($1C010)
incbin "../../resources/zelda2.nes":($1C010)-($20010)

org $BFC000
incbin "../../resources/zelda2.nes":($1C010)-($20010)

; CHR-ROM
org $CA0000
incbin "../../resources/zelda2.nes":($20010)-($28010)

org $CA8000
incbin "../../resources/zelda2.nes":($28010)-($30010)

org $CB0000
incbin "../../resources/zelda2.nes":($30010)-($38010)

org $CB8000
incbin "../../resources/zelda2.nes":($38010)-($40010)