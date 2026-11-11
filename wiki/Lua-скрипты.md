# Lua-скрипты

Серверная логика на ALE (AzerothCore Lua Engine). 38 файлов в `lua_scripts/`.

## Требование

Скрипты не работают без модуля **`mod-ale`** (форк Eluna). Если модуль не скомпилирован, все `.lua` молча игнорируются.

## Структура

### Кампании

| Файл | Содержание |
|---|---|
| `00_CampaignRegistry.ext` | реестр кампаний: ID, стадии, условия |
| `Campaign1.lua` | Пепел Зул'Драка |
| `Campaign2.lua` | Пробуждение |
| `Campaign3.lua` | Хранитель Эха |
| `Campaign4.lua` | четвёртая линия |
| `CampaignManager.lua` | общий менеджер прогресса |

### Системы мира (05–30)

| Файл | Назначение |
|---|---|
| `05_VoidAuras.lua` | ауры Пустоты |
| `06_WaloriaRewards.lua` | награды за уровни |
| `07_StartingZone.lua` | выбор стартовой зоны |
| `08_ClientFixes.lua` | фикс «голого персонажа», лор-анонсы |
| `09_WorldChat.lua` | мировой чат |
| `10_EventSystem.lua` | ивенты |
| `11_FixGear.lua` | починка экипировки |
| `12_ZoneRestrictor.lua` | ограничения зон |
| `13_AccountMounts.lua` | маунты на аккаунт |
| `14_AutoLearnSkills.lua` | автоизучение навыков |
| `15_Enchanter.lua` | зачарователь |
| `16_GoldStorage.lua` | банк золота |
| `17_TimeRift.lua` | временные разломы |
| `18_VoidCorruption.lua` | система порчи |
| `19_PlayedTimeRewards.lua` | награды за наигранное время |
| `20_PvpSystem.lua` | PvP-система |
| `21_FactionChanger.lua` | смена фракции |
| `22_SanctuaryPvP.lua` | PvP-зона |
| `30_PvpShop.lua` | PvP-магазин |

### Прочее

| Файл | Назначение |
|---|---|
| `AIO.lua` | каркас AIO-интерфейса |
| `AddonBridge.lua` | связь сервер ↔ аддон `AzerothEcho` |
| `LoreArchive.lua` | лор-архив |
| `PortalGuardian.lua` | Портальный Страж |
| `WelcomeSystem.lua` | приветствие |
| `Store_Client.lua`, `Store_Server.lua`, `Store_DataStruct.lua` | магазин |

### Зависимости

`Dep_crc32lua/`, `Dep_LuaSrcDiet/`, `Dep_Smallfolk/`, `extensions/`, `lualzw-zeros/`, `queue.lua` — библиотеки, не трогать без причины.

## Реестр кампаний

`00_CampaignRegistry.ext` — единая точка правды: какие кампании существуют, какие стадии, какие условия перехода.

```lua
-- пример структуры
local CAMPAIGNS = {
    [1] = { name = "Пепел Зул'Драка", stages = 3 },
    [2] = { name = "Пробуждение",      stages = 4 },
    [3] = { name = "Хранитель Эха",    stages = 5 },
    [4] = { name = "…",                stages = 3 },
}
```

Добавление кампании начинается отсюда, затем создаётся `<Имя>.lua` и регистрируется в менеджере.

## Выдача наград кампании 3

Конечная награда выдаётся в `Campaign3.lua`, функция `GrantFinalReward`:

```lua
player:AddItem(70002, 1)    -- Печать Хранителя Эха
player:AddItem(70003, 1)    -- Бездна-Пегас
player:SetTitle(178)        -- титул «Хранитель Эха»
```

Метод `SetTitle` может отсутствовать в некоторых сборках ALE — в таком случае используется `LearnTitle`. Проверяется на месте.

## Скрипты, адаптированные из waloriaold

