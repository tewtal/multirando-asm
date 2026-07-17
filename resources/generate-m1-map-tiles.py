#!/usr/bin/env python3
"""Generate M1 automap 2BPP graphics and C#-friendly tile lookup metadata.

The C# randomizer writes final 16-bit SNES BG tilemap words into the ROM map.
This generator therefore stores only symmetry-reduced graphics: H/V flip bits
select the remaining orientations. Basic shapes match Super Metroid's map style
(colour 1 room fill, colour 2 closed wall, colour 3 feature/door marker).
"""

from __future__ import annotations

import json
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TILES_PATH = ROOT / "src/data/m1_map_tiles.2bpp"
LOOKUP_PATH = ROOT / "src/data/m1_map_tiles.json"

PREVIEW_PATHS = {
    "topology": ROOT / "src/data/m1_map_tiles.png",
    "item": ROOT / "src/data/m1_map_item_tiles.png",
    "elevator": ROOT / "src/data/m1_map_elevator_tiles.png",
    "boss": ROOT / "src/data/m1_map_boss_tiles.png",
    "portal": ROOT / "src/data/m1_map_portal_tiles.png",
    "door": ROOT / "src/data/m1_map_door_tiles.png",
    "mapstation": ROOT / "src/data/m1_map_mapstation_tiles.png",
}

TILE_SIZE = 8
H_FLIP = 0x4000
V_FLIP = 0x8000

# The popup font occupies BG3 characters $000-$0FF. Automap graphics follow it.
GROUP_TILE_BASES = {
    "topology": 0x100,
    "item": 0x105,
    "elevator": 0x10A,
    "boss": 0x10D,
    "portal": 0x10F,
    "door": 0x114,
    "mapstation": 0x11B,
}
GROUP_ORDER = ("topology", "item", "elevator", "boss", "portal", "door", "mapstation")

# Connection bits are N=1, E=2, S=4, W=8. M1 rooms scroll on one axis and
# occupy one map cell, so turns, branches, and intersections do not occur.
CONNECTION_MASKS = (0x0, 0x1, 0x2, 0x4, 0x5, 0x8, 0xA)
# Doors are east/west only. These canonical states retain the three ordinary
# horizontal door forms and add the vertical-room door layouts used by the map
# editor. Horizontal and vertical flips provide the mirrored orientations.
DOOR_CANONICAL_STATES = (
    (0x2, 0x2),   # east door
    (0xA, 0x2),   # east door, horizontal room
    (0xA, 0xA),   # doors on both sides, horizontal room
    (0xB, 0xA),   # doors on both sides, north opening
    (0xF, 0xA),   # doors on both sides, vertical passage
    (0x7, 0x2),   # east door, vertical passage
    (0x3, 0x2),   # east door, north opening
)

HEX_FONT = {
    "0": ("111", "101", "101", "101", "111"),
    "1": ("010", "110", "010", "010", "111"),
    "2": ("110", "001", "111", "100", "111"),
    "3": ("110", "001", "111", "001", "110"),
    "4": ("101", "101", "111", "001", "001"),
    "5": ("111", "100", "110", "001", "110"),
    "6": ("011", "100", "111", "101", "111"),
    "7": ("111", "001", "010", "010", "010"),
    "8": ("111", "101", "111", "101", "111"),
    "9": ("111", "101", "111", "001", "110"),
    "A": ("010", "101", "111", "101", "101"),
    "B": ("110", "101", "110", "101", "110"),
    "C": ("011", "100", "100", "100", "011"),
    "D": ("110", "101", "101", "101", "110"),
    "E": ("111", "100", "110", "100", "111"),
    "F": ("111", "100", "110", "100", "100"),
}


def flip_horizontal(mask: int) -> int:
    return (mask & 0x5) | ((mask & 0x2) << 2) | ((mask & 0x8) >> 2)


def flip_vertical(mask: int) -> int:
    return (mask & 0xA) | ((mask & 0x1) << 2) | ((mask & 0x4) >> 2)


def transformed(mask: int, h_flip: bool, v_flip: bool) -> int:
    if h_flip:
        mask = flip_horizontal(mask)
    if v_flip:
        mask = flip_vertical(mask)
    return mask


