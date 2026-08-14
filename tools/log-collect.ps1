# AI-GENERATED #

[CmdletBinding()]
param(
    [Parameter()]
    [string]$UE4SSModsPath,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GameProcessName = "EchoesofAincrad",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$CentralLogsPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "logs"),

    [Parameter()]
    [switch]$NoWait
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($UE4SSModsPath)) {
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
}

if (-not (Test-Path -LiteralPath $UE4SSModsPath -PathType Container)) {
    throw "UE4SS Mods directory does not exist: $UE4SSModsPath"
}

if (-not $NoWait) {
    $gameProcesses = @(Get-Process -Name $GameProcessName -ErrorAction SilentlyContinue)
    if ($gameProcesses.Count -gt 0) {
        Write-Host "Waiting for $GameProcessName to exit..."
        $gameProcesses | Wait-Process
    }
}

New-Item -ItemType Directory -Path $CentralLogsPath -Force | Out-Null

# The per-mod logs only contain messages explicitly written by our Lua code.
# Preserve UE4SS's runtime log as well because hook registration failures and
# uncaught Lua errors are reported there.
$ue4ssRootPath = Split-Path -Parent $UE4SSModsPath
$ue4ssLogPath = Join-Path $ue4ssRootPath "UE4SS.log"

if (Test-Path -LiteralPath $ue4ssLogPath -PathType Leaf) {
    $runtimeLogTimestamp = (Get-Item -LiteralPath $ue4ssLogPath).LastWriteTime.ToString("yyyy-MM-dd_HH-mm-ss")
    $runtimeLogDestination = Join-Path $CentralLogsPath "UE4SS-$runtimeLogTimestamp.log"
    Copy-Item -LiteralPath $ue4ssLogPath -Destination $runtimeLogDestination -Force
    Write-Host "Collected UE4SS runtime log -> $runtimeLogDestination"
}
else {
    Write-Warning "UE4SS runtime log was not found: $ue4ssLogPath"
}

# Moving into a repository-local staging directory first ensures that a log is
# removed from the game directory before aggregation. If aggregation fails, the
# staged file remains recoverable for the next run.
$incomingPath = Join-Path $CentralLogsPath ".incoming"
New-Item -ItemType Directory -Path $incomingPath -Force | Out-Null

$modDirectories = @(
    Get-ChildItem -LiteralPath $UE4SSModsPath -Directory -Force |
        Sort-Object Name
)

$movedCount = 0
$collectedCount = 0

foreach ($modDirectory in $modDirectories) {
    $modLogsPath = Join-Path $modDirectory.FullName "logs"
    if (-not (Test-Path -LiteralPath $modLogsPath -PathType Container)) {
        continue
    }

    $logFiles = @(
        Get-ChildItem -LiteralPath $modLogsPath -File -Filter "*.log" -Force |
            Sort-Object Name
    )

    foreach ($logFile in $logFiles) {
        $safeModName = $modDirectory.Name -replace '[^A-Za-z0-9._-]', '_'
        $stagedName = "{0}--{1}--{2}.log" -f $safeModName, $logFile.BaseName, ([guid]::NewGuid().ToString("N"))
        $stagedPath = Join-Path $incomingPath $stagedName

        Move-Item -LiteralPath $logFile.FullName -Destination $stagedPath
        $movedCount++

        $centralLogPath = Join-Path $CentralLogsPath $logFile.Name
        $sourceStream = $null
        $destinationStream = $null

        try {
            $sourceStream = [System.IO.File]::OpenRead($stagedPath)
            $destinationStream = [System.IO.FileStream]::new(
                $centralLogPath,
                [System.IO.FileMode]::Append,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::Read
            )
            $sourceStream.CopyTo($destinationStream)
            $destinationStream.Flush()
        }
        finally {
            if ($destinationStream) {
                $destinationStream.Dispose()
            }
            if ($sourceStream) {
                $sourceStream.Dispose()
            }
        }

        Remove-Item -LiteralPath $stagedPath -Force
        $collectedCount++
        Write-Host "Collected $($modDirectory.Name)\logs\$($logFile.Name) -> $centralLogPath"
    }
}

Write-Host "Moved $movedCount log file(s) out of the game directories."
Write-Host "Aggregated $collectedCount log file(s) into:"
Write-Host "  $CentralLogsPath"

