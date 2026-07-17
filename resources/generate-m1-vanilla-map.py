#!/usr/bin/env python3
"""Generate the vanilla Metroid 1 automap as default M1 map ROM data.

Extracts the vanilla world from resources/metroid.nes:
  * global 32x32 world map (bank 0 $A53E, room number per cell, $FF empty),
  * per-area room definitions (structure -> macro -> tile expansion) to find
    which screen edges are passable,
  * enemy/door records for door sides and elevator rooms,
  * the per-bank special items table for power-up locations, elevator
    destinations/directions, extra doors and Mother Brain,
and converts it into the fixed-size automap format of
src/m1/randomizer/map_data.asm: five 32x32 SNES BG3 tilemaps of final
little-endian words, five bounds records and a seed/map identity.

Cells are assigned to the five areas by flood fill from each bank's Samus
start cell and elevator cells; elevator cells never propagate vertically
because that is exactly where two areas meet on the shared world grid.

Outputs:
  src/data/m1_map_vanilla_seed.bin      (4 bytes,  -> M1MapSeedId)
  src/data/m1_map_vanilla_bounds.bin    (20 bytes, -> M1MapAreaBounds)
  src/data/m1_map_vanilla_tilemaps.bin  (0x2800,   -> M1MapTilemaps)
  src/data/m1_map_vanilla.png           (human-readable preview)
"""

from __future__ import annotations

import json
import sys
import struct
import zlib
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROM_PATH = ROOT / "resources/metroid.nes"
LOOKUP_PATH = ROOT / "src/data/m1_map_tiles.json"
TILES_2BPP_PATH = ROOT / "src/data/m1_map_tiles.2bpp"

SEED_OUT = ROOT / "src/data/m1_map_vanilla_seed.bin"
BOUNDS_OUT = ROOT / "src/data/m1_map_vanilla_bounds.bin"
TILEMAPS_OUT = ROOT / "src/data/m1_map_vanilla_tilemaps.bin"
PREVIEW_OUT = ROOT / "src/data/m1_map_vanilla.png"

MAP_W = 32
MAP_H = 32
ROOM_W = 32  # tiles
ROOM_H = 30  # tiles

# Automap area order (matches m1_CurrentArea-$10) -> vanilla PRG bank.
AREAS = ("Brinstar", "Norfair", "Kraid", "Tourian", "Ridley")
AREA_BANK = (1, 2, 4, 3, 5)

# Word attributes: BG3 palette 3 (CGRAM $0C-$0F, same as the popup font)
# plus the priority bit, matching small_overlay.tbl ($2C00-based words).
WORD_ATTRIB = 0x2C00

N, E, S, W = 1, 2, 4, 8
OPPOSITE = {N: S, S: N, E: W, W: E}
DELTA = {N: (0, -1), S: (0, 1), E: (1, 0), W: (-1, 0)}
ALLOWED_MASKS = {0x0, 0x1, 0x2, 0x4, 0x5, 0x8, 0xA}

SPEC_POWERUP = 0x02
SPEC_ELEVATOR = 0x04
SPEC_MOTHER_BRAIN = 0x06
SPEC_DOOR = 0x09

