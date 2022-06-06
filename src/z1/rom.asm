; Maps the NES rom into the proper SNES banks and address space
; We're using multiple banks here to simulate MMC1 bank switching

org $808000
incbin "../../resources/zelda1prg0.nes":($0010)-($4010)
incbin "../../resources/zelda1prg0.nes":($1C010)-($20010)

org $818000
incbin "../../resources/zelda1prg0.nes":($4010)-($8010)
incbin "../../resources/zelda1prg0.nes":($1C010)-($20010)

org $828000
incbin "../../resources/zelda1prg0.nes":($8010)-($C010)
incbin "../../resources/zelda1prg0.nes":($1C010)-($20010)

org $838000
incbin "../../resources/zelda1prg0.nes":($C010)-($10010)
incbin "../../resources/zelda1prg0.nes":($1C010)-($20010)

org $848000
incbin "../../resources/zelda1prg0.nes":($10010)-($14010)
incbin "../../resources/zelda1prg0.nes":($1C010)-($20010)

org $858000
incbin "../../resources/zelda1prg0.nes":($14010)-($18010)
incbin "../../resources/zelda1prg0.nes":($1C010)-($20010)

org $868000
incbin "../../resources/zelda1prg0.nes":($18010)-($1C010)
incbin "../../resources/zelda1prg0.nes":($1C010)-($20010)

org $87C000
incbin "../../resources/zelda1prg0.nes":($1C010)-($20010)
