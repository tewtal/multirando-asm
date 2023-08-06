# Logic data format

## Should allow for completely custom map switcheroo (and enemizer)

## Screen
Editroid calls each unique part of a room a "screen". Each room is built out of a set of screens.
In reality it's just screens placed on a big master grid (X:00-1f, Y:00-1e).
This should in theory make door/entrance rando very easy since we can just edit the level data as we want, but let's stick with vanilla layout to start with.

### Screen Logic
Since each screen is unique (but can be used multiple times in the big grid) we want to define edges on a screen-to-screen basis so that it applies automatically to reused screens

So for example:

```yaml
name: "Vertical Shaft with Left Door"
area: Brinstar
screen: 0x04
scroll: Vertical
nodes:
    - doors:
        - name: "Left door"
          type: Blue
          direction: Left

    - exits:
        - name: "Top"
          type: Scroll
          direction: Up
          
        - name: "Bottom"
          type: Scroll
          direction: Down

    - enemies:
        - name: "Top Geemer"
          type: Geemer
          slot: 0x02
          position: [0x01, 0x02]

edges:
    - undirected:
        - fixed:
            - ["Top", "Bottom"]
            - ["Left door", "Top"]
            - ["Left door", "Bottom"]
```

```yaml
name: "Morph Ball Screen"
area: Brinstar
screen: 0x17
scroll: Horizontal
nodes:
    - exits:
        - name: "Left"
          type: Scroll
          direction: Left

        - name: "Right"
          type: Scroll
          direction: Right

    - locations:
        - name: "Morph Ball Pedestal"
          type: Item
          position: [0x05, 0x08]

edges:
    - directed:
        - fixed:
            - ["Right", "Morph Ball Pedestal"]
            - ["Right", "Left"]
            - ["Morph Ball Pedestal", "Left"]
          MorphBall:
            - ["Morph Ball Pedestal", "Right"]
            - ["Left", "Right"]

```


### Room
A room defintion is a contained set of screens combined, bordered by doors and walls.
Any item is defined in the room since it's actually something in a separate dataset and doesn't belong to the
actual screen. All that is listed under "sprites" that includes elevators and such things
Screen definitions are always, left-to-right, top-to-bottom

```yaml
name: "Morph Ball Room"
area: Brinstar
scroll: Horizontal
position: [0x01, 0x0e]
screens: [0x08, 0x17, 0x09, 0x14, 0x13]
sprites:
    - name: "Morph Ball"
      screen: [0x01]                   # Relative screen number this sprite is placed on 
      location: "Morph Ball Pedestal"  # This refers to the itemlocation name on the screen
      slot: 0x01                       # Sprite slot to use
      type: PowerUp
      item: MorphBall
      
exits:
    - name: "Right exit"
      position: [0x01, 0x12]           # X/Y coordinates of the screen this exit is on
      type: Door
      direction: Right
```


## Parsing

So when parsing this we read all the screens and all the rooms and then we build a graph from this data going room by room and attaching edges

So for example reading the Morph Ball room we'll just first pick screen 8, check it's nodes and exits, then screen 17 and start dynamically creating edges such as:

edges:
    - directed:
        - fixed:
            - ["Morph Ball Room - Morph Ball Screen (01) - Right", "Morph Ball Room - Morph Ball Screen (01) - Morph Ball Pedestal"]
            - ["Morph Ball Room - Morph Ball Screen (01) - Right", "Morph Ball Room - Morph Ball Screen (01) - Left"]
            - ["Morph Ball Room - Morph Ball Screen (01) - Morph Ball Pedestal", "Morph Ball Room - Morph Ball Screen (01) - Left"]
          MorphBall:
            - ["Morph Ball Room - Morph Ball Screen (01) - Morph Ball Pedestal", "Morph Ball Room - Morph Ball Screen (01) - Right"]
            - ["Morph Ball Room - Morph Ball Screen (01) - Left", "Morph Ball Room - Morph Ball Screen (01) - Right"]
        ....
    - undirected:
        - fixed:
            - ["Morph Ball Room - Morph Ball Screen (01) - Morph Ball Pedestal", "Morph Ball Room - Morph Ball"]
            - ["Morph Ball Room - Horizontal Right Door (04) - Right Door", "Morph Ball Room - Right Exit"]

After the whole room is wired up it'll have a proper graph and logic chain.
And all the exits can then be hooked up in some kind of entrance connection graph list

Things like

entrances:
    - fixed:
        - ["Morph Ball Room - Right Exit", "Parlor and Alcatraz - Map Station Door - Entrance"]

