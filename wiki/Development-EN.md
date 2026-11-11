# Development

How to make changes without breaking what works.

*Русская версия: [Разработка](Разработка)*

## Workflow

```
1. Edit azeroth-echo (content)
        │
        ├─ SQL    → apply → reload / restart
        ├─ Lua    → reload eluna
        ├─ module → copy to azeroth-echo-core → rebuild → restart
        └─ client → rebuild MPQ → release → player update
```

Rule: **content first, core second**. Content changes often and cheaply; the core
rarely and expensively.

## Where to add what

| I want to add | Where |
|---|---|
| NPC, item | a new migration in `sql/world/` + regenerate `world-adapted/` |
| Lua logic | a new file in `lua_scripts/` |
| C++ behaviour | a module in `modules/` → copy to core |
| Client content | DBC → `tools/dbc/` → rebuild MPQ |
| Interface element | `addons/AzerothEcho/` |
| Documentation | `docs/` or this wiki |

## SQL rules

### Numbering

The next migration is `0022`, then `0023`. Never insert in the middle: application
order is set by file name.

### Idempotency

Every migration must be re-appliable without errors:

```sql
DELETE FROM `creature_template` WHERE `entry` = 70200;
INSERT INTO `creature_template` (...) VALUES (...);
```

A `DELETE` + `INSERT` pair, not a bare `INSERT`.

### Header

```sql
-- ============================================================
-- Migration: 0022_my_feature.sql
-- Purpose: what it does exactly
-- SCHEMA: AzerothCore 3.3.5a — which schema specifics were handled
-- Database: echo_world (or echo_characters)
-- ============================================================

SET NAMES utf8mb4;
USE `echo_world`;
```

`SET NAMES utf8mb4` is mandatory — otherwise Cyrillic in NPC names becomes garbage.

### This core's schema

Check the real schema before writing:

```sql
SHOW COLUMNS FROM echo_world.creature_template;
```

Differences from typical AzerothCore guides:

| Expected | In this core |
|---|---|
| `creature.id1` | `creature.id` |
| `creature_template.InhabitType` | **absent** |
| `creature_template.minhealth/maxhealth` | **absent**, HP via `HealthModifier` |
| `creature.curpower` | **absent** |
| `item_template.StatsCount` | **absent**, use `stat_type1..10` |
| `spell_dbc.SpellNameLang` | **absent**, use `Name_Lang_enUS`/`_ruRU` |

### Verifying before applying

```sql
-- check whether rows exist on the live DB
SELECT COUNT(*) FROM echo_world.creature_template WHERE entry = 70200;
```

If a table has 138 columns, do not list them via `GROUP_CONCAT` — it truncates output
at 1024 bytes and gives a false picture. Use line-per-row output:

```sql
SELECT COLUMN_NAME FROM information_schema.columns
WHERE table_schema='echo_world' AND table_name='item_template'
ORDER BY ORDINAL_POSITION;
```

## Lua rules

- Encoding **UTF-8 without BOM**
- Numeric filename prefix sets load order: `23_MyFeature.lua`
- Load dependencies before dependants
- Do not rely on `SetTitle` — some ALE builds call it `LearnTitle`

Syntax check without starting the server:

```powershell
luac -p lua_scripts\23_MyFeature.lua
```

If `luac` is unavailable, test on the server: Lua errors land in the `worldserver` log.

## Module rules

### Structure

```
modules/mod-mymod/
├── conf/
│   └── mod_mymod.conf.dist
├── src/
│   ├── MyMod.cpp
│   └── MyMod.h
└── README.md
```

A `CMakeLists.txt` inside is not needed — the core generates it.

### Entry point

```cpp
void Addmod_mymodScripts()
{
    static bool registered = false;
    if (registered) return;
    registered = true;

    new MyWorldScript();
}
```

Name = `Add` + folder name untransformed + `Scripts`. Create scripts **inside**, never
globally.

### Syncing to the core

```powershell
Copy-Item -Recurse -Force E:\azeroth-echo\modules\mod-mymod E:\azeroth\modules\
cmake -S E:/azeroth -B E:/acbuild -G "Visual Studio 18 2026" -A x64
cmake --build E:/acbuild --config RelWithDebInfo --target worldserver
```

### Config

The `.conf.dist` is copied into `configs/modules/<name>.conf` during CMake
configuration. If the file does not appear, the build did not find the module.

## Client patch rules

### Order

```
1. Change the DBC with a script in tools/dbc/
2. Build the MPQ
3. Verify by unpacking (verify_mpq.py)
4. Update client/manifest.json (sha256 + size)
5. Publish a release
6. Players update via launcher or manually
```

### Critical: `Map.dbc` only in `patch-Z`

Any DBC present in several patches is fully overridden by the last one
alphabetically. Duplicating `Map.dbc` into `patch-x` makes maps from `patch-x`
disappear.

### Pre-release check

```bash
python tools/dbc/verify_mpq.py
```

Expected: all blocks unpacked, sizes match, `byte-identical=True`.

## Commits

Format: `<area>: <short description>`

```
sql: migration 0022 — merchant NPC in Morza
lua: fixed title grant in Campaign3
modules: echo-challenge-modes — OnPlayerResurrect signature
client: release v1.0.0 links in the manifest
docs: SOAP section in the wiki
```

Body explains **why**, not what. What is visible in the diff; why is not.

## What not to commit

`.gitignore` already excludes:

| Pattern | Why |
|---|---|
| `*.mpq`, `*.MPQ` | built from DBC |
| `*.exe`, `*.dll`, `*.pdb` | build artefacts |
| `data/` | maps and DBC, gigabytes |
| `*.log`, `Crashes/` | debug noise |
| `configs/*.conf` | contain DB credentials |

Check for secrets before committing:

```powershell
git diff --cached | Select-String -Pattern "password|PASS;|root;root|ghp_|sk-"
```

## Testing

### Without a client

```powershell
# server responds
soap "server info" "USER" "PASS"

# content loaded
soap "lookup item Seal" "USER" "PASS"            # → 70002
soap "lookup creature Portal" "USER" "PASS"      # → 70001
soap "lookup spell Voidrest" "USER" "PASS"       # → 70010
soap "lookup title Echo" "USER" "PASS"           # → 178
```

### With a client

Manually only:

```
.additem 70002                      → check the title list
.additem 70003                      → summon the mount
.go xyz -13950 2877 9 5000          → map 5000
```

Acceptance checklist — `docs/testing-plan.md` in the repository.

### What cannot be automated

- Map rendering, collisions, navigation
- Custom title display
- Creature models in the world
- Addon behaviour
- Client behaviour with custom IDs

These are verified only by a live login.

## Release procedure

```
1. Build artefacts
2. Compute SHA256
3. Update manifest.json (sha256, size, url)
4. Create tag vX.Y.Z
5. Create the GitHub Release
6. Upload assets
7. Download back and verify hashes
8. Only then tell players
```

Step 7 is mandatory: it catches a corrupted upload before users see it.

## Useful commands

```powershell
# reload everything without restart
soap "reload all" "USER" "PASS"

# reload Lua
soap "reload eluna" "USER" "PASS"

# server statistics
soap "server info" "USER" "PASS"

# repository state
git -C E:\azeroth-echo status -sb
git -C E:\azeroth status -sb
git -C E:\azeroth-echo log --oneline -5
```
