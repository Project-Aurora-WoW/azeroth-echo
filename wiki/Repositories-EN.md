# Repositories relation

The "Echo of the Void" project lives in two repositories. They do not duplicate
each other — each has its own role.

*Русская версия: [Связь репозиториев](Связь-репозиториев)*

```
┌─────────────────────────────────┐      ┌──────────────────────────────────┐
│  Project-Aurora-WoW/            │      │  Project-Aurora-WoW/             │
│  azeroth-echo                   │      │  azeroth-echo-core               │
│  CONTENT                        │      │  CORE                            │
│                                 │      │                                  │
│  sql/world/                     │      │  src/            (AzerothCore)   │
│  sql/world-adapted/             │ ───► │  deps/                           │
│  lua_scripts/                   │      │  modules/                        │
│  modules/  (sources)            │ ───► │    ├── mod-campaign              │
│  addons/AzerothEcho/            │      │    ├── mod-archivist-…           │
│  client/  (manifest, launcher)  │      │    ├── mod-echoes-architecture   │
│  configs/ (credentials masked)  │      │    ├── mod-stranniki-…           │
│  tools/dbc/  (patch building)   │      │    └── echo-challenge-modes      │
│  docs/                          │      │                                  │
└─────────────────────────────────┘      └──────────────────────────────────┘
         │                                          │
         └──────────► RELEASE v1.0.0 ◄──────────────┘
                    patch-x.mpq
                    patch-Z.mpq
                    AzerothEcho.zip
```

## What lives where

| Artifact | Repository | Path |
|---|---|---|
| SQL migrations (originals) | `azeroth-echo` | `sql/world/0001…0021` |
| SQL migrations (working) | `azeroth-echo` | `sql/world-adapted/` |
| Server Lua scripts | `azeroth-echo` | `lua_scripts/` |
| Module sources | `azeroth-echo` | `modules/echo-*/` |
| Client addon | `azeroth-echo` | `addons/AzerothEcho/` |
| Manifest and launcher | `azeroth-echo` | `client/` |
| DBC/MPQ tooling | `azeroth-echo` | `tools/dbc/` |
| Documentation | `azeroth-echo` | `docs/` |
| Core code | `azeroth-echo-core` | `src/`, `deps/` |
| Compiled-in modules | `azeroth-echo-core` | `modules/` |

## How modules reach the core

A module exists in two places on purpose:

1. **`azeroth-echo/modules/`** — source of truth. Edited here, versioned together
   with the SQL and Lua that depend on it.
2. **`azeroth-echo-core/modules/`** — working copy compiled into the core. CMake
   finds it automatically by directory structure (`<module>/src/*.cpp`).

Synchronisation is a plain copy:

```powershell
Copy-Item -Recurse -Force E:\azeroth-echo\modules\echo-challenge-modes E:\azeroth\modules\
```

Then reconfigure CMake and rebuild `worldserver`:

```powershell
cmake -S E:/azeroth -B E:/acbuild -G "Visual Studio 18 2026" -A x64
cmake --build E:/acbuild --config RelWithDebInfo --target worldserver
```

## How the core learns about a module

CMake scans `modules/*/src/` and generates a loader:

```
E:\acbuild\modules\gen_scriptloader\static\ModulesLoader.cpp
```

It declares an external function named after the module folder **without any case
transformation**:

| Folder | Expected function |
|---|---|
| `mod-campaign` | `Addmod_campaignScripts()` |
| `echo-challenge-modes` | `Addecho_challenge_modesScripts()` |
| `mod-stranniki-iz-niotkuda` | `Addmod_stranniki_iz_niotkudaScripts()` |

A mismatch produces `LNK2019: unresolved external symbol`. This is the most
common error when adding a module.

## How content affects the core

SQL migrations write to tables the core reads at startup:

| Migration | Writes to | Affects |
|---|---|---|
| `0001` | `creature_template`, `creature` | NPC spawns |
| `0004`, `0006`, `0008` | `item_template` | items and rewards |
| `0018` | `spell_dbc`, `creature_template_model` | spells and models |
| `0019` | `gameobject_template`, `gameobject` | Altar of Trials |
| `0020` | `realm_store_*` | store |

So the order is: **migrations first, then restart `worldserver`**. The core caches
reference data in memory.

## Client patches are a separate layer

`patch-x.mpq` and `patch-Z.mpq` are built from DBC by the scripts in `tools/dbc/`
and published as a release. They are not linked to the core directly, but must
match server-side records:

| Client (DBC) | Server (DB) | Must match |
|---|---|---|
| `CharTitles.dbc` ID 178 | `chartitles_dbc` ID 178 | title ID |
| `Spell.dbc` ID 70010 | `spell_dbc` ID 70010 | spell ID |
| `Map.dbc` map 5000 | server `Map.dbc` in `data/dbc` | map ID and name |

If the server has a record but the client does not, the client will not render it —
the server either errors or disconnects the player.

## Summary

- **Content** (`azeroth-echo`) — what you change daily: SQL, Lua, scripts, addon, patches.
- **Core** (`azeroth-echo-core`) — what is rebuilt rarely: C++ code and compiled-in modules.
- Editing a module → copy to core → rebuild → restart.
- Editing SQL/Lua → apply → `reload` or restart.
- Editing client content → build MPQ → release → player update.
