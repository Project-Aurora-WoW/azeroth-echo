# Client installation

How to install the realm patches and get into the game.

*Русская версия: [Установка клиента](Установка-клиента)*

## Requirements

| Component | Value |
|---|---|
| WoW client | **3.3.5a, build 12340** |
| Locale | ruRU, enGB or enUS |
| Disk space | ~15 MB on top of the client |

Other builds will not work: the patches are built for 12340.

## Step 1. Download files

From the release page: **[v1.0.0](https://github.com/Project-Aurora-WoW/azeroth-echo/releases/tag/v1.0.0)**

| File | Size | SHA256 (first 16) |
|---|---|---|
| `patch-x.mpq` | 4 120 622 B | `ad4377dd90f13fc9` |
| `patch-Z.mpq` | 2 676 286 B | `26310a6bb35c3cc5` |
| `AzerothEcho.zip` | 9 217 B | `0e0630725312014b` |

Verify integrity:

```powershell
Get-FileHash .\patch-x.mpq -Algorithm SHA256
```

## Step 2. Install patches

```
WoW/
├── Data/
│   ├── patch-2.MPQ          (stock)
│   ├── patch-3.MPQ          (stock)
│   ├── patch-x.mpq          ← copy here
│   └── patch-Z.mpq          ← copy here
```

The client loads `patch-*.mpq` **alphabetically**; a later archive fully overrides
an earlier one for matching files:

```
patch-2 → patch-3 → patch-x → patch-Z
```

`patch-Z` is last on purpose: its `Map.dbc` describes map 5000 and must win.

## Step 3. Install the addon

Extract `AzerothEcho.zip` so that you get:

```
WoW/Interface/AddOns/AzerothEcho/
├── AzerothEcho.toc
├── AzerothEcho.lua
├── Core.lua
├── Panel.lua
└── RiftMap.lua
```

There must be no nested `AzerothEcho/AzerothEcho/` folder — a common unpacking mistake.

## Step 4. Clear the cache

**Mandatory.** The client caches DBC data in `Cache/WDB/` and keeps reading stale
values after a patch change.

```powershell
Remove-Item -Recurse -Force "C:\WoW\Cache\WDB\ruRU"
```

Or delete the whole `Cache/WDB/` directory — it is recreated automatically.

## Step 5. Set the realmlist

File `WoW/Data/ruRU/realmlist.wtf` (or `enUS`):

```
set realmlist <server address>
```

For a local server: `set realmlist 127.0.0.1`.

## Step 6. Launch

`Wow.exe`. The addon is enabled by default (`## DefaultState: enabled` in the TOC).

## Verifying it works

In game, as a GM character:

```
.additem 70002                      → Seal of the Echo Keeper (grants the title)
.additem 70003                      → Voidrest Pegasus (mount)
.go xyz -13950 2877 9 5000          → Morza Island
.go xyz 10461 -9574 22 5000         → Valley of Betrayal
```

Title check: right-click your character → Titles tab → "Echo Keeper" should be listed.

## Automated install

The repository ships a PowerShell launcher that compares files against the manifest
and downloads only the differences:

```powershell
.\client\update-client.ps1 -WowDir "C:\WoW" -PatchUrl "https://github.com/Project-Aurora-WoW/azeroth-echo/releases/download/v1.0.0"
```

What it does:

1. Reads `manifest.json` (version 5).
2. Computes local SHA256 for each file and compares with the manifest.
3. Downloads only mismatches — using the `url` field when present.
4. Clears `Cache/WDB`.
5. Writes the realmlist.
6. Launches `Wow.exe`.

## If something is wrong

| Symptom | Cause |
|---|---|
| Client crashes on load | corrupted MPQ or wrong load order |
| Title not shown | `Cache/WDB` not cleared, or the title ID did not take |
| Mount cannot be summoned | spell 70010 missing from the client `Spell.dbc` |
| Map 5000 loads then disconnects | `patch-Z.mpq` missing from `Data/` |
| Addon not listed | nested folder on extraction |

More: [Troubleshooting](Troubleshooting-EN).
