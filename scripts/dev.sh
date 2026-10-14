#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo " Starting EventDock Development Environment"
echo "========================================="

# 1. Start Docker dependencies (PostgreSQL) if docker is available
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo "Starting PostgreSQL container via docker-compose..."
    docker compose up -d postgres
else
    echo "Docker is not running or not found. Ensure PostgreSQL is running on localhost:5432 with db 'eventdock'."
fi

# 2. Build starter and API
echo "Building EventDock starter and API..."
mvn clean install -DskipTests

# 3. Inform user
echo "EventDock is ready for local development."
echo "To run API:        cd eventdock-api && mvn spring-boot:run"
echo "To run Dashboard:  cd eventdock-dashboard && flutter run -d chrome"
echo "To run Sample App: cd eventdock-sample && mvn spring-boot:run"
