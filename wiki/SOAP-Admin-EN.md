# SOAP and administration

Remote server control without logging into the game.

*Русская версия: [SOAP и администрирование](SOAP-и-администрирование)*

## What SOAP is

The AzerothCore SOAP interface accepts console commands over HTTP and returns the
result. Useful for scripting, monitoring and administration without a client.

## Enabling

`configs/worldserver.conf`:

```ini
SOAP.Enabled = 1
SOAP.IP      = "127.0.0.1"
SOAP.Port    = 7878
```

Requires a `worldserver` restart. Verify:

```powershell
Test-NetConnection 127.0.0.1 -Port 7878
```

## Access rights

SOAP authenticates with an **account** and checks RBAC. Three things must line up:

1. The account exists in `echo_auth.account`.
2. The account has `gmlevel >= 3` in `account_access`.
3. `RealmID = -1` (access to all realms).

```sql
SELECT a.id, a.username, aa.gmlevel, aa.RealmID
FROM echo_auth.account a
JOIN echo_auth.account_access aa ON aa.id = a.id;
```

If `RealmID` is not `-1`, the core refuses with:

```
User <name> has to be assigned on all realms (with RealmID = '-1')
```

Grant permissions:

```sql
INSERT IGNORE INTO echo_auth.rbac_account_permissions (accountId, permissionId, granted, realmId)
VALUES (1, 192, 1, -1),   -- Role: Sec Level Administrator
       (1, 196, 1, -1),   -- Role: Administrator Commands
       (1, 725, 1, -1);   -- Command: server info
```

## Request format

The command parameter must sit inside a **`<command>` tag with no namespace
prefix**. With `ns1:` the core returns `Command can not be empty`.

### Working template

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

`SOAPAction: "urn:AC#executeCommand"`, header `Content-Type: text/xml; charset=utf-8`,
Basic authentication `login:account_password`.

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

## Useful commands

### Server state

```
server info
gm list
```

Sample `server info` output:

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

### Accounts

```
account create MYACC mypassword
account set gmlevel MYACC 3 -1
account delete MYACC
```

### Content lookup

```
lookup item Seal
lookup creature Portal
lookup spell Voidrest
lookup title Echo
```

Search works by name substring. A numeric ID in `lookup item 70002` will not match —
the command searches the base range; use the name.

### Reload

```
reload all
reload item_template
reload creature_template
```

`reload` without arguments prints available subcommands. Note that
`reload chartitles_dbc` **does not exist** — titles reload only on restart.

### Shutdown

```
server shutdown 10
server shutdown cancel
server restart 30
```

## Automation

Liveness check from a scheduler:

```powershell
$info = soap "server info" "USER" "PASS"
if ($info -match "uptime") { "Server is up" } else { "Server is not responding" }
```

Bulk account creation:

```powershell
$accounts = @(
    @("PLAYER1","pass1"), @("PLAYER2","pass2")
)
foreach ($a in $accounts) {
    soap "account create $($a[0]) $($a[1])" "USER" "PASS"
}
```

## Security

SOAP grants **full administrator-level access**. Mandatory:

| Rule | Why |
|---|---|
| `SOAP.IP = "127.0.0.1"` | never expose it |
| Dedicated account for SOAP | do not reuse a player account |
| Strong password | the password travels in Basic auth |
| Never log the password | do not hardcode it in scripts |
| Block the port in the firewall | if the server is not on a local network |

If SOAP is needed externally, use an SSH tunnel or a TLS reverse proxy — never
expose it directly.

## Diagnostics

| Symptom | Cause |
|---|---|
| `HTTP 401 Unauthorized` | wrong credentials, or `gmlevel < 3` |
| `Command can not be empty` | prefixed tag `<ns1:command>` instead of `<command>` |
| `User has to be assigned on all realms` | `RealmID != -1` |
| Connection refused | `SOAP.Enabled = 0` or the port is taken |
| Command does nothing | RBAC: no `permissionId` for the command |

Check whether a command is permitted for the account:

```sql
SELECT p.name
FROM echo_auth.rbac_account_permissions ap
JOIN echo_auth.rbac_permissions p ON p.id = ap.permissionId
WHERE ap.accountId = 1 AND p.name LIKE '%server%';
```
