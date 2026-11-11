# Аддон AzerothEcho

Клиентский интерфейс реалма: кампании, ивенты, PvP, карта разломов.

## Файлы

| Файл | Размер | Роль |
|---|---|---|
| `AzerothEcho.toc` | 403 б | манифест аддона |
| `AzerothEcho.lua` | 5 031 б | точка входа, роутинг |
| `Core.lua` | 4 543 б | ядро: события, состояние |
| `Panel.lua` | 10 500 б | главная панель |
| `RiftMap.lua` | 3 906 б | карта разломов |

## Манифест

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

Порядок в списке файлов важен: `Core.lua` грузится первым, `AzerothEcho.lua` — последним, потому что зависит от остальных.

`Interface: 30300` соответствует клиенту 3.3.5a (build 12340 → интерфейс 30300).

## Установка

Распаковать `AzerothEcho.zip` так, чтобы получилось:

```
WoW/Interface/AddOns/AzerothEcho/
├── AzerothEcho.toc
├── AzerothEcho.lua
├── Core.lua
├── Panel.lua
└── RiftMap.lua
```

Вложенная папка `AzerothEcho/AzerothEcho/` — ошибка, аддон не загрузится. Проверить: `.toc` должен лежать непосредственно в `AddOns/AzerothEcho/`.

## Связь с сервером

Аддон общается с сервером через `lua_scripts/AddonBridge.lua`. Канал — префикс сообщений, которые клиент и сервер обмениваются через чат-протокол.

```
клиент                          сервер
  │                              │
  ├─ SendAddonMessage("ECHO", …) ─► AddonBridge.lua
  │                              │  разбор, обработка
  ◄─ SendAddonMessage("ECHO", …) ─┤
  │                              │
```

Если аддон открывается, но данные пустые — проблема в мосте, а не в интерфейсе: проверить, что `AddonBridge.lua` загружен и `mod-ale` активен.

## Сборка ZIP

Архив должен содержать файлы без вложенного каталога верхнего уровня:

```python
import zipfile, os
src = "addons/AzerothEcho"
with zipfile.ZipFile("AzerothEcho.zip", "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted(os.listdir(src)):
        z.write(os.path.join(src, f), "AzerothEcho/" + f)
```

Проверка содержимого:

```bash
unzip -l AzerothEcho.zip
```

Ожидается:

```
Echoes/AzerothEcho/AzerothEcho.lua
Echoes/AzerothEcho/AzerothEcho.toc
Echoes/AzerothEcho/Core.lua
Echoes/AzerothEcho/Panel.lua
Echoes/AzerothEcho/RiftMap.lua
```

Текущий размер архива — **9 217 б**.

## Обновление в манифесте

После пересборки ZIP обновить `client/manifest.json`:

```powershell
$h = (Get-FileHash .\AzerothEcho.zip -Algorithm SHA256).Hash.ToLower()
$s = (Get-Item .\AzerothEcho.zip).Length
```

Записать `sha256` и `size` для записи `addons/AzerothEcho.zip`. Иначе лаунчер будет считать файл устаревшим или, наоборот, не заметит обновление.

## Отладка

Открыть окно аддона: `/echoe` или кнопка на миникарте.

Проверить, что аддон загружен:

```
/run print(IsAddOnLoaded("AzerothEcho"))
```

Посмотреть ошибки Lua: включить в клиенте `ScriptErrors` (`/console scriptErrors 1`).

Найти в списке аддонов: экран выбора персонажа → «Модификации» → должен быть `AzerothEcho`, отмечен включённым.

## Ограничения

В игре аддон не проверялся. Известно только, что структура архива корректна и `.toc` соответствует требованиям клиента 3.3.5a. Поведение интерфейса — открытие панели, отрисовка карты разломов, реакция на данные сервера — требует живого входа.
