#!/usr/bin/env bash
# Fast iOS check: compile the Kotlin/Native framework only, no Xcode.
# Catches Objective-C interop errors in a fraction of a full build. Runner sets:
#   APP_DIR, SHARED_MODULE (the KMP module with the iOS targets: shared, composeApp)
set -euo pipefail
cd "$APP_DIR"
echo "==> Compiling :$SHARED_MODULE for the iOS simulator"
./gradlew ":$SHARED_MODULE:compileKotlinIosSimulatorArm64" --stacktrace
echo "==> iOS framework compiles"
