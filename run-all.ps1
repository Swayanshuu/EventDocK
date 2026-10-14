# EventDock Full Stack Runner
# Runs API (8080), Starter / Sample App (8081), and Dashboard (Flutter Web)

$ErrorActionPreference = "Stop"
$workspaceDir = $PSScriptRoot

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "             EventDock Full Stack Runner                  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Step 0: Free ports 8080 and 8081 if occupied
Write-Host "[0/4] Checking ports 8080 and 8081..." -ForegroundColor Yellow
foreach ($port in @(8080, 8081)) {
    $connections = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    foreach ($conn in $connections) {
        Write-Host "  -> Port $port is in use by PID $($conn.OwningProcess). Stopping it..." -ForegroundColor Yellow
        Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
    }
}
Start-Sleep -Milliseconds 800

# Step 1: Install eventdock-starter into local Maven
Write-Host "`n[1/4] Installing eventdock-starter into local Maven repository..." -ForegroundColor Cyan
mvn install -pl eventdock-starter -am -DskipTests
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Failed to compile eventdock-starter" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Starter installed successfully." -ForegroundColor Green

# Step 2: Start API (Port 8080) in dedicated window
Write-Host "`n[2/4] Starting EventDock API (Port 8080)..." -ForegroundColor Cyan
Start-Process cmd -ArgumentList "/k", "title EventDock API (Port 8080) && cd /d `"$workspaceDir`" && mvn spring-boot:run -pl eventdock-api"

# Wait for API to boot
Write-Host "Waiting for EventDock API (http://localhost:8080/actuator/health)..." -NoNewline -ForegroundColor Gray
$apiReady = $false
for ($i = 0; $i -lt 35; $i++) {
    Start-Sleep -Seconds 1
    Write-Host "." -NoNewline -ForegroundColor Gray
    try {
        $res = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -Method Get -TimeoutSec 2 -ErrorAction Stop
        if ($res.status -eq "UP") {
            $apiReady = $true
            break
        }
    }
    catch {}
}
Write-Host ""
if ($apiReady) {
    Write-Host "[OK] EventDock API is UP and connected to database!" -ForegroundColor Green
}
else {
    Write-Host "[WARN] API is still starting up, proceeding..." -ForegroundColor Yellow
}

# Step 3: Start Sample App (Port 8081) in dedicated window
Write-Host "`n[3/4] Starting EventDock Sample App (Port 8081)..." -ForegroundColor Cyan
Start-Process cmd -ArgumentList "/k", "title EventDock Sample App (Port 8081) && cd /d `"$workspaceDir`" && mvn spring-boot:run -pl eventdock-sample"

# Step 4: Start Flutter Web Dashboard in Chrome
Write-Host "`n[4/4] Starting EventDock Dashboard (Flutter Web in Chrome)..." -ForegroundColor Cyan
Start-Process cmd -ArgumentList "/k", "title EventDock Dashboard (Flutter Web) && cd /d `"$workspaceDir\eventdock-dashboard`" && flutter run -d chrome"

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "           All EventDock Services Are Running!            " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  - API Backend:       http://localhost:8080" -ForegroundColor White
Write-Host "  - Health Check:      http://localhost:8080/actuator/health" -ForegroundColor White
Write-Host "  - Sample App:        http://localhost:8081" -ForegroundColor White
Write-Host "  - Web Dashboard:     Opening in Chrome via Flutter" -ForegroundColor White
Write-Host ""
Write-Host "  Sample Test Endpoints (trigger errors into EventDock):" -ForegroundColor Yellow
Write-Host "    curl http://localhost:8081/demo/fail" -ForegroundColor Gray
Write-Host "    curl http://localhost:8081/demo/bad-request" -ForegroundColor Gray
Write-Host "    curl http://localhost:8081/demo/database-error" -ForegroundColor Gray
Write-Host ""
Write-Host "  To stop all services at once, run: .\stop-all.ps1 or double-click stop-all.bat" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
