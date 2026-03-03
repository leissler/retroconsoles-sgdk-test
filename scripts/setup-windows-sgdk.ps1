param(
    [string] $SgdkPath = "",
    [switch] $PersistUserEnv,
    [bool] $AutoDownload = $true,
    [string] $SgdkTag = "v2.11",
    [string] $SgdkRepo = "https://github.com/Stephane-D/SGDK"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$sgdkFile = Join-Path $projectRoot ".sgdk-path"

function Test-SgdkRoot([string] $path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return $false }
    $makefile = Join-Path $path "makefile.gen"
    $rescomp = Join-Path $path "bin/rescomp.jar"
    return (Test-Path $makefile) -and (Test-Path $rescomp)
}

function Resolve-SgdkPath([string] $path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return "" }
    try {
        return (Resolve-Path -Path $path).Path
    } catch {
        return ""
    }
}

function Ensure-SgdkDownloaded([string] $targetPath, [string] $repo, [string] $tag) {
    if (Test-SgdkRoot $targetPath) {
        return $true
    }

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        Write-Error "Git is required for automatic SGDK download but was not found in PATH."
    }

    if (Test-Path $targetPath) {
        Remove-Item -Recurse -Force $targetPath
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $targetPath) | Out-Null
    Write-Host "Downloading SGDK $tag into $targetPath"
    & $gitCmd.Path clone --depth 1 --branch $tag $repo $targetPath
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    return (Test-SgdkRoot $targetPath)
}

if ([string]::IsNullOrWhiteSpace($SgdkPath)) {
    $candidates = @(
        $env:SGDK,
        $env:GDK,
        (Join-Path $projectRoot ".tools/sgdk"),
        "C:\SGDK",
        "C:\Dev\SGDK",
        (Join-Path $env:USERPROFILE "SGDK"),
        (Join-Path $env:USERPROFILE "Development\SGDK"),
        (Join-Path $env:USERPROFILE "Downloads\SGDK")
    )

    foreach ($candidate in $candidates) {
        $resolved = Resolve-SgdkPath $candidate
        if (Test-SgdkRoot $resolved) {
            $SgdkPath = $resolved
            break
        }
    }
} else {
    $SgdkPath = Resolve-SgdkPath $SgdkPath
}

if (-not (Test-SgdkRoot $SgdkPath)) {
    if ($AutoDownload) {
        $downloadTarget = Resolve-SgdkPath (Join-Path $projectRoot ".tools/sgdk")
        if ([string]::IsNullOrWhiteSpace($downloadTarget)) {
            $downloadTarget = Join-Path $projectRoot ".tools/sgdk"
        }

        if (Ensure-SgdkDownloaded -targetPath $downloadTarget -repo $SgdkRepo -tag $SgdkTag) {
            $SgdkPath = $downloadTarget
        }
    }
}

if (-not (Test-SgdkRoot $SgdkPath)) {
    Write-Error @"
Could not find a valid SGDK installation.
Provide it explicitly, for example:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-windows-sgdk.ps1 -SgdkPath C:\SGDK
Or allow automatic download:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-windows-sgdk.ps1 -AutoDownload \$true
"@
}

Set-Content -Path $sgdkFile -Value $SgdkPath -Encoding ascii
Write-Host "Wrote $sgdkFile -> $SgdkPath"

if ($PersistUserEnv) {
    [Environment]::SetEnvironmentVariable("SGDK", $SgdkPath, "User")
    Write-Host "Set persistent user env var: SGDK=$SgdkPath"
}

$makeExe = Join-Path $SgdkPath "bin/make.exe"
$gccExe = Join-Path $SgdkPath "bin/gcc.exe"
$javaOk = [bool](Get-Command java -ErrorAction SilentlyContinue)

if (-not (Test-Path $makeExe)) {
    Write-Warning "SGDK make.exe not found at $makeExe (expected for standard Windows SGDK package)."
}
if (-not (Test-Path $gccExe)) {
    Write-Warning "SGDK gcc.exe not found at $gccExe (expected for standard Windows SGDK package)."
}
if (-not $javaOk) {
    Write-Warning "Java command not found on PATH. Install Java (JRE/JDK) to build resources."
}

Write-Host ""
Write-Host "Next steps:"
Write-Host "1) Build: powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\sgdk-make.ps1"
Write-Host "2) Test : powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-rom.ps1"
Write-Host "3) Run  : powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-rom.ps1"