def canonical_pair(connections: int, doors: int = 0) -> tuple[int, int, bool, bool]:
    """Return canonical connection/door masks and flips from canonical to input."""
    candidates = []
    for h_flip, v_flip in ((False, False), (True, False), (False, True), (True, True)):
        candidate_connections = transformed(connections, h_flip, v_flip)
        candidate_doors = transformed(doors, h_flip, v_flip)
        candidates.append(
            (
                candidate_connections,
                candidate_doors,
                int(h_flip) + int(v_flip),
                h_flip,
                v_flip,
            )
        )
    canonical_connections, canonical_doors, _, h_flip, v_flip = min(candidates)
    return canonical_connections, canonical_doors, h_flip, v_flip


def expanded_door_states() -> tuple[tuple[int, int], ...]:
    """Return every requested door state, including its flip-derived forms."""
    states = {
        (transformed(connections, h_flip, v_flip), transformed(doors, h_flip, v_flip))
        for connections, doors in DOOR_CANONICAL_STATES
        for h_flip, v_flip in ((False, False), (True, False), (False, True), (True, True))
    }
    return tuple(sorted(states))


def make_tile(connections: int) -> list[list[int]]:
    """Return one SM-style 8x8 room tile. Connection bits are N=1,E=2,S=4,W=8."""
    pixels = [[1 for _ in range(TILE_SIZE)] for _ in range(TILE_SIZE)]
    if not connections & 0x1:
        pixels[0] = [2] * TILE_SIZE
    if not connections & 0x2:
        for row in pixels:
            row[-1] = 2
    if not connections & 0x4:
        pixels[-1] = [2] * TILE_SIZE
    if not connections & 0x8:
        for row in pixels:
            row[0] = 2
    return pixels


def add_pixels(
    tile: list[list[int]], points: tuple[tuple[int, int], ...], colour: int = 3
) -> list[list[int]]:
    result = [row[:] for row in tile]
    for x, y in points:
        result[y][x] = colour
    return result


FEATURE_PIXELS = {
    "item": ((3, 3), (4, 3), (3, 4), (4, 4)),
    "portal": (
        (3, 1), (4, 1),
        (2, 2), (5, 2),
        (2, 3), (5, 3),
        (2, 4), (5, 4),
        (2, 5), (5, 5),
        (3, 6), (4, 6),
    ),
    # Map station: a hollow 4x4 ring, symmetric under H/V flips so one drawing
    # serves every canonical-orientation lookup.
    "mapstation": (
        (2, 2), (3, 2), (4, 2), (5, 2),
        (2, 3), (5, 3),
        (2, 4), (5, 4),
        (2, 5), (3, 5), (4, 5), (5, 5),
    ),
}

DOOR_PIXELS = {
    0x2: ((7, 3), (7, 4)),
    0x8: ((0, 3), (0, 4)),
}


def make_feature_tile(connections: int, feature: str) -> list[list[int]]:
    return add_pixels(make_tile(connections), FEATURE_PIXELS[feature])


def make_door_tile(connections: int, doors: int) -> list[list[int]]:
    # A door is a connection logically, but graphically it remains embedded in
    # the room wall. Only a plain passage removes the corresponding wall.
    open_passages = connections & ~doors
    points = tuple(
        point
        for direction, direction_points in DOOR_PIXELS.items()
        if doors & direction
        for point in direction_points
    )
    return add_pixels(make_tile(open_passages), points)


def make_elevator_tile(kind: str, side_door: str | None) -> list[list[int]]:
    """Draw one M1 elevator endpoint in the style of SM's map elevators."""
    if kind == "entranceDown":
        tile = make_tile(0)
        shaft_points = ((3, 7), (4, 7))
        platform_points = ((2, 5), (3, 5), (4, 5), (5, 5))
    elif kind == "shaftTop":
        # This room sits above the shaft, so its entire south edge is open.
        tile = make_tile(0x4)
        shaft_points = ()
        platform_points = ((2, 5), (3, 5), (4, 5), (5, 5))
    elif kind == "shaft":
        tile = make_tile(0x5)
        shaft_points = tuple((x, y) for x in (3, 4) for y in range(TILE_SIZE))
        platform_points = ()
    else:
        raise ValueError(f"invalid elevator kind: {kind}")

    tile = add_pixels(tile, shaft_points, 3)
    tile = add_pixels(tile, platform_points, 2)
    if side_door == "west":
        tile = add_pixels(tile, DOOR_PIXELS[0x8], 3)
    elif side_door == "east":
        tile = add_pixels(tile, DOOR_PIXELS[0x2], 3)
    elif side_door is not None:
        raise ValueError(f"invalid elevator side door: {side_door}")
    return tile


