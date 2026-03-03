[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string] $Command = "build",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ExtraArgs
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$setupScript = Join-Path $projectRoot "scripts\setup-windows-sgdk.ps1"
$buildScript = Join-Path $projectRoot "scripts\sgdk-make.ps1"
$runScript = Join-Path $projectRoot "scripts\run-rom.ps1"
$testScript = Join-Path $projectRoot "scripts\test-rom.ps1"

function Show-Usage {
    Write-Host @"
Usage:
  .\sgdk.ps1 [command] [extra args]

Commands:
  setup            Configure or auto-download SGDK (.tools/sgdk)
  build            Build ROM (default)
  debug            Build debug ROM
  clean            Clean build output
  test             Build and run ROM smoke test
  run              Build and run ROM in emulator
  help             Show this help

Examples:
  .\sgdk.ps1
  .\sgdk.ps1 setup
  .\sgdk.ps1 build
  .\sgdk.ps1 debug
  .\sgdk.ps1 clean
  .\sgdk.ps1 test
  .\sgdk.ps1 run
"@
}

function Invoke-CheckedScript([string] $scriptPath, [string[]] $scriptArgs = @()) {
    if (-not (Test-Path $scriptPath)) {
        Write-Error "Missing script: $scriptPath"
    }

    & $scriptPath @scriptArgs
    $exitCode = $LASTEXITCODE
    if ($null -ne $exitCode -and $exitCode -ne 0) {
        exit $exitCode
    }
}

$cmd = $Command.ToLowerInvariant()
switch ($cmd) {
    "setup" {
        Invoke-CheckedScript $setupScript $ExtraArgs
    }
    "build" {
        Invoke-CheckedScript $buildScript $ExtraArgs
    }
    "debug" {
        Invoke-CheckedScript $buildScript (@("debug") + $ExtraArgs)
    }
    "clean" {
        Invoke-CheckedScript $buildScript (@("clean") + $ExtraArgs)
    }
    "test" {
        if ($ExtraArgs.Count -gt 0) {
            Write-Error "'test' does not accept extra args."
        }
        Invoke-CheckedScript $buildScript
        Invoke-CheckedScript $testScript
    }
    "run" {
        Invoke-CheckedScript $buildScript
        Invoke-CheckedScript $runScript $ExtraArgs
    }
    "help" {
        Show-Usage
    }
    default {
        Write-Error "Unknown command '$Command'. Run '.\sgdk.ps1 help' for usage."
    }
}
