# Design ideas

## Architechture
Some notes for a possible 4-game multi randomizer that can also be used as a framework for a bunch of different multi-randos

### General
- SA-1 will be used to handle ROM banking so little game remapping will be needed (SM needs patching for access to banks C0-DF)
- Use and move the SA-1 BW-RAM window at $6000-$7FFF for NES/SNES SRAM access (SM/ALTTP will need patching to redirect SRAM access (can use the SMZ3 patches))

### Mother Brain
Mother Brain is the "OS" running on the SA-1, it'll keep running in the background while all other games are running and will handle all common functionality.
Things such as timers, assisting game switching, providing IRQ services to do backgrounds tasks, multiworld functionality and so on.

Mother Brain will stay always loaded into ROM at bank DF.

Along with the SA-1 specific code, there needs to be an entry point for the main SNES CPU to jump to that puts it into SA-1 "slave" mode ready to accept commands from the SA-1 to do things like H/W access and WRAM access. (Maybe this can be handled with IRQ:s?)

The SNES IRQ/NMI vectors will be repointed differently depending on game to use game specific interrupt handlers.

When a game is running normally, Mother Brain will provide IRQ-based services that the running game can start as asynchronous "tasks" in the background.

Generally, Mother Brain will use only I-RAM for its internal state so that it can run the same no matter what the execution environment is on the SNES itself.


### ROM Layout
The SA-1 has registers to swap out 4 memory regions with one out of 8 1MB ROM slices, and it can be mapped as LoROM or HiROM.

Banks:
    Bank C - Hirom C0h-CFh / LoRom 00h-1Fh (W)
    Bank D - Hirom D0h-DFh / LoRom 20h-3Fh (W)
    Bank E - Hirom E0h-EFh / LoRom 80h-9Fh (W)
    Bank F - Hirom F0h-FFh / LoRom A0h-BFh (W)

Slots:
    0, 1, 2, 3: Super Metroid (Extended to 4MB)
    4, 5:       A Link to the Past (Extended to 2MB)
    6:          Zelda 1 (Extended to 1MB)
    7:          Metroid 1 (Extended to 1MB)

Mapping:
    Boot:
        Bank C -> Slot 0 (LoROM) (Regular SM LoROM Banks 80-9F)
        Bank D -> Slot 0 (LoROM) (Regular SM LoROM Banks 80-9F)
        Bank E -> Slot 0 (LoROM) (Regular SM LoROM Banks 80-9F)
        Bank F -> Slot 7 (HiROM) (Metroid 1 / Mother Brain Data)
    Super Metroid
        Bank C -> Slot 2 (HiROM) (Regular SM LoROM Banks C0-DF ends up as HiROM C0-CF here)
        Bank D -> Slot 3 (HiROM) (1MB of HiROM at D0-DF for extended SM code/data)
        Bank E -> Slot 0 (LoROM) (Regular SM LoROM Banks 80-9F)
        Bank F -> Slot 1 (LoROM) (Regular SM LoROM Banks A0-BF)
    
    A Link to the Past
        Bank C -> Slot 4 (LoROM) (Regular ALTTP LoROM Banks 00-1F)
        Bank D -> Slot 5 (LoROM) (1MB of LoROM at 20-3F for extended randomizer code/data)
        Bank E -> Slot 4 (LoROM) (Regular ALTTP LoROM Banks 00-1F) (mirror)
        Bank F -> Slot 5 (LoROM) (1MB of LoROM at A0-BF for extended randomizer code/data) (mirror)
    
    Zelda 1
        Bank E -> Slot 6 (LoROM) (Zelda 1 code/data + extra randomizer code/data at LoROM banks 80-9F)
    
    Metroid 1
        Bank E -> Slot 7 (LoROM) (Metroid 1 code/data + extra randomizer code/data at LoROM banks 80-9F + Mother Brain data)                                                
                                 (Note: Currently banks 90-9F (F8-FF hirom) are reserved for common code / data, leaving banks 88-8F free for M1 rando code)

At boot, copy the SA-1 code from Slot 7 to BW-RAM $40E000 and resume SA-1 execution from there.
This is needed since we can't keep a static block of ROM mapped in all cases due to ALTTP requiring some special mirroring to
be compatible with the base rom ASM.

### BW-RAM Layout
The SA-1:s BW-RAM will be used mainly for the different games SRAM, with different partsof it being mapped to 6000-7FFF depending on the game loaded.
Currently the plan is to use 64kb mapped into bank $40, leaving 192kb unused for future use. (Possibly to use as scratch space for faster game switches)

Mapping:
    Super Metroid
        $400000-$401FFF -> $6000-$7FFF  (Regular SM SRAM - Needs repointing)
    A Link to the Past
        $402000-$405FFF -> $6000-$7FFF  (Regular ALTTP SRAM - Needs repointing)
    Zelda 1
        $406000-$407FFF -> $6000-$7FFF  (Regular Z1 SRAM/Work RAM)
    Metroid 1
        $408000-$409FFF -> $6000-$7FFF  (Regular M1 Work RAM)
    
    Mother Brain
        $40A000-$40C7FF -> Randomizer   (12kb of extra SRAM for Mother Brain use: stats, timers, temporary item buffers etc)
        $40C800-$40CFFF -> Z1 NES RAM   (2kb backup of Z1 NES RAM State)
        $40D000-$40D7FF -> M1 NES RAM   (2kb backup of M1 NES RAM State)
        $40D800-$40DFFF -> SA-1 WRAM    (Used by menu code and more)
        $40E000-$40FFFF -> Code         (8kb of code, the SA-1 runs from here, copied from ROM at boot)
