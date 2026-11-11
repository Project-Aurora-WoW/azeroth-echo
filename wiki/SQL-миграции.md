# SQL-миграции

21 миграция проекта, две версии и почему используются именно адаптированные.

## Две папки

| Папка | Состояние | Использовать |
|---|---|---|
| `sql/world/` | исходные, под другую схему ядра | **нет** |
| `sql/world-adapted/` | адаптированные под фактическую схему | **да** |

Исходные миграции падают на 15 файлах из 21. Адаптированные прошли все 21 без ошибок.

## Состав

| № | Файл | Что создаёт |
|---|---|---|
| 0001 | `world_baseline.sql` | Портальный Страж 70001 + спавны в столицах |
| 0002 | `campaign_progress.sql` | `realm_campaign_progress` |
| 0003 | `cult_npcs.sql` | НПС Культа и спавны в Морзе |
| 0004 | `campaign_reward_item.sql` | предмет кампании 1 |
| 0005 | `campaign2_content.sql` | контент кампании 2 |
| 0006 | `campaign3_rewards.sql` | Печать 70002, Бездна-Пегас 70003 |
| 0007 | `campaign3_content.sql` | НПС кампании 3 |
| 0008 | `npc_displayid.sql` | модели НПС |
| 0009 | `event_pvp.sql` | предмет 70005, `realm_pvp_stats` |
| 0010 | `pvp_shop.sql` | Интендант Ордена 70170 |
| 0011 | `lore_archivist.sql` | Хронист Ордена 70180 |
| 0012 | `campaign4_content.sql` | контент кампании 4 |
| 0013 | `campaign_manager.sql` | `realm_campaign_log` |
| 0014 | `waloria_rewards.sql` | Паёк 70100, Сумка 70101, `realm_level_rewards` |
| 0015 | `token_outbox.sql` | `realm_token_outbox`, `realm_token_receipt` |
| 0016 | `dbc_reference_sample.sql` | **пустой** — образец, всё закомментировано |
| 0017 | `waloria_tools.sql` | `realm_fixgear` |
| 0018 | `eluna_scripts_tier_a.sql` | НПС 70191, предмет 70008, спелл в `spell_dbc` |
| 0019 | `challenge_modes.sql` | Алтарь Испытаний 705605 |
| 0020 | `store_system.sql` | 5 таблиц `realm_store_*` |
| 0021 | `public_scripts.sql` | `realm_played_time_rewards` |

## Целевые базы

Не все миграции пишут в `world`. Правильное распределение:

| База | Миграции |
|---|---|
| `echo_world` | 0001, 0003–0012, 0014, 0016, 0018–0021 |
| `echo_characters` | 0002, 0013, 0015, 0017 |
| обе | 0014 (предметы в world, `realm_level_rewards` в characters) |
| обе | 0018 (НПС и предметы в world, `realm_gold_storage` в characters) |
| обе | 0021 (`realm_played_time_rewards` в characters, НПС в world) |

В исходных миграциях `USE acore_world;` / `USE acore_characters;` указывают на апстрим — в адаптированных заменено на `echo_*`.

## Что было несовместимо

Ядро `ACDB 335.17-dev` имеет другую схему, чем ожидают исходные миграции.

### Отсутствующие колонки `creature_template`

| Колонка | Было в миграции | Что сделано |
|---|---|---|
| `InhabitType` | есть | выброшено — в этом ядре нет |
| `minhealth` / `maxhealth` | есть в 0010 | выброшено, HP через `HealthModifier` |
| `RangedModifier` | есть в 0010 | выброшено |
| `mechanic_immune_mask` | есть в 0010 | выброшено |
| `trainer_type/spell/class/race` | есть в 0010 | выброшено |

### Переименования

| Было | Стало |
|---|---|
| `creature.id1` | `creature.id` |
| `item_template.StatsCount` | нет — заменено на `stat_type1..10` |

### Отсутствующие колонки `creature` и `item_template`

`curpower`, `curenergy`, `modelid1`, `spawndist`, `baseattacktime`, `rangeattacktime` — выброшены в адаптированных версиях.

### Синтаксис MySQL 8.0

| Проблема | Решение |
|---|---|
| `CREATE INDEX IF NOT EXISTS` | нет в MySQL 8.0 → `CREATE INDEX` |
| `ADD INDEX IF NOT EXISTS` | → `ALTER TABLE ... ADD INDEX` |
| `subclass = -1` при `tinyint unsigned` | → `0` |

### `spell_dbc`

Исходная 0018 пишет в колонку `SpellNameLang` — её нет. В этом ядре локализованные имена разложены по `Name_Lang_enUS`, `Name_Lang_ruRU` и т.д.

## Порядок применения

```powershell
$dir = "E:\azeroth-echo\sql\world-adapted"
Get-ChildItem $dir -Filter *.sql | Sort-Object Name | ForEach-Object {
    Write-Host ">> $($_.Name)"
    Get-Content $_.FullName -Raw | mysql -u root -p --default-character-set=utf8mb4
}
```

`Sort-Object Name` гарантирует порядок `0001 → 0021`. Нарушать нельзя: `0006` создаёт предметы, на которые ссылаются более поздние миграции.

## Проверка после применения

```sql
-- НПС проекта
SELECT COUNT(*) FROM echo_world.creature_template WHERE entry BETWEEN 70000 AND 70200;  -- 18

-- предметы проекта
SELECT entry, name FROM echo_world.item_template WHERE entry BETWEEN 70000 AND 70200 ORDER BY entry;  -- 14

-- таблицы realm_*
SELECT table_schema, table_name FROM information_schema.tables
WHERE table_name LIKE 'realm\_%' ORDER BY 1,2;  -- 15

-- титул и спелл
SELECT ID, Name_Lang_ruRU FROM echo_world.chartitles_dbc WHERE ID=178;
SELECT ID, Name_Lang_ruRU FROM echo_world.spell_dbc WHERE ID=70010;
```

## Ловушка: дамп базового мира сносит кастом

Если заливать базовый ACDB **после** миграций проекта, дамп перезапишет таблицы и кастомные записи исчезнут.

Правильный порядок:

1. Схема баз
2. Базовый мир ACDB
3. Миграции проекта

Если кастом пропал — применить `sql/world-adapted/` повторно. Идемпотентность обеспечивается парами `DELETE` + `INSERT` в каждой миграции.

## Известные дефекты

**Предметы вставлены неполно.** Часть записей `item_template` из 0004/0005/0006/0009/0012 вставлялась только с 15–45 колонками из 138: `GROUP_CONCAT` в диагностике обрезал список на 1024 байтах, и адаптер выбросил `bonding`, `description`, `Material`, `Stackable`. Предметы 70002, 70003, 70004 вставлены отдельно, полными записями на все 138 колонок, через клон шаблона 70008.

При пересборке миграций это нужно учитывать: не полагаться на обрезанный список колонок.
