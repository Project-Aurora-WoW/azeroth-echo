# Server installation

Deploying the server side from scratch.

*Русская версия: [Установка сервера](Установка-сервера)*

## Requirements

| Component | Version | Note |
|---|---|---|
| Windows | 10/11 x64 | tested on 10.0.26200 |
| Visual Studio Build Tools | 18 (2026) | MSVC 19.51+ |
| CMake | 4.5+ | |
| MySQL | 8.0.46 | port 3306 |
| Boost | 1.78 | `C:\local\boost_1_78_0` |
| OpenSSL | 4.0.3 | `C:\Program Files\OpenSSL-Win64` |
| Client 3.3.5a | build 12340 | source of DBC and maps |

## Step 1. Sources

```powershell
git clone https://github.com/Project-Aurora-WoW/azeroth-echo-core.git E:\azeroth
```

`data/sql` is not tracked — take it from upstream AzerothCore:

```powershell
git clone --depth 1 https://github.com/azerothcore/azerothcore-wotlk.git C:\temp\ac
Copy-Item -Recurse C:\temp\ac\data\sql E:\azeroth\data\
```

Without it `worldserver` cannot apply auto-updates and fails with
`Failed to initialize network`.

## Step 2. Build

```powershell
cmake -S E:/azeroth -B E:/acbuild -G "Visual Studio 18 2026" -A x64 `
      -DCMAKE_INSTALL_PREFIX=E:/acbuild/bin -DSCRIPTS=static

cmake --build E:/acbuild --config RelWithDebInfo --target worldserver authserver --parallel
```

Output: `E:\acbuild\bin\RelWithDebInfo\worldserver.exe` and `authserver.exe`.

More on modules and build errors: [Core build](Core-Build-EN).

## Step 3. Client data

`E:\acbuild\bin\RelWithDebInfo\data\` needs:

```
data/
├── dbc/       ← DBC files (ruRU, enUS)
├── maps/
├── vmaps/
└── Cameras/
```

Copy from an existing installation or extract from the client with
`map_extractor.exe`, `vmap4_extractor.exe`, `mmaps_generator.exe`.

## Step 4. Databases

```sql
CREATE DATABASE echo_world      CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE echo_characters CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE echo_auth       CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Take the schema from a working AzerothCore install:

```powershell
mysqldump -u root -p --no-data --skip-add-drop-table --databases acore_world acore_characters acore_auth `
  --result-file=backup_schema.sql
```

Replace database names with `echo_*` in the dump, then import:

```powershell
Get-Content backup_schema.sql | mysql -u root -p
```

## Step 5. Base world

`echo_world` needs the base ACDB content (~30k NPCs, 46k items):

```powershell
mysqldump -u root -p --single-transaction --quick --hex-blob `
  --databases acore_world --result-file=base_world.sql
```

In the dump replace `USE acore_world` with `USE echo_world` and
`CREATE DATABASE ... acore_world` with `echo_world`, then:

```powershell
Get-Content base_world.sql | mysql -u root -p --default-character-set=utf8mb4
```

Same for `characters` and `auth`.

## Step 6. Project migrations

Use **`sql/world-adapted/`**, not `sql/world/` — the originals fail on this
core schema.

```powershell
$dir = "E:\azeroth-echo\sql\world-adapted"
Get-ChildItem $dir -Filter *.sql | Sort-Object Name | ForEach-Object {
    Get-Content $_.FullName -Raw | mysql -u root -p --default-character-set=utf8mb4
}
```

Order matters: `0001` → `0021`. Details: [SQL migrations](SQL-Migrations-EN).

## Step 7. Configuration

Copy `configs/*.conf.dist` and fill in:

**worldserver.conf**
```ini
LoginDatabaseInfo     = "127.0.0.1;3306;USER;PASS;echo_auth"
WorldDatabaseInfo     = "127.0.0.1;3306;USER;PASS;echo_world"
CharacterDatabaseInfo = "127.0.0.1;3306;USER;PASS;echo_characters"
DataDir               = "data"
WorldServerPort       = 8085
SOAP.Enabled          = 1
SOAP.IP               = "127.0.0.1"
SOAP.Port             = 7878
Appender.Console      = 1,4,0,"1 9 3 6 5 8"
```

**authserver.conf**
```ini
LoginDatabaseInfo = "127.0.0.1;3306;USER;PASS;echo_auth"
RealmServerPort   = 3724
```

Trap: `Appender.Console` must start with **`1`** (appender type). The value `4`
produces `Unknown type '4' for appender Console` and the server exits silently.

## Step 8. Realmlist

```sql
UPDATE echo_auth.realmlist
SET address='127.0.0.1', localAddress='127.0.0.1', port=8085, gamebuild=12340
WHERE id=1;
```

## Step 9. Launch

```powershell
cd E:\acbuild\bin\RelWithDebInfo
.\authserver.exe -c configs/authserver.conf
.\worldserver.exe -c configs/worldserver.conf
```

The `-c` flag is required: by default `worldserver` looks for the config in the
current directory, but it lives in `configs\`.

Success markers in the log:

```
Opening DatabasePool 'echo_world' ... opened successfully
Updating World database... >> World database is up-to-date!
WORLD: World Initialized In 0 Minutes 10 Seconds
worldserver-daemon ready...
```

## Step 10. Account

Via the `worldserver` console or SOAP:

```
account create MYACC mypassword
account set gmlevel MYACC 3 -1
```

## Shutdown and start order

Stop: `worldserver` first, then `authserver`. Start the other way around —
`authserver` first, then `worldserver`.

If `worldserver` starts without `authserver` it will come up, but clients cannot
authenticate.

## Next

- [SOAP and administration](SOAP-Admin-EN)
- [Troubleshooting](Troubleshooting-EN)
