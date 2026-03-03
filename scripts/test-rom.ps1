param(
    [string] $RomPath = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if ([string]::IsNullOrWhiteSpace($RomPath)) {
    $RomPath = Join-Path $projectRoot "out/rom.bin"
}

if (-not (Test-Path $RomPath)) {
    Write-Error "Missing ROM output: $RomPath"
}

$fileInfo = Get-Item $RomPath
if ($fileInfo.Length -lt 131072) {
    Write-Error "ROM size is too small ($($fileInfo.Length) bytes). Expected at least 131072 bytes."
}

$stream = [System.IO.File]::OpenRead($RomPath)
try {
    $stream.Seek(0x100, [System.IO.SeekOrigin]::Begin) | Out-Null
    $buffer = New-Object byte[] 4
    $readCount = $stream.Read($buffer, 0, 4)
    if ($readCount -ne 4) {
        Write-Error "Unable to read ROM header tag at 0x100."
    }

    $segaTag = [System.Text.Encoding]::ASCII.GetString($buffer)
    if ($segaTag -ne "SEGA") {
        Write-Error "ROM header check failed at 0x100: expected 'SEGA', got '$segaTag'"
    }
}
finally {
    $stream.Dispose()
}

Write-Host "ROM smoke test passed: $RomPath ($($fileInfo.Length) bytes)"
