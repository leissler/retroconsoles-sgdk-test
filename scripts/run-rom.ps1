param(
    [string] $RomPath = "",
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if ([string]::IsNullOrWhiteSpace($RomPath)) {
    $RomPath = Join-Path $projectRoot "out/rom.bin"
}

$localEmuFile = Join-Path $projectRoot ".megadrive-emulator.local"
$sharedEmuFile = Join-Path $projectRoot ".megadrive-emulator"

if (-not (Test-Path $RomPath)) {
    Write-Error "ROM not found: $RomPath. Run build first."
}

function Get-ConfiguredEmulatorFromFile([string] $file) {
    if (-not (Test-Path $file)) { return $null }

    foreach ($line in Get-Content $file) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        if ($trimmed.StartsWith("#")) { continue }
        return $trimmed
    }

    return $null
}

function Invoke-OrPrint([string] $cmd) {
    if ($DryRun) {
        Write-Host "DRY RUN: $cmd"
        return
    }

    $invocation = $cmd.Trim()
    if (-not $invocation.StartsWith("&")) {
        $invocation = "& $invocation"
    }
    Invoke-Expression $invocation
}

$configuredEmulator = $env:MEGADRIVE_EMULATOR
if ([string]::IsNullOrWhiteSpace($configuredEmulator)) {
    $configuredEmulator = Get-ConfiguredEmulatorFromFile $localEmuFile
}
if ([string]::IsNullOrWhiteSpace($configuredEmulator)) {
    $configuredEmulator = Get-ConfiguredEmulatorFromFile $sharedEmuFile
}

if (-not [string]::IsNullOrWhiteSpace($configuredEmulator)) {
    if ($configuredEmulator.Contains("{rom}")) {
        $cmd = $configuredEmulator.Replace("{rom}", "`"$RomPath`"")
    } else {
        $cmd = "$configuredEmulator `"$RomPath`""
    }

    Invoke-OrPrint $cmd
    exit $LASTEXITCODE
}

$blastemCmd = Get-Command blastem -ErrorAction SilentlyContinue
if (-not $blastemCmd) {
    $blastemCmd = Get-Command blastem.exe -ErrorAction SilentlyContinue
}
if ($blastemCmd) {
    Invoke-OrPrint "`"$($blastemCmd.Path)`" `"$RomPath`""
    exit $LASTEXITCODE
}

$blastemCandidates = @(
    "$env:ProgramFiles\blastem\blastem.exe",
    "$env:ProgramFiles\BlastEm\blastem.exe",
    "${env:ProgramFiles(x86)}\blastem\blastem.exe",
    "${env:ProgramFiles(x86)}\BlastEm\blastem.exe",
    "$env:LOCALAPPDATA\blastem\blastem.exe",
    "C:\blastem\blastem.exe"
)

foreach ($candidate in $blastemCandidates) {
    if (Test-Path $candidate) {
        Invoke-OrPrint "`"$candidate`" `"$RomPath`""
        exit $LASTEXITCODE
    }
}

Write-Error @"
No supported emulator found.
Install BlastEm or configure one of:
- env var: MEGADRIVE_EMULATOR='command {rom}'
- $localEmuFile
- $sharedEmuFile
"@
