# AI-GENERATED #

param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ModName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LuaCompiler = "luac",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LuaLinter = "luacheck"
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$RepoRoot = Split-Path -Parent $PSScriptRoot

# Change this to wherever UE4SS/Mods lives for Echoes of Aincrad.
$UE4SSModsPath = "C:\Program Files (x86)\Echoes of Aincrad\game\EchoesofAincrad\Binaries\Win64\ue4ss\Mods"

$BuildScriptPath = Join-Path $PSScriptRoot "build.ps1"
$PackagedModPath = Join-Path $RepoRoot "dist\$ModName"
$InstalledModPath = Join-Path $UE4SSModsPath $ModName
$ModsTxtPath = Join-Path $UE4SSModsPath "mods.txt"

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

if ([System.IO.Path]::GetFileName($ModName) -ne $ModName) {
    throw "ModName must be a directory name, not a path: $ModName"
}

if (-not (Test-Path -LiteralPath $BuildScriptPath -PathType Leaf)) {
    throw "Build script does not exist: $BuildScriptPath"
}

if (-not (Test-Path $UE4SSModsPath)) {
    throw "UE4SS Mods directory does not exist: $UE4SSModsPath"
}

if (-not (Test-Path $ModsTxtPath)) {
    throw "mods.txt does not exist: $ModsTxtPath"
}

# ------------------------------------------------------------
# Build mod
# ------------------------------------------------------------

& $BuildScriptPath `
    -ModName $ModName `
    -LuaCompiler $LuaCompiler `
    -LuaLinter $LuaLinter

$PackagedMainLuaPath = Join-Path $PackagedModPath "Scripts\main.lua"
if (-not (Test-Path -LiteralPath $PackagedMainLuaPath -PathType Leaf)) {
    throw "Build did not produce a valid mod package: $PackagedModPath"
}

# ------------------------------------------------------------
# Install mod
# ------------------------------------------------------------

if (Test-Path -LiteralPath $InstalledModPath) {
    Write-Host "Removing the existing $ModName installation..."
    Remove-Item -LiteralPath $InstalledModPath -Recurse -Force
}

Write-Host "Installing $ModName from dist..."
Copy-Item `
    -LiteralPath $PackagedModPath `
    -Destination $UE4SSModsPath `
    -Recurse `
    -Force

Write-Host "Installed package:"
Write-Host "  $PackagedModPath"
Write-Host "    -> $InstalledModPath"

# ------------------------------------------------------------
# Enable mod in mods.txt
# ------------------------------------------------------------

$Lines = Get-Content $ModsTxtPath

$ModPattern = "^\s*" + [regex]::Escape($ModName) + "\s*:"

$ExistingIndex = -1

for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match $ModPattern) {
        $ExistingIndex = $i
        break
    }
}

$EnabledEntry = "$ModName : 1"

if ($ExistingIndex -ge 0) {
    if ($Lines[$ExistingIndex] -ne $EnabledEntry) {
        $Lines[$ExistingIndex] = $EnabledEntry
        Set-Content $ModsTxtPath $Lines

        Write-Host "Enabled $ModName in mods.txt."
    }
    else {
        Write-Host "$ModName is already enabled in mods.txt."
    }
}
else {
    Add-Content $ModsTxtPath $EnabledEntry

    Write-Host "Added $ModName to mods.txt."
}

Write-Host ""
Write-Host "Done."

