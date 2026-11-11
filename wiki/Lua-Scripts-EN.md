# Lua scripts

Server-side logic on ALE (AzerothCore Lua Engine). 38 files in `lua_scripts/`.

*Русская версия: [Lua-скрипты](Lua-скрипты)*

## Requirement

Scripts do not work without the **`mod-ale`** module (an Eluna fork). If the module
is not compiled, all `.lua` files are silently ignored.

## Structure

### Campaigns

| File | Contents |
|---|---|
| `00_CampaignRegistry.ext` | campaign registry: IDs, stages, conditions |
| `Campaign1.lua` | Ashes of Zul'Drak |
| `Campaign2.lua` | The Awakening |
| `Campaign3.lua` | Echo Keeper |
| `Campaign4.lua` | fourth storyline |
| `CampaignManager.lua` | shared progress manager |

### World systems (05–30)

| File | Purpose |
|---|---|
| `05_VoidAuras.lua` | Void auras |
| `06_WaloriaRewards.lua` | level rewards |
| `07_StartingZone.lua` | starting zone choice |
| `08_ClientFixes.lua` | naked-character fix, lore announcements |
| `09_WorldChat.lua` | world chat |
| `10_EventSystem.lua` | events |
| `11_FixGear.lua` | gear repair |
| `12_ZoneRestrictor.lua` | zone restrictions |
| `13_AccountMounts.lua` | account-wide mounts |
| `14_AutoLearnSkills.lua` | automatic skill learning |
| `15_Enchanter.lua` | enchanter |
| `16_GoldStorage.lua` | gold storage |
| `17_TimeRift.lua` | time rifts |
| `18_VoidCorruption.lua` | corruption system |
| `19_PlayedTimeRewards.lua` | played-time rewards |
| `20_PvpSystem.lua` | PvP system |
| `21_FactionChanger.lua` | faction change |
| `22_SanctuaryPvP.lua` | PvP zone |
| `30_PvpShop.lua` | PvP shop |

### Other

| File | Purpose |
|---|---|
| `AIO.lua` | AIO interface framework |
| `AddonBridge.lua` | server ↔ `AzerothEcho` addon bridge |
| `LoreArchive.lua` | lore archive |
| `PortalGuardian.lua` | Portal Guardian |
| `WelcomeSystem.lua` | welcome system |
| `Store_Client.lua`, `Store_Server.lua`, `Store_DataStruct.lua` | store |

### Dependencies

`Dep_crc32lua/`, `Dep_LuaSrcDiet/`, `Dep_Smallfolk/`, `extensions/`,
`lualzw-zeros/`, `queue.lua` — libraries, do not touch without reason.

## Campaign registry

`00_CampaignRegistry.ext` is the single source of truth: which campaigns exist,
which stages, which transition conditions.

```lua
-- example structure
local CAMPAIGNS = {
    [1] = { name = "Ashes of Zul'Drak", stages = 3 },
    [2] = { name = "The Awakening",     stages = 4 },
    [3] = { name = "Echo Keeper",       stages = 5 },
    [4] = { name = "…",                 stages = 3 },
}
```

Adding a campaign starts here, then a `<Name>.lua` file is created and registered in
the manager.

## Campaign 3 final rewards

Granted in `Campaign3.lua`, function `GrantFinalReward`:

```lua
player:AddItem(70002, 1)    -- Seal of the Echo Keeper
player:AddItem(70003, 1)    -- Voidrest Pegasus
player:SetTitle(178)        -- "Echo Keeper" title
```

`SetTitle` may be absent in some ALE builds — in that case `LearnTitle` is used.
Verify on site.

## Scripts adapted from waloriaold

| Source | Adaptation |
|---|---|
| `90000_startingzonepicker.lua` | `07_StartingZone.lua` |
| `nakedbugfix.lua` | `08_ClientFixes.lua` — naked-character fix |
| `announcer.lua` | `08_ClientFixes.lua` — lore announcements |
| `worldchat.lua` | `09_WorldChat.lua` |
| `command_fixgear.lua` | `11_FixGear.lua` |
| `tbcwotlkrestricter.lua` | `12_ZoneRestrictor.lua` |

Starting zone coordinates in `07_StartingZone.lua` were verified on the Waloria realm.

## Debugging

Lua logs go to the shared `worldserver` log. For detail, raise the level:

```ini
Logger.scripts.hotswap = 5,Console Server
```

Hot reload a script without restarting:

```
reload eluna
```

If the command is missing, `mod-ale` is not compiled or failed to load.

## Common errors

| Symptom | Cause |
|---|---|
| Scripts do not execute | no `mod-ale` in the build |
| `attempt to index a nil value` | reference to a non-existent NPC or item — check the DB entry |
| Cyrillic in chat breaks | file not in UTF-8 without BOM |
| A script cannot see another | load order: dependencies (`Dep_*`) must load first |
