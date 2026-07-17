# M1 Automap Generator Plan

This document describes the C# randomizer work needed to generate the M1
automap for a randomized M1 world. The assembled base ROM supplies the map
renderer and map graphics. The randomizer supplies a fixed-size map payload
for each generated seed.

## Source Of Truth

Load `src/data/m1_map_tiles.json` with the base ROM. It is the glyph lookup
for the exact automap graphics in that ROM. Do not duplicate tile numbers,
flip flags, or connection rules in C#.

Before writing a seed, read and validate the `M1MP` header at SNES address
`$989000`:

| Offset | Size | Value |
| --- | ---: | --- |
| `+$00` | 4 | ASCII `M1MP` |
| `+$04` | 1 | Format version; currently `3` |
| `+$05` | 1 | Area count; currently `5` |
| `+$06` | 1 | Map width; currently `32` |
| `+$07` | 1 | Map height; currently `32` |
| `+$08` | 2 | Bytes per area; currently `$0800`, little-endian |
| `+$0A` | 1 | Bytes per entry; currently `2` |
| `+$0B` | 1 | Tile encoding; currently `2` for direct SNES BG words |
| `+$0C` | 4 | Seed/map identity, little-endian CRC-32 |

The five bounds records start at `header + areaBoundsOffset` from the JSON
file, currently `$989010`. The map planes begin at `romMap.tilemapsSnesAddress`,
currently `$989100`. Use the randomizer's existing SNES-to-file-offset helper;
do not hard-code a PC offset.

## C# Model

Build the automap from the final placed M1 world, not from the abstract world
graph. The runtime identifies Samus by the M1 room-grid coordinates, so a map
cell must use the same `(area, x, y)` assigned to the playable room.

Represent each generated cell with at least:

```csharp
sealed record M1MapCell(
    int Area,
    int X,
    int Y,
    DirectionMask Connections,
    DirectionMask Doors,
    M1MapFeature Feature,
    ElevatorKind? ElevatorKind,
    DoorSide? ElevatorSide);
```

Use `north=1`, `east=2`, `south=4`, and `west=8`, exactly as specified by
`connectionBits` in the JSON file. Area planes are ordered `Brinstar`,
`Norfair`, `Kraid`, `Tourian`, then `Ridley`, matching the runtime area index.

Each plane is a 32 by 32 row-major grid. The byte offset of a cell within its
plane is:

```text
(y * 32 + x) * 2
```

Start all five 2 KiB planes as zeroes. A zero word is a blank map cell.

## Composition

1. Place each final gameplay room in its runtime area and grid coordinate.
   Reject coordinates outside `0 <= x,y < 32`.
2. Derive `Connections` from the final room-to-room links within that area.
   A connection is represented as an undirected shared edge. Cross-area links
   are elevator topology, not normal map connections.
3. Derive `Doors` from east/west door edges. The map graphics only support
   east/west doors. A non-door topology cell must use one of
   `allowedConnectionMasks` from the JSON file.
4. Select the glyph from the JSON lookup and store its `word` field. That word
   already contains the character number and any required H/V flip bits.
5. OR the selected word with `$2C00` before serializing it. `$2C00` supplies
   BG3 priority and the base palette; the runtime replaces the palette to
   show current, visited, and revealed states.

Use lookups by semantic key, rather than by tile number:

| Cell type | JSON lookup |
| --- | --- |
| Ordinary room | `topology[connections]` |
| Item room | `features.item[connections]` |
| Cross-game portal | `features.portal[connections]` |
| Area-map pickup | `features.mapstation[connections]` |
| Text marker | Overlay-font character `$000-$0FF` |
| Door room | `doors[(connections, doors)]` |
| Boss room | `bosses[doors]` |
| Elevator entrance | `elevators[(kind=entrance, sideDoor)]` |
| Elevator shaft top | `elevators[kind=shaftTop]` |
| Elevator shaft | `elevators[kind=shaft]` |

Index the JSON arrays into dictionaries during initialization. Missing lookup
entries are generator errors, not cases to approximate with another tile.

### Features And Doors

One map cell can display one feature glyph. Keep map station, portal, boss,
elevator, and ordinary-item placement mutually exclusive in the generated
world where possible. When a feature cell has an east/west door, apply the
`sharedDoorRule` from the JSON file:

