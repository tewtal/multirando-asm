import argparse
import xml.etree.ElementTree as ET
import glob
import os
import json
import base64

def parse_base_offsets(arg):
    """Parse a string like '0=0x608DB4,1=0x61007F' into {0: int, 1: int}"""
    offsets = {}
    for pair in arg.split(","):
        k, v = pair.split("=")
        set_num = int(k.strip())
        offset = int(v.strip(), 0)  # auto-detect hex (0x...) or decimal
        offsets[set_num] = offset
    return offsets

def load_tiles_from_dataxml(filename):
    tree = ET.parse(filename)
    root = tree.getroot()
    tiles = []
    for tile_node in root.findall(".//Tile"):
        tile_text = (tile_node.text or "").strip()
        vals = [int(ch) for ch in tile_text]
        if len(vals) != 64:
            raise ValueError("Each <Tile> must be exactly 64 digits (8x8).")
        tiles.append([vals[i*8:(i+1)*8] for i in range(8)])
    return tiles

def flip_x(pixels):
    for y in range(8):
        for x in range(4):
            p0 = pixels[y][x]
            p1 = pixels[y][7 - x]
            pixels[y][x] = p1
            pixels[y][7 - x] = p0

def flip_y(pixels):
    for y in range(4):
        for x in range(8):
            p0 = pixels[y][x]
            p1 = pixels[7 - y][x]
            pixels[y][x] = p1
            pixels[7 - y][x] = p0

def to_ppu_bytes(pixels8x8):
    out = [0]*16
    for y in range(8):
        v0 = v1 = 0
        for x in range(8):
            w = 0x80 >> x
            p = pixels8x8[y][x]
            if p & 1: v0 |= w
            if p & 2: v1 |= w
        out[y] = v0
        out[y+8] = v1
    return out

def load_tilemap(filename):
    tree = ET.parse(filename)
    root = tree.getroot()

    entries = []
    for ord_pos, node in enumerate(root.findall(".//Tile")):
        entries.append({
            "set": int(node.attrib["Set"]),
            "idx": int(node.attrib["Idx"]),
            "ord": ord_pos,
            "flipx": node.attrib.get("FlipX", "false").lower() == "true",
            "flipy": node.attrib.get("FlipY", "false").lower() == "true"
        })
    return entries

