param(
    [string] $GdkPath = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$extSrcDir = Join-Path $projectRoot "rescomp_ext/src"
$extBuildDir = Join-Path $projectRoot ".cache/rescomp_ext"
$extClassesDir = Join-Path $extBuildDir "classes"
$extJarOut = Join-Path $projectRoot "res/rescomp_ext.jar"

if (-not (Test-Path $extSrcDir)) {
    exit 0
}

if ([string]::IsNullOrWhiteSpace($GdkPath)) {
    $GdkPath = $env:SGDK
}
if ([string]::IsNullOrWhiteSpace($GdkPath)) {
    $GdkPath = $env:GDK
}

$localGdkFile = Join-Path $projectRoot ".sgdk-path"
if ([string]::IsNullOrWhiteSpace($GdkPath) -and (Test-Path $localGdkFile)) {
    $GdkPath = (Get-Content $localGdkFile -Raw).Trim()
}

$embeddedGdk = Join-Path $projectRoot ".tools/sgdk"
if ([string]::IsNullOrWhiteSpace($GdkPath) -and (Test-Path (Join-Path $embeddedGdk "makefile.gen"))) {
    $GdkPath = $embeddedGdk
}

$rescompJar = Join-Path $GdkPath "bin/rescomp.jar"
if ([string]::IsNullOrWhiteSpace($GdkPath) -or -not (Test-Path $rescompJar)) {
    Write-Error "Cannot build rescomp extension: SGDK path or rescomp.jar not found."
}

$javacCmd = Get-Command javac -ErrorAction SilentlyContinue
$jarCmd = Get-Command jar -ErrorAction SilentlyContinue
if (-not $javacCmd -or -not $jarCmd) {
    if (Test-Path $extJarOut) {
        Write-Warning "javac/jar not found. Using existing extension jar: $extJarOut"
        exit 0
    }

    Write-Error @"
Cannot build rescomp extension: javac/jar command not found.
Install a JDK (not only a JRE), or provide prebuilt jar at:
  $extJarOut
"@
}

$javaSources = Get-ChildItem -Path $extSrcDir -Recurse -Filter *.java | Sort-Object FullName
if ($javaSources.Count -eq 0) {
    Write-Error "No Java source found for rescomp extension in $extSrcDir"
}

if (Test-Path $extClassesDir) {
    Remove-Item -Recurse -Force $extClassesDir
}
New-Item -ItemType Directory -Force -Path $extClassesDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $extJarOut) | Out-Null

Write-Host "Building rescomp extension jar: $extJarOut"
$javacHelp = (& $javacCmd.Path --help 2>&1 | Out-String)
$javacArgs = @("-source", "8", "-target", "8")
if ($javacHelp -match "--release") {
    $javacArgs = @("--release", "8")
}

& $javacCmd.Path @javacArgs -cp $rescompJar -d $extClassesDir ($javaSources | ForEach-Object { $_.FullName })
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $jarCmd.Path --create --file $extJarOut -C $extClassesDir .
exit $LASTEXITCODE
