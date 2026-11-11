# Realm content

Everything the project added to the world: NPCs, items, title, spell, modes.

*Русская версия: [Контент реалма](Контент-реалма)*

## ID ranges

To avoid collisions with base ACDB and modules:

| Range | Purpose |
|---|---|
| `70001–70199` | project NPCs and items |
| `70100–70199` | Waloria rewards, level rewards |
| `70200–70999` | campaign reserve |
| `705605` | challenge altar gameobject |
| `990001–991999` | Archivist module |
| `70010` (spell) | mount spell |
| `178` (title) | "Echo Keeper" title |

## NPCs (18)

| Entry | Name | Role |
|---|---|---|
| 70001 | Portal Guardian | starting zone choice, teleports, world entry |
| 70100 | Akheron the Voidborn | rift boss |
| 70101 | Cultist of the Abyssal Grin | servant of Prophet Nal'kur |
| 70103 | Ritual Altar of the Cult | ritual object |
| 70105 | Void Warden | rift elemental |
| 70106 | Ritual Hearth | heart of the Awakening |
| 70110 | Captive Mage Talvin | campaign 1 quest NPC |
| 70120 | Archmage Elianna | campaign 2 quest NPC |
| 70130 | Prophet Nal'kur | campaign 3 antagonist |
| 70140 | Foulsight | eye of the Void |
| 70150 | Commander Valiria | Order of Dawn |
| 70160 | Advisor Mortega | Order of Dawn |
| 70172 | Runic Burn | services |
| 70173 | Gold Keeper | gold storage |
| 70174 | Warden of Change | faction change |
| 70180 | Chronicler of the Order | lore archive (Archivist module) |
| 70190 | Void Rift | invasion point |
| 70191 | Withered of the Rift | elite |

## Items (14)

### Campaign rewards

| Entry | Name | Purpose |
|---|---|---|
| 70002 | Seal of the Echo Keeper | title token (campaign 3) |
| 70003 | Voidrest Pegasus | mount token, bound to spell 70010 |
| 70004 | Brand of the Void Wardens | dragon summon right (campaign 2) |
| 70008 | Void Shard | corruption source (VoidCorruption) |

### Banners and costumes

| Entry | Name |
|---|---|
| 70010 | Banner: Will of Lordaeron |
| 70011 | Banner: Cult of the Damned |
| 70012 | Banner: Silver Dawn |
| 70013 | Banner: Defectors of Stratholme |
| 70015 | Stalker's Overalls |
| 70016 | Plague Doctor's Costume |
| 70017 | Naxxramas Armor |
| 70018 | Zone Artifact |

### Waloria rewards

| Entry | Name | Condition |
|---|---|---|
| 70100 | Order Ration | level 2 |
| 70101 | Echo Satchel | every 5 levels |

## Title "Echo Keeper"

| Parameter | Value |
|---|---|
| ID | 178 |
| Male | "Echo Keeper" |
| Female | "Echo Keeper" |
| Mask (`Mask_ID`) | 6727 |
| Client | `CharTitles.dbc` inside `patch-x.mpq` |
| Server | `chartitles_dbc` in `echo_world` |

Granted from Lua on campaign 3 completion:

```lua
player:SetTitle(178)
```

The stock WoW title range is 1–47. ID 178 sits outside it and its behaviour is
empirical. If the title does not appear in game, a rebuild with an ID inside the
stock range is required.

## Spell "Summon: Voidrest Pegasus"

| Parameter | Value |
|---|---|
| ID | 70010 |
| Template | clone of spell 45991 |
| Name enUS | `Summon: Voidrest Pegasus` |
| Category | 76 (mounts) |
| Client | `Spell.dbc` inside `patch-x.mpq` |
| Server | `spell_dbc` in `echo_world` |

Item binding:

```sql
UPDATE item_template
SET spellid_1=70010, spelltrigger_1=0, spellcategory_1=76, spellcategorycooldown_1=-1
WHERE entry=70003;
```

The client spell name is enUS only: `Spell.dbc` has no separate ruRU slot for
`SpellName`.

## Campaigns

| # | Name | Key NPCs | Reward |
|---|---|---|---|
| 1 | Ashes of Zul'Drak | Talvin | access token |
| 2 | The Awakening | Elianna | Brand of the Void Wardens 70004 |
| 3 | Echo Keeper | Nal'kur | Seal 70002 + title 178 + mount 70003 |
| 4 | — | Valiria, Mortega | — |

Campaign logic: `lua_scripts/Campaign1–4.lua` and `CampaignManager.lua`;
registry in `00_CampaignRegistry.ext`.

## Challenge modes

The Altar of Trials (gameobject **705605**) opens the mode selection menu.
Implemented by the `echo-challenge-modes` module, class `altar_challenge_modes`.

| Mode | Effect |
|---|---|
| Hardcore | death is permanent, resurrection forbidden |
| Semi-Hardcore | penalties instead of permanent death |
| Self-Crafted | cannot use items made by others |
| Item Quality Level | gear quality cap |
| Slow XP | reduced experience multiplier |
| Very Slow XP | heavily reduced |
| Quest XP Only | experience from quests only |
| Iron Man | no deaths and no trading |

Configuration: `configs/modules/echo-challenge-modes.conf`.

## Store

Tables `realm_store_*` in `echo_world`; UI in `client/store-ui/` and
`lua_scripts/Store_*.lua`.

| Table | Purpose |
|---|---|
| `realm_store_categories` | item categories |
| `realm_store_services` | store entries |
| `realm_store_currencies` | currencies |
| `realm_store_logs` | purchase log |

## PvP and events

| Mechanism | Implementation |
|---|---|
| PvP stats | `realm_pvp_stats` (`echo_world`) |
| PvP zone | `22_SanctuaryPvP.lua` |
| PvP shop | `30_PvpShop.lua`, NPC 70170 |
| Echo tokens | item 70005 |
| Events | `10_EventSystem.lua`, `events` tables |
| Played-time rewards | `realm_played_time_rewards` (`echo_characters`) |

## Verifying content on a live server

Via SOAP (see [SOAP and administration](SOAP-Admin-EN)):

```
lookup item Seal          → 70002
lookup item Voidrest      → 70003
lookup item Shard         → 70008
lookup creature Portal    → 70001
lookup spell Voidrest     → 70010
lookup title Echo         → 178
```

Caveat: `lookup item 70002` by number does not match — the command searches the
base range; search by name works.
