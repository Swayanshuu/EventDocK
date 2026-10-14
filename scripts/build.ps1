Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Building EventDock Platform Artifacts (PowerShell)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

mvn clean package -DskipTests=false
if ($LASTEXITCODE -ne 0) {
    Write-Error "Maven packaging failed."
    exit $LASTEXITCODE
}

Write-Host "Java artifacts packaged successfully!" -ForegroundColor Green

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "Building Flutter Web dashboard..." -ForegroundColor Cyan
    Push-Location eventdock-dashboard
    flutter build web --release
    $flutterExit = $LASTEXITCODE
    Pop-Location
    if ($flutterExit -ne 0) {
        Write-Error "Flutter web build failed."
        exit $flutterExit
    }
}

Write-Host "EventDock full build completed." -ForegroundColor Green
