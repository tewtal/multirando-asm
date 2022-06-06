# Metroid 1 Porting Notes

## ROM Layout and info
Metroid uses MMC1 with 8 banks, bank 7 is always mapped to $C000-$FFFF while banks 0-6 can be switched at $8000-$BFFF
The disassembly doesn't seem to be complete, so editing code in the disassembly doesn't seem feasible which means we'll do
regular hooks with asar to modify functionality as needed.

We'll use python/js to explode the NES ROM into a LoROM configuration so we can use SNES banks to simulate bank switching.

SA-1 BW-RAM at $6000-$7FFF will be stand-in as regular MMC1 extra WRAM.

Mother Brain needs to have routines that does fast NES -> SNES graphics/OAM conversion on the fly to a buffer that can later be DMA:D

## Proposed SNES Layout

### ROM
    - $80:8000-BFFF: PRG 0
    - $80:C000-FFFF: PRG 7
    - $81:8000-BFFF: PRG 1
    - $81:C000-FFFF: PRG 7
    - $82:8000-BFFF: PRG 2
    - $82:C000-FFFF: PRG 7
    - $83:8000-BFFF: PRG 3
    - $83:C000-FFFF: PRG 7
    - $84:8000-BFFF: PRG 4
    - $84:C000-FFFF: PRG 7
    - $85:8000-BFFF: PRG 5
    - $85:C000-FFFF: PRG 7
    - $86:8000-BFFF: PRG 6
    - $86:C000-FFFF: PRG 7
    - $87:8000-FFFF: PRG SNES - SNES Specific Port Code
    - $88 - $9F:     Randomizer additions

### RAM
    - $8x:0000-07FF: NES RAM
    - $8x:6000-7FFF: NES MMC WRAM
    - $8x:3000-37FF: SA-1 IRAM
    - $8x:0800-0FFF: Unused LoRAM (Maybe use this for always-loaded variables that's SNES port specific)
    - $8x:1000-1FFF: Unused LoRAM (Since PRG 7 is crammed to the max, place SNES port specific code here that has to be available in all banks)
    - $40:8000-FFFF: Mother Brain BW-RAM
    - $7E:2000-FFFF: Unused SNES WRAM
    - $7F:0000-FFFF: Unused SNES WRAM



