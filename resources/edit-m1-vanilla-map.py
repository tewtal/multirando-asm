#!/usr/bin/env python3
"""Edit the built-in Metroid 1 automap data.

Run from the repository root with:

    py resources/edit-m1-vanilla-map.py

The editor works directly with the three binary files included by
src/m1/randomizer/map_data.asm. Saving writes the edited tilemaps, derives
area bounds from nonblank cells, and updates the CRC32 seed ID. Use --verify
in a non-GUI environment to check that the on-disk assets agree.
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
import zlib
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "src" / "data"
LOOKUP_PATH = DATA_DIR / "m1_map_tiles.json"
TILES_PATH = DATA_DIR / "m1_map_tiles.2bpp"
FONT_PATH = DATA_DIR / "ovl_gfx.bin"
FONT_TABLE_PATH = DATA_DIR / "tables" / "small_overlay.tbl"
SEED_PATH = DATA_DIR / "m1_map_vanilla_seed.bin"
BOUNDS_PATH = DATA_DIR / "m1_map_vanilla_bounds.bin"
TILEMAPS_PATH = DATA_DIR / "m1_map_vanilla_tilemaps.bin"

AREA_NAMES = ("Brinstar", "Norfair", "Kraid", "Tourian", "Ridley")
MAP_WIDTH = 32
MAP_HEIGHT = 32
CELLS_PER_AREA = MAP_WIDTH * MAP_HEIGHT
AREA_COUNT = len(AREA_NAMES)
WORD_ATTRIBUTES = 0x2C00
TEXT_PALETTES = (
    ("Overlay text (palette 3)", 3),
    ("Palette 0", 0),
    ("Palette 1", 1),
    ("Palette 2", 2),
    ("Palette 4", 4),
    ("Palette 5", 5),
    ("Palette 6", 6),
    ("Palette 7", 7),
)

PALETTE = (
    (10, 10, 14),
    (62, 138, 201),
    (224, 230, 234),
    (255, 188, 44),
)
UNKNOWN_TILE_COLOR = (191, 75, 75)


@dataclass(frozen=True)
class Brush:
    """A map word which can be painted, together with its palette label."""

    label: str
    word: int


class MapData:
    """The fixed-size automap payload and its derived metadata."""

    def __init__(self, tilemaps: list[list[int]]) -> None:
        self.tilemaps = tilemaps

    @classmethod
    def load(cls) -> "MapData":
        raw = TILEMAPS_PATH.read_bytes()
        expected = AREA_COUNT * CELLS_PER_AREA * 2
        if len(raw) != expected:
            raise ValueError(
                f"{TILEMAPS_PATH.relative_to(ROOT)} is {len(raw):#x} bytes; "
                f"expected {expected:#x}"
            )
        words = list(struct.unpack(f"<{AREA_COUNT * CELLS_PER_AREA}H", raw))
        return cls(
            [
                words[index * CELLS_PER_AREA:(index + 1) * CELLS_PER_AREA]
                for index in range(AREA_COUNT)
            ]
        )

    def tilemap_bytes(self) -> bytes:
        words = [word for area in self.tilemaps for word in area]
        return struct.pack(f"<{len(words)}H", *words)

    def bounds_bytes(self, character_mask: int) -> bytes:
        result = bytearray()
        for area in self.tilemaps:
            cells = [
                (index % MAP_WIDTH, index // MAP_WIDTH)
                for index, word in enumerate(area)
                if word & character_mask
            ]
            if cells:
                result.extend(
                    (
                        min(x for x, _ in cells),
                        max(x for x, _ in cells),
                        min(y for _, y in cells),
                        max(y for _, y in cells),
                    )
                )
            else:
                result.extend((0xFF, 0x00, 0xFF, 0x00))
        return bytes(result)

    def seed_id(self, character_mask: int) -> int:
        return zlib.crc32(self.tilemap_bytes() + self.bounds_bytes(character_mask)) & 0xFFFFFFFF

    def save(self, character_mask: int) -> None:
        tilemaps = self.tilemap_bytes()
        bounds = self.bounds_bytes(character_mask)
        seed = struct.pack("<I", zlib.crc32(tilemaps + bounds) & 0xFFFFFFFF)
        atomic_write(TILEMAPS_PATH, tilemaps)
        atomic_write(BOUNDS_PATH, bounds)
        atomic_write(SEED_PATH, seed)


def atomic_write(path: Path, data: bytes) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_bytes(data)
    temporary.replace(path)


def mask_label(mask: int) -> str:
    directions = ((1, "N"), (2, "E"), (4, "S"), (8, "W"))
    result = "".join(label for bit, label in directions if mask & bit)
    return result or "closed"


def brush_word(entry: dict[str, int | bool]) -> int:
    return int(entry["word"]) | WORD_ATTRIBUTES


def load_text_characters() -> dict[str, int]:
    """Load the overlay font's character-to-BG3-character mapping."""
    characters = {}
    for line in FONT_TABLE_PATH.read_text(encoding="ascii").splitlines():
        word, character = line.split("=", 1)
        if len(character) == 1:
            characters[character] = int(word, 16) & 0x03FF
    return characters


