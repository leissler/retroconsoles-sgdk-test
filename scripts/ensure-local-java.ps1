param(
    [string] $JavaVersion = "17"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$javaRoot = Join-Path $projectRoot ".tools\java"
$javaHome = Join-Path $javaRoot "current"

function Test-JavaHome([string] $path) {
    return (Test-Path (Join-Path $path "bin\java.exe")) -and
           (Test-Path (Join-Path $path "bin\javac.exe")) -and
           (Test-Path (Join-Path $path "bin\jar.exe"))
}

if (Test-JavaHome $javaHome) {
    Write-Output $javaHome
    exit 0
}

$archRaw = $env:PROCESSOR_ARCHITECTURE
if ([string]::IsNullOrWhiteSpace($archRaw)) { $archRaw = "AMD64" }

switch -Regex ($archRaw.ToUpperInvariant()) {
    "ARM64|AARCH64" { $arch = "aarch64" }
    default { $arch = "x64" }
}

$downloadUrl = "https://api.adoptium.net/v3/binary/latest/$JavaVersion/ga/windows/$arch/jdk/hotspot/normal/eclipse?project=jdk"
$tmpZip = Join-Path $env:TEMP ("jdk-" + [Guid]::NewGuid().ToString() + ".zip")
$tmpExtract = Join-Path $env:TEMP ("jdk-" + [Guid]::NewGuid().ToString())

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Host "Downloading local JDK $JavaVersion (windows/$arch)..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tmpZip -UseBasicParsing

    New-Item -ItemType Directory -Force -Path $tmpExtract | Out-Null
    Expand-Archive -Path $tmpZip -DestinationPath $tmpExtract -Force

    $sourceRoot = $null
    foreach ($dir in (Get-ChildItem -Path $tmpExtract -Directory -Recurse -ErrorAction SilentlyContinue)) {
        if (Test-JavaHome $dir.FullName) {
            $sourceRoot = $dir.FullName
            break
        }
    }

    if (-not $sourceRoot) {
        Write-Error "Could not locate extracted JDK home."
    }

    New-Item -ItemType Directory -Force -Path $javaRoot | Out-Null
    if (Test-Path $javaHome) {
        Remove-Item -Recurse -Force $javaHome
    }

    Move-Item -Path $sourceRoot -Destination $javaHome -Force
}
finally {
    if (Test-Path $tmpZip) { Remove-Item -Force $tmpZip -ErrorAction SilentlyContinue }
    if (Test-Path $tmpExtract) { Remove-Item -Recurse -Force $tmpExtract -ErrorAction SilentlyContinue }
}

if (-not (Test-JavaHome $javaHome)) {
    Write-Error "Local Java bootstrap failed."
}

Write-Output $javaHome
