# Modules

C++ modules of the project. Some are compiled into the core, others exist as
sources only.

*Русская версия: [Модули](Модули)*

## Composition

| Module | In core | Purpose |
|---|---|---|
| `mod-campaign` | yes | campaign engine for campaigns 1–4 |
| `mod-archivist-chronicle-of-azeroth` | yes | Chronicler of the Order, lore archive |
| `mod-echoes-architecture` | yes | realm framework: PlayerScript, SpellScript |
| `mod-stranniki-iz-niotkuda` | yes | wandering creatures |
| `echo-challenge-modes` | yes | challenge modes, Altar of Trials |
| `echo-balance` | **no** | damage and health multipliers |
| `echo-campaigns` | **no** | alternative campaign implementation |
| `echo-economy` | **no** | realm economy |
| `echo-pve` | **no** | PvE activities |
| `echo-pvp` | **no** | PvP system |
| `echo-startup` | **no** | starting scenario |

Only the first five are in `azeroth-echo-core/modules/` and compiled into
`worldserver.exe`. The rest live in the content repository as sources but are not
part of the build.

## How a module enters the build

CMake scans `modules/*/src/` and finds a module by directory structure:

```
modules/
└── echo-challenge-modes/
    ├── conf/
    │   └── echo-challenge-modes.conf.dist
    └── src/
        └── EchoChallengeModes.cpp
```

A `CMakeLists.txt` inside the module is **not** needed — the core generates it via
`GetModuleSourceList()` and `CollectSourceFiles()`.

### Entry point

The generated line looks like:

```cpp
void Addecho_challenge_modesScripts();
```

Rule: `Add` + folder name **as is** + `Scripts`.

| Folder | Function |
|---|---|
| `mod-campaign` | `Addmod_campaignScripts()` |
| `echo-challenge-modes` | `Addecho_challenge_modesScripts()` |
| `mod-stranniki-iz-niotkuda` | `Addmod_stranniki_iz_niotkudaScripts()` |

A mismatch gives `LNK2019: unresolved external symbol` when linking `worldserver`.

### Registering scripts

Create script objects inside the function:

```cpp
void Addecho_challenge_modesScripts()
{
    static bool registered = false;
    if (registered)
        return;
    registered = true;

    new ChallengeModesWorldScript();
    new altar_challenge_modes();
    new ChallengeModeHardcore();
    // ...
}
```

**Important:** create scripts **inside** the function, not as global objects. A
global `new ChallengeModesWorldScript()` runs before `ScriptRegistry` is
initialised and crashes the server on startup:

