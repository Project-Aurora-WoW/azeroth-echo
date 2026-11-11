# SQL migrations

21 project migrations, two versions, and why the adapted ones are used.

*Русская версия: [SQL-миграции](SQL-миграции)*

## Two folders

| Folder | State | Use |
|---|---|---|
| `sql/world/` | originals, written for another core schema | **no** |
| `sql/world-adapted/` | adapted to the actual schema | **yes** |

The originals fail on 15 of 21 files. The adapted ones passed all 21 without errors.

## Composition

| # | File | Creates |
|---|---|---|
| 0001 | `world_baseline.sql` | Portal Guardian 70001 + capital spawns |
| 0002 | `campaign_progress.sql` | `realm_campaign_progress` |
| 0003 | `cult_npcs.sql` | Cult NPCs and Morza spawns |
| 0004 | `campaign_reward_item.sql` | campaign 1 item |
| 0005 | `campaign2_content.sql` | campaign 2 content |
| 0006 | `campaign3_rewards.sql` | Seal 70002, Voidrest Pegasus 70003 |
| 0007 | `campaign3_content.sql` | campaign 3 NPCs |
| 0008 | `npc_displayid.sql` | NPC models |
| 0009 | `event_pvp.sql` | item 70005, `realm_pvp_stats` |
| 0010 | `pvp_shop.sql` | Order Quartermaster 70170 |
| 0011 | `lore_archivist.sql` | Chronicler of the Order 70180 |
| 0012 | `campaign4_content.sql` | campaign 4 content |
| 0013 | `campaign_manager.sql` | `realm_campaign_log` |
| 0014 | `waloria_rewards.sql` | Ration 70100, Satchel 70101, `realm_level_rewards` |
| 0015 | `token_outbox.sql` | `realm_token_outbox`, `realm_token_receipt` |
| 0016 | `dbc_reference_sample.sql` | **empty** — a sample, fully commented out |
| 0017 | `waloria_tools.sql` | `realm_fixgear` |
| 0018 | `eluna_scripts_tier_a.sql` | NPC 70191, item 70008, spell into `spell_dbc` |
| 0019 | `challenge_modes.sql` | Altar of Trials 705605 |
| 0020 | `store_system.sql` | 5 `realm_store_*` tables |
| 0021 | `public_scripts.sql` | `realm_played_time_rewards` |

## Target databases

Not every migration writes to `world`. Correct distribution:

| Database | Migrations |
|---|---|
| `echo_world` | 0001, 0003–0012, 0014, 0016, 0018–0021 |
| `echo_characters` | 0002, 0013, 0015, 0017 |
| both | 0014 (items in world, `realm_level_rewards` in characters) |
| both | 0018 (NPCs and items in world, `realm_gold_storage` in characters) |
| both | 0021 (`realm_played_time_rewards` in characters, NPCs in world) |

In the originals `USE acore_world;` / `USE acore_characters;` point at upstream —
the adapted versions use `echo_*`.

## What was incompatible

The core (`ACDB 335.17-dev`) has a different schema than the migrations expect.

### Missing `creature_template` columns

| Column | In migration | Action |
|---|---|---|
| `InhabitType` | yes | dropped — not present in this core |
| `minhealth` / `maxhealth` | in 0010 | dropped, HP via `HealthModifier` |
| `RangedModifier` | in 0010 | dropped |
| `mechanic_immune_mask` | in 0010 | dropped |
| `trainer_type/spell/class/race` | in 0010 | dropped |

### Renames

| Was | Became |
|---|---|
| `creature.id1` | `creature.id` |
| `item_template.StatsCount` | none — replaced by `stat_type1..10` |

### Missing `creature` and `item_template` columns

`curpower`, `curenergy`, `modelid1`, `spawndist`, `baseattacktime`,
`rangeattacktime` — dropped in adapted versions.

### MySQL 8.0 syntax

| Problem | Solution |
|---|---|
| `CREATE INDEX IF NOT EXISTS` | not in MySQL 8.0 → `CREATE INDEX` |
| `ADD INDEX IF NOT EXISTS` | → `ALTER TABLE ... ADD INDEX` |
| `subclass = -1` on `tinyint unsigned` | → `0` |

### `spell_dbc`

The original 0018 writes to `SpellNameLang` — it does not exist. This core splits
localised names across `Name_Lang_enUS`, `Name_Lang_ruRU`, etc.

## Applying

```powershell
$dir = "E:\azeroth-echo\sql\world-adapted"
Get-ChildItem $dir -Filter *.sql | Sort-Object Name | ForEach-Object {
    Write-Host ">> $($_.Name)"
    Get-Content $_.FullName -Raw | mysql -u root -p --default-character-set=utf8mb4
}
```

`Sort-Object Name` guarantees the `0001 → 0021` order. It must not be broken:
`0006` creates items referenced by later migrations.

## Verification after applying

```sql
-- project NPCs
SELECT COUNT(*) FROM echo_world.creature_template WHERE entry BETWEEN 70000 AND 70200;  -- 18

-- project items
SELECT entry, name FROM echo_world.item_template WHERE entry BETWEEN 70000 AND 70200 ORDER BY entry;  -- 14

-- realm_* tables
SELECT table_schema, table_name FROM information_schema.tables
WHERE table_name LIKE 'realm\_%' ORDER BY 1,2;  -- 15

-- title and spell
SELECT ID, Name_Lang_ruRU FROM echo_world.chartitles_dbc WHERE ID=178;
SELECT ID, Name_Lang_ruRU FROM echo_world.spell_dbc WHERE ID=70010;
```

## Trap: a base world dump wipes custom content

Importing base ACDB **after** the project migrations overwrites the tables and the
custom records disappear.

Correct order:

1. Database schema
2. Base ACDB world
3. Project migrations

If content is gone, reapply `sql/world-adapted/`. Idempotency is provided by the
`DELETE` + `INSERT` pairs in every migration.

## Known defects

**Items were inserted incompletely.** Some `item_template` rows from
0004/0005/0006/0009/0012 were inserted with only 15–45 columns out of 138:
`GROUP_CONCAT` in diagnostics truncates at 1024 bytes, so the adapter dropped
`bonding`, `description`, `Material`, `Stackable`. Items 70002, 70003 and 70004
were inserted separately, as full 138-column records, by cloning the 70008 template.

Keep this in mind when regenerating migrations: never trust a truncated column list.
