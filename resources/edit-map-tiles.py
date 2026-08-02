#!/usr/bin/env python3
"""Graphical editor for the map tile sheets (M1 automap + SM map/minimap).

Edits these files in place:

  src/data/m1_map_tiles.2bpp     M1 automap tiles, 2bpp, BG3 characters $100+.
                                 Group names/bases come from m1_map_tiles.json.
                                 This sheet can be EXTENDED (append rows) to
                                 create new tiles; the overlay DMA in
                                 src/common/nes/overlay.asm sizes itself from
                                 the file, and saving keeps "tileCount" in
                                 m1_map_tiles.json in sync.
  src/data/sm-maptiles.bin       SM pause-map tiles, 4bpp, characters
                                 $000-$1FF. $000-$0FF are regular map tiles
                                 (also drawn on the minimap), $100+ are
                                 pause-only deco tiles.
  src/data/sm-maptiles2.bin      SM pause-map tile page 2, 4bpp, characters
                                 $300-$3FF. Loaded into VRAM word $3000 by
                                 src/m3/randomizer/pause_map_tiles2.asm.
  src/data/sm-minimaptiles.bin   SM HUD minimap tiles, 2bpp, 1024 entries.
                                 Indexed by the SAME character number as the
                                 pause-map sheets, so a map dot needs a tile at
                                 the same character in both the pause sheet
                                 ($000-$1FF sheet 1, $300-$3FF sheet 2) and
                                 the minimap sheet.

Usage:  py resources/edit-map-tiles.py

  Left click / drag       select tile(s) in a sheet (drag or shift-click for a block)
  Ctrl+C / Ctrl+V         copy / paste the selected tile block (works across
                          sheets; colours above a 2bpp sheet's range clamp to 3)
  Ctrl+Z                  undo (per sheet)
  Ctrl+S                  save all modified sheets
  1-4                     pick draw colour 0-3 (click a swatch for colours 4-15)
  Editor: left drag paint, right drag erase (colour 0), Ctrl+click pick colour
  Double-click a palette swatch to change its display colour (display only,
  nothing palette-related is written to disk).
"""

from __future__ import annotations

import json
from pathlib import Path

import tkinter as tk
from tkinter import colorchooser, messagebox, ttk


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "src" / "data"

TILE_SIZE = 8
GRID_COLS = 16

SHEET_SPECS = [
    {
        "key": "m1",
        "title": "M1 automap",
        "path": DATA_DIR / "m1_map_tiles.2bpp",
        "bpp": 2,
        "char_base": 0x100,
        "zoom": 6,
        "extendable": True,
        "palette": ["#12141b", "#3e8ac9", "#e0e6ea", "#ffbc2c"],
        "counterparts": [],
    },
    {
        "key": "smmap",
        "title": "SM map",
        "path": DATA_DIR / "sm-maptiles.bin",
        "bpp": 4,
        "char_base": 0x000,
        "zoom": 3,
        "extendable": False,
        "palette": [
            "#000010", "#d84890", "#f8f8f8", "#f8d820",
            "#4048d8", "#40b0f8", "#38a048", "#80e880",
            "#d84040", "#f89050", "#8850c8", "#c8a0f8",
            "#684830", "#b09070", "#606878", "#b8c0d0",
        ],
        "counterparts": ["smmini"],
    },
    {
        "key": "smmap2",
        "title": "SM map p2",
        "path": DATA_DIR / "sm-maptiles2.bin",
        "bpp": 4,
        "char_base": 0x300,
        "zoom": 3,
        "extendable": False,
        "palette": [
            "#000010", "#d84890", "#f8f8f8", "#f8d820",
            "#4048d8", "#40b0f8", "#38a048", "#80e880",
            "#d84040", "#f89050", "#8850c8", "#c8a0f8",
            "#684830", "#b09070", "#606878", "#b8c0d0",
        ],
        "counterparts": ["smmini"],
    },
    {
        "key": "smmini",
        "title": "SM minimap",
        "path": DATA_DIR / "sm-minimaptiles.bin",
        "bpp": 2,
        "char_base": 0x000,
        "zoom": 4,
        "extendable": False,
        "palette": ["#001018", "#4f8a56", "#e8f8e8", "#f8d800"],
        "counterparts": ["smmap", "smmap2"],
    },
]

