#!/bin/zsh
# Mechanical pre-publish checks for an Android/KMP app. See ../SKILL.md.
#   prepublish_check.sh <appDir> [module=androidApp] [aabPath]
# Exit 1 if any FAIL. WARN and INFO never block.
set -uo pipefail
APP=${1:?appDir}; MODULE=${2:-androidApp}; AAB=${3:-}
cd "$APP" || exit 2
FAILS=0
pass() { echo "PASS  $1"; }
warn() { echo "WARN  $1"; }
info() { echo "INFO  $1"; }
fail() { echo "FAIL  $1"; FAILS=$((FAILS+1)); }

G=$MODULE/build.gradle.kts
[ -f "$G" ] || { fail "no $G"; exit 1; }
# The release { } block of buildTypes, up to the next top-level buildType.
REL=$(awk '/getByName\("release"\)|release *\{/{f=1} f{print} f&&/^        }/{exit}' "$G")

echo "$REL" | grep -q 'isMinifyEnabled *= *true' && pass "R8 minification on" \
  || fail "R8 is off: set isMinifyEnabled = true in the release build, then RUN the minified build before shipping"
echo "$REL" | grep -q 'isShrinkResources *= *true' && pass "resource shrinking on" || warn "isShrinkResources is not true"
if echo "$REL" | grep -q 'proguardFiles'; then
  PRO=$(echo "$REL" | grep -oE '"[^"]*\.pro"' | tr -d '"' | tail -1)
  [ -n "$PRO" ] && [ -f "$MODULE/$PRO" ] && pass "keep rules file $PRO" || warn "proguardFiles set but rules file not found"
else warn "no proguardFiles in release build"; fi

echo "$REL" | grep -q 'debuggable *= *true' && fail "release is debuggable" || pass "release not debuggable"

KS=distribution/android/keystore/keystore.properties
[ -f "$KS" ] && pass "release signing properties present" || fail "$KS missing: release would be signed with the debug key"

MAN=$MODULE/src/main/AndroidManifest.xml
if [ -f "$MAN" ]; then
  grep -q 'usesCleartextTraffic="true"' "$MAN" && warn "usesCleartextTraffic=true" || pass "no cleartext traffic flag"
  grep -q 'allowBackup="false"' "$MAN" && pass "allowBackup=false" || warn "allowBackup not false (private data can be backed up)"
  N=$(grep -c 'android:exported="true"' "$MAN"); info "$N exported component(s) in the manifest; the launcher activity is expected, review the rest"
fi

AABF=${AAB:-$MODULE/build/outputs/bundle/release/$MODULE-release.aab}
if [ -f "$AABF" ]; then
  SZ=$(du -m "$AABF" | cut -f1); info "AAB $AABF is ${SZ} MB"
  M=$(unzip -p "$AABF" base/manifest/AndroidManifest.xml 2>/dev/null | strings)
  echo "$M" | grep -q 'permission.AD_ID' && fail "built AAB declares AD_ID: remove it (tools:node=\"remove\") unless the app shows ads" || pass "built AAB has no AD_ID"
  echo "$M" | grep -q 'debuggable' && warn "AAB manifest mentions debuggable, check it is false"
  echo "$M" | grep -oE 'android\.permission\.[A-Z_]+' | sort -u | tr '\n' ' ' | sed 's/^/INFO  permissions: /'; echo
else info "no AAB at $AABF (build first for AD_ID and size checks)"; fi

if git rev-parse --git-dir >/dev/null 2>&1; then
  S=$(git grep -InE 'BEGIN (RSA |EC )?PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{32,}' -- . ':!*.md' ':!*.lock' 2>/dev/null | head -3)
  [ -z "$S" ] && pass "no obvious secrets in tracked files" || fail "possible secrets: $S"
  T=$(git ls-files | grep -E '\.jks$|\.keystore$|keystore\.properties$|service-account.*\.json$|google-service-app-publisher\.json$' | head -3)
  [ -z "$T" ] && pass "no keystore or service account tracked" || fail "tracked secret files: $T"
fi

echo; echo "AGENT STEPS still to do (see SKILL.md §2): android-review on the diff, security pass, policy pass, run the minified build."
[ $FAILS -eq 0 ] || { echo "$FAILS check(s) FAILED"; exit 1; }
