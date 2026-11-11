<#
.SYNOPSIS
    Останавливает worldserver и authserver — в обратном порядке запуску.

.DESCRIPTION
    Сначала worldserver (чтобы он успел закрыть пулы и записать состояние),
    затем authserver. Worldserver останавливается через SOAP, если он доступен,
    иначе процесс завершается принудительно.

.PARAMETER ServerDir
    Каталог с бинарниками.

.PARAMETER SoapUser
    Логин ГМ-аккаунта для SOAP (по умолчанию MAX).

.EXAMPLE
    .\stop-server.ps1
#>
[CmdletBinding()]
param(
    [string]$ServerDir = "E:\acbuild\bin\RelWithDebInfo",
    [string]$SoapUser = "MAX",
    [string]$SoapPass = "max",
    [int]$SoapPort = 7878
)

function Write-Step($m) { Write-Host "> $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "  OK  $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "  !!  $m" -ForegroundColor Yellow }

$world = Get-Process worldserver -ErrorAction SilentlyContinue
if ($world) {
    Write-Step "Остановка worldserver (SOAP, до 60 с)"
    $body = @"
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<soap:Body><executeCommand xmlns="urn:AC"><command>server shutdown 10</command></executeCommand></soap:Body>
</soap:Envelope>
"@
    $soapOk = $false
    try {
        $auth = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${SoapUser}:${SoapPass}")) }
        $null = Invoke-WebRequest -Uri "http://127.0.0.1:$SoapPort/" -Method Post -Body $body -ContentType "text/xml; charset=utf-8" -Headers $auth -UseBasicParsing -TimeoutSec 15
        $soapOk = $true
    } catch {
        Write-Warn "SOAP недоступен: $($_.Exception.Message)"
    }

    if ($soapOk) {
        $deadline = (Get-Date).AddSeconds(60)
        while ((Get-Date) -lt $deadline -and (Get-Process -Id $world.Id -ErrorAction SilentlyContinue)) {
            Start-Sleep -Seconds 2
        }
    }
    if (Get-Process -Id $world.Id -ErrorAction SilentlyContinue) {
        Write-Warn "graceful shutdown не сработал — завершаю процесс"
        Stop-Process -Id $world.Id -Force
    }
    Start-Sleep -Seconds 3
    Write-Ok "worldserver остановлен"
} else {
    Write-Warn "worldserver не запущен"
}

Write-Step "Остановка authserver"
$authProc = Get-Process authserver -ErrorAction SilentlyContinue
if ($authProc) {
    $authProc | ForEach-Object { Stop-Process -Id $_.Id -Force }
    Start-Sleep -Seconds 2
    Write-Ok "authserver остановлен"
} else {
    Write-Warn "authserver не запущен"
}

foreach ($port in 8085, 3724, 7878) {
    $busy = Test-NetConnection -ComputerName 127.0.0.1 -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($busy) { Write-Warn "порт $port всё ещё занят" } else { Write-Host "  порт $port свободен" }
}
