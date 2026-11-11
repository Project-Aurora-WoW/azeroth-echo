# SOAP и администрирование

Удалённое управление сервером без входа в игру.

## Что такое SOAP

SOAP-интерфейс AzerothCore принимает команды консоли по HTTP и возвращает результат. Полезен для скриптов, мониторинга и администрирования без клиента.

## Включение

`configs/worldserver.conf`:

```ini
SOAP.Enabled = 1
SOAP.IP      = "127.0.0.1"
SOAP.Port    = 7878
```

Требуется рестарт `worldserver`. Проверка:

```powershell
Test-NetConnection 127.0.0.1 -Port 7878
```

## Права доступа

SOAP авторизуется **учётной записью аккаунта** и проверяет RBAC. Три вещи должны совпасть:

1. Аккаунт существует в `echo_auth.account`.
2. У аккаунта `gmlevel >= 3` в `account_access`.
3. `RealmID = -1` (доступ на все реалмы).

```sql
SELECT a.id, a.username, aa.gmlevel, aa.RealmID
FROM echo_auth.account a
JOIN echo_auth.account_access aa ON aa.id = a.id;
```

Если `RealmID` не `-1`, ядро откажет с сообщением:

```
User <name> has to be assigned on all realms (with RealmID = '-1')
```

Выдать права:

```sql
INSERT IGNORE INTO echo_auth.rbac_account_permissions (accountId, permissionId, granted, realmId)
VALUES (1, 192, 1, -1),   -- Role: Sec Level Administrator
       (1, 196, 1, -1),   -- Role: Administrator Commands
       (1, 725, 1, -1);   -- Command: server info
```

## Формат запроса

Параметр команды должен быть внутри тега **`<command>` без префикса namespace**. С префиксом `ns1:` ядро вернёт `Command can not be empty`.

### Рабочий шаблон

```xml
<?xml version="1.0" encoding="utf-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                   xmlns:ns1="urn:AC">
  <SOAP-ENV:Body>
    <ns1:executeCommand>
      <command>server info</command>
    </ns1:executeCommand>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
```

`SOAPAction: "urn:AC#executeCommand"`, заголовок `Content-Type: text/xml; charset=utf-8`, Basic-аутентификация `логин:пароль_аккаунта`.

### Python

```python
import base64, urllib.request, re

def soap(cmd, user, pw):
    env = ('<?xml version="1.0" encoding="utf-8"?>'
           '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" '
           'xmlns:ns1="urn:AC"><SOAP-ENV:Body><ns1:executeCommand>'
           f'<command>{cmd}</command>'
           '</ns1:executeCommand></SOAP-ENV:Body></SOAP-ENV:Envelope>').encode()
    auth = base64.b64encode(f"{user}:{pw}".encode()).decode()
    req = urllib.request.Request("http://127.0.0.1:7878/", data=env, headers={
        "Content-Type": "text/xml; charset=utf-8",
        "SOAPAction": '"urn:AC#executeCommand"',
        "Authorization": "Basic " + auth})
    out = urllib.request.urlopen(req, timeout=30).read().decode("utf-8", "replace")
    m = re.search(r"<result[^>]*>(.*?)</result>", out, re.S)
    return re.sub(r"<[^>]+>", "", m.group(1) if m else out).replace("&#xD;", "").strip()

print(soap("server info", "MAX", "max"))
```

### PowerShell

```powershell
$user = "MAX"; $pw = "max"
$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${user}:${pw}"))
$body = @"
<?xml version="1.0" encoding="utf-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="urn:AC">
  <SOAP-ENV:Body><ns1:executeCommand><command>server info</command></ns1:executeCommand></SOAP-ENV:Body>
</SOAP-ENV:Envelope>
"@
Invoke-RestMethod -Uri "http://127.0.0.1:7878/" -Method Post -Body $body `
  -ContentType "text/xml; charset=utf-8" `
  -Headers @{ SOAPAction = '"urn:AC#executeCommand"'; Authorization = "Basic $pair" }
```

## Полезные команды

### Состояние сервера

```
server info
gm list
```

Пример ответа `server info`:

```
AzerothCore rev. unknown 1970-01-01 ... (Win64, RelWithDebInfo, Static)
Connected players: 0 (peak: 0).
Characters in world: 0 (peak: 0, lifetime: 2).
Minimum account security level to log in: 0.
Server uptime: 4 minute(s) 2 second(s)
Update time diff: 2ms. Last 500 diffs summary:
|- Mean: 3ms
|- Median: 2ms
|- Percentiles (95, 99, max): 8ms, 16ms, 22ms
```

### Аккаунты

```
account create MYACC mypassword
account set gmlevel MYACC 3 -1
account delete MYACC
```

### Поиск контента

```
lookup item Печать
lookup creature Портальный
lookup spell Voidrest
lookup title Echo
```

Поиск работает по подстроке имени. Числовой ID в `lookup item 70002` не находится — команда ищет в базовом диапазоне; используйте имя.

### Перезагрузка

```
reload all
reload item_template
reload creature_template
```

Список доступных: `reload` без аргументов печатает возможные подкоманды. Например, `reload chartitles_dbc` **не существует** — титулы перезагружаются только рестартом.

### Остановка

```
server shutdown 10
server shutdown cancel
server restart 30
```

## Автоматизация

Проверка живости сервера из планировщика:

```powershell
$info = soap "server info" "USER" "PASS"
if ($info -match "uptime") { "Сервер жив" } else { "Сервер не отвечает" }
```

Массовое создание аккаунтов:

```powershell
$accounts = @(
    @("PLAYER1","pass1"), @("PLAYER2","pass2")
)
foreach ($a in $accounts) {
    soap "account create $($a[0]) $($a[1])" "USER" "PASS"
}
```

## Безопасность

SOAP даёт **полный доступ уровня администратора**. Обязательно:

| Правило | Почему |
|---|---|
| `SOAP.IP = "127.0.0.1"` | не выставлять наружу |
| Отдельный аккаунт для SOAP | не использовать аккаунт игрока |
| Сильный пароль | пароль передаётся в Basic-аутентификации |
| Не логировать пароль | не писать в скриптах открытым текстом |
| Закрыть порт в файрволе | если сервер не в локальной сети |

Если SOAP нужен снаружи — только через SSH-туннель или обратный прокси с TLS, не напрямую.

## Диагностика

| Симптом | Причина |
|---|---|
| `HTTP 401 Unauthorized` | неверный логин/пароль, или `gmlevel < 3` |
| `Command can not be empty` | тег с префиксом `<ns1:command>` вместо `<command>` |
| `User has to be assigned on all realms` | `RealmID != -1` |
| Соединение отклонено | `SOAP.Enabled = 0` или порт занят |
| Команда не выполняется | RBAC: нет `permissionId` на команду |

Проверить, что команда вообще разрешена аккаунту:

```sql
SELECT p.name
FROM echo_auth.rbac_account_permissions ap
JOIN echo_auth.rbac_permissions p ON p.id = ap.permissionId
WHERE ap.accountId = 1 AND p.name LIKE '%server%';
```