M1_LOOKUP_PATH = DATA_DIR / "m1_map_tiles.json"

EDITOR_CELL = 36
UNDO_LIMIT = 100


def decode_tile(data: bytes, index: int, bpp: int) -> list[list[int]]:
    """Decode one SNES 2bpp/4bpp tile into 8 rows of 8 pixel values."""
    tile_bytes = TILE_SIZE * bpp
    offset = index * tile_bytes
    rows = []
    for y in range(TILE_SIZE):
        planes = [
            data[offset + (plane // 2) * 16 + y * 2 + (plane & 1)]
            for plane in range(bpp)
        ]
        row = []
        for x in range(TILE_SIZE):
            bit = 7 - x
            row.append(
                sum(((plane >> bit) & 1) << p for p, plane in enumerate(planes))
            )
        rows.append(row)
    return rows


def encode_tile(pixels: list[list[int]], bpp: int) -> bytes:
    encoded = bytearray(TILE_SIZE * bpp)
    for y, row in enumerate(pixels):
        for x, colour in enumerate(row):
            bit = 7 - x
            for plane in range(bpp):
                if (colour >> plane) & 1:
                    encoded[(plane // 2) * 16 + y * 2 + (plane & 1)] |= 1 << bit
    return bytes(encoded)


def load_m1_groups() -> list[tuple[int, int, str]]:
    """Return (char_base, count, name) for every M1 tile group, sorted."""
    try:
        lookup = json.loads(M1_LOOKUP_PATH.read_text(encoding="utf-8"))
        bases = lookup["groupTileBases"]
        counts = lookup["groupTileCounts"]
    except (OSError, KeyError, ValueError):
        return []
    return sorted((bases[name], counts[name], name) for name in bases)


class Sheet:
    def __init__(self, spec: dict):
        self.key = spec["key"]
        self.title = spec["title"]
        self.path: Path = spec["path"]
        self.bpp: int = spec["bpp"]
        self.tile_bytes = TILE_SIZE * self.bpp
        self.colours = 1 << self.bpp
        self.char_base: int = spec["char_base"]
        self.zoom: int = spec["zoom"]
        self.extendable: bool = spec["extendable"]
        self.palette: list[str] = list(spec["palette"])
        self.counterparts: list[str] = list(spec["counterparts"])
        self.data = bytearray(self.path.read_bytes())
        if len(self.data) % self.tile_bytes:
            raise ValueError(
                f"{self.path.name} is not a whole number of {self.bpp}bpp tiles"
            )
        self.dirty = False
        self.undo_stack: list[bytes] = []
        # Selection: anchor tile index plus rectangle extent (inclusive).
        self.anchor = 0
        self.extent = 0
        self.update_geometry()

    def update_geometry(self) -> None:
        self.tile_count = len(self.data) // self.tile_bytes
        self.rows = (self.tile_count + GRID_COLS - 1) // GRID_COLS

    def tile_pixels(self, index: int) -> list[list[int]]:
        return decode_tile(self.data, index, self.bpp)

    def write_tile(self, index: int, pixels: list[list[int]]) -> None:
        offset = index * self.tile_bytes
        self.data[offset : offset + self.tile_bytes] = encode_tile(pixels, self.bpp)
        self.dirty = True

    def set_pixel(self, index: int, x: int, y: int, colour: int) -> None:
        base = index * self.tile_bytes
        bit = 7 - x
        for plane in range(self.bpp):
            offset = base + (plane // 2) * 16 + y * 2 + (plane & 1)
            if (colour >> plane) & 1:
                self.data[offset] |= 1 << bit
            else:
                self.data[offset] &= ~(1 << bit)
        self.dirty = True

    def append_tiles(self, count: int) -> None:
        self.data.extend(bytes(count * self.tile_bytes))
        self.update_geometry()
        self.dirty = True

    def push_undo(self) -> None:
        self.undo_stack.append(bytes(self.data))
        del self.undo_stack[:-UNDO_LIMIT]

    def undo(self) -> bool:
        if not self.undo_stack:
            return False
        self.data[:] = self.undo_stack.pop()
        self.update_geometry()
        self.anchor = min(self.anchor, self.tile_count - 1)
        self.extent = min(self.extent, self.tile_count - 1)
        self.dirty = True
        return True

    def selection_rect(self) -> tuple[int, int, int, int]:
        """Return (col0, row0, col1, row1), inclusive, normalised."""
        a_col, a_row = self.anchor % GRID_COLS, self.anchor // GRID_COLS
        b_col, b_row = self.extent % GRID_COLS, self.extent // GRID_COLS
        return (
            min(a_col, b_col),
            min(a_row, b_row),
            max(a_col, b_col),
            max(a_row, b_row),
        )


class TileEditor:
    def __init__(self):
        self.tk = tk.Tk()
        self.tk.title("Map tile editor")
        self.sheets = {spec["key"]: Sheet(spec) for spec in SHEET_SPECS}
        self.m1_groups = load_m1_groups()
        self.draw_colour = 3
        self.clipboard: dict | None = None
        # Per-sheet UI: canvas, PhotoImage, selection rectangle item.
        self.views: dict[str, dict] = {}
        self.current_key = SHEET_SPECS[0]["key"]
        self.build_ui()
        for key in self.sheets:
            self.redraw_sheet(key)
        self.select_tile(self.current_sheet(), 0)
        self.tk.protocol("WM_DELETE_WINDOW", self.on_close)

    # ------------------------------------------------------------------ UI --

    def build_ui(self) -> None:
        root = self.tk
        root.columnconfigure(0, weight=1)
        root.rowconfigure(0, weight=1)

        self.notebook = ttk.Notebook(root)
        self.notebook.grid(row=0, column=0, sticky="nsew", padx=(6, 0), pady=6)
        self.notebook.bind("<<NotebookTabChanged>>", self.on_tab_changed)

        for spec in SHEET_SPECS:
            sheet = self.sheets[spec["key"]]
            frame = ttk.Frame(self.notebook)
            frame.columnconfigure(0, weight=1)
            frame.rowconfigure(0, weight=1)
            self.notebook.add(
                frame, text=f"{sheet.title}  ({sheet.path.name}, {sheet.bpp}bpp)"
            )

            canvas = tk.Canvas(frame, background="#0b0c10", highlightthickness=0)
            vbar = ttk.Scrollbar(frame, orient="vertical", command=canvas.yview)
            hbar = ttk.Scrollbar(frame, orient="horizontal", command=canvas.xview)
            canvas.configure(yscrollcommand=vbar.set, xscrollcommand=hbar.set)
            canvas.grid(row=0, column=0, sticky="nsew")
            vbar.grid(row=0, column=1, sticky="ns")
            hbar.grid(row=1, column=0, sticky="ew")

            key = spec["key"]
            canvas.bind("<Button-1>", lambda e, k=key: self.on_grid_press(k, e, extend=False))
            canvas.bind("<Shift-Button-1>", lambda e, k=key: self.on_grid_press(k, e, extend=True))
            canvas.bind("<B1-Motion>", lambda e, k=key: self.on_grid_press(k, e, extend=True))
            canvas.bind("<Motion>", lambda e, k=key: self.on_grid_hover(k, e))
            self.views[key] = {"canvas": canvas, "image": None, "frame": frame}

        panel = ttk.Frame(root, padding=8)
        panel.grid(row=0, column=1, sticky="ns", pady=6)

        self.info_var = tk.StringVar()
        ttk.Label(panel, textvariable=self.info_var, justify="left", width=34).grid(
            row=0, column=0, sticky="w"
        )

        editor_size = TILE_SIZE * EDITOR_CELL
        self.editor = tk.Canvas(
            panel,
            width=editor_size,
            height=editor_size,
            background="#000000",
            highlightthickness=1,
            highlightbackground="#555555",
        )
        self.editor.grid(row=1, column=0, pady=(6, 6))
        self.editor_cells = []
        for y in range(TILE_SIZE):
            row_cells = []
            for x in range(TILE_SIZE):
                row_cells.append(
                    self.editor.create_rectangle(
                        x * EDITOR_CELL,
                        y * EDITOR_CELL,
                        (x + 1) * EDITOR_CELL,
                        (y + 1) * EDITOR_CELL,
                        outline="#2c2f38",
                        fill="#000000",
                    )
                )
            self.editor_cells.append(row_cells)
        self.editor.bind("<Button-1>", lambda e: self.on_editor_paint(e, stroke_start=True))
        self.editor.bind("<B1-Motion>", self.on_editor_paint)
        self.editor.bind("<Button-3>", lambda e: self.on_editor_erase(e, stroke_start=True))
        self.editor.bind("<B3-Motion>", self.on_editor_erase)
        self.editor.bind("<Control-Button-1>", self.on_editor_pick)

        swatch_frame = ttk.Frame(panel)
        swatch_frame.grid(row=2, column=0, sticky="w")
        self.swatches = []
        for colour in range(16):
            swatch = tk.Canvas(
                swatch_frame,
                width=34,
                height=26,
                highlightthickness=2,
                highlightbackground="#333333",
            )
            swatch.grid(row=colour // 8, column=colour % 8, padx=(0, 2), pady=(0, 2))
            swatch.bind("<Button-1>", lambda _e, c=colour: self.set_draw_colour(c))
            swatch.bind("<Double-Button-1>", lambda _e, c=colour: self.edit_palette(c))
            swatch.create_text(18, 13, text=f"{colour:X}", fill="#888888", tags="label")
            self.swatches.append(swatch)

        buttons = ttk.Frame(panel)
        buttons.grid(row=3, column=0, sticky="w", pady=(8, 0))
        ttk.Button(buttons, text="Flip H", width=7, command=lambda: self.flip_tile(True, False)).grid(row=0, column=0)
        ttk.Button(buttons, text="Flip V", width=7, command=lambda: self.flip_tile(False, True)).grid(row=0, column=1)
        ttk.Button(buttons, text="Clear", width=7, command=self.clear_tile).grid(row=0, column=2)
        ttk.Button(buttons, text="Copy", width=7, command=self.copy_selection).grid(row=1, column=0, pady=(4, 0))
        ttk.Button(buttons, text="Paste", width=7, command=self.paste_clipboard).grid(row=1, column=1, pady=(4, 0))
        ttk.Button(buttons, text="Undo", width=7, command=self.undo).grid(row=1, column=2, pady=(4, 0))

        self.counterpart_button = ttk.Button(
            panel, text="Jump to counterpart tile", command=self.jump_to_counterpart
        )
        self.counterpart_button.grid(row=4, column=0, sticky="ew", pady=(8, 0))

        self.append_button = ttk.Button(
            panel, text="Append row of 16 tiles", command=self.append_row
        )
        self.append_button.grid(row=5, column=0, sticky="ew", pady=(8, 0))

        ttk.Button(panel, text="Save all (Ctrl+S)", command=self.save_all).grid(
            row=6, column=0, sticky="ew", pady=(8, 0)
        )

        self.status_var = tk.StringVar()
        ttk.Label(root, textvariable=self.status_var, anchor="w", padding=(8, 2)).grid(
            row=1, column=0, columnspan=2, sticky="ew"
        )

        root.bind("<Control-s>", lambda _e: self.save_all())
        root.bind("<Control-z>", lambda _e: self.undo())
        root.bind("<Control-c>", lambda _e: self.copy_selection())
        root.bind("<Control-v>", lambda _e: self.paste_clipboard())
        for digit in range(1, 5):
            root.bind(str(digit), lambda _e, c=digit - 1: self.set_draw_colour(c))

        self.update_swatches()

    # ------------------------------------------------------------ rendering --

    def current_sheet(self) -> Sheet:
        return self.sheets[self.current_key]

    def redraw_sheet(self, key: str) -> None:
        sheet = self.sheets[key]
        view = self.views[key]
        canvas: tk.Canvas = view["canvas"]
        zoom = sheet.zoom
        tile_px = TILE_SIZE * zoom
        width = GRID_COLS * tile_px
        height = sheet.rows * tile_px
        margin_left, margin_top = 48, 22

        image = tk.PhotoImage(width=width, height=height)
        view["image"] = image
        view["margins"] = (margin_left, margin_top)
        for index in range(sheet.tile_count):
            self.blit_tile(key, index)

        canvas.delete("all")
        canvas.create_image(margin_left, margin_top, anchor="nw", image=image)

        for col in range(GRID_COLS):
            canvas.create_text(
                margin_left + col * tile_px + tile_px // 2,
                margin_top // 2,
                text=f"{col:X}",
                fill="#9aa0ae",
                font=("Consolas", 8),
            )
        for row in range(sheet.rows):
            canvas.create_text(
                margin_left // 2,
                margin_top + row * tile_px + tile_px // 2,
                text=f"{sheet.char_base + row * GRID_COLS:03X}",
                fill="#9aa0ae",
                font=("Consolas", 8),
            )
        for col in range(GRID_COLS + 1):
            x = margin_left + col * tile_px
            canvas.create_line(x, margin_top, x, margin_top + height, fill="#20242e")
        for row in range(sheet.rows + 1):
            y = margin_top + row * tile_px
            canvas.create_line(margin_left, y, margin_left + width, y, fill="#20242e")

        view["selection"] = canvas.create_rectangle(
            0, 0, 0, 0, outline="#ff4040", width=2
        )
        canvas.configure(
            scrollregion=(0, 0, margin_left + width + 8, margin_top + height + 8)
        )
        self.update_selection_marker(key)

    def blit_tile(self, key: str, index: int) -> None:
        sheet = self.sheets[key]
        image: tk.PhotoImage = self.views[key]["image"]
        zoom = sheet.zoom
        pixels = sheet.tile_pixels(index)
        rows = []
        for row in pixels:
            colours = " ".join(sheet.palette[value] for value in row for _ in range(zoom))
            rows.extend(["{" + colours + "}"] * zoom)
        col, row = index % GRID_COLS, index // GRID_COLS
        image.put(" ".join(rows), to=(col * TILE_SIZE * zoom, row * TILE_SIZE * zoom))

    def update_selection_marker(self, key: str) -> None:
        sheet = self.sheets[key]
        view = self.views[key]
        margin_left, margin_top = view["margins"]
        tile_px = TILE_SIZE * sheet.zoom
        col0, row0, col1, row1 = sheet.selection_rect()
        view["canvas"].coords(
            view["selection"],
            margin_left + col0 * tile_px,
            margin_top + row0 * tile_px,
            margin_left + (col1 + 1) * tile_px,
            margin_top + (row1 + 1) * tile_px,
        )
        view["canvas"].tag_raise(view["selection"])

    def refresh_editor(self) -> None:
        sheet = self.current_sheet()
        pixels = sheet.tile_pixels(sheet.anchor)
        for y in range(TILE_SIZE):
            for x in range(TILE_SIZE):
                self.editor.itemconfigure(
                    self.editor_cells[y][x], fill=sheet.palette[pixels[y][x]]
                )
        self.info_var.set(self.describe_tile(sheet, sheet.anchor))
        counterpart_ok = self.resolve_counterpart(sheet) is not None
        self.counterpart_button.state(["!disabled"] if counterpart_ok else ["disabled"])
        self.append_button.state(["!disabled"] if sheet.extendable else ["disabled"])
        self.update_title()

    def update_swatches(self) -> None:
        sheet = self.current_sheet()
        for colour, swatch in enumerate(self.swatches):
            if colour < sheet.colours:
                swatch.grid()
                swatch.configure(background=sheet.palette[colour])
                swatch.configure(
                    highlightbackground="#ff4040"
                    if colour == self.draw_colour
                    else "#333333"
                )
            else:
                swatch.grid_remove()

    def update_title(self) -> None:
        dirty = [s.path.name for s in self.sheets.values() if s.dirty]
        marker = f"  *modified: {', '.join(dirty)}" if dirty else ""
        self.tk.title(f"Map tile editor{marker}")

    def describe_tile(self, sheet: Sheet, index: int) -> str:
        char = sheet.char_base + index
        lines = [f"{sheet.title}: tile {index} (char ${char:03X})"]
        if sheet.key == "m1":
            for base, count, name in self.m1_groups:
                if base <= char < base + count:
                    lines.append(f"group: {name} +{char - base}")
                    break
            else:
                lines.append("new tile (no group in JSON yet)")
        elif sheet.key == "smmap":
            if char < 0x100:
                lines.append("map tile (mirrored by minimap char)")
            else:
                lines.append("deco tile (pause map only)")
        elif sheet.key == "smmap2":
            lines.append("page-2 map tile (pause + minimap char)")
        elif sheet.key == "smmini":
            if 0x200 <= char < 0x300:
                lines.append("minimap gfx (no pause char: sprite page)")
            else:
                lines.append(f"minimap gfx for map char ${char:03X}")
        col0, row0, col1, row1 = sheet.selection_rect()
        if (col0, row0) != (col1, row1):
            lines.append(f"selection: {col1 - col0 + 1}x{row1 - row0 + 1} tiles")
        if self.clipboard:
            lines.append(
                f"clipboard: {self.clipboard['w']}x{self.clipboard['h']} tiles"
            )
        return "\n".join(lines)

    # ----------------------------------------------------------- grid input --

    def grid_tile_at(self, key: str, event) -> int | None:
        sheet = self.sheets[key]
        view = self.views[key]
        canvas: tk.Canvas = view["canvas"]
        margin_left, margin_top = view["margins"]
        tile_px = TILE_SIZE * sheet.zoom
        x = canvas.canvasx(event.x) - margin_left
        y = canvas.canvasy(event.y) - margin_top
        col, row = int(x // tile_px), int(y // tile_px)
        if x < 0 or y < 0 or col >= GRID_COLS or row >= sheet.rows:
            return None
        index = row * GRID_COLS + col
        return index if index < sheet.tile_count else None

    def on_grid_press(self, key: str, event, extend: bool) -> None:
        index = self.grid_tile_at(key, event)
        if index is None:
            return
        sheet = self.sheets[key]
        if extend:
            sheet.extent = index
        else:
            sheet.anchor = index
            sheet.extent = index
        self.update_selection_marker(key)
        self.refresh_editor()

    def on_grid_hover(self, key: str, event) -> None:
        index = self.grid_tile_at(key, event)
        if index is None:
            self.status_var.set("")
            return
        sheet = self.sheets[key]
        self.status_var.set(
            self.describe_tile(sheet, index).replace("\n", "  |  ")
        )

    def on_tab_changed(self, _event) -> None:
        tab = self.notebook.index(self.notebook.select())
        self.current_key = SHEET_SPECS[tab]["key"]
        sheet = self.current_sheet()
        if self.draw_colour >= sheet.colours:
            self.draw_colour = sheet.colours - 1
        self.update_swatches()
        self.refresh_editor()

    def select_tile(self, sheet: Sheet, index: int) -> None:
        sheet.anchor = sheet.extent = max(0, min(index, sheet.tile_count - 1))
        self.update_selection_marker(sheet.key)
        self.refresh_editor()

    # --------------------------------------------------------- editor input --

    def editor_pixel_at(self, event) -> tuple[int, int] | None:
        x, y = event.x // EDITOR_CELL, event.y // EDITOR_CELL
        if 0 <= x < TILE_SIZE and 0 <= y < TILE_SIZE:
            return x, y
        return None

    def paint_pixel(self, event, colour: int, stroke_start: bool) -> None:
        cell = self.editor_pixel_at(event)
        if cell is None:
            return
        x, y = cell
        sheet = self.current_sheet()
        if stroke_start:
            sheet.push_undo()
        sheet.set_pixel(sheet.anchor, x, y, colour)
        self.editor.itemconfigure(self.editor_cells[y][x], fill=sheet.palette[colour])
        self.blit_tile(sheet.key, sheet.anchor)
        self.update_title()

    def on_editor_paint(self, event, stroke_start: bool = False) -> None:
        if event.state & 0x0004:  # Control held: pick, not paint
            return
        self.paint_pixel(event, self.draw_colour, stroke_start)

    def on_editor_erase(self, event, stroke_start: bool = False) -> None:
        self.paint_pixel(event, 0, stroke_start)

    def on_editor_pick(self, event) -> None:
        cell = self.editor_pixel_at(event)
        if cell is None:
            return
        sheet = self.current_sheet()
        pixels = sheet.tile_pixels(sheet.anchor)
        self.set_draw_colour(pixels[cell[1]][cell[0]])

    def set_draw_colour(self, colour: int) -> None:
        if colour >= self.current_sheet().colours:
            return
        self.draw_colour = colour
        self.update_swatches()

    def edit_palette(self, colour: int) -> None:
        sheet = self.current_sheet()
        if colour >= sheet.colours:
            return
        chosen = colorchooser.askcolor(sheet.palette[colour], parent=self.tk)
        if chosen and chosen[1]:
            sheet.palette[colour] = chosen[1]
            self.update_swatches()
            self.redraw_sheet(sheet.key)
            self.refresh_editor()

    # -------------------------------------------------------------- actions --

    def flip_tile(self, h_flip: bool, v_flip: bool) -> None:
        sheet = self.current_sheet()
        sheet.push_undo()
        pixels = sheet.tile_pixels(sheet.anchor)
        rows = [row[::-1] if h_flip else row[:] for row in pixels]
        if v_flip:
            rows = rows[::-1]
        sheet.write_tile(sheet.anchor, rows)
        self.blit_tile(sheet.key, sheet.anchor)
        self.refresh_editor()

    def clear_tile(self) -> None:
        sheet = self.current_sheet()
        sheet.push_undo()
        sheet.write_tile(
            sheet.anchor, [[0] * TILE_SIZE for _ in range(TILE_SIZE)]
        )
        self.blit_tile(sheet.key, sheet.anchor)
        self.refresh_editor()

    def copy_selection(self) -> None:
        sheet = self.current_sheet()
        col0, row0, col1, row1 = sheet.selection_rect()
        tiles = []
        for row in range(row0, row1 + 1):
            tile_row = []
            for col in range(col0, col1 + 1):
                index = row * GRID_COLS + col
                tile_row.append(
                    sheet.tile_pixels(index)
                    if index < sheet.tile_count
                    else [[0] * TILE_SIZE for _ in range(TILE_SIZE)]
                )
            tiles.append(tile_row)
        self.clipboard = {
            "w": col1 - col0 + 1,
            "h": row1 - row0 + 1,
            "tiles": tiles,
            "source": sheet.title,
        }
        self.status_var.set(
            f"Copied {self.clipboard['w']}x{self.clipboard['h']} tiles from {sheet.title}"
        )
        self.refresh_editor()

    def paste_clipboard(self) -> None:
        if not self.clipboard:
            self.status_var.set("Clipboard is empty")
            return
        sheet = self.current_sheet()
        sheet.push_undo()
        base_col, base_row = sheet.anchor % GRID_COLS, sheet.anchor // GRID_COLS
        max_colour = sheet.colours - 1
        pasted = 0
        clamped = False
        for dy, tile_row in enumerate(self.clipboard["tiles"]):
            for dx, pixels in enumerate(tile_row):
                col, row = base_col + dx, base_row + dy
                if col >= GRID_COLS or row >= sheet.rows:
                    continue
                index = row * GRID_COLS + col
                if index >= sheet.tile_count:
                    continue
                if any(value > max_colour for prow in pixels for value in prow):
                    clamped = True
                sheet.write_tile(
                    index,
                    [[min(value, max_colour) for value in prow] for prow in pixels],
                )
                self.blit_tile(sheet.key, index)
                pasted += 1
        message = (
            f"Pasted {pasted} tiles from {self.clipboard['source']} into {sheet.title}"
        )
        if clamped:
            message += f" (colours clamped to 0-{max_colour})"
        self.status_var.set(message)
        self.refresh_editor()

    def undo(self) -> None:
        sheet = self.current_sheet()
        if sheet.undo():
            self.redraw_sheet(sheet.key)
            self.refresh_editor()
            self.status_var.set(f"Undid last change in {sheet.title}")
        else:
            self.status_var.set(f"Nothing to undo in {sheet.title}")

    def append_row(self) -> None:
        sheet = self.current_sheet()
        if not sheet.extendable:
            return
        sheet.push_undo()
        sheet.append_tiles(GRID_COLS)
        self.redraw_sheet(sheet.key)
        self.refresh_editor()
        first_new = sheet.char_base + sheet.tile_count - GRID_COLS
        self.status_var.set(
            f"Appended 16 blank tiles to {sheet.title}: chars "
            f"${first_new:03X}-${sheet.char_base + sheet.tile_count - 1:03X} "
            "(tileCount in the JSON updates on save)"
        )

    def resolve_counterpart(self, sheet: Sheet) -> tuple[Sheet, int] | None:
        """Find the sheet holding the other rendering of the selected character."""
        char = sheet.char_base + sheet.anchor
        for key in sheet.counterparts:
            other = self.sheets[key]
            index = char - other.char_base
            if 0 <= index < other.tile_count:
                return other, index
        return None

    def jump_to_counterpart(self) -> None:
        resolved = self.resolve_counterpart(self.current_sheet())
        if resolved is None:
            self.status_var.set("No counterpart sheet covers this character")
            return
        other, index = resolved
        for tab, spec in enumerate(SHEET_SPECS):
            if spec["key"] == other.key:
                self.notebook.select(tab)
                break
        self.select_tile(other, index)

    def sync_m1_tile_count(self) -> str | None:
        """Keep tileCount in m1_map_tiles.json matching the .2bpp file size."""
        sheet = self.sheets["m1"]
        try:
            lookup = json.loads(M1_LOOKUP_PATH.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            return None
        if lookup.get("tileCount") == sheet.tile_count:
            return None
        lookup["tileCount"] = sheet.tile_count
        M1_LOOKUP_PATH.write_text(
            json.dumps(lookup, indent=2) + "\n", encoding="utf-8"
        )
        return f"{M1_LOOKUP_PATH.name} (tileCount={sheet.tile_count})"

    def save_all(self) -> None:
        saved = []
        for sheet in self.sheets.values():
            if sheet.dirty:
                sheet.path.write_bytes(bytes(sheet.data))
                sheet.dirty = False
                saved.append(sheet.path.name)
        if saved:
            synced = self.sync_m1_tile_count()
            if synced:
                saved.append(synced)
        self.status_var.set(
            f"Saved {', '.join(saved)}" if saved else "No changes to save"
        )
        self.update_title()

    def on_close(self) -> None:
        dirty = [s.path.name for s in self.sheets.values() if s.dirty]
        if dirty:
            answer = messagebox.askyesnocancel(
                "Unsaved changes",
                f"Save changes to {', '.join(dirty)} before closing?",
                parent=self.tk,
            )
            if answer is None:
                return
            if answer:
                self.save_all()
        self.tk.destroy()

    def run(self) -> None:
        self.tk.mainloop()


def main() -> int:
    missing = [spec["path"] for spec in SHEET_SPECS if not spec["path"].exists()]
    if missing:
        for path in missing:
            print(f"missing tile sheet: {path}")
        return 1
    TileEditor().run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
