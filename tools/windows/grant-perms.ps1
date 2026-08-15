# AI-GENERATED #

param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ModName = "02-MenuExtension",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$EnvFilePath = Join-Path $RepoRoot ".env.ps1"

if (-not (Test-Path -LiteralPath $EnvFilePath -PathType Leaf)) {
    throw "Missing local environment file: $EnvFilePath. Copy .env.example.ps1 to .env.ps1 and set EOA_GAME_PATH."
}

. $EnvFilePath

if ([string]::IsNullOrWhiteSpace($env:EOA_GAME_PATH)) {
    throw "EOA_GAME_PATH is not set in $EnvFilePath."
}

$UE4SSModsPath = Join-Path $env:EOA_GAME_PATH "EchoesofAincrad\Binaries\Win64\ue4ss\Mods"
$LogsPath = Join-Path $UE4SSModsPath "$ModName\logs"

$Principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script from PowerShell as Administrator."
}

New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null

Write-Host "Granting Modify permission to '$User' on:"
Write-Host "  $LogsPath"

& icacls.exe $LogsPath /grant "${User}:(OI)(CI)M" /T
if ($LASTEXITCODE -ne 0) {
    throw "icacls failed with exit code $LASTEXITCODE."
}

Write-Host "Permissions granted successfully."
