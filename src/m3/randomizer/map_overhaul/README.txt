
---------------------------------------------------------------------------------------------------
|x|                                        MAP OVERHAUL                                         |x|
|x|                                       Made by MFreak                                        |x|
---------------------------------------------------------------------------------------------------

Map Overhaul is a patch which adds and changes a lot of stuff in the map system of Super Metroid.

Following features are:
	- Changed minimap routine, it doesn't use graphics from the already loaded HUD tiles anymore.
	  Instead it constructs the necessary tiles and transfers it into the HUD graphics if needed.
	  This allows for more maptile variations without being restricted to the HUD graphics.
	- All 8 palettes can be use for maptiles in the pause screen.
	- Maptiles can have different tiles as coverup if loaded tiles in the area hasn't been explored yet.
	- Palettes in the pause screen are not restricted to "explored" and "loaded" types.
	  Every palette can have a designated "cover palette" bound to it. For example: cover palette variant of pal 2 (normal) can be 0 (yellow)
	- Items can change maptiles. Very useful to remove dots which indicates items, if the item is collected.
	- Adds a maptile glow effect. You can control which palette should have a transitional color effect.
	- Adds a switch map function into the pause screen. By pressing SELECT in the pause screen
	  map section you can load the map of a different area you have visited.

New additions for version 1.2:
	- Smooth mapscreen controls. You can control the screen in all 8 directions in the map section of the pause menu.
	- Pause index and cursor get saved when unpausing.
	- More minimap palette options. You can set minimap maptile palettes depending on initial maptile palette of the map.
	- Vertical area maps. You can control which areas should have a 32x64 area field instead of the vanilla 64x32.
	- Map decorations. You can fancy up the pause screen map with non-maptile graphics to create more appealing maps.
	- Doors in the pause screen map can visualized with map icons. When opening these doors they also disappear in the map as well.


---------------------------------------------------------------------------------------------------
|x|                                    APPLYING THE MAIN PATCH                                  |x|
---------------------------------------------------------------------------------------------------

There are 2 versions of this patch, depending which assembler you are using (either "xkas" or "asar").
When patching, "MapTiles.bin" and the newly included "MapOverhaulResources" folder should be present in the same folder with the main patch as well.


If you are using the SMART editor, you must use the ASAR version of the main patch. Remember to adjust the assembler in the config file to use asar.exe .
If no ASM folder is in your project, create one or press "Tools -> Apply ASM files to ROM" to let SMART make one for you.
Put the ASM file with the resource folder in the "ASM" folder of you project. The BIN file can be ignored for the moment.
Then press "Tools -> Scan ASM files for used space" to see if there are any conflicts with your other patches.
If an error message appears with the text: "[ERROR] Assembly failed with code 1", try this:
	Config -> Global -> Paths -> Extra Arguments (add this: --no-title-check --fix-checksum=off )

If no collision is found, close SMART and patch the ROM with the ASAR version, containing both the BIN file and the resource folder.
Also apply the Basic Graphic Patch IPS as well. If the patch was successful you can restart SMART and then "Load Rooms -> Load from ROM".
This makes so the maptile table for the minimap in the Map Graphics Editor gets included, as well as some graphics and palette changes
for the pause screen and the hexmap, so some parts of the graphics don't get screwed up.


The "BasicGraphicPatch.ips" file only applies small graphical changes to the pause screen graphics (mainly switch map and maptile palette related),
as well as changing the graphics of the hex map to adjust the palette changes, which makes it possible to display all 8 maptile palettes in the file select map.
This should be applied first before opening SMART as this makes the graphical changes before SMART saves them in the project folder.


The BIN file in the patch included only need to be used once to applying the vanilla maptiles for the new minimap GFX methode.


The "NoHexMap.asm" file will make it so you will jump directly into gameplay when selecting "start game" in file select
and delete anything related to the hex map.


---------------------------------------------------------------------------------------------------
|x|                                    EXAMPLE                                                  |x|
---------------------------------------------------------------------------------------------------

This folder contains an IPS file called "MapOverhaul_v1.2_Example.ips". Just apply it on an unmodified, unheadered Super Metroid(JU).smc.
It's more of a small hack which only has map and slight palette changes. Its purpose is to showcase what is possible with this patch.

It is best to view the maps through SMILE RF.
These addresses to see graphical changes:
	- D4200: minimap graphics (size: $1000)
	- 1B0000: pause screen graphics (size: $8000)

