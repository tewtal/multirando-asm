# Zelda 1 Porting Notes

## ROM Layout and info
Zelda 1 uses MMC1 with 8 banks, bank 7 is always mapped to $C000-$FFFF while banks 0-6 can be switched at $8000-$BFFF
SA-1 BW-RAM / HiROM SRAM at $6000-$7FFF will be stand-in as regular MMC1 extra WRAM.

## Proposed SNES Layout
Banks 80+ for SA-1 Layout, Banks A0+ for HiROM Layout (Standalone)

### ROM
    - $80/A0:8000-BFFF: PRG 0
    - $80/A0:C000-FFFF: PRG 7
    - $81/A1:8000-BFFF: PRG 1
    - $81/A1:C000-FFFF: PRG 7
    - $82/A2:8000-BFFF: PRG 2
    - $82/A2:C000-FFFF: PRG 7
    - $83/A3:8000-BFFF: PRG 3
    - $83/A3:C000-FFFF: PRG 7
    - $84/A4:8000-BFFF: PRG 4
    - $84/A4:C000-FFFF: PRG 7
    - $85/A5:8000-BFFF: PRG 5
    - $85/A5:C000-FFFF: PRG 7
    - $86/A6:8000-BFFF: PRG 6
    - $86/A6:C000-FFFF: PRG 7
    - $87/A7:C000-FFFF: PRG 7
    - $88/A8:8000-FFFF: PRG SNES - SNES Specific Port Code
    - $89/A9-$9F/BF   : Randomizer additions

### RAM
    - $8x/Ax:0000-07FF: NES RAM
    - $8x/Ax:6000-7FFF: NES MMC WRAM
    - $8x:3000-37FF: SA-1 IRAM (If SA-1 is used)
    - $8x/Ax:0800-0FFF: Unused LoRAM (Used for SNES-port specific memory)
    - $8x/Ax:1000-1FFF: Unused LoRAM (Common code - available in all banks)
    - $40:8000-FFFF: SA-1 BW-RAM (If SA-1 is used)
    - $7E:2000-FFFF: SNES WRAM (Used for temporary OAM/Tile buffers)
    - $7F:0000-FFFF: Unused SNES WRAM