def build_brushes(lookup: dict) -> list[Brush]:
    brushes = [Brush("Blank", 0)]
    for entry in lookup["topology"]:
        brushes.append(Brush(f"Room {mask_label(entry['connections'])}", brush_word(entry)))
    for feature in ("item", "portal"):
        for entry in lookup["features"][feature]:
            brushes.append(
                Brush(
                    f"{feature.title()} {mask_label(entry['connections'])}",
                    brush_word(entry),
                )
            )
    for entry in lookup["elevators"]:
        if entry["kind"] == "entrance":
            label = f"Elevator down {entry['sideDoor']}"
        elif entry["kind"] == "shaftTop":
            label = "Elevator shaft top"
        else:
            label = "Elevator shaft"
        brushes.append(Brush(label, brush_word(entry)))
    for entry in lookup["bosses"]:
        brushes.append(Brush(f"Boss {mask_label(entry['doors'])}", brush_word(entry)))
    for entry in lookup["doors"]:
        brushes.append(
            Brush(
                f"Door {mask_label(entry['connections'])} / {mask_label(entry['doors'])}",
                brush_word(entry),
            )
        )
    return brushes


def load_lookup() -> dict:
    lookup = json.loads(LOOKUP_PATH.read_text(encoding="utf-8"))
    rom_map = lookup["romMap"]
    if (rom_map["width"], rom_map["height"], rom_map["areaBytes"]) != (
        MAP_WIDTH,
        MAP_HEIGHT,
        CELLS_PER_AREA * 2,
    ):
        raise ValueError("m1_map_tiles.json does not describe the expected 32x32 map format")
    return lookup


def verify_assets(lookup: dict) -> list[str]:
    errors: list[str] = []
    try:
        map_data = MapData.load()
    except (OSError, ValueError) as error:
        return [str(error)]

    character_mask = int(lookup["tilemapWord"]["characterMask"])
    expected_bounds = map_data.bounds_bytes(character_mask)
    expected_seed = struct.pack("<I", map_data.seed_id(character_mask))
    for path, expected in ((BOUNDS_PATH, expected_bounds), (SEED_PATH, expected_seed)):
        try:
            actual = path.read_bytes()
        except OSError as error:
            errors.append(str(error))
            continue
        if actual != expected:
            errors.append(
                f"{path.relative_to(ROOT)} is stale; save it with edit-m1-vanilla-map.py"
            )
    return errors