To see setting in the config list there is a folder in "MapOverhaulResources" called "Example". This contains some changes
used in the example patch for better understanding how everything works.


---------------------------------------------------------------------------------------------------
|x|                                    THINGS TO NOTE                                           |x|
---------------------------------------------------------------------------------------------------

Tourian room 7DAAE (elevator entrance room) uses setup ASM C90A to activate map station for tourian.
However, this doesn't work properly with Map Overhaul. Instead I've created a seperate ASM for this issue.
In the ASM file check out "!SetCollectedAreaCodePosition = $E99B", set it to any small freespace around bank $8F
This will be the pointer to this custom ASM. Patch it and then go to the tourian room and replace C90A with
where you put the custom ASM in your ROM. If you used setup ASM ($8F)C90A anywhere else in your ROM, replace them too.
$8FC90A can be safely removed then, as it is pretty much unused now.



The bitmask for item tilechecks has been changed slightly in this version (mainly the tile change part has been altered).
So when using a previous version of Map Overhaul you have to update the item tilecheck list with the changes for the new version.
As of v1.2.3 the file as been overhauled to use macros instead. This will be explained in the instruction section "Changing Maptiles Through Items" below.



If using the feature to change maptiles with items you have to know where your item is in relation to the map.
By using SMILE RF in the map editor you can see the position of the tile by hovering the mouse over it.
Checking the third map option you can see a bunch of information regarding tile data.
Only X and Y values are relevant. However, if you are using SMART you have to use a different methode of finding your tile position.
Using room data gives you a rough idea where the tile is you want to change. These information can be found under:
Room States: Room (xxxx) / section "Room Data" / Map: X and Y.

One thing to note is you have to add +1 to Y when finding tile position by using room data.
Adjusting X and Y room position of the item in relation to the room gives you the position of the tile you want to change. 


---------------------------------------------------------------------------------------------------
|x|                                    INSTRUCTIONS                                             |x|
---------------------------------------------------------------------------------------------------

--------------------------------------- Editing Map ------------------------------------------------

In terms of editing the map itself there only is one thing to note. Instead of only using palette 3 on your map as
loaded, unexplored tiles you can use any palette as explored tile. How it works with palettes in terms of loaded, unexplored state
will be explained in the "Palette Of Unexplored Tiles" section.


--------------------------------------- Editing Maptiles -------------------------------------------

By default the HUD maptiles are located at $9AC200 (PC: D4200). Same rules apply as changing maptile graphics as usual:
The HUD graphics should be in the same position as in the graphics of the pause screen in $B68000 (PC: 1B0000).
Normally the minimap will change tiles with the graphics loaded from D3200.
However, this patch will use the graphics table of D4200 to construct the minimap.
Which means nearly all maptile graphics in the HUD graphics department can be changed without any drawbacks, now.
Two thing to note however:
1. The tiles 5B - 5F, 6B - 6F and 7B - 7F are used to display the minimap. Editing them has no effect, as they get overwritten constantly.
2. Tile 1F (empty maptile) in HUD graphics should not be replaced, because this gets used for blocking minimap during bossfights.
   You can change what should be the empty tile by changing the value "!EmptyTile" in the main configs under "General".


--------------------------------------- Unexplored Maptile Coverup ---------------------------------

Map Overhaul gives you the possibility to cover up the original tile with a different tile,
if the mapstation of that area has been activated and that tile is loaded, but hasn't been explored yet.
By default the list with what tile it should be covered is at $B6F200 (PC: 1B7200).
It is located in MapOverhaulResources/CoverTileList.asm.

Every entry is 1 byte large and are sorted by maptile GFX index. The number on the entry represent which tile will be used as coverup
if the entry tile has been loaded but not been explored yet.
Example: You have tile 6F (single room with item), but you don't want it to be visible until the player enters that area.
You can cover it up with tile 20 (single room without item). In the list change $6F -> $20.
Now, every 6F tile which is loaded by mapstation, but not explored, will be covered by tile 20.


--------------------------------------- Changing Map Palettes --------------------------------------

You can use palette 4 - 7 for the mapscreen, too. The palettes for it are located at $B6F000 (PC: 1B7000).
The reason why it doesn't get used for hacks (at least my assumption) is the palette for the map after the hex map
in the file select are different then the palettes in the pause screen.
Now the maptile palettes for file select map are gathered from the pause screen palette, meaning when changing
any maptile palette from pause screen you also indirectly change the palette for the file select map.

