# Quad randomizer MSU-1 support

The ROM uses one shared MSU-1 transport in the permanent Mother Brain BW-RAM
kernel. Super Metroid, Zelda 1, and Metroid 1 submit 16-bit requests to it; the
transport is serviced once per frame. A Link to the Past retains its randomizer
MSU policy code, but uses the same track namespace and availability cache.

Create an empty `<rom-name>.msu` file and name PCM files
`<rom-name>-<decimal-track>.pcm`.

## Track ABI v1

### A Link to the Past

Tracks 1-61 retain the existing SMZ3/ALttP randomizer meanings. Track 99 is
reserved for credits. The old alternate-pack `+100` mechanism is intentionally
disabled because it collides with Super Metroid.

### Super Metroid

Tracks 101-140 retain the SMZ3 order: add 100 to the semantic SM track number.
The adapter includes the extended Kraid, Phantoon, Draygon, Ridley, Baby, hyper
beam, and game-over mappings. Extended tracks 131-139 use the shared fallback
chains when their PCM is missing. Track 141 is the map-randomizer
storm-without-music extension. Temporary item-room, boss, tension, and miniboss
tracks request the MSU-1 resume behavior used by the map-randomizer
implementation.

### Zelda 1

| Track | Use |
| ---: | --- |
| 201 | Title/demo/story |
| 202 | Overworld |
| 203 | Generic dungeon (levels 1-8) |
| 204 | Level 9 |
| 205 | Ganon/Triforce sequence |
| 206 | Triforce piece / dungeon clear |
| 207 | Zelda rescued |
| 208 | Item acquisition |
| 209 | Ending |
| 210 | Game over |
| 211-218 | Dungeon 1 through dungeon 8 |

Missing dungeon-specific tracks fall back to 203. Level 9 has its own theme
(204) and no dungeon-specific slot. Missing base tracks fall back to the
ALttP equivalents below, then to the native NES music engine.
Tune/effect/sample output is not muted, so native SFX continue over PCM
playback.

### Metroid 1

| Track | Use |
| ---: | --- |
| 301 | Intro |
| 302 | Brinstar |
| 303 | Norfair |
| 304 | Kraid hideout |
| 305 | Ridley hideout |
| 306 | Tourian |
| 307 | Item room |
| 308 | Generic boss |
| 309 | Mother Brain |
| 310 | Escape |
| 311 | Power-up |
| 312 | Ending |
| 313 | Fade-in/interlude |
| 314 | Kraid battle (falls back to 308) |
| 315 | Ridley battle (falls back to 308) |

Only music-phase APU writes are suppressed. Noise, weapon, movement, enemy, and
other SFX phases remain audible through the custom SPC driver.

## Cross-game fallback chains

When a requested PCM is absent, the transport substitutes a fallback track so
a plain SMZ3 pack (tracks 1-61 and 101-140) covers Metroid 1 and Zelda 1 too.
If the whole chain is absent, the native engine plays as before.

Fallbacks are declared as null-terminated priority chains in
`randomizer/msu_init.asm` (e.g. `dw 211,203,35,17,0`). At boot, after the
availability scan, each chain's head is resolved to its first present member
and written into a BW-RAM table; at runtime a missing track is a single table
lookup. A chain can pass through a shared node on the way to an origin-
specific one — e.g. a Zelda 1 dungeon falls to the generic dungeon track, and
if that is also absent, to the matching ALttP dungeon theme — because each
chain lists its full path independently. The boot-only resolver and chain data
live in ROM; only the resolved lookup table occupies BW-RAM.

| Track | Falls back to |
| ---: | --- |
| 201 Title | 1 Title ~ Link to the Past |
| 202 Overworld | 2 Hyrule Field |
| 203 Generic dungeon | 17 Lost Ancient Ruins |
| 204 Level 9 | 46 Ganon's Tower, then 22 Dungeon of Shadows |
| 205 Ganon | 29 Release of Ganon |
| 206 Dungeon clear | 19 Great Victory! |
| 207 Zelda rescued | 25 Princess Zelda's Rescue |
| 209 Ending | 34 Staff Roll |
| 211-213 Dungeons 1-3 | 203, Eastern/Desert/Hera (35/36/43), then 17 |
| 214-218 Dungeons 4-8 | 203, Darkness/Swamp/Skull/Ice/Mire (39/38/41/42/40), then 22 |
| 131/133/137 SM tension variants | 123 base tension |
| 132/134/138 SM Kraid/Phantoon/Mother Brain | 122 base boss 2 |
| 135/136 SM Draygon/Ridley | 119 base boss 1 |
| 139 SM Hyper Beam | 110 base track 10 |
| 301 Intro | 104 Opening |
| 302 Brinstar | 110 Green Brinstar |
| 303 Norfair | 112 Upper Norfair |
| 304 Kraid hideout | 111 Red Brinstar |
| 305 Ridley hideout | 113 Lower Norfair |
| 306 Tourian | 117 Tourian |
| 307 Item room | 103 Item Room |
| 308 Generic boss | 119 Big Boss Battle 1 |
| 309 Mother Brain | 118 Mother Brain |
| 310 Escape | 120 Evacuation |
| 311 Power-up | 102 Item Acquisition |
| 312 Ending | 130 Credits |
| 313 Fade-in/interlude | 101 base SM track 1 |
| 314 Kraid battle | 308, then SM Kraid 132, then 122 |
| 315 Ridley battle | 308, then SM Ridley 136, then 119 |

Z1 tracks 208 (item) and 210 (game over) have no shared fallback and use the
native engine when their PCM is absent.

## Availability cache

Boot scans the manifest only when the cache ABI or four-byte seed fingerprint
changes. The committed cache lives at `$40BD00` and its per-track bytes begin at
`$40BD20`. To rescan after changing PCM files without changing the ROM seed,
clear `$40BD00-$40BE5C` in SRAM or start with a fresh SRAM file.

Runtime track selection is frame-driven and has no busy wait. A seek that stays
busy, or an SM silent-sequencer acknowledgement that remains pending, for 240
service calls disables native-music suppression and enters the error state.
Every game transition sets MSU volume to zero before replacing the SPC engine
and completes the stop after the device becomes ready.

## Volume configuration

`config_msu_volume` holds the maximum MSU-1 PCM volume in its low byte
($00-$FF, default $7F). It lives in the website-patchable configuration block
at ROM address `$FFFF06` (file offset `0x7FFF06`); boot copies it to BW-RAM
`$40FF06` with the rest of the block. Every game applies it: the shared
transport starts tracks at this volume, and the ALttP adapter uses it as its
full-volume fade target (its half-volume fade becomes half the configured
value). Lowering it keeps PCM music from overpowering native SFX.

## Runtime behavior

- ALttP keeps its existing fade, shuffle, extended OST, fanfare, and resume
  policy.
- When a Zelda 1 or Metroid 1 one-shot PCM ends, the silently running native
  sequencer becomes audible.
- Zelda 1 Tune0/Tune1 jingles remain native except for game over.
- The shared transport plays at the configured maximum volume without fades;
  ALttP retains its existing fades.
