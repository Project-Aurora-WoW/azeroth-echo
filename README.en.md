# Azeroth: Echo of the Void — Azeroth Custom Realm

> Custom realm on **AzerothCore** for **WoW 3.3.5a (build 12340)**.
> An alternate timeline: a shard of the Lich King's throne soaked in Void energy,
> and the Cult of the Abyssal Grin prepares to wake an Old God.

**Русская версия: [README.md](README.md)**

---

## Documentation

Full guide in the **[Wiki](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki)** — every page
exists in both Russian and English, English pages carry the `-EN` suffix:

| Page | Audience |
|---|---|
| [Client installation (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Client-Install-EN) | players |
| [Realm content (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Realm-Content-EN) | players, GMs |
| [Custom map 5000 (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Custom-Map-5000-EN) | players, developers |
| [Server installation (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Server-Install-EN) | admins |
| [SQL migrations (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/SQL-Migrations-EN) | admins |
| [SOAP & admin (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/SOAP-Admin-EN) | admins |
| [Core build (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Core-Build-EN) | developers |
| [Client patches (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Client-Patches-EN) | developers |
| [Modules (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Modules-EN) | developers |
| [Lua scripts (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Lua-Scripts-EN) | developers |
| [Addon AzerothEcho (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Addon-AzerothEcho-EN) | developers |
| [Development (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Development-EN) | developers |
| [Troubleshooting (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Troubleshooting-EN) | everyone |

Wiki sources live in [`wiki/`](wiki/) — edit there, publish with [`tools/wiki-push.ps1`](tools/wiki-push.ps1).

---

## Related repositories

| Repository | Contents |
|---|---|
| **azeroth-echo** ← you are here | Content: SQL, Lua, modules, addon, client patches, tools |
| [**azeroth-echo-core**](https://github.com/Project-Aurora-WoW/azeroth-echo-core) | AzerothCore 3.3.5a fork with project modules |
| [**Releases**](https://github.com/Project-Aurora-WoW/azeroth-echo/releases) | Ready-to-use client patches |

How they connect: [Repositories relation](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Repositories-EN).

### Quick client setup

Download from [release v1.0.0](https://github.com/Project-Aurora-WoW/azeroth-echo/releases/tag/v1.0.0):

```
patch-x.mpq     → WoW/Data/
patch-Z.mpq     → WoW/Data/
AzerothEcho.zip → extract into WoW/Interface/AddOns/
delete WoW/Cache/WDB/
```

Set `set realmlist <server>` in `WoW/Data/ruRU/realmlist.wtf` and launch `Wow.exe`.

---

## Stack

| Component | Version / source |
|---|---|
| Core | [Project-Aurora-WoW/azeroth-echo-core](https://github.com/Project-Aurora-WoW/azeroth-echo-core) — AzerothCore 3.3.5a fork with project modules |
| Client | WoW 3.3.5a (12340) |
| Scripting | [mod-ale](https://github.com/azerothcore/mod-ale) (ALE, Eluna fork) |
| Database | MySQL 8.0 (`echo_world`, `echo_characters`, `echo_auth`) |
| Addon | [`addons/AzerothEcho`](addons/README.md) — campaign panel, rift map |

**Principle:** this repository holds realm content only — migrations, Lua,
addon, docs, client patch tooling. The core is built separately from
[`azeroth-echo-core`](https://github.com/Project-Aurora-WoW/azeroth-echo-core).

---

## Repository layout

```
addons/AzerothEcho/     client addon
client/                 manifest.json, update-client.ps1 launcher
configs/                worldserver.conf.dist, authserver.conf.dist (credentials masked)
docs/                   client patches, deployment, AIO, testing plan
lua_scripts/            38 server-side Lua scripts (ALE/Eluna)
modules/                C++ modules for the realm
scripts/                build and setup helpers
sql/world/              original migrations 0001–0021
sql/world-adapted/      same migrations, adapted to the actual core schema
tools/dbc/              Python tooling for DBC editing and MPQ building
tools/wiki-push.ps1     publish wiki pages
wiki/                   wiki page sources (RU + EN)
```

---

## Current state (2026-11-11)

| Component | Status |
|---|---|
| `worldserver` | running, port 8085, `World Initialized` |
| `authserver` | running, port 3724 |
| Databases | `echo_world` (348 tables), `echo_characters` (123), `echo_auth` (22) |
| SOAP | enabled on `127.0.0.1:7878` |
| Modules | campaign, archivist, echoes-architecture, stranniki, challenge-modes |
| Client | `patch-x.mpq`, `patch-Z.mpq`, addon `AzerothEcho` |
| In-game test | **not performed** — requires a live client login |

Content loaded: 29 991 creature templates, 46 132 items, 9 472 quests,
150 228 spawns, 4 507 spell_dbc rows.

---

## Custom content

**NPCs (18):** Portal Guardian 70001, Akheron the Voidborn 70100,
Cultist of the Abyssal Grin 70101, Ritual Altar 70103, Void Warden 70105,
Ritual Hearth 70106, Captive Mage Talvin 70110, Archmage Elianna 70120,
Prophet Nal'kur 70130, Foulsight 70140, Commander Valiria 70150,
Advisor Mortega 70160, Runic Burn 70172, Gold Keeper 70173,
Warden of Change 70174, Chronicler of the Order 70180, Void Rift 70190,
Withered of the Rift 70191.

**Items (14):** Seal of the Echo Keeper 70002, Voidrest Pegasus 70003,
Brand of the Void Wardens 70004, Void Shard 70008, banners 70010–70013,
costumes 70015–70018, Order Ration 70100, Echo Satchel 70101.

**Title:** ID 178 "Echo Keeper" / "Echo Keeper" (female variant separate).
**Spell:** ID 70010 "Summon: Voidrest Pegasus".
**Map:** ID 5000 "CustomMaps" — Morza Island, Valley of Betrayal.

Details: [Realm content (EN)](https://github.com/Project-Aurora-WoW/azeroth-echo/wiki/Realm-Content-EN).

---

## Client patches

| File | Contents |
|---|---|
| `patch-x.mpq` | `CharTitles.dbc` (title 178), `Spell.dbc` (spell 70010), based on Patch-T |
| `patch-Z.mpq` | `Map.dbc`, `CustomMaps.wdt` + 10 `.adt` — map 5000 |

MPQ load order: `patch-2` → `patch-3` → `patch-x` → `patch-Z`.
`Map.dbc` lives **only** in `patch-Z` — duplicating it in `patch-x` makes newer
patches unable to override the map.

### Building patches

```bash
python tools/dbc/patch_chartitles.py   # title 178 into CharTitles.dbc
python tools/dbc/patch_spell.py        # spell 70010 into Spell.dbc (from Patch-T)
python tools/dbc/build_mpq.py          # build patch-x.mpq
python tools/dbc/build_z.py            # build patch-Z.mpq from unpacked maps
python tools/dbc/verify_mpq.py         # verify: unpack + SHA256 comparison
```

The MPQ builder is written from scratch (format v1, per-sector zlib, encrypted
hash and block tables) because Ladik's MPQ Editor has no working CLI mode.

---

## Known limitations

- `sql/world/` fails on this core's schema (no `InhabitType`, `minhealth`/`maxhealth`,
  `StatsCount`; `creature.id1` instead of `id`; `CREATE INDEX IF NOT EXISTS`
  unsupported in MySQL 8.0). Use `sql/world-adapted/`.
- `creaturedisplayinfo_dbc` is empty, so NPC models come from the client DBC.
  Some displayids from the original migrations do not exist there — nearest
  matching models were substituted.
- Title 178 is empirical: the stock title range is 1–47, behaviour of custom IDs
  beyond it is undocumented.
- `patch-Z.MPQ` in the upstream custom-maps repo is corrupted (unreadable hash
  tables); the `patch-Z.mpq` here was rebuilt from unpacked `.adt`/`.wdt`/`Map.dbc`.

---

## License

Realm content — by the author's decision. AzerothCore is GPL-2.0; third-party
modules keep their own licenses (see `modules/*/README.md`).
