Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Starting EventDock Dev Environment" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Starting PostgreSQL container via docker-compose..." -ForegroundColor Green
        docker compose up -d postgres
    } else {
        Write-Host "Docker daemon is not running. Using local PostgreSQL or H2 profile." -ForegroundColor Yellow
    }
}

Write-Host "Building EventDock starter and API..." -ForegroundColor Cyan
mvn clean install -DskipTests

Write-Host "EventDock is ready for local development." -ForegroundColor Green
Write-Host "To run API:        cd eventdock-api; mvn spring-boot:run"
Write-Host "To run Dashboard:  cd eventdock-dashboard; flutter run -d chrome"
Write-Host "To run CLI:        cd eventdock-cli; mvn package -DskipTests"
