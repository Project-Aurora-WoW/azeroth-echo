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
