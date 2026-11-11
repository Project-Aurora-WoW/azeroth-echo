<#
.SYNOPSIS
    Заливает локальные страницы wiki в GitHub Wiki репозитория.

.DESCRIPTION
    GitHub Wiki — это отдельный git-репозиторий <repo>.wiki.git.
    Он создаётся только после того, как первая страница сохранена
    через веб-интерфейс. Если репозиторий ещё не существует,
    скрипт сообщит об этом и укажет, что делать.

    Источник правды — каталог wiki/ в этом репозитории.
    Скрипт копирует страницы, коммитит и пушит в wiki.

.PARAMETER Repo
    Репозиторий в формате owner/name. По умолчанию Project-Aurora-WoW/azeroth-echo.

.EXAMPLE
    .\wiki-push.ps1
    .\wiki-push.ps1 -Repo Project-Aurora-WoW/azeroth-echo-core
#>
[CmdletBinding()]
param(
    [string]$Repo = "Project-Aurora-WoW/azeroth-echo"
)

$ErrorActionPreference = "Continue"

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$wikiSource = Join-Path (Split-Path -Parent $scriptDir) "wiki"
$cloneDir   = Join-Path $env:TEMP ("wiki-push-" + ($Repo -replace "[/\\]", "-"))
$wikiUrl    = "https://github.com/$Repo.wiki.git"

function Write-Step($msg) { Write-Host "> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  OK  $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  !!  $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  XX  $msg" -ForegroundColor Red }

if (-not (Test-Path $wikiSource)) {
    Write-Err "Не найден каталог с исходными страницами: $wikiSource"
    exit 1
}

$pages = Get-ChildItem -Path $wikiSource -Filter "*.md"
Write-Step "Страниц для публикации: $($pages.Count)"

# --- Проверка: существует ли wiki-репозиторий ---
Write-Step "Проверка wiki-репозитория $wikiUrl"
$probe = & git ls-remote $wikiUrl 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Err "Wiki-репозиторий не существует."
    Write-Host ""
    Write-Host "GitHub создаёт .wiki.git только после сохранения ПЕРВОЙ страницы" -ForegroundColor Yellow
    Write-Host "через веб-интерфейс. REST API этого не умеет." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Что сделать (30 секунд):" -ForegroundColor White
    Write-Host "  1. Открыть https://github.com/$Repo/wiki"
    Write-Host "  2. Нажать 'Create the first page'"
    Write-Host "  3. Заголовок: Home, в поле ввести что угодно, нажать 'Save Page'"
    Write-Host "  4. Запустить этот скрипт снова — он перезапишет страницу содержимым"
    Write-Host ""
    Write-Host "Альтернатива без веба: страницы уже лежат в каталоге" -ForegroundColor White
    Write-Host "  $wikiSource" -ForegroundColor DarkGray
    Write-Host "и опубликованы в репозитории по пути /wiki/" -ForegroundColor White
    exit 2
}
Write-Ok "wiki-репозиторий доступен"

# --- Клонирование ---
if (Test-Path $cloneDir) { Remove-Item $cloneDir -Recurse -Force }
Write-Step "Клонирование в $cloneDir"
& git clone $wikiUrl $cloneDir 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Err "Не удалось клонировать"; exit 3 }
Write-Ok "склонировано"

# --- Копирование страниц ---
Write-Step "Копирование страниц"
foreach ($p in $pages) {
    Copy-Item -Path $p.FullName -Destination $cloneDir -Force
    Write-Host "    $($p.Name)"
}
Write-Ok "скопировано $($pages.Count) файлов"

# --- Коммит ---
Push-Location $cloneDir
try {
    & git config user.name  | Out-Null
    & git config user.email | Out-Null

    & git add -A
    $status = & git status --porcelain
    if (-not $status) {
        Write-Warn "Изменений нет — wiki уже актуальна"
    } else {
        $changed = ($status | Measure-Object -Line).Lines
        Write-Step "Изменено файлов: $changed"

        $stamp = Get-Date -Format "yyyy-MM-dd HH:mm"
        & git commit -q -m "wiki: обновление страниц ($stamp)"
        Write-Ok "коммит создан"

        Write-Step "Пуш"
        & git push origin HEAD 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Err "Пуш не удался"; exit 4 }
        Write-Ok "запушено"
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Ok "Готово: https://github.com/$Repo/wiki"
