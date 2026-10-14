#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo " Building EventDock Platform Artifacts"
echo "========================================="

# Build Java backend, starter, sample, and CLI
mvn clean package -DskipTests=false

echo "Java artifacts compiled and packaged successfully!"

if command -v flutter &> /dev/null; then
    echo "Building Flutter Web dashboard..."
    cd eventdock-dashboard && flutter build web --release && cd ..
fi

echo "EventDock full build completed."
