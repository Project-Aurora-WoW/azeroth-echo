<#
.SYNOPSIS
    Показывает логи сервера в правильной кодировке (UTF-8), даже когда файл занят.

.DESCRIPTION
    worldserver и authserver пишут логи в UTF-8, а консоль Windows в русской
    локали по умолчанию cp866 — при чтении «в лоб» кириллица превращается в
    мусор. Скрипт открывает файл с FileShare.ReadWrite (сервер продолжает
    писать) и декодирует его как UTF-8.

.PARAMETER Name
    Имя файла в logs: Server.log, Errors.log, Auth.log, ALE.log.

.PARAMETER Lines
    Сколько последних строк показать.

.PARAMETER Filter
    Показать только строки, содержащие подстроку.

.PARAMETER Follow
    Не выходить, дописывать новые строки (Ctrl+C для выхода).

.EXAMPLE
    .\watch-log.ps1
    .\watch-log.ps1 -Name Errors.log
    .\watch-log.ps1 -Name Server.log -Filter "lua_scripts" -Lines 50
    .\watch-log.ps1 -Name Server.log -Follow
#>
[CmdletBinding()]
param(
    [string]$Name = "Server.log",
    [int]$Lines = 30,
    [string]$Filter = "",
    [switch]$Follow,
    [string]$ServerDir = "E:\acbuild\bin\RelWithDebInfo"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$path = Join-Path (Join-Path $ServerDir "logs") $Name
if (-not (Test-Path $path)) {
    Write-Host "нет файла $path" -ForegroundColor Yellow
    exit 1
}

function Read-Tail([string]$file, [int]$Count) {
    # Файл занят сервером на запись — читаем с FileShare.ReadWrite.
    $fs = [IO.File]::Open($file, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        $reader = New-Object IO.StreamReader($fs, [Text.Encoding]::UTF8)
        $all = $reader.ReadToEnd()
    } finally {
        $fs.Dispose()
    }
    return $all -split "`r?`n"
}

$tail = Read-Tail $path $Lines
if ($Filter) { $tail = $tail | Where-Object { $_ -like "*$Filter*" } }
$tail | Select-Object -Last $Lines | ForEach-Object { Write-Host $_ }

if (-not $Follow) { exit 0 }

Write-Host ""
Write-Host "--- слежение за $Name (Ctrl+C для выхода) ---" -ForegroundColor Cyan
$position = (Get-Item $path).Length
while ($true) {
    Start-Sleep -Milliseconds 700
    try {
        $fs = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try {
            if ($fs.Length -le $position) { $position = $fs.Length; continue }
            $null = $fs.Seek($position, [IO.SeekOrigin]::Begin)
            $reader = New-Object IO.StreamReader($fs, [Text.Encoding]::UTF8)
            $chunk = $reader.ReadToEnd()
            $position = $fs.Position
        } finally { $fs.Dispose() }
        if ($chunk) {
            foreach ($line in ($chunk -split "`r?`n")) {
                if ($line -and ((-not $Filter) -or ($line -like "*$Filter*"))) { Write-Host $line }
            }
        }
    } catch {
        Start-Sleep -Seconds 2
    }
}
