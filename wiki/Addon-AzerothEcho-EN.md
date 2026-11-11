# Addon AzerothEcho

Client-side realm interface: campaigns, events, PvP, rift map.

*Русская версия: [Аддон AzerothEcho](Аддон-AzerothEcho)*

## Files

| File | Size | Role |
|---|---|---|
| `AzerothEcho.toc` | 403 B | addon manifest |
| `AzerothEcho.lua` | 5 031 B | entry point, routing |
| `Core.lua` | 4 543 B | core: events, state |
| `Panel.lua` | 10 500 B | main panel |
| `RiftMap.lua` | 3 906 B | rift map |

## Manifest

```
## Interface: 30300
## Title: AzerothEcho |cff9b59b6Эхо Пустоты|r
## Notes: Полноценный интерфейс реалма: кампании, ивенты, PvP, карта разломов.
## Author: Azeroth Custom Realm
## Version: 2.1.0
## X-Website: https://sourcecraft.dev/m-orlovrus59/azeroth-custom-realm
## DefaultState: enabled

Core.lua
Panel.lua
RiftMap.lua
AzerothEcho.lua
```

The file order matters: `Core.lua` loads first, `AzerothEcho.lua` last because it
depends on the others.

`Interface: 30300` corresponds to client 3.3.5a (build 12340 → interface 30300).

## Installation

Extract `AzerothEcho.zip` so that you get:

```
WoW/Interface/AddOns/AzerothEcho/
├── AzerothEcho.toc
├── AzerothEcho.lua
├── Core.lua
├── Panel.lua
└── RiftMap.lua
```

A nested `AzerothEcho/AzerothEcho/` folder is an error — the addon will not load.
Verify: the `.toc` must sit directly in `AddOns/AzerothEcho/`.

## Server communication

The addon talks to the server through `lua_scripts/AddonBridge.lua`. The channel is a
message prefix exchanged over the chat protocol.

```
client                          server
  │                              │
  ├─ SendAddonMessage("ECHO", …) ─► AddonBridge.lua
  │                              │  parse, handle
  ◄─ SendAddonMessage("ECHO", …) ─┤
  │                              │
```

If the addon opens but data is empty, the bridge is the problem, not the UI: verify
that `AddonBridge.lua` is loaded and `mod-ale` is active.

## Building the ZIP

The archive must contain files without a nested top-level directory:

```python
import zipfile, os
src = "addons/AzerothEcho"
with zipfile.ZipFile("AzerothEcho.zip", "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted(os.listdir(src)):
        z.write(os.path.join(src, f), "AzerothEcho/" + f)
```

Verify contents:

```bash
unzip -l AzerothEcho.zip
```

Expected:

```
AzerothEcho/AzerothEcho.lua
AzerothEcho/AzerothEcho.toc
AzerothEcho/Core.lua
AzerothEcho/Panel.lua
AzerothEcho/RiftMap.lua
```

Current archive size — **9 217 B**.

## Updating the manifest

After rebuilding the ZIP, update `client/manifest.json`:

```powershell
$h = (Get-FileHash .\AzerothEcho.zip -Algorithm SHA256).Hash.ToLower()
$s = (Get-Item .\AzerothEcho.zip).Length
```

Write `sha256` and `size` for the `addons/AzerothEcho.zip` entry. Otherwise the
launcher will consider the file outdated — or miss the update entirely.

## Debugging

Open the addon window: `/echoe` or the minimap button.

Verify the addon is loaded:

```
/run print(IsAddOnLoaded("AzerothEcho"))
```

Show Lua errors: enable `ScriptErrors` (`/console scriptErrors 1`).

Check the addon list: character select → "AddOns" → `AzerothEcho` should be listed
and enabled.

## Limitations

The addon has not been tested in game. Only the archive structure is known to be
correct and the `.toc` meets 3.3.5a requirements. Interface behaviour — opening the
panel, rendering the rift map, reacting to server data — requires a live login.