class MapEditor:
    """A compact Tk editor for the five map planes."""

    def __init__(self, root, lookup: dict, map_data: MapData) -> None:
        import tkinter as tk
        from tkinter import messagebox, ttk

        self.root = root
        self.tk = tk
        self.ttk = ttk
        self.messagebox = messagebox
        self.lookup = lookup
        self.map_data = map_data
        self.character_mask = int(lookup["tilemapWord"]["characterMask"])
        self.h_flip_mask = int(lookup["tilemapWord"]["hFlipMask"])
        self.v_flip_mask = int(lookup["tilemapWord"]["vFlipMask"])
        self.tile_base = int(lookup["groupTileBases"]["topology"])
        self.tile_count = int(lookup["tileCount"])
        self.tile_data = TILES_PATH.read_bytes()
        self.font_data = FONT_PATH.read_bytes()
        self.text_characters = load_text_characters()
        if len(self.tile_data) != self.tile_count * 16:
            raise ValueError(
                f"m1_map_tiles.2bpp does not contain the expected {self.tile_count} map tiles"
            )
        if len(self.font_data) != self.tile_base * 16:
            raise ValueError("ovl_gfx.bin does not contain the expected 256 overlay font characters")

        self.brushes = build_brushes(lookup)
        self.area_index = 0
        self.brush_word = self.brushes[0].word
        self.text_words: tuple[int, ...] = ()
        self.dirty = False
        self.cell_scale = 2
        self.margin = 22
        self.map_image = None
        self.last_drag_cell: tuple[int, int] | None = None

        root.title("Metroid 1 Vanilla Automap Editor")
        root.minsize(860, 600)
        root.protocol("WM_DELETE_WINDOW", self.close)

        self.area_var = tk.StringVar(value=AREA_NAMES[0])
        self.word_var = tk.StringVar(value=f"{self.brush_word:04X}")
        self.text_var = tk.StringVar()
        self.text_palette_var = tk.StringVar(value=TEXT_PALETTES[0][0])
        self.cell_var = tk.StringVar(value="Brinstar")
        self.bounds_var = tk.StringVar()
        self.status_var = tk.StringVar()

        self.build_widgets()
        self.select_brush(0)
        self.render_map()

    @property
    def map_pixels(self) -> int:
        return MAP_WIDTH * 8 * self.cell_scale

    def build_widgets(self) -> None:
        outer = self.ttk.Frame(self.root, padding=8)
        outer.grid(sticky="nsew")
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        outer.columnconfigure(0, weight=1)
        outer.rowconfigure(1, weight=1)

        toolbar = self.ttk.Frame(outer)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(1, weight=1)
        self.ttk.Label(toolbar, text="Area").grid(row=0, column=0, sticky="w")
        area_picker = self.ttk.Combobox(
            toolbar,
            state="readonly",
            values=AREA_NAMES,
            textvariable=self.area_var,
            width=12,
        )
        area_picker.grid(row=0, column=1, sticky="w", padx=(6, 18))
        area_picker.bind("<<ComboboxSelected>>", self.change_area)
        self.ttk.Button(toolbar, text="Save", command=self.save).grid(row=0, column=2, padx=3)
        self.ttk.Button(toolbar, text="Reload", command=self.reload).grid(row=0, column=3, padx=3)

        map_frame = self.ttk.Frame(outer)
        map_frame.grid(row=1, column=0, sticky="nsew")
        self.canvas = self.tk.Canvas(
            map_frame,
            width=self.map_pixels + self.margin + 1,
            height=self.map_pixels + self.margin + 1,
            background="#171920",
            highlightthickness=0,
        )
        self.canvas.grid(sticky="nsew")
        self.canvas.bind("<Button-1>", self.paint_event)
        self.canvas.bind("<B1-Motion>", self.paint_event)
        self.canvas.bind("<Button-3>", self.erase_event)
        self.canvas.bind("<B3-Motion>", self.erase_event)
        self.canvas.bind("<Motion>", self.inspect_event)
        self.canvas.bind("<Leave>", self.clear_drag)

        controls = self.ttk.LabelFrame(outer, text="Tiles", padding=6)
        controls.grid(row=1, column=1, sticky="ns", padx=(10, 0))
        controls.rowconfigure(1, weight=1)
        self.brush_list = self.tk.Listbox(controls, exportselection=False, width=27, height=24)
        self.brush_list.grid(row=1, column=0, sticky="ns")
        scrollbar = self.ttk.Scrollbar(controls, orient="vertical", command=self.brush_list.yview)
        scrollbar.grid(row=1, column=1, sticky="ns")
        self.brush_list.configure(yscrollcommand=scrollbar.set)
        for brush in self.brushes:
            self.brush_list.insert("end", f"{brush.label}  ${brush.word:04X}")
        self.brush_list.bind("<<ListboxSelect>>", self.brush_selected)

        raw_frame = self.ttk.Frame(controls)
        raw_frame.grid(row=2, column=0, columnspan=2, sticky="ew", pady=(8, 0))
        self.ttk.Label(raw_frame, text="Word").grid(row=0, column=0, sticky="w")
        word_entry = self.ttk.Entry(raw_frame, width=8, textvariable=self.word_var)
        word_entry.grid(row=0, column=1, padx=5)
        word_entry.bind("<Return>", self.use_raw_word)
        self.ttk.Button(raw_frame, text="Use", command=self.use_raw_word).grid(row=0, column=2)

        text_frame = self.ttk.Frame(controls)
        text_frame.grid(row=3, column=0, columnspan=2, sticky="ew", pady=(8, 0))
        self.ttk.Label(text_frame, text="Text").grid(row=0, column=0, sticky="w")
        text_entry = self.ttk.Entry(text_frame, width=12, textvariable=self.text_var)
        text_entry.grid(row=0, column=1, padx=5)
        text_entry.bind("<Return>", self.use_text)
        self.ttk.Button(text_frame, text="Paint", command=self.use_text).grid(row=0, column=2)
        self.ttk.Label(text_frame, text="Palette").grid(row=1, column=0, sticky="w", pady=(4, 0))
        self.ttk.Combobox(
            text_frame,
            state="readonly",
            values=tuple(label for label, _ in TEXT_PALETTES),
            textvariable=self.text_palette_var,
            width=20,
        ).grid(row=1, column=1, columnspan=2, sticky="w", padx=5, pady=(4, 0))

        footer = self.ttk.Frame(outer)
        footer.grid(row=2, column=0, columnspan=2, sticky="ew", pady=(6, 0))
        footer.columnconfigure(0, weight=1)
        self.ttk.Label(footer, textvariable=self.cell_var).grid(row=0, column=0, sticky="w")
        self.ttk.Label(footer, textvariable=self.bounds_var).grid(row=0, column=1, sticky="e")
        self.ttk.Label(footer, textvariable=self.status_var).grid(
            row=1, column=0, columnspan=2, sticky="w", pady=(3, 0)
        )

    def change_area(self, _event=None) -> None:
        self.area_index = AREA_NAMES.index(self.area_var.get())
        self.last_drag_cell = None
        self.render_map()

    def brush_selected(self, _event=None) -> None:
        selection = self.brush_list.curselection()
        if selection:
            self.select_brush(selection[0])

    def select_brush(self, index: int) -> None:
        self.brush_word = self.brushes[index].word
        self.text_words = ()
        self.word_var.set(f"{self.brush_word:04X}")
        self.brush_list.selection_clear(0, "end")
        self.brush_list.selection_set(index)
        self.brush_list.activate(index)
        self.status_var.set(f"Brush: {self.brushes[index].label}")

    def use_raw_word(self, _event=None) -> None:
        text = self.word_var.get().strip().removeprefix("$").removeprefix("0x")
        try:
            word = int(text, 16)
        except ValueError:
            self.messagebox.showerror("Invalid word", "Enter a hexadecimal value from 0000 to FFFF.")
            return
        if not 0 <= word <= 0xFFFF:
            self.messagebox.showerror("Invalid word", "Enter a hexadecimal value from 0000 to FFFF.")
            return
        self.brush_word = word
        self.text_words = ()
        self.word_var.set(f"{word:04X}")
        self.brush_list.selection_clear(0, "end")
        self.status_var.set(f"Brush: raw ${word:04X}")

    def use_text(self, _event=None) -> None:
        text = self.text_var.get().rstrip()
        if not text:
            self.messagebox.showerror("No text", "Enter at least one supported overlay-font character.")
            return
        unsupported = sorted({character for character in text if character not in self.text_characters})
        if unsupported:
            self.messagebox.showerror(
                "Unsupported text",
                f"The overlay font has no glyph for: {''.join(unsupported)}",
            )
            return
        palette = next(
            palette
            for label, palette in TEXT_PALETTES
            if label == self.text_palette_var.get()
        )
        attributes = 0x2000 | (palette << 10)
        self.text_words = tuple(self.text_characters[character] | attributes for character in text)
        self.brush_list.selection_clear(0, "end")
        self.last_drag_cell = None
        self.status_var.set(f'Text brush: "{text}" ({self.text_palette_var.get()})')

    def canvas_cell(self, event) -> tuple[int, int] | None:
        x = (event.x - self.margin) // (8 * self.cell_scale)
        y = (event.y - self.margin) // (8 * self.cell_scale)
        if 0 <= x < MAP_WIDTH and 0 <= y < MAP_HEIGHT:
            return x, y
        return None

    def paint_event(self, event) -> None:
        cell = self.canvas_cell(event)
        if self.text_words:
            self.paint_text(cell)
        else:
            self.paint_cell(cell, self.brush_word)

    def erase_event(self, event) -> None:
        self.paint_cell(self.canvas_cell(event), 0)

    def paint_cell(self, cell: tuple[int, int] | None, word: int) -> None:
        if cell is None or cell == self.last_drag_cell:
            return
        self.last_drag_cell = cell
        x, y = cell
        index = y * MAP_WIDTH + x
        area = self.map_data.tilemaps[self.area_index]
        if area[index] == word:
            return
        area[index] = word
        self.dirty = True
        self.render_map()
        self.cell_var.set(f"{AREA_NAMES[self.area_index]} ({x}, {y})  ${word:04X}")

    def paint_text(self, cell: tuple[int, int] | None) -> None:
        if cell is None or cell == self.last_drag_cell:
            return
        self.last_drag_cell = cell
        x, y = cell
        words = self.text_words[:MAP_WIDTH - x]
        area = self.map_data.tilemaps[self.area_index]
        changed = False
        for offset, word in enumerate(words):
            index = y * MAP_WIDTH + x + offset
            if area[index] != word:
                area[index] = word
                changed = True
        if not changed:
            return
        self.dirty = True
        self.render_map()
        end_x = x + len(words) - 1
        self.cell_var.set(f"{AREA_NAMES[self.area_index]} ({x}-{end_x}, {y})  text")

    def inspect_event(self, event) -> None:
        cell = self.canvas_cell(event)
        if cell is None:
            return
        x, y = cell
        word = self.map_data.tilemaps[self.area_index][y * MAP_WIDTH + x]
        self.cell_var.set(f"{AREA_NAMES[self.area_index]} ({x}, {y})  ${word:04X}")

    def clear_drag(self, _event=None) -> None:
        self.last_drag_cell = None

    def tile_pixels(self, word: int) -> list[list[int]] | None:
        character = word & self.character_mask
        if character < self.tile_base:
            tile_data = self.font_data
            offset = character * 16
        else:
            tile_data = self.tile_data
            offset = (character - self.tile_base) * 16
        if offset < 0 or offset + 16 > len(tile_data):
            return None
        pixels = []
        for y in range(8):
            plane_zero, plane_one = tile_data[offset + y * 2:offset + y * 2 + 2]
            pixels.append(
                [
                    ((plane_zero >> (7 - x)) & 1) | (((plane_one >> (7 - x)) & 1) << 1)
                    for x in range(8)
                ]
            )
        if word & self.h_flip_mask:
            pixels = [row[::-1] for row in pixels]
        if word & self.v_flip_mask:
            pixels.reverse()
        return pixels

    def render_map(self) -> None:
        pixels = bytearray()
        area = self.map_data.tilemaps[self.area_index]
        for cell_y in range(MAP_HEIGHT):
            rows = [bytearray() for _ in range(8)]
            for cell_x in range(MAP_WIDTH):
                word = area[cell_y * MAP_WIDTH + cell_x]
                tile = self.tile_pixels(word) if word else None
                for pixel_y in range(8):
                    color_row = rows[pixel_y]
                    for pixel_x in range(8):
                        if word and tile is None:
                            color = UNKNOWN_TILE_COLOR if (pixel_x + pixel_y) % 2 else PALETTE[0]
                        else:
                            color = PALETTE[tile[pixel_y][pixel_x]] if tile else PALETTE[0]
                        color_row.extend(color * self.cell_scale)
            for row in rows:
                for _ in range(self.cell_scale):
                    pixels.extend(row)

        header = f"P6\n{self.map_pixels} {self.map_pixels}\n255\n".encode("ascii")
        self.map_image = self.tk.PhotoImage(data=header + bytes(pixels), format="PPM")
        self.canvas.delete("all")
        self.canvas.create_image(self.margin, self.margin, anchor="nw", image=self.map_image)
        cell_pixels = 8 * self.cell_scale
        for position in range(MAP_WIDTH + 1):
            offset = self.margin + position * cell_pixels
            self.canvas.create_line(offset, self.margin, offset, self.margin + self.map_pixels, fill="#343847")
            self.canvas.create_line(self.margin, offset, self.margin + self.map_pixels, offset, fill="#343847")
        for position in range(0, MAP_WIDTH, 4):
            offset = self.margin + position * cell_pixels
            self.canvas.create_text(offset + 1, 10, text=f"{position:X}", fill="#c8cad3", anchor="n")
            self.canvas.create_text(10, offset + 1, text=f"{position:X}", fill="#c8cad3", anchor="w")
        self.update_bounds_label()

    def update_bounds_label(self) -> None:
        bounds = self.map_data.bounds_bytes(self.character_mask)
        offset = self.area_index * 4
        left, right, top, bottom = bounds[offset:offset + 4]
        if left == 0xFF:
            self.bounds_var.set("Bounds: empty")
        else:
            self.bounds_var.set(f"Bounds: x {left}-{right}, y {top}-{bottom}")

    def save(self) -> None:
        try:
            self.map_data.save(self.character_mask)
        except OSError as error:
            self.messagebox.showerror("Save failed", str(error))
            return
        self.dirty = False
        self.status_var.set(
            f"Saved map data; seed ${self.map_data.seed_id(self.character_mask):08X}"
        )

    def reload(self) -> None:
        if self.dirty and not self.messagebox.askyesno(
            "Discard changes", "Reload the map data and discard unsaved edits?"
        ):
            return
        try:
            self.map_data = MapData.load()
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Reload failed", str(error))
            return
        self.dirty = False
        self.last_drag_cell = None
        self.status_var.set("Reloaded map data")
        self.render_map()

    def close(self) -> None:
        if self.dirty and not self.messagebox.askyesno(
            "Unsaved changes", "Close without saving the edited map data?"
        ):
            return
        self.root.destroy()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Edit or validate the vanilla M1 automap assets.")
    parser.add_argument(
        "--verify",
        action="store_true",
        help="verify tilemap size plus the derived bounds and seed ID without opening the editor",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        lookup = load_lookup()
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    if args.verify:
        errors = verify_assets(lookup)
        if errors:
            for error in errors:
                print(f"error: {error}", file=sys.stderr)
            return 1
        print("M1 vanilla map assets are valid.")
        return 0

    try:
        import tkinter as tk

        root = tk.Tk()
        MapEditor(root, lookup, MapData.load())
        root.mainloop()
    except (OSError, ValueError, tk.TclError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())