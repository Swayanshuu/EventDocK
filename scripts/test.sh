#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo " Running All EventDock Tests"
echo "========================================="

mvn clean test

echo "All backend and starter tests passed successfully!"

if command -v flutter &> /dev/null; then
    echo "Running Flutter dashboard tests..."
    cd eventdock-dashboard && flutter test && cd ..
fi