One thing to mention: Some maptile palettes only get seen during the fade in when entering the pause screen.
They get overwritten by the maptile glow palettes immediately after. See "Editing Maptile Glow Effect" entry for more information.


--------------------------------------- Palette Of Unexplored Tiles --------------------------------

If a tile of a specific palette has not been explored, the palette will be replaced with the palette values
designated to that specific palette. You can change the values at "Unexplored Tile Palette" for easy editing.
Example: Your main palette is 2 and you want to have palette 5 as your unexplored palette.
Set "!UnexploredTilePalette2" for palette 2 in "Unexplored Tile Palette" to 5. Now every maptile saved as palette 2
in the map screen will be covered by palette 5.


--------------------------------------- Changing Maptiles Through Items ----------------------------

It is very helpful to indicate which items have been collected yet. With this addition it is possible to visualize it.
By default the list is located at $B6FC00 (PC: 1B7C00).
It is located in MapOverhaulResources/ItembitTilechangeList.asm.
Every entry is 2 bytes large and are sorted by item index. If set to $0000 it will not change any tiles.
You can set multiple item bits to the same map position and its effect is stackable.
ONLY ONE MAPTILE can be changed per item bit.

Before doing any editing, you have to comment out the command in line 10/11, depending on which assembler you are using,
as this will affect the calculation done by the assembler which would results in unwanted byteformations.
When using xkas, write the semicolon (like in line 11) to line 10 and remove the semicolon in line 11 to put set it to xkas math.
When using asar, you don't have to do any changes as it is set to asar by default.


