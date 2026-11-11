# Core build

Compiling `worldserver` and `authserver` from sources with project modules.

*Русская версия: [Сборка ядра](Сборка-ядра)*

## Requirements

| Component | Verified version | Path |
|---|---|---|
| Visual Studio Build Tools | 18 (2026), MSVC 19.51 | `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools` |
| CMake | 4.5.0 | `C:\Program Files\CMake\bin` |
| Boost | 1.78.0 | `C:\local\boost_1_78_0` |
| OpenSSL | 4.0.3 | `C:\Program Files\OpenSSL-Win64` |
| MySQL client libs | 8.0.46 | `libmysql.dll` |

The core requires MSVC **19.24+** — the check is built in, CMake stops on older
versions.

## Layout

```
E:\azeroth\            ← sources (azeroth-echo-core)
E:\acbuild\            ← build directory (outside sources)
E:\acbuild\bin\RelWithDebInfo\
    ├── worldserver.exe
    ├── authserver.exe
    ├── configs/
    └── data/
```

The build directory is **always separate** from sources — otherwise artefacts end
up in git and switching configurations becomes painful.

## Configuration

```powershell
cmake -S E:/azeroth -B E:/acbuild `
      -G "Visual Studio 18 2026" -A x64 `
      -DCMAKE_INSTALL_PREFIX=E:/acbuild/bin `
      -DSCRIPTS=static
```

Key parameters:

| Parameter | Value | Effect |
|---|---|---|
| `-G` | `Visual Studio 18 2026` | generator, multi-config |
| `-A` | `x64` | required for 64-bit |
| `CMAKE_INSTALL_PREFIX` | `E:/acbuild/bin` | where binaries are installed |
| `SCRIPTS` | `static` | scripts compiled in, no DLLs |

On success CMake prints:

```
* Modules configuration (static):
  |   +- worldserver
  |   +- echo-challenge-modes
  |   +- mod-archivist-chronicle-of-azeroth
  |   +- mod-campaign
  |   +- mod-echoes-architecture
  |   +- mod-stranniki-iz-niotkuda
-- Configuring done
-- Generating done
```

If a module is missing from this list, CMake did not find it. Check the structure:
`modules/<name>/src/*.cpp`.

## Build

```powershell
cmake --build E:/acbuild --config RelWithDebInfo --target worldserver authserver --parallel
```

Duration: a clean build takes about 20 minutes on an i5-9400F; an incremental
single-module change takes minutes.

Output:

```
worldserver.vcxproj -> E:\acbuild\bin\RelWithDebInfo\worldserver.exe
authserver.vcxproj -> E:\acbuild\bin\RelWithDebInfo\authserver.exe
```

## Configurations

| Configuration | `worldserver.exe` size | When |
|---|---|---|
| `Debug` | larger, slower | code debugging |
| `RelWithDebInfo` | 35–37 MB + 380 MB PDB | **working** |
| `Release` | smallest | production |

`RelWithDebInfo` was chosen because it produces a full stack trace in crash dumps.
`Crashes/*.txt` contains function names and line numbers.

## Required files after build

`bin/RelWithDebInfo/` must contain or receive:

| File | Source |
|---|---|
| `libmysql.dll` | MySQL |
| `libcrypto-4-x64.dll`, `libssl-4-x64.dll` | OpenSSL |
| `libcrypto-3-x64.dll`, `libssl-3-x64.dll` | OpenSSL (compatibility) |
| `legacy.dll` | previous build |
| `configs/` | content repository |
| `data/dbc`, `data/maps`, `data/vmaps` | client |

Without `libmysql.dll` the server fails to start with a missing-module error.

## Common errors

### `LNK2019: unresolved external symbol Add<...>Scripts`

The function name in the module does not match what CMake generated.

```powershell
# see what is expected
Get-Content E:\acbuild\modules\gen_scriptloader\static\ModulesLoader.cpp | Select-String "Scripts"
```

Rule: `Add` + folder name **as is** + `Scripts`. For folder
`echo-challenge-modes` — `Addecho_challenge_modesScripts`.

### `error C3668: method with override specifier does not override`

The hook signature does not match the core. Check
`src/server/game/Scripting/ScriptDefines/PlayerScript.h`:

```powershell
Select-String -Path E:\azeroth\src\server\game\Scripting\ScriptDefines\PlayerScript.h `
              -Pattern "OnPlayerResurrect"
```

Known case: `bool& applySickness` (by reference), not `bool`.

### `ACCESS_VIOLATION` in `ScriptRegistry<...>::_checkMemory` at startup

Scripts are created as global objects and register before the core initialises.
Move creation into the `Add<...>Scripts()` function.

### `Could not find a proper repository signature`

No tags in `.git`. Not critical — the version becomes `unknown 1970-01-01`:

```
* AzerothCore revision : unknown 1970-01-01 ... (Archived branch)
```

Only affects `server info` output.

### `CMake Error: Unknown argument -E:\azeroth`

Typo: source path without a flag. Correct form is `-S E:/azeroth` or the path as
the last argument without a dash.

## Verifying the build

```powershell
# which modules are actually linked
$exe = "E:\acbuild\bin\RelWithDebInfo\worldserver.exe"
$bytes = [System.IO.File]::ReadAllBytes($exe)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
foreach ($m in "Archivist","Campaign","Echoes","Stranniki","AiBots","Cursed") {
    "$m : " + ([regex]::Matches($text, $m)).Count
}
```

Non-zero counts for the first four and zeros for the last two mean a correct build.

## Running after build

```powershell
cd E:\acbuild\bin\RelWithDebInfo
.\worldserver.exe -c configs/worldserver.conf
```

Success markers:

```
WORLD: World Initialized In 0 Minutes 10 Seconds
worldserver-daemon ready...
```

## Rebuilding only a changed module

```powershell
cmake --build E:/acbuild --config RelWithDebInfo --target modules
cmake --build E:/acbuild --config RelWithDebInfo --target worldserver
```

MSBuild rebuilds `modules.lib` and relinks `worldserver`. Core headers are untouched,
so it is fast.
