#!/usr/bin/env bash
# Fast iOS check: compile the Kotlin/Native framework (or Kotlin Toolchain / Amper iOS module), no simulator boot.
# Catches Objective-C / Swift interop errors in a fraction of a full build. Runner sets:
#   APP_DIR, SHARED_MODULE (the KMP module with the iOS targets: shared, composeApp)
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

cd "$APP_DIR"
if [ -x "./gradlew" ]; then
  echo "==> Compiling :$SHARED_MODULE for the iOS simulator"
  ./gradlew ":$SHARED_MODULE:compileKotlinIosSimulatorArm64" --stacktrace
  echo "==> iOS framework compiles"
elif [ -x "./kotlin" ]; then
  IOS_MOD="iosApp"
  [ -d "$IOS_MOD" ] || IOS_MOD="$SHARED_MODULE"
  echo "==> Compiling $IOS_MOD for the iOS simulator (Kotlin Toolchain)"
  ./kotlin build -m "$IOS_MOD" -p iosSimulatorArm64
  echo "==> iOS module compiles"
else
  echo "Neither ./gradlew nor ./kotlin found in $APP_DIR."
  exit 1
fi
