## Misc notes

```
Anim_WriteSpecificItemSprites:
    STX $08                     ; Store the object index in [08].
    LDA #$01                    ; Assume the object has two sides.
    STA $07
    LDA #$08                    ; Both sides are usually separated by 8 pixels.
    STA $0A
    LDA Anim_ItemFrameOffsets, Y
    CLC
    ADC $0C                     ; Get the frame.
    TAY
    LDA Anim_ItemFrameTiles, Y
    STA $02                     ; [02] gets the tile we just looked up.
    CLC
    ADC #$02                    ; The second tile must be two tiles farther in CHR.
    STA $03                     ; Put it in [03].

    ; If left tile is $F3 or in [$20, $62),
    ; then this is a narrow / half-width object.
    LDA $02
    CMP #$F3
    BEQ @Narrow
    CMP #$20
    BCC @Wide
    CMP #$62
    BCS @Wide
```

* This code handles writing sprites, it has some specifics for wide/small sprites using tile index which isn't great.
* We might need to change that when using our custom items. I guess here is also where we would prep dynamic loading of tiles
* for items for our "new snes items"

