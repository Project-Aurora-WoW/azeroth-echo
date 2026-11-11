# Custom Map 5000 "CustomMaps"

The project's custom map: two regions assembled from `.adt` tiles.

*Русская версия: [Карта 5000](Карта-5000)*

## Regions

| Region | Tiles | Teleport |
|---|---|---|
| Morza Island | 25–26 / 57–58 | `.go xyz -13950 2877 9 5000` |
| Valley of Betrayal | 48–50 / 12–14 | `.go xyz 10461 -9574 22 5000` |

## Lore

- **Morza** — a fleet crossing of the Cult of the Abyssal Grin. Mentioned by the
  Portal Guardian (entry 70001).
- **Valley of Betrayal** — a secret Cult staging point where the rift echo distorts
  the thoughts of anyone who lingers more than a day.

## `patch-Z.mpq` contents

| File | Size | Purpose |
|---|---|---|
| `DBFilesClient\Map.dbc` | 43 523 B | map 5000 record in the client |
| `World\Maps\CustomMaps\CustomMaps.wdt` | 32 844 B | map description |
| `.adt` × 10 | 13.5 MB | region tiles |

Built archive — **2 676 286 B**.

## Why `Map.dbc` lives only in `patch-Z`

The client loads `patch-*.mpq` alphabetically, and the last one fully overrides
earlier ones for matching files:

```
patch-2 → patch-3 → patch-x → patch-Z
```

If `Map.dbc` sits in both `patch-x` and `patch-Z`, the `patch-Z` version survives —
and when you later add your own maps to `patch-x`, they silently disappear. Hence the
rule: **`Map.dbc` lives only in `patch-Z`**.

When you need to add a map, merge on top of the `Map.dbc` from `patch-Z` and pick a
patch name that sorts **after** `Z`: `patch-Z2.mpq`, `patch-0.mpq`. `patch-y` will not
do — `y` < `z`.

## Server side

`Map.dbc` is needed by the server too: it sits in `data/dbc/` next to `worldserver.exe`.

```
E:\acbuild\bin\RelWithDebInfo\data\dbc\Map.dbc
```

If the server does not see map 5000, `.go xyz ... 5000` fails with "map not found" and
the client most likely disconnects.

## The corrupted original archive

The upstream `patch-Z.MPQ` from the `custom-maps` repository (3 209 747 B) is
**unreadable**: the header reports `hash_table_size = 3144003`,
`hash_table_offset = 4096`, `block_table_offset = 13`, and no 16-byte record has valid
`0x80xxxxxx` flags — every `start+csize` runs past the file end. Sweeping hash table
sizes and aligned offsets found no valid table.

The archive in the release was rebuilt from unpacked `.adt`/`.wdt`/`Map.dbc` by the
same builder used for `patch-x`:

```bash
python tools/dbc/build_z.py
```

## Verifying the archive

```bash
python tools/dbc/verify_mpq.py
```

The script decrypts hash and block tables, unpacks every block and compares sizes
with `fsize`. Expected result for `patch-Z` — **13/13 blocks correct**.

## Limitations

The map has not been tested in game. Validity is confirmed only by successful block
unpacking — that proves file integrity, not rendering, collisions or navigation.
The first walk on map 5000 is the only real test.
