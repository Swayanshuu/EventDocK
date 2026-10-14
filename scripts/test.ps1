Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Running All EventDock Tests (PowerShell)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

mvn clean test
if ($LASTEXITCODE -ne 0) {
    Write-Error "Maven tests failed."
    exit $LASTEXITCODE
}

Write-Host "All backend and starter tests passed successfully!" -ForegroundColor Green

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "Running Flutter dashboard tests..." -ForegroundColor Cyan
    Push-Location eventdock-dashboard
    flutter test
    $flutterExit = $LASTEXITCODE
    Pop-Location
    if ($flutterExit -ne 0) {
        Write-Error "Flutter tests failed."
        exit $flutterExit
    }
}
