Write-Host ""
Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "             Stopping EventDock Services                  " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

# Kill port 8080 (API)
$conn8080 = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if ($conn8080) {
    foreach ($c in $conn8080) {
        Write-Host "Stopping EventDock API on port 8080 (PID: $($c.OwningProcess))..." -ForegroundColor Cyan
        Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
    }
}

# Kill port 8081 (Sample)
$conn8081 = Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue
if ($conn8081) {
    foreach ($c in $conn8081) {
        Write-Host "Stopping EventDock Sample on port 8081 (PID: $($c.OwningProcess))..." -ForegroundColor Cyan
        Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
    }
}

# Close any cmd windows titled EventDock
Get-Process cmd -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like "*EventDock*" } | ForEach-Object {
    Write-Host "Closing window: $($_.MainWindowTitle)" -ForegroundColor Cyan
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

# Close Flutter / dart if applicable
Get-Process -Name dart -ErrorAction SilentlyContinue | Where-Object { 
    $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
    $cmd -like "*eventdock-dashboard*" -or $cmd -like "*flutter_tools.snapshot*"
} | ForEach-Object {
    Write-Host "Stopping Flutter process (PID: $($_.Id))..." -ForegroundColor Cyan
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Write-Host "`n[OK] All EventDock services have been stopped." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Yellow
