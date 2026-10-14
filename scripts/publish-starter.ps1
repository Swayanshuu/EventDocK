param(
    [Parameter(Mandatory = $false)]
    [string]$GpgPassphrase,

    [Parameter(Mandatory = $false)]
    [string]$GpgKeyName = "FDE643E6C00D7488",

    [Parameter(Mandatory = $false)]
    [string]$CentralUser,

    [Parameter(Mandatory = $false)]
    [string]$CentralPassword
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  EventDock Starter - Publishing to Maven Central" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Find Maven
$mvnCmd = "C:\Maven\apache-maven-3.9.14\bin\mvn.cmd"
if (-not (Test-Path $mvnCmd)) {
    $mvnFind = Get-Command mvn.cmd -ErrorAction SilentlyContinue
    if ($mvnFind) { $mvnCmd = $mvnFind.Source } else { $mvnCmd = "mvn" }
}

# Find GPG
$gpgFind = Get-Command gpg -ErrorAction SilentlyContinue
if (-not $gpgFind) {
    Write-Error "GPG was not found in PATH."
    exit 1
}

# Always switch to repository root
$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
Set-Location $repoRoot
Write-Host "[INFO] Repository Root: $repoRoot" -ForegroundColor Gray

$mvnArgs = @(
    "clean",
    "deploy",
    "-P", "release",
    "--batch-mode"
)

if ($GpgKeyName) {
    $mvnArgs += "-Dgpg.keyname=$GpgKeyName"
}

if ($GpgPassphrase) {
    $mvnArgs += "-Dgpg.passphrase=$GpgPassphrase"
}

if ($CentralUser -and $CentralPassword) {
    $mvnArgs += "-Dcentral.username=$CentralUser"
    $mvnArgs += "-Dcentral.password=$CentralPassword"
}

Write-Host ""
Write-Host "[INFO] Executing Maven Deployment:" -ForegroundColor Yellow
Write-Host "$mvnCmd $($mvnArgs -join ' ')" -ForegroundColor Gray
Write-Host ""

& $mvnCmd @mvnArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  SUCCESS: EventDock Starter published successfully!" -ForegroundColor Green
    Write-Host "  Check deployment: https://central.sonatype.com/publishing" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host "  FAILED: Deployment exited with code $LASTEXITCODE" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Red
    exit $LASTEXITCODE
}