# Reference ownership for ambiguous world cells.
#   B/N/K/T/R  only that area may claim the cell
#   b/n/k/t/r  preferred area when resolving a tie
#   x          unreachable filler
#   .          empty cell ($FF)
VANILLA_AREA_HINTS = (
    "................................",
    "...........B.B......B...........",
    "...BBBBBBBBB.BBBBBBBB.........B.",
    ".T.b.......B.BBBBBBBBBBBBBBBBBB.",
    ".T.T.......B.B................B.",
    ".T.T..BBBBBB.B..........BBBBBBB.",
    ".T.T.......B.B....B...B.......B.",
    ".T.TTTttTTTBbBBBBBBBBBBBBBBBBBB.",
    ".T........TB.B....B...B.......B.",
    ".T........TB.B....BBBBB.N.....N.",
    ".T........TB.B....B...B.NNNNNNN.",
    ".TTTTTTTTTTB.BBBBBBBBBB.NNNNNNN.",
    "...........B.B........b.NNNNNNN.",
    "...........B.N........N.N.....N.",
    ".BBBBBBBBBBB.NNNNNNNNNNNNNNNNNN.",
    "......B....B.NNNNNNNNNNNNNNNNNN.",
    "......B.K..K.NNNNNN...........N.",
    "......B.KKKK.NNNNNNNNNbNNNNNNNN.",
    "......BBKKKK.NNNNNNNNNNNNNNNNNN.",
    "......BbKKKK.N...NN......NNNNNN.",
    ".K.....KK..K.NNBNNNNNNNBNBNNNNN.",
    ".KKKKKKKKKKK.N...NNNNN..NNNNNNN.",
    ".KKKKKKKKKKK.x..xNNNNN..NN....N.",
    ".K..K..K....K....N.....RNb....x.",
    ".K..KKKKKBBKK.R..RRRRRRRRR....R.",
    ".K..K..K.KKKK.RRRRRRRRRRRRRRRRR.",
    ".K..KKKKKK.KK.R..R....R.......R.",
    ".KKKKKBKKKKKK.RRRRRRRRRRRRRRRRR.",
    ".K.KKKKKKKKKK.R.......R.......R.",
    "........KKKKK.RRRRRRRRRRRRRRRRR.",
    "............K.RRRRRRRRRRRRRRRRR.",
    "................................",
)
HINT_AREA = {"B": 0, "N": 1, "K": 2, "T": 3, "R": 4}
# Bytes each special item type occupies (type byte included).
SPEC_ITEM_LEN = {
    0x01: 3, 0x02: 3, 0x03: 1, 0x04: 2, 0x05: 2,
    0x06: 1, 0x07: 1, 0x08: 1, 0x09: 2, 0x0A: 1,
}


class Bank:
    """One vanilla area bank with its standard table layout."""

    def __init__(self, prg: bytes, bank: int, is_brinstar: bool):
        self.prg = prg
        self.bank = bank
        self.air_threshold = 0x80 if is_brinstar else 0x70
        self.spec_items_addr = self.read_word(0x9598)
        self.room_ptr_addr = self.read_word(0x959A)
        self.struct_ptr_addr = self.read_word(0x959C)
        self.macro_addr = self.read_word(0x959E)
        self.boss_room = self.read_byte(0x95CC)
        self.start_x = self.read_byte(0x95D7)
        self.start_y = self.read_byte(0x95D8)
        self.room_count = (self.struct_ptr_addr - self.room_ptr_addr) // 2
        self._rooms: dict[int, Room | None] = {}

    def offset(self, cpu_addr: int) -> int:
        assert 0x8000 <= cpu_addr < 0xC000, hex(cpu_addr)
        return self.bank * 0x4000 + cpu_addr - 0x8000

    def read_byte(self, cpu_addr: int) -> int:
        return self.prg[self.offset(cpu_addr)]

    def read_word(self, cpu_addr: int) -> int:
        off = self.offset(cpu_addr)
        return self.prg[off] | self.prg[off + 1] << 8

    def room(self, number: int) -> "Room | None":
        if number >= self.room_count:
            return None
        if number not in self._rooms:
            self._rooms[number] = Room(self, number)
        return self._rooms[number]


