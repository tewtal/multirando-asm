# Global randomized transition system

To make it easier to handle all the transition data from the randomizer end, it'd be ideal to have one global table of "from -> to" transitions for each possible transition point, and these have to be unidirectional since the mappings can be uncoupled.

Having some more complexity at runtime isn't too bad since transitions between games shouldn't be too common and it's already pretty slow, so adding a few hundred cycles isn't going to do much of a difference. (And some of this can possibly be run on the SA-1 for improved speed too, and should probably be run on the SA-1 to be able to easily swap NMI/IRQ and banks without crashing)


Each game has a transition table populated by the randomizer that's checked on entering a door/cave/etc matching the games specific type of entrance data
For example SM would have a table where the check is listed by door ID, and Z3 would have it listed by inlet-id.

Each game specific table would have simply
- Entry ID
- Game ID
- Destination ID

Where destination ID's are a unique pointer to a table containing destination data needed for a transition to that destination for the game we're transitioning to.

Then each game will have their own destination table that specifies the data required to enter the game through that destination.
And the destination table would be pre-generated static data for each possible destination that can be entered.


So it'd be something like:
- destination Id
- ... Data required to entrance 

This means that to add a transition only the inlet data is require to be written in a simple table, and we could for example use a "magic" inlet to trigger scanning the table itself so
that it's only done for actual transitions.


# Transitioning

To make this simple, let's just have each game save its own save data, write back item buffers, jump the SPC to the IPL and then finally trigger an SA-1 IRQ message
to tell the SA-1 to take over control for a bit and handle switching between games (remap IRQ/NMI, remap BW-RAM, switch ROM banks and more).
And then when that's finally done, have the SA-1 go back into waiting mode and issue a jump to the "incoming transition" code for that specific game and then let the game
specific transition code take it from there.

This means that basically we only need to save "Game Id" and "destination Id" somewhere in I-RAM/BW-RAM to carry over between transitions. I-RAM is probably best suited for this.