def make_boss_tile(doors: int) -> list[list[int]]:
    """Draw one horizontally scrolling boss room with one or two side doors."""
    tile = make_door_tile(doors, doors)
    boss_pixels = (
        (2, 2), (5, 2),
        (3, 3), (4, 3),
        (3, 4), (4, 4),
        (2, 5), (5, 5),
    )
    return add_pixels(tile, boss_pixels)


def flip_pixels(
    tile: list[list[int]], h_flip: bool, v_flip: bool
) -> list[list[int]]:
    rows = [row[::-1] if h_flip else row[:] for row in tile]
    return rows[::-1] if v_flip else rows


def validate_symmetry_lookups() -> None:
    """Prove that every lookup flip reconstructs the requested graphic."""
    for connections in CONNECTION_MASKS:
        canonical_connections, _, h_flip, v_flip = canonical_pair(connections)
        assert transformed(canonical_connections, h_flip, v_flip) == connections
        assert flip_pixels(
            make_tile(canonical_connections), h_flip, v_flip
        ) == make_tile(connections)
        for feature in FEATURE_PIXELS:
            assert flip_pixels(
                make_feature_tile(canonical_connections, feature), h_flip, v_flip
            ) == make_feature_tile(connections, feature)

    for connections, doors in expanded_door_states():
        canonical_connections, canonical_doors, h_flip, v_flip = canonical_pair(
            connections, doors
        )
        assert transformed(canonical_connections, h_flip, v_flip) == connections
        assert transformed(canonical_doors, h_flip, v_flip) == doors
        assert flip_pixels(
            make_door_tile(canonical_connections, canonical_doors), h_flip, v_flip
        ) == make_door_tile(connections, doors)

    assert flip_pixels(
        make_elevator_tile("entranceDown", "west"), True, False
    ) == make_elevator_tile("entranceDown", "east")
    assert flip_pixels(
        make_elevator_tile("shaft", None), False, True
    ) == make_elevator_tile("shaft", None)
    assert flip_pixels(make_boss_tile(0x8), True, False) == make_boss_tile(0x2)


def encode_snes_2bpp(pixels: list[list[int]]) -> bytes:
    encoded = bytearray()
    for row in pixels:
        plane_0 = 0
        plane_1 = 0
        for x, colour in enumerate(row):
            bit = 7 - x
            plane_0 |= (colour & 1) << bit
            plane_1 |= ((colour >> 1) & 1) << bit
        encoded.extend((plane_0, plane_1))
    return bytes(encoded)


def tilemap_lookup(tile: int, h_flip: bool, v_flip: bool) -> dict[str, int | bool]:
    word = tile | (H_FLIP if h_flip else 0) | (V_FLIP if v_flip else 0)
    return {"tile": tile, "hFlip": h_flip, "vFlip": v_flip, "word": word}


def build_topology_lookup(tile_base: int) -> tuple[list[int], list[dict[str, int | bool]]]:
    canonical_masks = sorted(
        {canonical_pair(mask)[0] for mask in CONNECTION_MASKS}
    )
    assert len(canonical_masks) == 5
    tile_by_mask = {mask: tile_base + index for index, mask in enumerate(canonical_masks)}

    lookup = []
    for mask in CONNECTION_MASKS:
        canonical_mask, _, h_flip, v_flip = canonical_pair(mask)
        entry = {"connections": mask, "canonicalConnections": canonical_mask}
        entry.update(tilemap_lookup(tile_by_mask[canonical_mask], h_flip, v_flip))
        lookup.append(entry)
    return canonical_masks, lookup


def build_door_lookup(tile_base: int) -> tuple[list[tuple[int, int]], list[dict[str, int | bool]]]:
    canonical_states = sorted(DOOR_CANONICAL_STATES)
    assert len(canonical_states) == 7
    assert {
        canonical_pair(connections, doors)[:2]
        for connections, doors in expanded_door_states()
    } == set(canonical_states)
    tile_by_state = {
        state: tile_base + index for index, state in enumerate(canonical_states)
    }

    lookup = []
    for connections, doors in expanded_door_states():
        canonical_connections, canonical_doors, h_flip, v_flip = canonical_pair(
            connections, doors
        )
        entry = {
            "connections": connections,
            "doors": doors,
            "canonicalConnections": canonical_connections,
            "canonicalDoors": canonical_doors,
        }
        entry.update(
            tilemap_lookup(
                tile_by_state[(canonical_connections, canonical_doors)],
                h_flip,
                v_flip,
            )
        )
        lookup.append(entry)
    assert len(lookup) == 14
    return canonical_states, lookup


