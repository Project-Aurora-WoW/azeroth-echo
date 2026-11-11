# Troubleshooting

Real problems encountered during deployment and how they were solved.

*Русская версия: [Устранение неполадок](Устранение-неполадок)*

## Server

### Server exits with code 0 right after start

**Console output:**

```
Log::CreateAppenderFromConfig: Unknown type '4' for appender Console
Error while configuring Appender Console in Logger root. Appender does not exist
AC>
```

**Cause:** `Appender.Console` starts with `4` (unknown appender type).

**Fix:** the first number is the appender type; `1` is valid:

```ini
Appender.Console = 1,4,0,"1 9 3 6 5 8"
```

### `Config::LoadFile: Failed open file 'worldserver.conf'`

**Cause:** `worldserver.exe` looks for the config in the current directory, but it
lives in `configs\`.

**Fix:** run with the flag:

```powershell
.\worldserver.exe -c configs/worldserver.conf
```

### `StartNetwork failed to bind socket acceptor` / `Failed to initialize network`

**Cause:** `data/sql` is missing. The core tries to apply auto-updates, fails
during init and never reaches networking.

**Fix:** copy `data/sql` from upstream AzerothCore:

```powershell
git clone --depth 1 https://github.com/azerothcore/azerothcore-wotlk.git C:\temp\ac
Copy-Item -Recurse C:\temp\ac\data\sql E:\azeroth\data\
```

### `Applying of file '...' to database 'echo_world' failed!`

**Example:**

```
ERROR 1062 (23000) at line 49: Duplicate entry '991001' for key 'creature.PRIMARY'
Applying of file '.../archivist_tables.sql' to database 'echo_world' failed!
```

**Cause:** the module migration file hash changed, the core tries to reapply it.

**Fix:** update the hash in the `updates` table:

```powershell
$sha1 = (Get-FileHash <path to .sql> -Algorithm SHA1).Hash
```

```sql
UPDATE echo_world.updates SET hash='<SHA1>' WHERE name='archivist_tables.sql';
```

### `Unknown column 'team' in 'field list'`

**Cause:** `mod-ai-bots` requires a column missing from a table created by another
module or core version.

**Fix:** the module is unrelated to the project — remove it from `modules/` and
`configs/modules/`, reconfigure CMake.

### `Script named '<name>' is assigned in the database, but has no code!`

**Cause:** the DB has a `ScriptName`, but no matching C++ class in the built
`worldserver`.

**Fix:** either compile the module implementing it, or clear the `ScriptName`:

```sql
UPDATE echo_world.gameobject_template SET ScriptName='' WHERE entry=705605;
```

### Crash `ACCESS_VIOLATION` in `ScriptRegistry<...>::_checkMemory`

**Symptom:** `worldserver` dies within seconds, `Crashes/*.txt` shows:

```
Exception code: C0000005 ACCESS_VIOLATION
ScriptRegistry<WorldScript>::_checkMemory+29
WorldScript::WorldScript+D3
`dynamic initializer for 'ChallengeModesWorldScriptInstance''
```

**Cause:** scripts created as global objects — their constructors run before
`ScriptRegistry` is initialised.

**Fix:** move creation into the loader function:

```cpp
void Addecho_challenge_modesScripts()
{
    static bool registered = false;
    if (registered) return;
    registered = true;
    new ChallengeModesWorldScript();
    // ...
}
```

### `Creature (Entry: N) lists non-existing CreatureDisplayID id (M)`

**Cause:** a model in `creature_template_model` is absent from the client's
`CreatureDisplayInfo.dbc`.

**Fix:** substitute an existing ID. Verify it exists in the client DBC, then:

```sql
UPDATE echo_world.creature_template_model
SET CreatureDisplayID = <existing>
WHERE CreatureID = <entry>;
```

### Server does not see the database after a config change

The shutdown log shows which pools were opened:

```
Closing down DatabasePool 'echo_world' ...
```

If it shows `1acore_world_new` or another name, the config was not applied. Check:

```powershell
Select-String -Path configs\worldserver.conf -Pattern "DatabaseInfo"
```

## Client

### Title is not displayed

**Possible causes:**

1. `Cache/WDB` not cleared — the client reads the old `CharTitles.dbc`.
2. Title not granted: `SELECT * FROM echo_characters.character_titles WHERE guid=<guid>;`
3. ID 178 is outside the stock 1–47 range and the mask did not take.

**Fix:**

```powershell
Remove-Item -Recurse -Force "C:\WoW\Cache\WDB\ruRU"
```

If that does not help, rebuild `patch-x.mpq` with an ID in the 1–47 range.

### Mount cannot be summoned

1. Spell 70010 in the client: run `verify_mpq.py` — expect `70010 present: True`.
2. Spell on the server: `SELECT * FROM echo_world.spell_dbc WHERE ID=70010;`
3. Item binding: `SELECT spellid_1 FROM echo_world.item_template WHERE entry=70003;` — must be `70010`.

### Map 5000: disconnect or "map not found"

1. Is `patch-Z.mpq` in `Data/`?
2. Load order: is `patch-Z` last alphabetically?
3. Is `Map.dbc` on the server in `data/dbc/`?
4. Is `Map.dbc` **not** duplicated in `patch-x.mpq`?

### Addon missing from the list

Check the structure: the `.toc` must be directly in `AddOns/AzerothEcho/`, not in
`AddOns/AzerothEcho/AzerothEcho/`:

```powershell
Test-Path "C:\WoW\Interface\AddOns\AzerothEcho\AzerothEcho.toc"
```

### Client crashes on load

Corrupted MPQ or a conflict. Quick isolation — move out the patches:

```powershell
Move-Item "C:\WoW\Data\patch-x.mpq" "C:\WoW\Data\patch-x.mpq.off"
Move-Item "C:\WoW\Data\patch-Z.mpq" "C:\WoW\Data\patch-Z.mpq.off"
```

If the client starts, put them back one at a time to find the culprit.

## Databases

### `Unknown column 'InhabitType' in 'field list'`

The migration was written for a different core schema. Use `sql/world-adapted/`,
not `sql/world/`.

### `Out of range value for column 'subclass'`

`subclass` is `tinyint unsigned` while the migration writes `-1`. Replace with `0`.

### `Duplicate entry '<guid>' for key 'creature.PRIMARY'`

Reapplying a migration that creates spawns with fixed `guid`. Remove the conflicting
rows before reimporting:

```sql
DELETE FROM echo_world.creature WHERE guid BETWEEN 7000101 AND 7000102;
```

### `Table 'echo_characters.item_template' doesn't exist`

The migration writes to the wrong database. `item_template` lives in `echo_world`,
not `echo_characters`.

### Custom records disappeared after importing a dump

The base world dump overwrote the tables. The correct order is: schema → base ACDB
→ project migrations. If content is gone, reapply `sql/world-adapted/`.

## SOAP

| Symptom | Fix |
|---|---|
| `HTTP 401 Unauthorized` | check account credentials and `gmlevel >= 3` |
| `Command can not be empty` | use `<command>` without the `ns1:` prefix |
| `User has to be assigned on all realms` | set `account_access.RealmID = -1` |
| Port closed | `SOAP.Enabled = 1` and restart |

## Tooling

### Ladik's MPQ Editor does nothing

No CLI support: `script`, `/console`, stdin — all exit with code 0 and no effect.
It is a GUI application. Use `tools/dbc/build_mpq.py`.

### PowerShell: "Missing closing ')' in expression"

The script is UTF-8 **without BOM**; PowerShell 5.1 reads it as ANSI and breaks on
Cyrillic.

**Fix:** save with BOM:

```powershell
$content = Get-Content script.ps1 -Raw -Encoding UTF8
[System.IO.File]::WriteAllText("$PWD\script.ps1", $content, [System.Text.UTF8Encoding]::new($true))
```

### `git push` rejected because of file size

GitHub rejects files over 100 MB. Add to `.gitignore`:

```
data/sql/
*.mpq
*.pdb
```

## Reading a crash dump

The `Crashes/` directory next to `worldserver.exe` holds two files per crash:
`.dmp` (for WinDbg) and `.txt` (human-readable).

In `.txt` the `Call stack` section matters — top to bottom from the failure point:

```
00007FF7A7B18ED9  ScriptRegistry<WorldScript>::_checkMemory+29  ScriptMgr.h line 932
00007FF7A7B17F73  ScriptRegistry<WorldScript>::AddScript+53      ScriptMgr.h line 802
00007FF7A70718D3  `dynamic initializer for 'ChallengeModesWorldScriptInstance'
```

The first line mentioning **your** file is the problem location. Here: static
script initialisation.

## Logs

`worldserver` writes to the console. No file logs until an appender is configured:

```ini
Appender.Server = 2,5,0,Server.log,w
Appender.Errors = 2,2,0,Errors.log,w
Logger.root     = 2,Console Server
```

Capturing output to a file:

```powershell
.\worldserver.exe -c configs/worldserver.conf > ws.log 2>&1
```

Log encoding is **cp1251**; read it explicitly:

```powershell
Get-Content ws.log -Encoding Default
```