Item tilecheck macro: ItemTile(change, area, page, y, x)

 x = X coordinate of map
 y = Y coordinate of map
 page = which side of the map to change the tile (either left or right part)
        (for vertical maps it's either top or bottom part of the map)
 area = in which area to change the tile
 change = to change current tile to another one, depending on current tile ID

All ranges for these values are either listet in brackets or listed in defines "!Abc". Going over the designated range would affect other values of the item tile check.
For the values "area" and "change" you can use the defines as your value for clearer information on what item changes which tile.

These "%ItemTile(0, 0, 0, $00, $00)" are your macro calls. Change the zeros to the values designated above.
To change the desired tile for a specific item, check out the ID set for your item.
Then go down the itembit tilechange list for the position of that ID. Each line are 4 IDs with the specifiaction commented on the right.
Once found, change the values to the tile data you want.

One valid example is "%ItemTile(!LeftS, !Brn, 0, $0C, $11)".
This will change the tile where Charge Beam is located.
	!LeftS = tile change type (change current GFX maptile with the left GFX maptile)
	!Brn   = Brinstar
	 0     = left map page
	 $0C   = tile Y coordinate
	 $11   = tile X coordinate


--------------------------------------- Visualizing Colored Doors In The Map -----------------------

Map Overhaul allows you to visualize colored doors (non-blue doors) in the pause screen map through map icons now.
By binding them to their door ID you can also make them disappear when the colored door gets opened.
By default the list is located at $B6F800 (PC: 1B7800).
The table for defining these door icons is located in MapOverhaulResources/DoorbitSpritelockList.asm.
The lists are sorted by area, each door icon entry is 3 bytes large. You can put as many entries in one area as you want,
as long as you have enough freespace in your designated bank.

Before doing any editing, you have to comment out the command in line 10/11, depending on which assembler you are using,
as this will affect the calculation done by the assembler which would results in unwanted byteformations.
When using xkas, write the semicolon (in line 11) to line 10 and remove the semicolon in line 11 to put set it to xkas math.
When using asar, you don't have to do any changes as it is set to asar by default.

The graphics for the door icons are located at $B6D200 (PC: 1B5200) in 4x1 tiles.
The door icon itself will be placed between 2 tiles. By default the door icons are sorted as red, green, yellow and gray doors.
The palettes for map icons are located at $B6F100 (PC: $1B7100) for pause screen map
and $8EE500 (PC: $76500) for file select map. By default the door icons use palette 5.


Door spritelock macro: DoorSprite(variant, direction, page, y, x, index)

 index = the door index defined to the door sprite
 x = X coordinate of map
 y = Y coordinate of map
 page = which side of the map to change the tile (either left or right part)
        (for vertical maps it's either top or bottom part of the map)
 direction = changes in which side of the tile the door sprite gets set
 variant = type of door to display

All ranges for these values are either listet in brackets or listed in defines "!Abc". Going over the designated range would affect other values of the door sprite check.
For the values "direction" and "variant" you can use the defines as your value for clearer information on how the door icon gets displayed.

These "%DoorSprite(0, 0, 0, $00, $00, $000)" are your entries. Change the zeros to the values designated above in the file.
If you want to add another entry to your desired area, you can just copy the entry again on the next line. There is no limit on how many entries you are adding,
but they should be written inside the confined list. Writing entries outside the area list will be ignored.
To bind your desired door with the door icon on the map, check out the ID set for your door (00xx/01xx).

One valid example is "%DoorSprite(!Red, !Right, 0, $07, $18, $01D)".
These are the coordinates for the red door before bomb torizo in crateria.
	!Red = red single door icon
	!Right = right side of the tile
	 0     = left map page
	 $07   = tile Y coordinate
	 $18   = tile X coordinate
	 $01D  = the doorbit tied to it


--------------------------------------- Revealing Adjacent Maptiles --------------------------------

In vanilla there is a special case where diagonal rooms will update the maptile above when samus
explores a room chunk with the unique maptile (tile $28), so rooms with diagonal hallways will not
appear with random cut offs on the map because the corners are hard to reach.
Map Overhaul gives you the possibilty to do this with every maptile in 4 directions.

The location of config list for revealing adjacent maptiles:
It is located in MapOverhaulResources/AdjacentMaptileTable.asm.

In the config list there are 2 tables. The values of these tables are sorted by the maptile ID in bits.
You literally read them from left to right. Do not read them like traditional bit orientation!
The first table is a check rather or not to explore an adjacent tile. Set it to 1 to enable adjacent update for specific maptiles.
The second one determines from which side it should reveal it. 2 Bits are the direction value of one maptile ID.
So one bytes are direction values of 4 maptile IDs sorted like this:
	%aabbccdd ;aa = direction of tile $00, bb = direction of tile $01, and so on...
To set your desired side:
	$00 = update above, $01 = update below, $10 = update leftside, $11 = update rightside


--------------------------------------- Editing Maptile Glow Effect --------------------------------

Map Overhaul adds a pseudo glow effect for every palette.
In the main config under "MAPTILE GLOW" you have 2 values: 

MaptileGlow_TimerAmount: how many different color steps can it have before looping
MaptileGlow_PaletteAmount: how many palettes should the maptile glow effect have


The location of config list for maptile glow:
It is located in MapOverhaulResources/MaptileGlow.asm.
The list is structured like this:

<Word>_MapGlow:
	These are the colors for the maptile glow effect.

MaptileGlow_GlobalTimer:
	Times in frames for each color to be represented.
	Range for each timer can be 00 (one frame) up to FF (over 4 seconds).
	Amount of different values is determand by "MaptileGlow_TimerAmount".

MaptileGlow_PalettePointer:
	Pointer to the maptile glow palettes (<Word>_MapGlow).
	Amount of different glowpalettes is determand by "MaptileGlow_PaletteAmount".

MaptileGlow_PaletteOffset:
	Values of palette indexes. Each value is a multiple of 2 for each palette index.
	Interconnected with "MaptileGlow_PalettePointer"
	For example: the first value $0042 (index $21: palette 2 / color 1) is connected with "Loaded_MapGlow".
	the second value $0062 (index $31: palette 3 / color 1) is connected with "Explored_MapGlow" and so on.


If you want to add another glow effect to one color:
	- increase "MaptileGlow_PaletteAmount" by one in the main configs
	- in the config list/maptile glow:
		- in "MaptileGlow_PalettePointer" add another pointer. Name it whatever you want it, as long as it only contains letters, numbers and underline symbols.
		  (if a new row: a "DW" should be written before the label. Any additional pointers can be seperated with an comma)
		- in "MaptileGlow_PaletteOffset" add another value. This is the color from which you want the glow effect.
		  (if a new row: a "DW" should be written before the value. Any additional values can be seperated with an comma)
		- Copy your pointer label under the color_MapGlow list and add a colon.
		  Now write "DW" next to it and add as many values as listed in "MaptileGlow_TimerAmount" (or the amount of the other palettes).
		  These values represent the colors for your glow effect.


If you want to add more colors to an glow effect:
	- increase "MaptileGlow_TimerAmount" by one in the main configs
	- in the config list/maptile glow:
		- in "MaptileGlow_GlobalTimer" add another value.
		  (you can extend it by adding "DB" on the next row and continue from there)
		- every glow palette in this list must have another color value added, or else it would use some parts of the other glow palettes as well.


--------------------------------------- Setting Vertical Maps --------------------------------------

Map Overhaul allows you to set areas from their vanilla 64x32 range to 32x64.
This is achived by placing the right map page below the left map page.
The byte (which determines what ares should be vertical) is located at $829442 (PC: 11442).
This also can be edited in the configs under "Vertical Area Map", by setting specific bits for their respective area.
Editing it with verticality in mind is quite tricky. Here are some tipps on how to edit
the map and room to make vertical areas work:
	- For now, set your preferred vertical area to horizontal for easy editing. Create a map with verticality in mind.
	  If you want to see your progress in action, temporarily set it vertical, open quickmet and load the mapstation for that area.
	- If a room is near the bottom edge of the left map page, set the room coordinates temporarily to
	  Y = 00, X = origin coord + 20. Open the map editor and mark the location where your room would warp into.
	  Save the map and set the room back to their original location.
	- All rooms which are supposed to be on the lower half of the vertical area, should have map coordinates to the right map page
	  for the time being, so you can enter them through the map editor.
	- In quickmet even if the area is set to vertical, on the minimap it will display the area correctly when going to the bottom half of the area.
	- If everything is done, set the location of every room in the right map page to
	  X = origin coord - 20, Y = origin coord + 20, as you wouldn't be able to open them through the map editor anymore.
	  For map icons and area names it's the same routine.


--------------------------------------- Creating Map Decoration ------------------------------------

Map decoration are fancy tiles which get drawn first before the area map gets constructed.
For map decorations there are 2 types of tiles mentioned here. First are the usual map tiles (Tile $000 - $0FF).
They always get drawn in map decorations, regardless of settings. This makes it perfect for setting up preloaded map sections like in Zero Mission.
Second are "deco tiles" (Tile $100 - $3FF). They only are visible in the pause screen map and not visible in the file select map section or in the minimap.
You can control if they should be included in the map screen boundary calculation and if they should only be visible when activating mapstation.

The location of config list for map decoration:
It is located in MapOverhaulResources/MapDecoration.asm.

Map Decoration has 3 layers which work as followed:
Area Pointer:
	A list of all areas to point to a list of decoration groups for their respective area.
	This is labeled on top in the file as "MapDecoration_AreaPointer".
	You can change the label to a unique one, for instance "MapDecoration_List_Crateria" to point to a new decoration list
	or "MapDecoration_NoDecoration" to not draw any deco tiles for that area.
Deco Group List:
	A list of various deco group instructions to point to and position to in the map.
	An instruction for it looks like this:
		DW $aaaa : DB $xx, $yy
	aaaa : pointer to deco group instruction. Labels also can be used for this.
	       $0000 is the terminator for deco group lists.
	xx : X position for deco tilegroup (range: $00 - $1F ($3F, if vertical map is not set for this area))
	yy : Y position for deco tilegroup (range: $00 - $1F ($3F, if vertical map is set for this area))
Deco Group Instruction:
	The actual instruction to draw these decorations.
	An instruction for it looks like this:
		DB bb : DW tttt, ...
	bb : amount of tiles to draw in one row. If 00, it will jump to the next row.
	     Setting it to $40 and above is the terminator for deco group instructions.
	tttt : tiledata. You should write as many tiledata as listed in "bb"
	       the bitmask for tiledata looks like this:
				vhpc cctt tttt tttt
		   v = vertical mirror of tile
		   h = horizontal mirror of tile
		   p = priority bit (must be 0)
		   c = palette
		   t = tile ID (must be $100 and above to be considered as a deco tile)


One example is included as comments in the config list. To see it in action:
	Replace the first pointer label in Area Pointer with "MapDecoration_List_Crateria"
	and the semicolons (;) below the example text in the config list file.


Some notes on map decoration:
	- If you don't want any map decoration for a specific area, you can set an area pointer to a deco group list
	  with just $0000 to not draw any decoration tiles. This is set by default.
	- If you position a deco tilegroup...
		- near the bottom end of the left map page, some parts will wrap around the top of the right map page (when map set to horizontal)
		- near the right end of the left map page, some parts will wrap around the left end of the right map page (when map set to vertical)
		- near the right or bottom end of the right map page, it will stop to draw beyond the map end
	- Deco groups can draw over each other. So if you want a deco tilegroup to be partially overwritten,
	  you should set it first on the list.
	- If a tile is set to $0000 in a deco group instruction, the tile will not be drawn. This makes it useful
	  for overlapping other deco groups on top of each other.


---------------------------------------------------------------------------------------------------
|x|                                    CHANGELOG                                                |x|
---------------------------------------------------------------------------------------------------

- Apr 2024 - v1.2.7 -
	- new feature: "Hex Map Select Switch" (optional), when pressing select it will transition to the hex map view instead to choose which area to display (ASAR exclusive) (suggestion by "Tundain")
	- doorbit spritelock data structure changed. Door sprites will be check by an amount of entries listed per area. (suggestion by "Tundain")
	- some bugfixes (listed below)

- Nov 2023 - v1.2.6 -
	- map in pause screen doesn't screenwrap (seeing other side of map when scrolling over confined area) (suggestion by "Tundain")

- Nov 2023 - v1.2.5 -
	- one bugfix (listed below)

- Sep 2023 - v1.2.4 -
	- new feature: "Doorbit SpriteIcons", colored doors can be visualized and deleted when opening now (suggestion by "Nodever2")
	- hex graph graphics are included in the "BasicGraphicPatch"
	- one bugfix (listed below)

- Sep 2023 - v1.2.3 -
	- changed "Itembit Tilechange List" to use macros for better visualisation (suggestion by "Tundain")
	- changed "adjacent maptile table" config to make it less confusing
	- changed BASE and SMART patch version to XKAS and ASAR version
	- updated example patch
	- one bugfix (listed below)

- Apr 2023 - v1.2.2 -
	- add feature: Adjacent Maptile Revealed

- Apr 2023 - v1.2.1 -
	- bugfixes (listed below)

- Feb 2023 - v1.2 -
	- more code optimizations
	- 5 new features:
		- Smooth Map Screen Controls
		- Preserve Screen Index
		- More Minimap Palette Options
		- Vertical Area Maps
		- Map Decorations
	- more config options
	- different pause screen boundary routine (which also supports vertical area maps)
	- minimap routine overhaul (no need for freespace in bank $90)
	- updated example "hack" with (most) new additions

- Apr 2022 - v1.1.1 -
	- fixed crash after unpausing at ridley's room

- Apr 2022 - v1.1 -
	- some code optimization
	- freespace used code of bank 82 can be put anywhere in rom, now
	- added config in patch to control how many areas can be selected
	- reworked "Change" folder: now just an ASM file with information and various options to repoint pausescreen graphic tiles
	- added a "SMART" version of the patch where this patch is compatible with the SMART editor
	- some bugfixes listed below

- Dec 2021 - v1.0 -
	- release


--------------------------------------- BUGFIXES ---------------------------------------------------

- v1.2.7 -
	+ fixed a bug where the pause screen index doesn't update back to map when activating a map station (found by "Tundain")
	+ area maps correctly displayed as vertical areas in file select map screen now (found by "Tundain")
- v1.2.5 -
	+ fixed some bugs with the ASAR patch version, where the minimap is blank constantly and map screen scroll boundaries are set wrong (found by "Tundain")
- v1.2.4 -
	+ fixed crash when entering main boss rooms (or rooms where minimap gets disabled)
- v1.2.3 -
	+ minimap updates properly when leaving ceres ridley's room
- v1.2.1 -
	+ fixed a bug where the HUD graphics in kraid's room will not fully reload when unpausing after kraid's death (found by "ouichegeante")
	+ fixed a bug in optional "NoHexMap" to reload explored bits after death (found by "ouichegeante")
	+ fixed a bug where the pause label index wasn't changed properly when loading map from the mapstation (found by "Tundain")
	+ fixed a bug where the mapscreen would crash when pressing up/down together (found by "Tundain")
	+ added LOROM to "NoHexMap" so it can properly patch it
- v1.2 -
	+ fixed crash when switching back to current area in pause screen from SMART patch
	+ more tiles in crocomire room get set as explored when entering it for the first time, so collecting an item during a bossfight does update it properly.
- v1.1.1 -
	+ fixed crash after unpausing at ridley's room
- v1.1 -
	+ boss rooms are visible in the minimap after beating them
	+ minimap in kraid room fixed
	+ special room asm for tourian mapstation bit set