def png_chunk(kind: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    )


def write_png(path: Path, width: int, height: int, pixels: bytearray) -> None:
    stride = width * 3
    rows = [b"\x00" + pixels[y * stride : (y + 1) * stride] for y in range(height)]
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(b"".join(rows), 9))
        + png_chunk(b"IEND", b"")
    )


def write_preview(path: Path, tiles: list[list[list[int]]], labels: list[str]) -> None:
    scale = 8
    columns = 4
    rows = (len(tiles) + columns - 1) // columns
    margin = 8
    label_height = 7 * scale
    cell_width = TILE_SIZE * scale + margin * 2
    cell_height = label_height + TILE_SIZE * scale + margin * 2
    width = columns * cell_width
    height = rows * cell_height

    background = (18, 20, 27)
    palette = (background, (62, 138, 201), (224, 230, 234), (255, 188, 44))
    rgb = bytearray(background * (width * height))

    def rectangle(x: int, y: int, w: int, h: int, colour: tuple[int, int, int]) -> None:
        for py in range(y, y + h):
            for px in range(x, x + w):
                offset = (py * width + px) * 3
                rgb[offset : offset + 3] = bytes(colour)

    for index, tile in enumerate(tiles):
        cell_x = (index % columns) * cell_width
        cell_y = (index // columns) * cell_height
        tile_x = cell_x + margin
        tile_y = cell_y + margin + label_height

        label = labels[index]
        glyph_scale = 3
        label_width = len(label) * 4 * glyph_scale - glyph_scale
        glyph_x = cell_x + (cell_width - label_width) // 2
        glyph_y = cell_y + margin
        for character in label:
            for gy, row in enumerate(HEX_FONT[character]):
                for gx, value in enumerate(row):
                    if value == "1":
                        rectangle(
                            glyph_x + gx * glyph_scale,
                            glyph_y + gy * glyph_scale,
                            glyph_scale,
                            glyph_scale,
                            palette[2],
                        )
            glyph_x += 4 * glyph_scale

        for y, row in enumerate(tile):
            for x, colour in enumerate(row):
                rectangle(
                    tile_x + x * scale,
                    tile_y + y * scale,
                    scale,
                    scale,
                    palette[colour],
                )

    write_png(path, width, height, rgb)


def main() -> None:
    validate_symmetry_lookups()
    canonical_masks, topology_lookup = build_topology_lookup(GROUP_TILE_BASES["topology"])
    canonical_door_states, door_lookup = build_door_lookup(GROUP_TILE_BASES["door"])

    groups: dict[str, list[list[list[int]]]] = {
        "topology": [make_tile(mask) for mask in canonical_masks],
        "item": [make_feature_tile(mask, "item") for mask in canonical_masks],
        # H-flip supplies the right-door form of the first tile. The following
        # two tiles are the shaft top and a north/south shaft segment.
        "elevator": [
            make_elevator_tile("entranceDown", "west"),
            make_elevator_tile("shaftTop", None),
            make_elevator_tile("shaft", None),
        ],
        # H-flip supplies the east-only form of the first boss tile.
        "boss": [make_boss_tile(0x8), make_boss_tile(0xA)],
        "portal": [make_feature_tile(mask, "portal") for mask in canonical_masks],
        "door": [
            make_door_tile(connections, doors)
            for connections, doors in canonical_door_states
        ],
        "mapstation": [
            make_feature_tile(mask, "mapstation") for mask in canonical_masks
        ],
    }

    next_tile = GROUP_TILE_BASES[GROUP_ORDER[0]]
    for group in GROUP_ORDER:
        assert GROUP_TILE_BASES[group] == next_tile
        next_tile += len(groups[group])
    tile_count = next_tile - GROUP_TILE_BASES[GROUP_ORDER[0]]

    encoded = b"".join(
        encode_snes_2bpp(tile)
        for group in GROUP_ORDER
        for tile in groups[group]
    )
    assert len(encoded) == tile_count * 16
    TILES_PATH.write_bytes(encoded)

    feature_lookups = {}
    for feature in ("item", "portal", "mapstation"):
        _, feature_lookups[feature] = build_topology_lookup(GROUP_TILE_BASES[feature])

    elevator_base = GROUP_TILE_BASES["elevator"]
    elevator_lookup = [
        {
            "kind": "entrance",
            "verticalConnection": "doorSouth",
            "sideDoor": "west",
            **tilemap_lookup(elevator_base, False, False),
        },
        {
            "kind": "entrance",
            "verticalConnection": "doorSouth",
            "sideDoor": "east",
            **tilemap_lookup(elevator_base, True, False),
        },
        {
            "kind": "shaftTop",
            "verticalConnection": "openSouth",
            "sideDoor": None,
            **tilemap_lookup(elevator_base + 1, False, False),
        },
        {
            "kind": "shaft",
            "verticalConnection": "openNorthSouth",
            "sideDoor": None,
            **tilemap_lookup(elevator_base + 2, False, False),
        },
    ]

    boss_base = GROUP_TILE_BASES["boss"]
    boss_lookup = [
        {
            "doors": 0x8,
            "sideDoors": "west",
            **tilemap_lookup(boss_base, False, False),
        },
        {
            "doors": 0x2,
            "sideDoors": "east",
            **tilemap_lookup(boss_base, True, False),
        },
        {
            "doors": 0xA,
            "sideDoors": "both",
            **tilemap_lookup(boss_base + 1, False, False),
        },
    ]

    metadata = {
        "format": 1,
        "description": "M1 automap BG3 characters and flip lookup",
        "romMap": {
            "headerSnesAddress": 0x989000,
            "areaBoundsOffset": 0x10,
            "tilemapsSnesAddress": 0x989100,
            "width": 32,
            "height": 32,
            "entryBytes": 2,
            "areaBytes": 0x800,
            "byteOrder": "little-endian",
            "blankWord": 0,
            "tileEncoding": 2,
            "areaOrder": ["Brinstar", "Norfair", "Kraid", "Tourian", "Ridley"],
        },
        "connectionBits": {"north": 1, "east": 2, "south": 4, "west": 8},
        "scrollConstraint": "M1 rooms use one scroll axis; vertical rooms may also have east/west door edges.",
        "allowedConnectionMasks": list(CONNECTION_MASKS),
        "doorDirections": ["east", "west"],
        "tilemapWord": {
            "characterMask": 0x03FF,
            "paletteMask": 0x1C00,
            "paletteShift": 10,
            "priorityMask": 0x2000,
            "hFlipMask": H_FLIP,
            "vFlipMask": V_FLIP,
            "lookupWordContains": "character and flip bits; OR palette and priority as desired",
        },
        "sharedDoorRule": (
            "A cell has one character. If a feature and door share a cell, draw the "
            "shared door edge on the adjacent non-feature cell."
        ),
        "groupTileBases": GROUP_TILE_BASES,
        "groupTileCounts": {group: len(groups[group]) for group in GROUP_ORDER},
        "tileCount": tile_count,
        "canonicalConnectionMasks": canonical_masks,
        "topology": topology_lookup,
        "features": feature_lookups,
        "elevators": elevator_lookup,
        "bosses": boss_lookup,
        "doors": door_lookup,
    }
    LOOKUP_PATH.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")

    for group, tiles in groups.items():
        base = GROUP_TILE_BASES[group]
        preview_tiles = tiles
        labels = [f"{base + index:03X}" for index in range(len(tiles))]
        if group == "elevator":
            preview_tiles = [tiles[0], flip_pixels(tiles[0], True, False), *tiles[1:]]
            labels = [f"{base:03X}", f"{base:03X}", f"{base + 1:03X}", f"{base + 2:03X}"]
        elif group == "boss":
            preview_tiles = [tiles[0], flip_pixels(tiles[0], True, False), tiles[1]]
            labels = [f"{base:03X}", f"{base:03X}", f"{base + 1:03X}"]
        write_preview(PREVIEW_PATHS[group], preview_tiles, labels)

    print(
        f"Wrote {TILES_PATH.relative_to(ROOT)} "
        f"({len(encoded)} bytes, {tile_count} tiles)"
    )
    print(f"Wrote {LOOKUP_PATH.relative_to(ROOT)}")
    for path in PREVIEW_PATHS.values():
        print(f"Wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