```
Exception code: C0000005 ACCESS_VIOLATION
ScriptRegistry<WorldScript>::_checkMemory
WorldScript::WorldScript
`dynamic initializer for 'ChallengeModesWorldScriptInstance''
```

This crash was reproduced and fixed by moving registration into the entry point.

## Module `echo-challenge-modes`

### What it does

Opens the mode selection menu when the Altar of Trials (gameobject 705605) is used.

### Classes

| Class | Mode |
|---|---|
| `ChallengeModesWorldScript` | router, stores states |
| `altar_challenge_modes` | GameObjectScript, menu |
| `ChallengeModeHardcore` | death is permanent |
| `ChallengeModeSemiHardcore` | penalties instead of death |
| `ChallengeModeSelfCrafted` | forbids foreign items |
| `ChallengeModeItemQualityLevel` | quality cap |
| `ChallengeModeSlowXpGain` | reduced XP |
| `ChallengeModeVerySlowXpGain` | heavily reduced |
| `ChallengeModeQuestXpOnly` | XP from quests only |
| `ChallengeModeIronMan` | no deaths, no trading |

### PlayerScript hooks

```cpp
void OnPlayerGiveXP(Player*, uint32& amount, Unit*, uint8) override;
void OnPlayerLevelChanged(Player*, uint8) override;
void OnPlayerLogin(Player*) override;
void OnPlayerReleasedGhost(Player*) override;
void OnPlayerPVPKill(Player*, Player*) override;
void OnPlayerKilledByCreature(Creature*, Player*) override;
void OnPlayerResurrect(Player*, float, bool& applySickness) override;
void OnPlayerTalentsReset(Player*, bool) override;
void OnPlayerLearnSpell(Player*, uint32) override;
```

Trap: `OnPlayerResurrect` takes `bool&` (by reference), not `bool`. Declaring
`bool applySickness` produces:

```
error C3668: method with override specifier does not override any base class method
error C4263: member function does not override any virtual member function
error C4264: no available override for virtual member function
```

### Configuration

`configs/modules/echo-challenge-modes.conf`:

```ini
ChallengeModes.Enable = 1
Hardcore.Enable = 1
Hardcore.XPMultiplier = 1
SemiHardcore.Enable = 1
```

## Module `mod-campaign`

Campaign engine. Files:

| File | Role |
|---|---|
| `campaign_mgr.cpp` | manager core: progress, stages |
| `campaign_boss_ai.cpp` | boss AI |
| `campaign_commands.cpp` | GM commands |
| `campaign_gossip.cpp` | NPC dialogues |
| `campaign_loader.cpp` | DB loading |
| `campaign_world.cpp` | WorldScript, initialisation |

Startup log line: `Campaign module loaded`.

## Module `mod-archivist-chronicle-of-azeroth`

Lore archive: the Chronicler of the Order (NPC 70180) hands out records and
rewards for exploration.

Files: `ArchivistAddon`, `ArchivistItems`, `ArchivistMgr`, `ArchivistNPC`,
`ArchivistPlayerScript`, `ArchivistRewards`, `ArchivistSetup`, `ArchivistStrings`.

Startup: `Archivist module loaded (enabled: yes)`, `Archivist: locale set to 'ru'`.

**Known issue:** the module updates the DB aggressively. The first run failed on a
repeated migration:

```
Applying of file 'archivist_tables.sql' to database 'echo_world' failed!
ERROR 1062 (23000) at line 49: Duplicate entry '991001' for key 'creature.PRIMARY'
```

Cause: the migration file hash changed, the core tried to reapply it. Fix by
updating the hash in `echo_world.updates`:

```sql
UPDATE echo_world.updates
SET hash='<new SHA1 of the file>'
WHERE name='archivist_tables.sql';
```

## Module `mod-stranniki-iz-niotkuda`

Wandering creatures: random encounters with travelling merchants and monsters.

Configuration:

```ini
Stranniki.Enabled = 1
Stranniki.SpawnChance = 20
Stranniki.Announce = 1
Stranniki.SummonDuration = 120
Stranniki.SpawnCooldown = 300
Stranniki.MonsterHealthMultiplier = 1
Stranniki.MonsterDamageMultiplier = 1
```

## Module `mod-echoes-architecture`

Framework: `PlayerScript_Echoes.cpp`, `SpellScript_Echoes.cpp`,
`EchoesArchitecture.cpp`. Base infrastructure for realm script systems.

## Removed modules

Four modules were removed from the build — unrelated to the project and blocking
startup:

| Module | Why removed |
|---|---|
| `mod-ai-bots` | migration required a `team` column missing from the `game_tele`-derived table; DB auto-update failed |
| `mod-cursed-islands` | unrelated |
| `mod-night-of-fallen-heroes` | unrelated |
| `mod-stalker-teni-lorderona` | unrelated |

After removal from `E:\azeroth\modules` and CMake reconfigure, DB auto-update
stopped failing.

## Adding a module

1. Put it in `azeroth-echo/modules/<name>/` with a `src/` subdirectory
2. Copy to `azeroth-echo-core/modules/<name>/`
3. Declare `Add<folder name unchanged>Scripts()` in one of the `.cpp` files
4. Create scripts inside it, never globally
5. Reconfigure CMake and rebuild

```powershell
cmake -S E:/azeroth -B E:/acbuild -G "Visual Studio 18 2026" -A x64
cmake --build E:/acbuild --config RelWithDebInfo --target worldserver
```

6. Check the log: `Using modules configuration: > <name>.conf`
7. Confirm the warning `Script named '<name>' is assigned in the database, but has no code!` is gone
