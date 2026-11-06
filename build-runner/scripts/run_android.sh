#!/usr/bin/env bash
# Build, install and launch an Android app on exactly one device.
# Generalized from GolfSparks/run-android.sh. Runner sets:
#   APP_DIR         folder with gradlew or kotlin
#   APP_NAME        display name (e.g. "My App")
#   BASE_PACKAGE    production applicationId (e.g. com.me.myapp)
#   ANDROID_MODULE  module that builds the APK (composeApp, androidApp)
#   PACKAGE         effective debug applicationId (e.g. com.me.myapp.dev)
#   SERIAL          an attached phone or running emulator, or
#   AVD             an emulator to boot first
set -euo pipefail

resolve_java_home() {
  if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    local major
    major=$("$JAVA_HOME/bin/java" -version 2>&1 | awk -F '[\".]' '/version/ {print ($2=="1" ? $3 : $2); exit}')
    [ -n "$major" ] && [ "$major" -le 23 ] 2>/dev/null && return 0
  fi
  for v in 21 17; do
    local jh
    jh=$(/usr/libexec/java_home -F -v "$v" 2>/dev/null || true)
    if [ -n "$jh" ] && [ -x "$jh/bin/java" ]; then export JAVA_HOME="$jh"; return 0; fi
  done
  for jbr in "/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
             "/Applications/Android Studio Preview.app/Contents/jbr/Contents/Home"; do
    if [ -x "$jbr/bin/java" ]; then export JAVA_HOME="$jbr"; return 0; fi
  done
}
resolve_java_home

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
if [ -x "./gradlew" ]; then
  echo "==> Building and installing :$ANDROID_MODULE"
  ./gradlew ":$ANDROID_MODULE:installDebug"
elif [ -x "./kotlin" ]; then
  echo "==> Building $ANDROID_MODULE (Kotlin Toolchain / Amper)"
  ./kotlin build -m "$ANDROID_MODULE" -p android -v debug
  APK="$(find "build/tasks/_${ANDROID_MODULE}_buildAndroidDebug" -name '*-debug.apk' 2>/dev/null | head -1)"
  [ -n "$APK" ] || APK="$(find build -path "*_${ANDROID_MODULE}*" -name '*.apk' 2>/dev/null | head -1)"
  [ -n "$APK" ] || { echo "Build succeeded, but could not find debug APK under build/."; exit 1; }

  BASE_PKG="${BASE_PACKAGE:-$PACKAGE}"
  if [ "$PACKAGE" != "$BASE_PKG" ]; then
    DEV_LABEL="${APP_NAME:-App} Dev"
    echo "==> Packaging Dev APK ($PACKAGE · \"$DEV_LABEL\") so Store builds stay untouched"
    MERGED_MANIFEST="$(find "build/tasks/_${ANDROID_MODULE}_buildAndroidDebug" \
      -path '*/packaged_manifests/*/AndroidManifest.xml' 2>/dev/null | head -1)"
    [ -n "$MERGED_MANIFEST" ] || { echo "Could not locate merged AndroidManifest.xml under build/."; exit 1; }

    BT_DIR="$(ls -1d "$SDK"/build-tools/* 2>/dev/null | sort -V | tail -1)"
    PLAT_JAR="$(ls -1 "$SDK"/platforms/android-*/android.jar 2>/dev/null | sort -V | tail -1)"
    [ -x "$BT_DIR/aapt2" ] || { echo "aapt2 not found in $SDK/build-tools."; exit 1; }
    [ -f "$PLAT_JAR" ] || { echo "android.jar not found in $SDK/platforms."; exit 1; }

    WORK="build/runner/android-dev"
    rm -rf "$WORK"
    mkdir -p "$WORK/extracted"

    BASE_PKG="$BASE_PKG" TARGET_PKG="$PACKAGE" DEV_LABEL="$DEV_LABEL" \
      SRC_MANIFEST="$MERGED_MANIFEST" OUT_MANIFEST="$WORK/AndroidManifest.xml" \
      python3 - <<'PY'
import os
with open(os.environ["SRC_MANIFEST"], "r", encoding="utf-8") as f:
    xml = f.read()
base = os.environ["BASE_PKG"]
target = os.environ["TARGET_PKG"]
label = (
    os.environ["DEV_LABEL"]
    .replace("&", "&amp;")
    .replace('"', "&quot;")
    .replace("<", "&lt;")
)
# Keep package="{base}" here so resource references resolve against the APK's
# resource table; aapt2 --rename-manifest-package rewrites the binary package
# attribute (and expands any relative class names) to {target}.
xml = xml.replace(
    f'{base}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
    f'{target}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
)
xml = xml.replace(f'android:authorities="{base}.', f'android:authorities="{target}.')
xml = xml.replace('android:label="@string/app_name"', f'android:label="{label}"')
with open(os.environ["OUT_MANIFEST"], "w", encoding="utf-8") as f:
    f.write(xml)
PY

    "$BT_DIR/aapt2" link \
      -o "$WORK/manifest-only.apk" \
      --manifest "$WORK/AndroidManifest.xml" \
      -I "$PLAT_JAR" \
      -I "$APK" \
      --rename-manifest-package "$PACKAGE"

    unzip -qo "$WORK/manifest-only.apk" AndroidManifest.xml -d "$WORK/extracted"
    cp "$APK" "$WORK/repackaged.apk"
    zip -qd "$WORK/repackaged.apk" 'META-INF/*.SF' 'META-INF/*.RSA' 'META-INF/*.DSA' 'META-INF/MANIFEST.MF' 2>/dev/null || true
    ( cd "$WORK/extracted" && zip -q0 ../repackaged.apk AndroidManifest.xml )

    DEV_APK="$WORK/${ANDROID_MODULE}-dev.apk"
    "$BT_DIR/zipalign" -p -f 4 "$WORK/repackaged.apk" "$DEV_APK"

    DEBUG_KS="$HOME/.android/debug.keystore"
    if [ ! -f "$DEBUG_KS" ]; then
      keytool -genkeypair -v -keystore "$DEBUG_KS" -storepass android \
        -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 \
        -validity 10000 -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
    fi
    "$BT_DIR/apksigner" sign \
      --ks "$DEBUG_KS" \
      --ks-pass pass:android \
      --key-pass pass:android \
      --ks-key-alias androiddebugkey \
      "$DEV_APK"
    APK="$DEV_APK"
  fi

  echo "==> Installing $APK on $SERIAL"
  adb -s "$SERIAL" install -r -g "$APK"
else
  echo "Neither ./gradlew nor ./kotlin found in $APP_DIR."
  exit 1
fi

echo "==> Launching $PACKAGE"
# Ask the device for the launcher activity instead of hardcoding it; this survives
# namespace != applicationId and debug package renames.
COMPONENT="$(adb -s "$SERIAL" shell cmd package resolve-activity --brief \
  -c android.intent.category.LAUNCHER "$PACKAGE" 2>/dev/null | tr -d '\r' | tail -1)"
case "$COMPONENT" in
  */*) adb -s "$SERIAL" shell am start -n "$COMPONENT" >/dev/null ;;
  *)   adb -s "$SERIAL" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null ;;
esac
echo "==> Running on $SERIAL${MODEL:+ ($MODEL)}"