1. Render the feature at its own cell without a door overlay.
2. Add the reciprocal door flag to the adjacent non-feature cell.
3. Re-select that neighbor from the `doors[(connections, doors)]` lookup.
4. Reject the generated layout if the neighbor is unavailable or the resulting
   pair has no lookup entry.

This is a second composition pass after every cell has its initial glyph.
It preserves the feature marker while still showing the shared door edge.

### Special Cells

- A map-station cell must correspond to a local M1 custom item with ID `$CE`.
  Picking up `$CE` reveals the current area, but does not add an inventory item.
  The map-station glyph is intentionally visible before the area is revealed.
- A text marker uses an overlay-font character from
   `src/data/tables/small_overlay.tbl`. Encode it as
   `character | $2000 | (palette << 10)`. Palette `3` is the standard overlay
   text palette, giving `$2C00` attributes. Text markers always render with
   their selected palette, regardless of exploration or area reveal state.
- A portal cell uses `features.portal`. Use it for a cross-game portal or other
  world-generator connection that should be visually distinct from an item.
- A boss cell uses `bosses` keyed by its east/west door mask. Do not use a
  generic item glyph for a boss location.
- Model elevator geometry explicitly. An entrance uses its east/west side-door
  lookup. For an upward entrance, also OR the JSON `vFlipMask` into that word.
  Use `shaftTop` for the upper arrival room and `shaft` for the north/south
  intermediate room.

The existing map graphics support the connection/door pairs present in the
JSON file, including vertical rooms with side doors. Do not silently collapse
an unsupported junction or door layout. Either make the generated room layout
compatible or extend the graphics and lookup schema in the base ROM first.

## Bounds And Seed Identity

After composing the five planes, derive one four-byte bounds record per area:

```text
minX, maxX, minY, maxY
```

Consider a cell populated when `word & tilemapWord.characterMask` is nonzero.
For an empty area, write `$FF, $00, $FF, $00`. Bounds are used to center the
full-screen map view, so calculate them from the final serialized planes.

Serialize the planes in area order, each as 1024 little-endian `ushort` values.
Then compute the standard CRC-32 numeric value over:

```text
all five plane byte sequences, followed by all 20 bounds bytes
```

Write that CRC-32 value as a four-byte little-endian integer at header `+$0C`.
The C# implementation must match `zlib.crc32`; add a golden test using the
checked-in vanilla map assets to confirm both CRC variant and byte order.
Changing this value resets stale explored-map SRAM for a new map layout.

## ROM Write Step

After the normal M1 world, room, door, and item tables have been written:

1. Compose and validate the automap payload from that final world state.
2. Write the 20 bounds bytes at `header + areaBoundsOffset`.
3. Write the 4-byte seed identity at `header + $0C`.
4. Write the five contiguous map planes at `romMap.tilemapsSnesAddress`.
5. Do not modify the `M1MP` header fields, `m1_map_tiles.2bpp`, or
   `m1_map_tiles.json` during seed generation.

Writing the bounds and seed before the planes is acceptable because the ROM is
an output artifact; build the complete payload in memory and validate it before
performing any writes.

## Validation Plan

Add pure unit tests for the map composer and a ROM integration test.

1. Verify the M1MP header and JSON dimensions before composition.
2. Verify every populated cell has valid coordinates, an allowed semantic
   feature combination, and a lookup entry.
3. Verify the output is exactly `5 * $0800 = $2800` bytes and each bounds
   record encloses every nonblank cell in its plane.
4. Verify the generated CRC by recomputing it from the final bytes and compare
   the four serialized seed-ID bytes.
5. Use a small fixture covering ordinary rooms, horizontal and vertical rooms,
   each door shape, item, portal, map station, boss, and every elevator shape.
6. Generate a ROM with a deterministic randomized world, load it in an
   emulator, and confirm room tracking, area reveal, map view centering, and
   cross-game portal markers match the generated world.

Keep the composer independent of ROM I/O. It should return a payload containing
the five planes, bounds, and seed identity; a thin writer can then apply that
payload through the randomizer's existing ROM abstraction.