class Room:
    """One parsed and rendered room definition."""

    def __init__(self, bank: Bank, number: int):
        self.doors: set[int] = set()  # E and/or W
        self.has_elevator = False
        prg, base = bank.prg, bank.offset(bank.read_word(bank.room_ptr_addr + number * 2))
        i = base + 1  # skip attribute byte
        structures = []
        has_enemy_data = False
        while True:
            v = prg[i]
            if v == 0xFF:
                break
            if v == 0xFD:
                i += 1
                has_enemy_data = True
                break
            if v == 0xFE:
                i += 1
                continue
            structures.append((prg[i], prg[i + 1]))
            i += 3
        if has_enemy_data:
            while prg[i] != 0xFF:
                kind = prg[i] & 0x0F
                if kind in (0x1, 0x7):  # enemy / regenerating enemy
                    i += 3
                elif kind == 0x2:  # door: info bit 4 selects the side
                    self.doors.add(W if prg[i + 1] & 0x10 else E)
                    i += 2
                elif kind == 0x4:  # elevator
                    self.has_elevator = True
                    i += 2
                elif kind == 0x6:  # Kraid/Ridley statues
                    i += 1
                else:
                    raise ValueError(
                        f"bank {bank.bank} room {number:02X}: "
                        f"unknown enemy/door record {prg[i]:02X}"
                    )

        grid = bytearray(b"\xff" * (ROOM_W * ROOM_H))
        for pos, struct_id in structures:
            self._draw_struct(bank, grid, struct_id, (pos & 0x0F) * 2, (pos >> 4) * 2)

        air = bank.air_threshold
        self.open_edges = 0
        if any(t >= air for t in grid[0:ROOM_W]):
            self.open_edges |= N
        if any(t >= air for t in grid[(ROOM_H - 1) * ROOM_W:]):
            self.open_edges |= S
        if any(grid[y * ROOM_W] >= air for y in range(ROOM_H)):
            self.open_edges |= W
        if any(grid[y * ROOM_W + ROOM_W - 1] >= air for y in range(ROOM_H)):
            self.open_edges |= E

    @staticmethod
    def _draw_struct(bank: Bank, grid: bytearray, struct_id: int, x: int, y: int):
        prg = bank.prg
        i = bank.offset(bank.read_word(bank.struct_ptr_addr + struct_id * 2))
        macro_base = bank.offset(bank.macro_addr)
        row_y = y
        while prg[i] != 0xFF:
            count = prg[i] & 0x0F or 0x10
            col_x = x + (prg[i] >> 4) * 2
            i += 1
            if row_y >= ROOM_H:  # DrawMacro stops at the end of room RAM
                break
            for _ in range(count):
                macro = macro_base + prg[i] * 4
                i += 1
                if col_x >= ROOM_W:
                    continue  # row ended early to prevent wrapping
                for t, (dx, dy) in enumerate(((0, 0), (1, 0), (0, 1), (1, 1))):
                    ty, tx = row_y + dy, col_x + dx
                    if ty < ROOM_H and tx < ROOM_W:
                        grid[ty * ROOM_W + tx] = prg[macro + t]
                col_x += 2
            row_y += 2


def parse_special_items(bank: Bank) -> dict[tuple[int, int], list[tuple[int, bytes]]]:
    """Return {(x, y): [(type, data), ...]} from the bank's special items table."""
    prg = bank.prg
    items: dict[tuple[int, int], list[tuple[int, bytes]]] = {}
    long_addr = bank.spec_items_addr
    while True:
        i = bank.offset(long_addr)
        y = prg[i]
        next_long = prg[i + 1] | prg[i + 2] << 8
        i += 3
        while True:  # short entries chained by their offset byte
            x, off = prg[i], prg[i + 1]
            j = i + 2
            while prg[j] != 0x00:
                kind = prg[j] & 0x0F
                length = SPEC_ITEM_LEN[kind]
                items.setdefault((x, y), []).append((kind, bytes(prg[j + 1:j + length])))
                j += length
            if off == 0xFF:
                break
            i += off  # offset is relative to the entry's X byte
        if next_long == 0xFFFF:
            break
        long_addr = next_long
    return items


