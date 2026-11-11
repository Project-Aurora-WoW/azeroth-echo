# Client patches

How `patch-x.mpq` and `patch-Z.mpq` are built and why.

*Русская версия: [Клиентские патчи](Клиентские-патчи)*

## Why patches are needed

The server can grant title 178 or spell 70010, but a 3.3.5a client renders only
what exists in its DBC files. A patch MPQ replaces those files with modified ones.

Affected:

| DBC | Contents | Patch |
|---|---|---|
| `CharTitles.dbc` | title ID 178 | `patch-x.mpq` |
| `Spell.dbc` | spell 70010 | `patch-x.mpq` |
| `Map.dbc` | map ID 5000 | `patch-Z.mpq` |

## MPQ format

WoW uses the MPQ (MoPaQ) format up to v3. The build uses **v1** with 4 KB sectors
and zlib compression:

```
[32-byte header]
hash table    (1024 entries × 16 bytes, encrypted)
block table   (one entry per file × 16 bytes, encrypted)
data          (per sector, each compressed independently)
```

Header structure:

```c
struct MPQHeader {          // 32 bytes
    char  magic[4];         // "MPQ\x1A"
    uint32 headerSize;      // == 32
    uint32 archiveSize;     // == file size
    uint16 formatVersion;   // 1
    uint16 sectorSizeShift; // 12 → 4 KB
    uint32 hashTablePos;
    uint32 blockTablePos;
    uint32 hashTableSize;   // 1024
    uint32 blockTableSize;
};
```

Table encryption follows StormLib: the key is derived from the component name
(`"(hash table)"`, `"(block table)"`) through a hash function with a 1280-entry
table, then data is mixed on a 32-bit key.

## Why a custom builder

**Ladik's MPQ Editor has no working non-interactive mode.** Tested every way:

| Method | Result |
|---|---|
| `MPQEditor.exe script file.txt` | exits with code 0, does nothing |
| `MPQEditor.exe /console` | same |
| stdin with commands | same |
| `-help`, `/?` | prints help |

It is a GUI application that needs a window. Not usable from a build script.

A custom Python builder was written: `struct` + `zlib` from the standard library,
no external dependencies.

## Tools

All in `tools/dbc/`:

| Script | What it does |
|---|---|
| `patch_chartitles.py` | adds title 178 to `CharTitles.dbc` |
| `patch_spell.py` | clones spell 45991 into 70010 in `Spell.dbc` |
| `build_mpq.py` | builds `patch-x.mpq` from the two DBC files |
| `build_z.py` | builds `patch-Z.mpq` from maps |
| `verify_mpq.py` | unpacks the archive and compares sizes |
| `reitems.py` | extracts item rows from SQL migrations |

## DBC specifics

### The string block is at the end of the file

String offsets are counted **from the start of the string block**, not from the
start of the file:

```
WDBC header (20 bytes)
records     (records × recordSize)
stringIDs   (records × 4 bytes)
string block
```

Validation: `20 + records×recordSize + stringBlockSize == file size`. If it does not
add up, the structure was read incorrectly.

### `CharTitles.dbc`: 37 fields, 148-byte records

| Index | Field |
|---|---|
| 0 | ID |
| 1 | Name (primary) |
| 10 | TitleMask_int1 (in practice a UI step index) |
| 11 | TitleMask_int2 (always 0) |
| 27 | Name_lang ruRU |
| 36 | NextTitle |

The string "Echo Keeper %s" uses `%s` as a player-name placeholder — standard client
behaviour for titles.

### `Spell.dbc`: 234 fields, 936-byte records

| Index | Field |
|---|---|
| 0 | ID |
| 4 | Attributes |
| 136 | SpellName (enUS) |

There is **no** ruRU slot for the spell name — only enUS. That is why 70010 shows as
`Summon: Voidrest Pegasus` rather than a Russian name.

### Base for `patch-x`

`Spell.dbc` is taken from **Patch-T** (49 113 266 B, 49 994 records), not from the
server ACDB build (48 968 120 B, 49 839 records). The difference is 155 custom
69900+ spells the project uses. Using the server base would drop them from the client.

## Verification

```bash
python tools/dbc/verify_mpq.py
```

Expected for `patch-x.mpq`:

```
hdr size=32 arc=4120622 ver=1 shift=12
hash entries: 3
CharTitles.dbc: extracted=28053  source=28053  byte-identical=True
Spell.dbc:      extracted=49114265 source=49114265 byte-identical=True
Spell: 70010 present: True
      70010 name = 'Summon: Voidrest Pegasus'
```

## Limitations

Unpacking verification proves container integrity, not in-game behaviour. Whether
the client accepts title 178 and renders the mount is only proven by logging in.

## Building patches: mpqcli on StormLib

Patches are built with our own CLI over native StormLib — `tools/mpq/mpqcli.cpp`. The in-house Python builder is retired: it wrote archives whose contents read back wrong (`CharTitles.dbc` came out empty), and a ctypes wrapper of the same StormLib reliably corrupted the second call in a row (`SFileAddFileEx` overwrote the first file).

**Build the CLI** (once, needs Visual Studio Build Tools):

```
tools\mpq\build-mpqcli.cmd
```

Or through CMake: `cmake -S tools/mpq -B tools/mpq/build -A x64` + `cmake --build tools/mpq/build --config Release`. StormLib sources are expected at `E:\tools\StormLib`.

**Build patch-x**:

```powershell
$exe = "tools\mpq\build\Release\mpqcli.exe"
& $exe create patch-x.mpq 64
& $exe add patch-x.mpq CharTitles.dbc "DBFilesClient\CharTitles.dbc"
& $exe add patch-x.mpq Spell.dbc      "DBFilesClient\Spell.dbc"
& $exe list patch-x.mpq
```

**patch-Z** is the same for `DBFilesClient\Map.dbc`, `World\Maps\CustomMaps\CustomMaps.wdt` and ten `.adt` tiles.

### The backslash rule

Names inside the archive must use **backslashes**: `DBFilesClient\Spell.dbc`.

- StormLib and the client normalise `/` to `\` and read the archive either way;
- `mapextractor` and anything built on libmpq do **not** find files stored with forward slashes: the archive opens, extraction yields nothing. That is why map 5000 extracted without tiles.

### Verifying a build

"Opens fine" is not enough — verify the contents:

```powershell
& $exe size patch-x.mpq "DBFilesClient\CharTitles.dbc"   # 28053
& $exe size patch-x.mpq "DBFilesClient\Spell.dbc"        # 49114468
& $exe read patch-x.mpq "DBFilesClient\Spell.dbc" out.dbc
# then compare SHA256 with the source file
```

### Extracting server map data

1. Build an archive with `Map.dbc` and the tiles (backslashes) and put it into `Data` as `patch-5.MPQ` — the extractor only reads names from its hardcoded list (`common.MPQ` … `patch-5.MPQ`).
2. `map_extractor.exe -i <client> -o <output> -e 1`.
3. Copy `maps\5000*.map` into the server build's `data\maps`.
4. Delete `patch-5.MPQ` from the client.

Map 5000 is appended to the extractor's map list in `System.cpp`: the stock `Map.dbc` shipped in the archives does not contain it.