def contiguous_runs_by_idx(sorted_entries):
    runs = []
    if not sorted_entries:
        return runs
    cur = [sorted_entries[0]]
    for e in sorted_entries[1:]:
        if e["idx"] == cur[-1]["idx"] + 1:
            cur.append(e)
        else:
            runs.append(cur)
            cur = [e]
    runs.append(cur)
    return runs

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Output Zelda asset tiles as JavaScript array.")
    parser.add_argument("--base-offsets", required=True,
                        help="Set offsets, e.g. '0=0x608DB4,1=0x61007F'")
    parser.add_argument("--data-dir", required=True, help="Directory containing *.asset files")
    parser.add_argument("--tilemap", required=True, help="Path to tilemap.xml")
    args = parser.parse_args()

    base_offsets = parse_base_offsets(args.base_offsets)
    tilemap = load_tilemap(args.tilemap)

    asset_files = sorted(glob.glob(os.path.join(args.data_dir, "*.asset")))

    if not asset_files:
        raise FileNotFoundError(f"No .asset files found in {args.data_dir}")

    assets = []

    for asset_file in asset_files:
        data_tiles = load_tiles_from_dataxml(asset_file)

        if len(tilemap) > len(data_tiles):
            raise IndexError(
                f"TileMap has {len(tilemap)} tiles but data has only {len(data_tiles)} in {asset_file}."
            )

        writes = []
        sets = sorted({e["set"] for e in tilemap})
        for s in sets:
            if s not in base_offsets:
                raise KeyError(f"Missing base offset for Set {s}")
            subset = [e for e in tilemap if e["set"] == s]
            subset.sort(key=lambda e: e["idx"])
            for run in contiguous_runs_by_idx(subset):
                all_bytes = []
                for e in run:
                    pixels = [row[:] for row in data_tiles[e["ord"]]]
                    if e["flipx"]:
                        flip_x(pixels)
                    if e["flipy"]:
                        flip_y(pixels)
                    all_bytes.extend(to_ppu_bytes(pixels))

                start_idx = run[0]["idx"]
                offset = base_offsets[s] + start_idx * 16

                b64_string = base64.b64encode(bytes(all_bytes)).decode("ascii")

                writes.append({
                    "offset": f"0x{offset:06X}",
                    "setAndIdx": f"Set {s}, Idx {start_idx}",
                    "length": len(all_bytes),
                    "base64": b64_string
                })

                # hex_string = "".join(f"{b:02X}" for b in all_bytes)

                # writes.append({
                #     "offset": f"0x{offset:06X}",
                #     "setAndIdx": f"Set {s}, Idx {start_idx}",
                #     "length": len(all_bytes),
                #     "hex": hex_string
                # })

        tree = ET.parse(asset_file)
        root = tree.getroot()
        base_pal = ''.join(f'{int(num):02X}' for num in root.findtext(".//Data/NormalColors", "").split())
        blue_val = ''.join(f'{int(num):02X}' for num in root.findtext(".//Data/BlueRingColors", "")[:2].split())
        red_val  = ''.join(f'{int(num):02X}' for num in root.findtext(".//Data/RedRingColors", "")[:2].split())
        tunics   = f'{base_pal[:2]}{blue_val}{red_val}'
        blue_pal = ''.join(f'{int(num):02X}' for num in root.findtext(".//Data/BlueRingColors", "").split())
        red_pal  = ''.join(f'{int(num):02X}' for num in root.findtext(".//Data/RedRingColors", "").split())

        #  Write palette writes (zelda1)
        writes.append({
            "offset": [ "0x612287", "0x794325", "0x7cc325" ],
            "length": 3,
            "base64": base64.b64encode(bytes.fromhex(tunics)).decode("ascii")
        })

        writes.append({
            "offset": [ "0x631314", "0x631410", "0x63150c", "0x631608", "0x631704", "0x631800", "0x6318fc", "0x6319f8", "0x631af4", "0x631bf0", "0x631cec", "0x3d3804", "0x793804", "0x7cb804" ],
            "length": 3,
            "base64": base64.b64encode(bytes.fromhex(base_pal)).decode("ascii")
        })

        writes.append({
            "offset": [ "0x631cf0" ],
            "length": 3,
            "base64": base64.b64encode(bytes.fromhex(blue_pal)).decode("ascii")
        })
        
        writes.append({
            "offset": [ "0x631cf4" ],
            "length": 3,
            "base64": base64.b64encode(bytes.fromhex(red_pal)).decode("ascii")
        })


        # base_pal = ''.join(f'{int(num):02X}' for num in root.findtext(".//Data/NormalColors", "").split())
        # normal_pal = ''.join(f'{int(num):02X}' for num in root.findtext(".//Data/NormalColors", "").split()[1:3])
        # missile_pal  = ''.join(f'{int(num):02X}' for num in root.findtext(".//Data/NormalMslColors", "").split()[1:3])
        # varia_pal   = ''.join(f'{int(num):02X}' for num in root.findtext(".//Data/VariaColors", "").split()[1:3])
        # varia_missile_pal   = ''.join(f'{int(num):02X}' for num in root.findtext(".//Data/VariaMslColors", "").split()[1:3])

        # #  Write palette writes (metroid1)
        # writes.append({
        #     "offset": ["0x68a285", "0x68a2e8", "0x69218c", "0x6921ef", "0x69a72c", "0x69a7a5", "0x6a2169", "0x6a21a9", "0x6aa0ff", "0x6aa153"],
        #     "length": 3,
        #     "base64": base64.b64encode(bytes.fromhex(base_pal)).decode("ascii")
        # })

        # writes.append({
        #     "offset": ["0x68a298", "0x69219f", "0x69a73f", "0x6a217c", "0x6aa112"],
        #     "length": 2,
        #     "base64": base64.b64encode(bytes.fromhex(normal_pal)).decode("ascii")
        # })

        # writes.append({
        #     "offset": ["0x68a29e", "0x6921a5", "0x69a745", "0x6a2182", "0x6aa118"],
        #     "length": 2,
        #     "base64": base64.b64encode(bytes.fromhex(missile_pal)).decode("ascii")
        # })

        # writes.append({
        #     "offset": ["0x68a2a4", "0x6921ab", "0x69a74b", "0x6a2188", "0x6aa11e"],
        #     "length": 2,
        #     "base64": base64.b64encode(bytes.fromhex(varia_pal)).decode("ascii")
        # })

        # writes.append({
        #     "offset": ["0x68a2aa", "0x6921b1", "0x69a751", "0x6a218e", "0x6aa124"],
        #     "length": 2,
        #     "base64": base64.b64encode(bytes.fromhex(varia_missile_pal)).decode("ascii")
        # })

        assets.append({
            "name": root.get("Name", ""),
            "category": root.get("Category", ""),
            "creator": root.get("Creator", ""),
            "originalBy": root.get("OriginalBy", ""),
            "writes": writes
        })

    print("export default ")
    print(json.dumps(assets, indent=2))
