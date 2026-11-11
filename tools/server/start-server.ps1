<#
.SYNOPSIS
    Запускает authserver, затем worldserver — в правильном порядке.

.DESCRIPTION
    Порядок критичен: при старте authserver ставит всем реалмам
    REALM_FLAG_OFFLINE, а worldserver снимает этот бит только у своего реалма.
    Если worldserver поднять первым, authserver тут же пометит реалм офлайн
    и клиент покажет его недоступным.

    Скрипт ждёт открытия порта authserver, только потом стартует worldserver,
    затем проверяет порты и бит офлайна в таблице realmlist.

.PARAMETER ServerDir
    Каталог с worldserver.exe и authserver.exe.

.PARAMETER Restart
    Остановить уже запущенные процессы перед стартом.

.EXAMPLE
    .\start-server.ps1
    .\start-server.ps1 -Restart
#>
[CmdletBinding()]
param(
    [string]$ServerDir = "E:\acbuild\bin\RelWithDebInfo",
    [switch]$Restart
)

$ErrorActionPreference = "Continue"

function Write-Step($m) { Write-Host "> $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "  OK  $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "  !!  $m" -ForegroundColor Yellow }
function Write-Err($m)  { Write-Host "  XX  $m" -ForegroundColor Red }

function Wait-Port([int]$Port, [int]$TimeoutSec, [string]$What) {
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue) {
            return $true
        }
        Start-Sleep -Seconds 3
    }
    Write-Err "$What не открыл порт $Port за $TimeoutSec с"
    return $false
}

function Start-Utf8Process([string]$ExeName) {
    # Сервер печатает в консоль UTF-8, а стандартная консоль Windows в русской
    # локали работает в cp866 — кириллица превращается в «╨╖╨░╨│╤Г╨╢╨╡╨╜».
    # Запускаем через cmd, который сначала переключает кодовую страницу на 65001.
    $exe = Join-Path $ServerDir $ExeName
    if (-not (Test-Path $exe)) {
        Write-Err "не найден $exe"
        return $null
    }
    $null = Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c", "chcp 65001 >nul & `"$ExeName`"" `
        -WorkingDirectory $ServerDir -PassThru
    # cmd стартует сервер дочерним процессом — ждём именно его
    $baseName = [IO.Path]::GetFileNameWithoutExtension($ExeName)
    $deadline = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        $proc = Get-Process $baseName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($proc) { return $proc }
    }
    Write-Err "$ExeName не появился в списке процессов"
    return $null
}

if (-not (Test-Path (Join-Path $ServerDir "worldserver.exe"))) {
    Write-Err "Не найден $ServerDir\worldserver.exe"; exit 1
}
if (-not (Test-Path (Join-Path $ServerDir "logs"))) {
    New-Item -ItemType Directory -Path (Join-Path $ServerDir "logs") -Force | Out-Null
}

if ($Restart) {
    Write-Step "Остановка текущих процессов"
    Get-Process worldserver, authserver -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "    стоп $($_.Name) pid=$($_.Id)"
        Stop-Process -Id $_.Id -Force
    }
    Start-Sleep -Seconds 4
}

$running = Get-Process worldserver, authserver -ErrorAction SilentlyContinue
if ($running) {
    Write-Warn "Уже запущено: " + (($running | ForEach-Object { "$($_.Name) pid=$($_.Id)" }) -join ", ")
    Write-Warn "Для перезапуска: -Restart"
    exit 0
}

Write-Step "1/2 authserver (сначала — он ставит флаг офлайна всем реалмам)"
$auth = Start-Utf8Process "authserver.exe"
if (-not $auth) { Write-Err "authserver не запустился"; exit 2 }
if (-not (Wait-Port 3724 60 "authserver")) { exit 2 }
Write-Ok "authserver pid=$($auth.Id) слушает 3724"

Start-Sleep -Seconds 2

Write-Step "2/2 worldserver (снимает флаг офлайна у своего реалма)"
$world = Start-Utf8Process "worldserver.exe"
if (-not $world) { Write-Err "worldserver не запустился"; exit 3 }
if (-not (Wait-Port 8085 240 "worldserver")) { exit 3 }
Write-Ok "worldserver pid=$($world.Id) слушает 8085"

$log = Join-Path $ServerDir "logs\Server.log"
$deadline = (Get-Date).AddSeconds(120)
while ((Get-Date) -lt $deadline) {
    if ((Test-Path $log) -and (Select-String -LiteralPath $log -Pattern "worldserver-daemon\) ready" -Quiet)) { break }
    Start-Sleep -Seconds 5
}
if (Select-String -LiteralPath $log -Pattern "worldserver-daemon\) ready" -Quiet) {
    Write-Ok "worldserver-daemon ready"
} else {
    Write-Warn "признак 'ready' в Server.log не появился — смотрите " + $log
}

Write-Step "Проверка флага реалма"
$conf = Join-Path $ServerDir "configs\worldserver.conf"
$line = Select-String -LiteralPath $conf -Pattern '^LoginDatabaseInfo\s*=' | Select-Object -First 1
if ($line -and $line.Line -match '"([^";]+);(\d+);([^";]*);([^";]*);([^";]+)"') {
    $dbHost = $Matches[1]; $dbPort = $Matches[2]; $dbUser = $Matches[3]; $dbPass = $Matches[4]; $dbName = $Matches[5]
    $mysql = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
    if (Test-Path $mysql) {
        $sql = "SELECT id, name, flag, (flag & 2) AS offline_bit FROM realmlist;"
        $out = & $mysql "--default-character-set=utf8mb4" "-h$dbHost" "-P$dbPort" "-u$dbUser" "-p$dbPass" $dbName -t -e $sql 2>$null
        $out | ForEach-Object { Write-Host "    $_" }
        if ($out -match '\|\s*2\s*\|\s*$' -or $out -match '\|\s*2\s*\|') {
            Write-Warn "offline_bit = 2: реалм помечен офлайн. Серверы перезапущены в неверном порядке?"
        }
    } else {
        Write-Warn "mysql.exe не найден — флаг не проверен"
    }
} else {
    Write-Warn "не удалось разобрать LoginDatabaseInfo в worldserver.conf"
}

Write-Host ""
Write-Ok "Готово: auth 3724, world 8085, SOAP 7878 (если включён)"
