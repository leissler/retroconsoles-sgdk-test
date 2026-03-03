param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $MakeArgs
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$javaSetupScript = Join-Path $projectRoot "scripts/ensure-local-java.ps1"
if (-not (Test-Path $javaSetupScript)) {
    Write-Error "Missing Java bootstrap script: $javaSetupScript"
}

$javaHome = (& $javaSetupScript).Trim()
if ([string]::IsNullOrWhiteSpace($javaHome) -or -not (Test-Path (Join-Path $javaHome "bin\java.exe"))) {
    Write-Error "Local Java bootstrap failed."
}
$javaExe = Join-Path $javaHome "bin\java.exe"
$javaForMake = $javaExe -replace "\\", "/"

$gdkPath = $env:SGDK
if ([string]::IsNullOrWhiteSpace($gdkPath)) { $gdkPath = $env:GDK }

$localGdkFile = Join-Path $projectRoot ".sgdk-path"
if ([string]::IsNullOrWhiteSpace($gdkPath) -and (Test-Path $localGdkFile)) {
    $gdkPath = (Get-Content $localGdkFile -Raw).Trim()
}

$embeddedGdk = Join-Path $projectRoot ".tools/sgdk"
if ([string]::IsNullOrWhiteSpace($gdkPath) -and (Test-Path (Join-Path $embeddedGdk "makefile.gen"))) {
    $gdkPath = $embeddedGdk
}

if ([string]::IsNullOrWhiteSpace($gdkPath)) {
    $setupScript = Join-Path $projectRoot "scripts/setup-windows-sgdk.ps1"
    if (-not (Test-Path $setupScript)) {
        Write-Error "No SGDK configured and setup script is missing."
    }

    Write-Host "No SGDK configured. Running Windows SGDK bootstrap..."
    & $setupScript -AutoDownload $true
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    if (Test-Path $localGdkFile) {
        $gdkPath = (Get-Content $localGdkFile -Raw).Trim()
    }
    if ([string]::IsNullOrWhiteSpace($gdkPath) -and (Test-Path (Join-Path $embeddedGdk "makefile.gen"))) {
        $gdkPath = $embeddedGdk
    }
}

$makefileGen = Join-Path $gdkPath "makefile.gen"
if (-not (Test-Path $makefileGen)) {
    $setupScript = Join-Path $projectRoot "scripts/setup-windows-sgdk.ps1"
    if (Test-Path $setupScript) {
        Write-Host "Configured SGDK path is invalid. Running Windows SGDK bootstrap..."
        & $setupScript -AutoDownload $true
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        if (Test-Path $localGdkFile) {
            $gdkPath = (Get-Content $localGdkFile -Raw).Trim()
            $makefileGen = Join-Path $gdkPath "makefile.gen"
        }
    }

    if (-not (Test-Path $makefileGen)) {
        Write-Error "SGDK path is set but makefile.gen was not found at: $gdkPath"
    }
}

$buildExtScript = Join-Path $projectRoot "scripts/build-rescomp-ext.ps1"
if (Test-Path (Join-Path $projectRoot "rescomp_ext/src")) {
    & $buildExtScript -GdkPath $gdkPath
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$makeExe = $null
$cmdMake = Get-Command make -ErrorAction SilentlyContinue
if ($cmdMake) {
    $makeExe = $cmdMake.Path
} else {
    $bundledMake = Join-Path $gdkPath "bin/make.exe"
    if (Test-Path $bundledMake) {
        $makeExe = $bundledMake
    }
}

if (-not $makeExe) {
    Write-Error "No make executable found. Install make or use SGDK bundled make.exe."
}

$extraPath = @()
$extraPath += (Join-Path $javaHome "bin")
$extraPath += (Join-Path $gdkPath "bin")

$convsymCandidates = @(
    (Join-Path $gdkPath "tools/convsym/build"),
    (Join-Path $gdkPath "tools/convsym/build/Release")
)

foreach ($candidate in $convsymCandidates) {
    if (Test-Path (Join-Path $candidate "convsym")) {
        $extraPath += $candidate
        break
    }
    if (Test-Path (Join-Path $candidate "convsym.exe")) {
        $extraPath += $candidate
        break
    }
}

$extraFlags = $env:EXTRA_FLAGS
if ($null -eq $extraFlags) { $extraFlags = "" }
if ($extraFlags -notmatch "-std=") {
    $extraFlags = ($extraFlags + " -std=gnu11").Trim()
}

$oldPath = $env:PATH
$oldGdk = $env:GDK
$oldExtraFlags = $env:EXTRA_FLAGS
$oldJavaHome = $env:JAVA_HOME

try {
    $env:PATH = (($extraPath -join ";") + ";" + $env:PATH)
    $env:JAVA_HOME = $javaHome
    $env:GDK = $gdkPath
    $env:EXTRA_FLAGS = $extraFlags

    Write-Host "Using local SGDK at $gdkPath"
    & $makeExe -f $makefileGen "JAVA=$javaForMake" @MakeArgs
    exit $LASTEXITCODE
}
finally {
    $env:PATH = $oldPath
    $env:JAVA_HOME = $oldJavaHome
    $env:GDK = $oldGdk
    $env:EXTRA_FLAGS = $oldExtraFlags
}
