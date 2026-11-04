#!/usr/bin/env bash
# Build, install and launch an Android app on exactly one device.
# Generalized from GolfSparks/run-android.sh. Runner sets:
#   APP_DIR         folder with gradlew
#   ANDROID_MODULE  Gradle module that builds the APK (composeApp, androidApp)
#   PACKAGE         applicationId
#   SERIAL          an attached phone or running emulator, or
#   AVD             an emulator to boot first
set -euo pipefail

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
[ -d "$SDK" ] || { echo "Android SDK not found at $SDK. Set ANDROID_HOME."; exit 1; }
export PATH="$SDK/platform-tools:$SDK/emulator:$PATH"
cd "$APP_DIR"

online() { adb devices | awk 'NR>1 && $2=="device" {print $1}'; }

if [ -n "${AVD:-}" ]; then
  echo "==> Booting emulator $AVD"
  before="$(online)"
  # Double fork so the emulator outlives this script (and a Cancel in Runner).
  ( nohup emulator -avd "$AVD" -netdelay none -netspeed full >/dev/null 2>&1 & )
  SERIAL=""
  for _ in $(seq 1 90); do
    SERIAL="$(online | grep '^emulator-' | grep -vxF "${before:-none}" | head -1 || true)"
    [ -n "$SERIAL" ] && break
    sleep 2
  done
  [ -n "$SERIAL" ] || { echo "Emulator $AVD did not come up within 3 minutes."; exit 1; }
  echo "==> Waiting for $SERIAL to finish booting"
  until [ "$(adb -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 2; done
  adb -s "$SERIAL" shell input keyevent 82 >/dev/null 2>&1 || true
fi

[ -n "${SERIAL:-}" ] || { echo "No device given."; exit 1; }
STATE="$(adb -s "$SERIAL" get-state 2>/dev/null || echo offline)"
if [ "$STATE" != "device" ]; then
  echo "$SERIAL is '$STATE'. If it says unauthorized, unlock the phone and accept the"
  echo "USB debugging prompt, then press Run again."
  exit 1
fi
MODEL="$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || true)"
echo "==> Target: $SERIAL${MODEL:+ ($MODEL)}"

# ANDROID_SERIAL keeps adb and the Gradle install task on this one device.
export ANDROID_SERIAL="$SERIAL"
echo "==> Building and installing :$ANDROID_MODULE"
./gradlew ":$ANDROID_MODULE:installDebug"

echo "==> Launching $PACKAGE"
# Ask the device for the launcher activity instead of hardcoding it; this survives
# namespace != applicationId (Golf Sparks) and package renames.
COMPONENT="$(adb -s "$SERIAL" shell cmd package resolve-activity --brief \
  -c android.intent.category.LAUNCHER "$PACKAGE" 2>/dev/null | tr -d '\r' | tail -1)"
case "$COMPONENT" in
  */*) adb -s "$SERIAL" shell am start -n "$COMPONENT" >/dev/null ;;
  *)   adb -s "$SERIAL" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null ;;
esac
echo "==> Running on $SERIAL${MODEL:+ ($MODEL)}"
