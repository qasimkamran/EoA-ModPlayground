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

# Resolve all build paths from the repository, regardless of the caller's current working directory.
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ModsRoot = Join-Path $RepoRoot "mods"
$SourceModPath = Join-Path $ModsRoot $ModName
$SourceScriptsPath = Join-Path $SourceModPath "Scripts"
$SharedLibPath = Join-Path $RepoRoot "lib"
$DistRoot = Join-Path $RepoRoot "dist"
$PackagedModPath = Join-Path $DistRoot $ModName
$PackagedScriptsPath = Join-Path $PackagedModPath "Scripts"
$PackagedLibPath = Join-Path $PackagedScriptsPath "lib"

function Resolve-BuildTool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    $ResolvedCommand = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $ResolvedCommand) {
        throw "$Purpose was not found: '$Command'. Install it or pass its path to the build script."
    }

    return $ResolvedCommand.Source
}

# A mod name must identify one direct child of mods/.
# This also prevents the clean step below from ever targeting a path outside dist/.
if ([System.IO.Path]::GetFileName($ModName) -ne $ModName) {
    throw "ModName must be a directory name, not a path: $ModName"
}

if (-not (Test-Path -LiteralPath $SourceModPath -PathType Container)) {
    throw "Mod does not exist: $SourceModPath"
}

if (-not (Test-Path -LiteralPath $SourceScriptsPath -PathType Container)) {
    throw "Mod is missing its Scripts directory: $SourceScriptsPath"
}

$MainLuaPath = Join-Path $SourceScriptsPath "main.lua"
if (-not (Test-Path -LiteralPath $MainLuaPath -PathType Leaf)) {
    throw "Mod is missing Scripts\main.lua: $SourceModPath"
}

$LuaCompilerPath = Resolve-BuildTool $LuaCompiler "Lua compiler"
$LuaLinterPath = Resolve-BuildTool $LuaLinter "Lua linter"

Write-Host "Building $ModName..."

if (Test-Path -LiteralPath $PackagedModPath) {
    Get-ChildItem -LiteralPath $PackagedModPath -Force |
        Remove-Item -Recurse -Force
}
else {
    New-Item -ItemType Directory -Path $PackagedModPath | Out-Null
}

# Package everything inside the selected mod directory, preserving Scripts
# and all sibling directories and assets.
Copy-Item `
    -Path (Join-Path $SourceModPath "*") `
    -Destination $PackagedModPath `
    -Recurse `
    -Force

# Shared libraries are the canonical copies and intentionally replace any
# stale copies that may exist in the mod's source Scripts/lib directory.
if (Test-Path -LiteralPath $SharedLibPath -PathType Container) {
    New-Item -ItemType Directory -Path $PackagedLibPath -Force | Out-Null

    Copy-Item `
        -Path (Join-Path $SharedLibPath "*") `
        -Destination $PackagedLibPath `
        -Recurse `
        -Force
}

$LuaFiles = @(
    Get-ChildItem -LiteralPath $PackagedScriptsPath -Filter "*.lua" -File -Recurse |
        Sort-Object FullName
)

if ($LuaFiles.Count -eq 0) {
    throw "Package contains no Lua source files: $PackagedScriptsPath"
}

Write-Host "Linting $($LuaFiles.Count) Lua file(s)..."
& $LuaLinterPath --codes --no-color $PackagedScriptsPath
if ($LASTEXITCODE -ne 0) {
    throw "Lua linting failed with exit code $LASTEXITCODE."
}

Write-Host "Compile-checking $($LuaFiles.Count) Lua file(s)..."
foreach ($LuaFile in $LuaFiles) {
    & $LuaCompilerPath -p $LuaFile.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "Lua compilation failed for '$($LuaFile.FullName)' with exit code $LASTEXITCODE."
    }
}

Write-Host "Build complete:"
Write-Host "  $PackagedModPath"
