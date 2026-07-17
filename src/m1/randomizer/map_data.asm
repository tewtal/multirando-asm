; ============================================================================
; Metroid 1 automap data format
; ============================================================================
;
; ROM data is fixed-size and uncompressed. The randomizer patches the header,
; five area bounds records, and five 32x32 SNES BG tilemaps.
; Every map cell is the final little-endian 16-bit tilemap word:
;
;   bits  0-9  BG3 character number
;   bits 10-12 palette
;   bit     13 priority
;   bit     14 horizontal flip
;   bit     15 vertical flip
;
; Runtime rendering copies words and changes their palette. The seed generator
; selects symmetry-reduced room, door, item, elevator, boss, and portal tiles.
; Word $0000 is blank.
;
; Bounds records are four bytes: min X, max X, min Y, max Y. An empty/default
; area uses $FF,$00,$FF,$00. The four-byte seed ID must change whenever the
; generated maps change so stale explored SRAM is cleared automatically.
;

!M1_MAP_FORMAT_VERSION = $03
!M1_MAP_AREA_COUNT = 5
!M1_MAP_WIDTH = 32
!M1_MAP_HEIGHT = 32
!M1_MAP_CELLS_PER_AREA = $0400
!M1_MAP_ENTRY_BYTES = 2
!M1_MAP_BYTES_PER_AREA = $0800
!M1_MAP_VISITED_BYTES_PER_AREA = $0080

; Automap graphics immediately follow the 256-character overlay font.
; Counts: 5 topology, 5 item, 3 elevator, 2 boss, 5 portal, 7 door,
; 5 map station.
; M1 rooms use one scroll axis only, so maps contain only closed, end-cap,
; vertical, and horizontal cells. Doors remain east/west only; their vertical
; room variants cover single or double side doors with one or two vertical
; openings. Elevator $10A is down+west-door (H-flippable), $10B is the shaft
; top with an open south edge, and $10C is the north/south shaft segment.
; Boss $10D has one west door (H-flippable) and $10E has doors on both ends.
; Overlay-font characters $000-$0FF are always-visible text markers.
!M1_MAP_BG3_TEXT_TILE_COUNT = $0100
!M1_MAP_BG3_TOPOLOGY_TILE_BASE = $0100
!M1_MAP_BG3_ITEM_TILE_BASE = $0105
!M1_MAP_BG3_ELEVATOR_TILE_BASE = $010A
!M1_MAP_BG3_BOSS_TILE_BASE = $010D
!M1_MAP_BG3_PORTAL_TILE_BASE = $010F
!M1_MAP_BG3_DOOR_TILE_BASE = $0114
; Map-station cells render even when unvisited and unrevealed so players can
; find the map item on randomized layouts.
!M1_MAP_BG3_MAPSTATION_TILE_BASE = $011B
!M1_MAP_MAPSTATION_TILE_COUNT = $0005
!M1_MAP_BG3_TILE_COUNT = $0020

!M1_MAP_TILE_CHARACTER_MASK = $03FF
!M1_MAP_TILE_PALETTE_MASK = $1C00
!M1_MAP_TILE_PRIORITY = $2000
!M1_MAP_TILE_HFLIP = $4000
!M1_MAP_TILE_VFLIP = $8000

; Persistent cart RAM. Each visited plane is aligned to $80 bytes:
;   Brinstar $7980-$79FF, Norfair $7A00-$7A7F, Kraid $7A80-$7AFF,
;   Tourian $7B00-$7B7F, Ridley $7B80-$7BFF.
!M1_MAP_STATE_BASE = $7900
!M1_MAP_STATE_MAGIC = !M1_MAP_STATE_BASE
!M1_MAP_STATE_VERSION = !M1_MAP_STATE_BASE+$04
!M1_MAP_STATE_REVEALED_AREAS = !M1_MAP_STATE_BASE+$05
!M1_MAP_STATE_SEEN_AREAS = !M1_MAP_STATE_BASE+$06
!M1_MAP_STATE_SEED_ID = !M1_MAP_STATE_BASE+$08
!M1_MAP_VISITED_BASE = $7980
!M1_MAP_STATE_END = $7C00

M1MapStateMagic = !M1_MAP_STATE_MAGIC
M1MapStateVersion = !M1_MAP_STATE_VERSION
M1MapRevealedAreas = !M1_MAP_STATE_REVEALED_AREAS
M1MapSeenAreas = !M1_MAP_STATE_SEEN_AREAS
M1MapStateSeedId = !M1_MAP_STATE_SEED_ID
M1MapBrinstarVisited = !M1_MAP_VISITED_BASE
M1MapNorfairVisited = !M1_MAP_VISITED_BASE+$0080
M1MapKraidVisited = !M1_MAP_VISITED_BASE+$0100
M1MapTourianVisited = !M1_MAP_VISITED_BASE+$0180
M1MapRidleyVisited = !M1_MAP_VISITED_BASE+$0200

; Seed-facing ROM header. Offsets are stable and may be patched directly:
;   +$00  "M1MP"
;   +$04  format version
;   +$05  area count
;   +$06  width
;   +$07  height
;   +$08  bytes per area (word)
;   +$0A  bytes per map entry ($02)
;   +$0B  tile encoding ($02 = direct SNES BG tilemap words)
;   +$0C  four-byte seed/map identity
org $989000
M1MapDataHeader:
    db $4D,$31,$4D,$50
    db !M1_MAP_FORMAT_VERSION,!M1_MAP_AREA_COUNT,!M1_MAP_WIDTH,!M1_MAP_HEIGHT
    dw !M1_MAP_BYTES_PER_AREA
    db !M1_MAP_ENTRY_BYTES,$02
; Default data comes from resources/metroid.nes. The seed generator replaces
; the seed ID, bounds, and tilemaps for randomized maps.
M1MapSeedId:
    incbin ../../data/m1_map_vanilla_seed.bin

; Area order matches m1_CurrentArea-$10:
; Brinstar, Norfair, Kraid, Tourian, Ridley.
M1MapAreaBounds:
    incbin ../../data/m1_map_vanilla_bounds.bin

; Initial revealed-areas mask, copied into the persistent reveal/seen bytes when
; the automap state resets for a new seed. Vanilla-layout seeds patch this to $1F
; so the whole map is visible from the start; generated maps keep $00 and reveal
; areas through their map-station pickups instead.
M1MapInitialReveal:
    db $00
assert M1MapInitialReveal == $989024

; Keep the tilemaps page-aligned and at stable addresses for the seed writer.
org $989100
M1MapTilemaps:
    ; One 32x32 tilemap per area: Brinstar, Norfair, Kraid, Tourian, Ridley.
    incbin ../../data/m1_map_vanilla_tilemaps.bin
M1MapTilemapsEnd:
assert M1MapTilemapsEnd-M1MapTilemaps == !M1_MAP_BYTES_PER_AREA*!M1_MAP_AREA_COUNT