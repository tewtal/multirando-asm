# Global randomized transition system

To make it easier to handle all the transition data from the randomizer end, it'd be ideal to have one global table of "from -> to" transitions for each possible transition point, and these have to be unidirectional since the mappings can be uncoupled.

Having some more complexity at runtime isn't too bad since transitions between games shouldn't be too common and it's already pretty slow, so adding a few hundred cycles isn't going to do much of a difference. (And some of this can possibly be run on the SA-1 for improved speed too, and should probably be run on the SA-1 to be able to easily swap NMI/IRQ and banks without crashing)

What data would be required in a table to easily support this then

- From Game (maybe have these tables split by game for easier access)

- From Id
- To Game
- To Id (This could be a per-game unique id (z3 entrance, m3 door ptr and so on), or it could be some randomizer id to be translated later)
- Type (Some enum of types of transition valid for all games)
- Direction
- Metadata PTR (Pointer to additional metadata for the target entrance required for loading properly) 



# SA-1 transition code example
- Put a from ID in IRAM somewhere (along with possible extra parameters)
- Trigger SA-1 IRQ Command to process transition
- Jump the SNES CPU to a BW-RAM block containing a function for transition support
  This function will start by doing things like disabling IRQ/NMI:s and so on on the main cpu and then waiting for further instructions

- While the transition is happening, the SA-1 will modify some variable to have the SNES CPU execute things like
  DMA:ing blocks to VRAM/WRAM, updating PPU variables and whatever is needed to process the transition

- When that's done, the SNES CPU is guided to a routine that will continue execution in the new game