| Источник | Адаптация |
|---|---|
| `90000_startingzonepicker.lua` | `07_StartingZone.lua` |
| `nakedbugfix.lua` | `08_ClientFixes.lua` — фикс «голого персонажа» |
| `announcer.lua` | `08_ClientFixes.lua` — лор-анонсы |
| `worldchat.lua` | `09_WorldChat.lua` |
| `command_fixgear.lua` | `11_FixGear.lua` |
| `tbcwotlkrestricter.lua` | `12_ZoneRestrictor.lua` |

Координаты стартовых зон в `07_StartingZone.lua` выверены на реалме Waloria.

## Отладка

Логи Lua уходят в общий лог `worldserver`. Для подробностей поднять уровень:

```ini
Logger.scripts.hotswap = 5,Console Server
```

Горячая перезагрузка скрипта без рестарта сервера:

```
reload eluna
```

Если команда отсутствует — модуль `mod-ale` не скомпилирован или загрузился с ошибкой.

## Типичные ошибки

| Симптом | Причина |
|---|---|
| Скрипты не выполняются | нет `mod-ale` в сборке |
| `attempt to index a nil value` | обращение к несуществующему НПС или предмету — проверить entry в БД |
| Кириллица в чате ломается | файл не в UTF-8 без BOM |
| Скрипт не видит другого | порядок загрузки: зависимости (`Dep_*`) должны грузиться раньше |

## Порядок загрузки

ALE не грузит файлы «как лежат» — порядок детерминирован и складывается из двух правил (`modules/mod-ale/src/LuaEngine/LuaEngine.cpp`):

1. Сначала исполняются **все `.ext`**, затем всё остальное (`.lua`, `.moon`, `.dll`, `.so`, `.out`) — строки 689–692.
2. Внутри каждой группы сортировка по **полному пути** как строке — `ScriptPathComparator`, строка 667.

Из этого следует:

- цифровые префиксы работают, и это единственный надёжный способ задать порядок;
- строчные буквы в ASCII больше заглавных, поэтому `queue.lua` уедет в самый конец, а `Store_DataStruct.lua` — раньше него;
- подпапки (`Dep_*`, `extensions/`) сортируются вместе со всеми: `Dep_crc32lua/…` встанет между `CampaignManager.lua` и `Dep_LuaSrcDiet/…`;
- файлы с **одинаковым именем** в разных папках не грузятся дважды — второй пропускается (строка 704).

### Раскладка проекта

| Префикс | Файл | Слой |
|---|---|---|
| — | `00_CampaignRegistry.ext` | реестр; всегда первый благодаря правилу `.ext` |
| 01 | `01_WelcomeSystem.lua` | приветствие входа, нужен только реестр |
| 02 | `02_AddonBridge.lua` | `AE_SendProgress` для менеджера |
| 03 | `03_CampaignManager.lua` | `AzerothEchoManager`, команды `.ae` / `.aecampaign` |
| 05–22 | системы реалма | ауры, ивенты, чат, казна, PvP и т.д. |
| 30 | `30_PvpShop.lua` | магазин жетонов |
| 41–44 | `4x_CampaignN.lua` | кампании — после менеджера |
| 45 | `45_LoreArchive.lua` | лор-архив |
| 46 | `46_PortalGuardian.lua` | Портальный Страж |
| 47 | `47_Store_Server.lua` | AIO-магазин |
| без номера | `AIO.lua`, `Store_DataStruct.lua`, `queue.lua`, `Store_Client.lua`, `Dep_*`, `extensions/` | библиотеки |

Файлы `AIO.lua`, `Store_DataStruct.lua` и `queue.lua` **не переименовываются**: их подключают через `require("AIO")`, `require("Store_DataStruct")`, `require("queue")`, а `require` ищет файл по имени.

### Как проверить фактический порядок

В `configs/worldserver.conf` поднять уровень логгера и перезапустить:

```ini
Logger.ALE=5,Console Server ALELog
```

В `logs/Server.log` появятся строки `AddScriptPath add path …` в порядке обхода каталога; исполнение идёт по отсортированному списку, поэтому проверять надо по именам файлов.