def main() -> None:
    rom = ROM_PATH.read_bytes()
    assert rom[:4] == b"NES\x1a", "resources/metroid.nes is not an iNES ROM"
    prg = rom[16:16 + 128 * 1024]
    world = prg[0x253E:0x253E + MAP_W * MAP_H]  # bank 0 $A53E -> RAM $7000

    lookup = json.loads(LOOKUP_PATH.read_text(encoding="utf-8"))
    topo_word = {e["connections"]: e["word"] for e in lookup["topology"]}
    item_word = {e["connections"]: e["word"] for e in lookup["features"]["item"]}
    door_word = {(e["connections"], e["doors"]): e["word"] for e in lookup["doors"]}
    boss_word = {e["doors"]: e["word"] for e in lookup["bosses"]}
    elev_entrance_word = {e["sideDoor"]: e["word"]
                          for e in lookup["elevators"] if e["kind"] == "entrance"}
    shaft_top_word = next(e["word"] for e in lookup["elevators"] if e["kind"] == "shaftTop")
    shaft_word = next(e["word"] for e in lookup["elevators"] if e["kind"] == "shaft")
    v_flip = lookup["tilemapWord"]["vFlipMask"]

    banks = [Bank(prg, AREA_BANK[a], AREA_BANK[a] == 1) for a in range(len(AREAS))]
    specials = [parse_special_items(b) for b in banks]

    def room_at(area: int, x: int, y: int) -> Room | None:
        number = world[y * MAP_W + x]
        return None if number == 0xFF else banks[area].room(number)

    def cell_doors(area: int, x: int, y: int) -> set[int]:
        room = room_at(area, x, y)
        doors = set(room.doors) if room else set()
        for kind, data in specials[area].get((x, y), []):
            if kind == SPEC_DOOR:
                doors.add(W if data[0] & 0x10 else E)
        return doors

    # Vanilla injects every elevator through the special items table. Bit 7 of
    # the data byte marks the lower area's side of a shaft. Each shaft spans
    # three cells; a bit-7 entry with a sibling elevator entry two cells below
    # it is the shared room at the top of the shaft, not a ride-up platform.
    elevators: list[dict[tuple[int, int], str]] = [{} for _ in AREAS]
    for area in range(len(AREAS)):
        entries = {(x, y): data
                   for (x, y), cell_entries in specials[area].items()
                   for kind, data in cell_entries if kind == SPEC_ELEVATOR}
        for (x, y), data in entries.items():
            if not data[0] & 0x80:
                elevators[area][(x, y)] = "down"
            elif (x, y + 2) in entries:
                elevators[area][(x, y)] = "up_top"
            else:
                elevators[area][(x, y)] = "up"
        for (x, y), kind in list(elevators[area].items()):
            if kind == "up":
                elevators[area].setdefault((x, y - 2), "up_top")
                elevators[area].setdefault((x, y - 1), "shaft")

    def side_passable(area: int, x: int, y: int, side: int) -> bool:
        room = room_at(area, x, y)
        if room is None:
            return False
        return bool(room.open_edges & side) or side in cell_doors(area, x, y)

    # ---- Flood fill area assignment --------------------------------------
    # A cell normally belongs to one area; the shared room at the top of each
    # elevator shaft is seeded into both adjoining areas. The reference hint
    # grid keeps the fill from leaking across area boundaries; seeds derived
    # from the game's own start/elevator tables outrank it.
    def claim_allowed(area: int, x: int, y: int) -> bool:
        ch = VANILLA_AREA_HINTS[y][x]
        if ch == "x":
            return False
        return not (ch.isupper() and HINT_AREA[ch] != area)

    def hint_prefers(area: int, x: int, y: int) -> int:
        ch = VANILLA_AREA_HINTS[y][x].upper()
        return 0 if HINT_AREA.get(ch) == area else 1

    area_cells: list[set[tuple[int, int]]] = [set() for _ in AREAS]
    claimed: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int, int]] = deque()

    def seed(area: int, x: int, y: int, propagate: bool = True) -> None:
        if not (0 <= x < MAP_W and 0 <= y < MAP_H):
            return
        if world[y * MAP_W + x] == 0xFF or (x, y) in area_cells[area]:
            return
        area_cells[area].add((x, y))
        claimed.add((x, y))
        if propagate:
            queue.append((x, y, area))

    for area, bank in enumerate(banks):
        seed(area, bank.start_x, bank.start_y)
        for (x, y), kind in elevators[area].items():
            # The shared shaft-top room borders the area above; never spread
            # from it. The cell between it and the "up" platform is plain shaft.
            seed(area, x, y, propagate=kind != "up_top")
            if kind == "up":
                seed(area, x, y - 1)

    while queue:
        x, y, area = queue.popleft()
        if elevators[area].get((x, y)) == "down":
            continue  # everything beyond a down elevator is the next area
        for side, (dx, dy) in DELTA.items():
            nx, ny = x + dx, y + dy
            if not (0 <= nx < MAP_W and 0 <= ny < MAP_H):
                continue
            if (nx, ny) in claimed or world[ny * MAP_W + nx] == 0xFF:
                continue
            if not claim_allowed(area, nx, ny):
                continue
            if side_passable(area, x, y, side) and side_passable(area, nx, ny, OPPOSITE[side]):
                area_cells[area].add((nx, ny))
                claimed.add((nx, ny))
                queue.append((nx, ny, area))

    # Second pass: adopt rooms only reachable through one-way or hidden
    # passages (breakable blocks read as solid edge tiles) into the area that
    # can see them across the shared edge. Elevator boundary cells never adopt.
    changed = True
    while changed:
        changed = False
        for y in range(MAP_H):
            for x in range(MAP_W):
                if world[y * MAP_W + x] == 0xFF or (x, y) in claimed:
                    continue
                candidates = []
                for side, (dx, dy) in DELTA.items():
                    nx, ny = x + dx, y + dy
                    for a in range(len(AREAS)):
                        if (nx, ny) not in area_cells[a]:
                            continue
                        if elevators[a].get((nx, ny)) in ("down", "up_top"):
                            continue
                        if not claim_allowed(a, x, y):
                            continue
                        if side_passable(a, nx, ny, OPPOSITE[side]):
                            candidates.append((0, hint_prefers(a, x, y), a))
                        elif side_passable(a, x, y, side):
                            candidates.append((1, hint_prefers(a, x, y), a))
                if candidates:
                    area = min(candidates)[2]
                    area_cells[area].add((x, y))
                    claimed.add((x, y))
                    changed = True

    # Final pass: the leftovers are the banks' sealed filler rooms (drawn in
    # the real game as decorated dead cells) and a few rooms whose structure
    # ties with an identical room in another bank. Fillers go to their hinted
    # area; structural ties go to the enclosing area instead, because their
    # hinted area is nowhere nearby.
    for y in range(MAP_H):
        for x in range(MAP_W):
            if world[y * MAP_W + x] == 0xFF or (x, y) in claimed:
                continue
            ch = VANILLA_AREA_HINTS[y][x].upper()
            if ch not in HINT_AREA:
                continue  # never drawn in-game: unreachable filler
            hinted = HINT_AREA[ch]
            adjacent = {a for side, (dx, dy) in DELTA.items() for a in range(len(AREAS))
                        if (x + dx, y + dy) in area_cells[a]}
            if hinted in adjacent or not adjacent:
                area = hinted
            else:
                area = min((hint_prefers(a, x, y), a) for a in adjacent)[1]
            area_cells[area].add((x, y))
            claimed.add((x, y))

    orphans = [
        (x, y)
        for y in range(MAP_H)
        for x in range(MAP_W)
        if world[y * MAP_W + x] != 0xFF
        and (x, y) not in claimed
        and VANILLA_AREA_HINTS[y][x] != "x"
    ]

    # Every special item is keyed by map cell in its own bank, so each listed
    # cell must have been assigned to that bank's area. (A couple of entries
    # target empty world cells and never trigger in-game; skip those.)
    for area in range(len(AREAS)):
        for x, y in specials[area]:
            if world[y * MAP_W + x] != 0xFF and (x, y) not in area_cells[area]:
                print(f"WARNING: {AREAS[area]} special item cell {(x, y)} "
                      f"was assigned elsewhere")

    if "--grid" in sys.argv:  # debug: one letter per assigned cell
        for y in range(MAP_H):
            row = ""
            for x in range(MAP_W):
                owners = [a for a in range(len(AREAS)) if (x, y) in area_cells[a]]
                if len(owners) > 1:
                    row += "*"
                elif owners:
                    row += AREAS[owners[0]][0]
                else:
                    row += "?" if world[y * MAP_W + x] != 0xFF else "."
            print(f"{y:2} {row}")

    # ---- Compose tilemap words -------------------------------------------
    def same_area(area: int, x: int, y: int) -> bool:
        return (x, y) in area_cells[area]

    def connections(
        area: int, x: int, y: int, preserve_vertical_doors: bool
    ) -> tuple[int, int]:
        """Final (connection mask, door mask) for one cell."""
        mask = doors = 0
        my_doors = cell_doors(area, x, y)
        for side, (dx, dy) in DELTA.items():
            nx, ny = x + dx, y + dy
            if not same_area(area, nx, ny):
                continue
            if side_passable(area, x, y, side) or side_passable(area, nx, ny, OPPOSITE[side]):
                mask |= side
                if side in my_doors:
                    doors |= side
        if mask not in ALLOWED_MASKS:
            horizontal, vertical = mask & (E | W), mask & (N | S)
            vertical_door_mask = vertical | doors
            if (
                preserve_vertical_doors
                and doors
                and horizontal == doors
                and (vertical_door_mask, doors) in door_word
            ):
                # This is a one-axis vertical room with side doors, not a
                # horizontal passage. Preserve its vertical geometry so the
                # dedicated vertical-room door glyph describes it accurately.
                mask = vertical_door_mask
            elif doors & (E | W):
                mask = horizontal
            elif horizontal.bit_count() >= vertical.bit_count():
                mask = horizontal
            else:
                mask = vertical
        doors &= mask
        return mask, doors

    tilemaps = [[0] * (MAP_W * MAP_H) for _ in AREAS]
    pushed_doors: list[tuple[int, int, int, int]] = []  # area, x, y, side

    for area in range(len(AREAS)):
        for x, y in area_cells[area]:
            room = room_at(area, x, y)
            spec = specials[area].get((x, y), [])
            elevator = elevators[area].get((x, y))
            is_boss = (room is not None and world[y * MAP_W + x] == banks[area].boss_room) \
                or any(kind == SPEC_MOTHER_BRAIN for kind, _ in spec)
            has_item = any(kind == SPEC_POWERUP for kind, _ in spec)
            mask, doors = connections(
                area,
                x,
                y,
                preserve_vertical_doors=not (is_boss or has_item or elevator is not None),
            )

            if is_boss:
                word = boss_word[(mask & (E | W)) or W]
            elif elevator == "up_top":
                word = shaft_top_word  # arrival room at the top of this area's shaft
            elif elevator == "shaft":
                word = shaft_word
            elif elevator is not None:
                side = "east" if mask & (E | W) == E else "west"
                word = elev_entrance_word[side]
                if elevator == "up":
                    word |= v_flip  # platform at the bottom of the shaft, rides up
            elif has_item:
                word = item_word[mask]
                for side in (E, W):
                    if doors & side:  # sharedDoorRule: door edge moves to the neighbor
                        pushed_doors.append((area, x + DELTA[side][0], y, OPPOSITE[side]))
            elif doors:
                word = door_word[(mask, doors)]
            else:
                word = topo_word[mask]
            tilemaps[area][y * MAP_W + x] = word | WORD_ATTRIB

    char_of = lambda word: word & lookup["tilemapWord"]["characterMask"]
    door_chars = {char_of(w) for w in door_word.values()}
    topo_chars = {char_of(w) for w in topo_word.values()}
    for area, x, y, side in pushed_doors:
        word = tilemaps[area][y * MAP_W + x]
        mask, doors = connections(area, x, y, preserve_vertical_doors=True)
        if char_of(word) in door_chars | topo_chars and (mask, doors | side) in door_word:
            tilemaps[area][y * MAP_W + x] = door_word[(mask, doors | side)] | WORD_ATTRIB

    # ---- Emit ROM data ----------------------------------------------------
    tilemap_bytes = b"".join(
        struct.pack("<%dH" % (MAP_W * MAP_H), *tilemap) for tilemap in tilemaps)

    bounds = bytearray()
    for area in range(len(AREAS)):
        cells = area_cells[area]
        if cells:
            bounds += bytes((min(x for x, _ in cells), max(x for x, _ in cells),
                             min(y for _, y in cells), max(y for _, y in cells)))
        else:
            bounds += bytes((0xFF, 0x00, 0xFF, 0x00))

    seed_id = zlib.crc32(tilemap_bytes + bytes(bounds)) & 0xFFFFFFFF
    SEED_OUT.write_bytes(struct.pack("<I", seed_id))
    BOUNDS_OUT.write_bytes(bytes(bounds))
    TILEMAPS_OUT.write_bytes(tilemap_bytes)

    write_preview(tilemaps, lookup)

    char_base = lookup["groupTileBases"]
    char_count = lookup["groupTileCounts"]
    counts_of = lambda area, base, size: sum(
        1 for w in tilemaps[area]
        if w and base <= (w & 0x03FF) < base + size)
    for area, name in enumerate(AREAS):
        count = len(area_cells[area])
        b = bounds[area * 4:area * 4 + 4]
        print(f"{name:9} {count:3} cells, bounds x {b[0]:2}-{b[1]:2}, y {b[2]:2}-{b[3]:2}, "
              f"items {counts_of(area, char_base['item'], char_count['item']):2}, "
              f"elevators {counts_of(area, char_base['elevator'], char_count['elevator'])}, "
              f"bosses {counts_of(area, char_base['boss'], char_count['boss'])}, "
              f"doors {counts_of(area, char_base['door'], char_count['door']):2}")
    print(f"Seed id ${seed_id:08X}")
    if orphans:
        print(f"WARNING: {len(orphans)} unassigned cells with rooms: {orphans}")
    for path in (SEED_OUT, BOUNDS_OUT, TILEMAPS_OUT, PREVIEW_OUT):
        print(f"Wrote {path.relative_to(ROOT)}")


