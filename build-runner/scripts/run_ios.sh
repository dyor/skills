#!/usr/bin/env bash
# Build, install and launch an iOS app on a simulator or a physical iPhone.
# Generalized from GolfSparks/run-ios.sh. Runner sets:
#   APP_DIR           folder containing the Xcode project
#   IOS_PROJECT       e.g. iosApp/iosApp.xcodeproj
#   IOS_SCHEME        e.g. iosApp
#   TARGET_KIND       simulator | device
#   UDID              simulator UDID, or the iPhone's UDID
#   DEVELOPMENT_TEAM  optional; overrides the project's signing team (device only)
set -euo pipefail
cd "$APP_DIR"

if [ "$TARGET_KIND" = "simulator" ]; then
  SDK_DIR=Debug-iphonesimulator
  echo "==> Booting simulator $UDID"
  xcrun simctl boot "$UDID" 2>/dev/null || true
  open -a Simulator
  EXTRA=()
else
  SDK_DIR=Debug-iphoneos
  # Lets Xcode create or refresh the development profile for this iPhone.
  EXTRA=(-allowProvisioningUpdates)
  [ -n "${DEVELOPMENT_TEAM:-}" ] && EXTRA+=("DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM")
fi

DERIVED="build/runner/$TARGET_KIND"
echo "==> Building $IOS_SCHEME (the first build compiles the Kotlin framework and is slow)"
if ! xcodebuild -project "$IOS_PROJECT" -scheme "$IOS_SCHEME" -configuration Debug \
      -destination "id=$UDID" -derivedDataPath "$DERIVED" ${EXTRA[@]+"${EXTRA[@]}"} build; then
  echo
  if [ "$TARGET_KIND" = "device" ]; then
    echo "Build failed. For a physical iPhone this is usually signing: open the project in"
    echo "Xcode once, pick your team under Signing & Capabilities, and make sure the"
    echo "iPhone is unlocked, trusted, and has Developer Mode on."
  else
    echo "Build failed. If it says \"Unable to find a destination\", this simulator's iOS is"
    echo "older than the app's minimum; pick one on a newer iOS. To list schemes:"
    echo "  xcodebuild -list -project $IOS_PROJECT"
  fi
  exit 1
fi

APP="$(find "$DERIVED/Build/Products/$SDK_DIR" -maxdepth 1 -name '*.app' | head -1)"
[ -n "$APP" ] || { echo "Build succeeded but no .app was produced in $DERIVED."; exit 1; }
# Read the bundle ID from the build; it can differ from the Android package.
BUNDLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")"

echo "==> Installing $BUNDLE"
if [ "$TARGET_KIND" = "simulator" ]; then
  # A long first build gives the simulator time to shut down; boot and wait again.
  xcrun simctl bootstatus "$UDID" -b >/dev/null
  xcrun simctl install "$UDID" "$APP"
  xcrun simctl launch "$UDID" "$BUNDLE"
else
  xcrun devicectl device install app --device "$UDID" "$APP"
  xcrun devicectl device process launch --device "$UDID" "$BUNDLE"
fi
echo "==> Running $BUNDLE"
