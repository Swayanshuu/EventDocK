#!/usr/bin/env bash
set -e

echo "=========================================================="
echo "  EventDock Starter — Publishing to Maven Central"
echo "=========================================================="

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

MVN_ARGS=("clean" "deploy" "-P" "release")

if [ -n "$GPG_PASSPHRASE" ]; then
    MVN_ARGS+=("-Dgpg.passphrase=$GPG_PASSPHRASE")
fi

if [ -n "$CENTRAL_USER" ] && [ -n "$CENTRAL_PASSWORD" ]; then
    MVN_ARGS+=("-Dcentral.username=$CENTRAL_USER" "-Dcentral.password=$CENTRAL_PASSWORD")
fi

echo "[INFO] Running: mvn ${MVN_ARGS[*]}"
mvn "${MVN_ARGS[@]}"

echo "=========================================================="
echo "  SUCCESS: EventDock Starter published successfully!"
echo "  Track release at: https://central.sonatype.com/publishing"
echo "=========================================================="