# ---- Preview rendering -----------------------------------------------------

def write_preview(tilemaps: list[list[int]], lookup: dict) -> None:
    tile_data = TILES_2BPP_PATH.read_bytes()
    base = lookup["groupTileBases"]["topology"]

    def tile_pixels(char: int) -> list[list[int]]:
        off = (char - base) * 16
        rows = []
        for y in range(8):
            p0, p1 = tile_data[off + y * 2], tile_data[off + y * 2 + 1]
            rows.append([((p0 >> (7 - x)) & 1) | (((p1 >> (7 - x)) & 1) << 1)
                         for x in range(8)])
        return rows

    scale, gap = 3, 8
    panel = MAP_W * 8 * scale
    width = len(tilemaps) * (panel + gap) - gap
    height = MAP_H * 8 * scale
    palette = ((22, 24, 33), (62, 138, 201), (224, 230, 234), (255, 188, 44))
    background = (10, 10, 14)
    rgb = bytearray(background * (width * height))

    for area, tilemap in enumerate(tilemaps):
        panel_x = area * (panel + gap)
        for cy in range(MAP_H):
            for cx in range(MAP_W):
                word = tilemap[cy * MAP_W + cx]
                if word == 0:
                    continue
                pixels = tile_pixels(word & 0x03FF)
                if word & lookup["tilemapWord"]["hFlipMask"]:
                    pixels = [row[::-1] for row in pixels]
                if word & lookup["tilemapWord"]["vFlipMask"]:
                    pixels = pixels[::-1]
                for py, row in enumerate(pixels):
                    for px, colour in enumerate(row):
                        x0 = panel_x + (cx * 8 + px) * scale
                        y0 = (cy * 8 + py) * scale
                        for sy in range(scale):
                            off = ((y0 + sy) * width + x0) * 3
                            rgb[off:off + 3 * scale] = bytes(palette[colour]) * scale
    def chunk(kind: bytes, data: bytes) -> bytes:
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF))

    stride = width * 3
    raw = b"".join(b"\x00" + bytes(rgb[y * stride:(y + 1) * stride]) for y in range(height))
    PREVIEW_OUT.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b""))


if __name__ == "__main__":
    main()
