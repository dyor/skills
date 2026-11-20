#!/bin/zsh
# Mechanical release scan for an Android or KMP app. Shared by android-review and kmp-review
# (identical copy in both skills; edit one, copy to the other).
#   release_scan.sh <appDir> [androidModule=auto] [baseRef=last tag or empty]
# Levels: FAIL blocks release, WARN needs a human look, INFO is context. Exit 1 on any FAIL.
set -uo pipefail
APP=${1:?appDir}; MODULE=${2:-auto}; BASE=${3:-}
cd "$APP" || exit 2
FAILS=0; WARNS=0
pass() { echo "PASS  $1"; }
warn() { echo "WARN  $1"; WARNS=$((WARNS+1)); }
info() { echo "INFO  $1"; }
fail() { echo "FAIL  $1"; FAILS=$((FAILS+1)); }
head3() { head -${2:-5} | sed 's/^/        /'; }

GIT=0; git rev-parse --git-dir >/dev/null 2>&1 && GIT=1
if [ $GIT -eq 1 ]; then FILES=$(git ls-files); else FILES=$(find . -type f -not -path '*/build/*' -not -path '*/.gradle/*' -not -path '*/Pods/*' | sed 's|^\./||'); fi
SRC=$(echo "$FILES" | grep -E '\.(kt|kts|java|swift|m|h|xml|plist|json|properties|gradle|pro|toml|yml|yaml|js|ts|env)$' | grep -vE '(^|/)(build|node_modules|Pods)/')

# Detect shape
KMP=0; echo "$FILES" | grep -qE 'src/(commonMain|iosMain)/' && KMP=1
IOS=0; echo "$FILES" | grep -qE '\.xcodeproj/|(^|/)Info\.plist$' && IOS=1
if [ "$MODULE" = auto ]; then
  MODULE=$(echo "$FILES" | grep -E '(^|/)build\.gradle(\.kts)?$' | xargs grep -lE 'com\.android\.application|android\.application' 2>/dev/null | head -1 | xargs -I{} dirname {})
  [ -z "$MODULE" ] && MODULE=androidApp
fi
info "shape: KMP=$KMP iOS=$IOS androidModule=$MODULE"

echo; echo "== 1. R8 / shrinking (Android release) =="
G=""; for c in "$MODULE/build.gradle.kts" "$MODULE/build.gradle"; do [ -f "$c" ] && G=$c && break; done
if [ -z "$G" ]; then warn "no Android app build file found at $MODULE"; else
  REL=$(awk '/getByName\("release"\)|release *\{/{f=1} f{print} f&&/^        }/{exit}' "$G")
  echo "$REL" | grep -qE 'isMinifyEnabled *= *true|minifyEnabled true' && pass "R8 minification on" \
    || fail "R8 is off: set isMinifyEnabled = true in the release build, then RUN the minified build"
  echo "$REL" | grep -qE 'isShrinkResources *= *true|shrinkResources true' && pass "resource shrinking on" || warn "isShrinkResources is not true"
  echo "$REL" | grep -q 'debuggable *= *true' && fail "release is debuggable" || pass "release not debuggable"
  echo "$REL" | grep -q 'getDefaultProguardFile("proguard-android-optimize.txt")' && pass "optimizing default rules" \
    || { echo "$REL" | grep -q 'proguard-android.txt' && warn "uses proguard-android.txt; prefer proguard-android-optimize.txt"; }
  PRO=$(echo "$REL" | grep -oE '"[^"]*\.pro"' | tr -d '"' | tail -1)
  if [ -n "$PRO" ] && [ -f "$MODULE/$PRO" ]; then
    pass "keep rules file $PRO"
    R="$MODULE/$PRO"
    # Libraries that need keep rules unless their consumer rules cover them
    grep -rqlE 'kotlinx\.serialization|@Serializable' $MODULE/src $(echo "$FILES" | grep -E 'src/commonMain/.*\.kt$') 2>/dev/null \
      && ! grep -q 'kotlinx.serialization' "$R" && info "uses kotlinx.serialization: its consumer rules usually suffice; confirm JSON decode on a minified build"
    grep -qE '^-dontwarn \*\*|^-keep class \*\* *\{ *\*; *\}|^-keep class \*\*$' "$R" && warn "blanket keep/dontwarn in $PRO defeats R8; narrow it"
    grep -qE 'koin|Koin' "$G" && info "Koin in use: run the minified build, check every injected screen"
  else warn "no keep-rules (.pro) file referenced by the release build"; fi
fi
[ -f "$MODULE/build/outputs/mapping/release/mapping.txt" ] && pass "R8 mapping.txt exists (minified build was produced)" \
  || info "no mapping.txt: build releaseBundle to confirm R8 ran; upload mapping to Play/Crashlytics"

echo; echo "== 2. Secrets and API keys in tracked files =="
if [ $GIT -eq 1 ]; then
  P='BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{32,}|sk-ant-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{10,}|SG\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}|sk_live_[A-Za-z0-9]{16,}|rk_live_[A-Za-z0-9]{16,}|-----BEGIN CERTIFICATE-----'
  S=$(git grep -InE "$P" -- . ':!*.lock' ':!*.md' 2>/dev/null | head -5)
  [ -z "$S" ] && pass "no provider-format secrets in tracked files" || { fail "possible secrets:"; echo "$S" | head3; }
  # Firebase/Google API keys: normal inside google-services.json / GoogleService-Info.plist, suspect elsewhere
  A=$(git grep -InE 'AIza[0-9A-Za-z_-]{35}' -- . ':!*google-services.json' ':!*GoogleService-Info.plist' ':!*.md' 2>/dev/null | head -5)
  [ -z "$A" ] && pass "no Google API keys outside Firebase config files" || { warn "Google API key in source (restrict it by package/SHA in Cloud Console, or move out of source):"; echo "$A" | head3; }
  # Generic assignments: apiKey = "longstring", token: "...", password = "..."
  Q=$(git grep -InE "(api[_-]?key|apikey|secret|token|passw(or)?d|client[_-]?secret|private[_-]?key)[\"']? *[:=] *[\"'][A-Za-z0-9_/+=.-]{16,}[\"']" -- $(echo "$SRC") ':!*.md' ':!*/test/*' ':!*Test*' ':!*test*' 2>/dev/null | grep -viE 'example|placeholder|your[_-]|changeme|xxxx|<|\$\{|BuildConfig|getenv|System\.getProperty|stringResource|R\.string' | head -8)
  [ -z "$Q" ] && pass "no hard-coded key/token/password assignments" || { warn "hard-coded credential-looking assignments (verify each; a public client key is fine, a server secret is not):"; echo "$Q" | head3 "" 8; }
  T=$(echo "$FILES" | grep -E '\.jks$|\.keystore$|keystore\.properties$|\.p12$|\.pem$|\.p8$|service-account.*\.json$|google-service-app-publisher\.json$|AuthKey_.*\.p8$|(^|/)\.env(\..*)?$|local\.properties$|secrets?\.(properties|json|ya?ml)$' | head -5)
  [ -z "$T" ] && pass "no keystore / signing / service-account / .env file tracked" || { fail "tracked secret-type files (git rm --cached, rotate the secret):"; echo "$T" | head3; }
  # History: a secret deleted from HEAD is still leaked
  H=$(git log --all --diff-filter=D --name-only --pretty=format: 2>/dev/null | grep -E '\.jks$|\.keystore$|\.p8$|\.pem$|service-account.*\.json$|(^|/)\.env$|keystore\.properties$' | sort -u | head -5)
  [ -z "$H" ] && pass "no secret-type files deleted from history" || { warn "secret-type files exist in git history (rotate them; deleting from HEAD does not unleak):"; echo "$H" | head3; }
  # Ignore rules
  for f in local.properties keystore.properties '*.jks'; do git check-ignore -q "$f" 2>/dev/null || info ".gitignore does not match $f (ok only if the file never exists here)"; done
fi

echo; echo "== 3. Unfinished or non-production code =="
if [ $GIT -eq 1 ]; then
  KT='\.(kt|java|swift)$'
  N=$(git grep -InE 'TODO\(|NotImplementedError|fatalError\("(not|todo)|error\("(not implemented|TODO)' -- '*.kt' '*.swift' '*.java' ':!*/test/*' ':!*Test*' ':!*/build/*' 2>/dev/null | grep -vE ':[0-9]+:\s*(//|\*|/\*)')
  [ -z "$N" ] && pass "no TODO()/NotImplementedError stubs" || { fail "stubs that throw at runtime:"; echo "$N" | head3 "" 10; }
  T=$(git grep -InE '//\s*(TODO|FIXME|XXX|HACK)|/\*\s*(TODO|FIXME)' -- '*.kt' '*.swift' '*.java' ':!*/test/*' ':!*Test*' 2>/dev/null)
  C=$(echo "$T" | grep -c . ); [ "$C" -eq 0 ] && pass "no TODO/FIXME comments" || { warn "$C TODO/FIXME/HACK comment(s); each is either done, ticketed or deleted:"; echo "$T" | head3 "" 12; }
  P=$(git grep -InEi 'lorem ipsum|placeholder text|coming soon|not yet implemented|unimplemented|stub(bed)?\b|dummy (data|user)|fake (data|user|token)|mock(ed)? (data|response)|hardcoded for now|temporary(ly)? (hack|fix)' -- '*.kt' '*.swift' '*.xml' ':!*/test/*' ':!*Test*' ':!*/androidTest/*' 2>/dev/null | head -10)
  [ -z "$P" ] && pass "no placeholder/stub/mock wording in production sources" || { warn "placeholder-looking wording:"; echo "$P" | head3 "" 10; }
  D=$(git grep -InE 'Log\.(d|v)\(|println\(|print\(|NSLog\(|BuildConfig\.DEBUG *= *true|isDebug *= *true|DEBUG_MODE *= *true|(Napier|Logger)\.d\(' -- '*.kt' '*.swift' ':!*/test/*' ':!*Test*' ':!*/androidTest/*' 2>/dev/null | wc -l | tr -d ' ')
  [ "$D" -eq 0 ] && pass "no debug logging/print calls" || warn "$D debug log/print call(s) in production sources (check none logs PII, tokens or purchase data)"
  U=$(git grep -InE 'https?://(localhost|127\.0\.0\.1|10\.0\.2\.2|192\.168\.|[a-z0-9.-]*\.(local|test|ngrok(-free)?\.(io|app|dev)))' -- '*.kt' '*.swift' '*.java' '*.xml' '*.plist' '*.gradle' '*.kts' '*.properties' ':!*/test/*' ':!*Test*' ':!*/debug/*' 2>/dev/null | head -5)
  [ -z "$U" ] && pass "no localhost/dev/ngrok URLs" || { fail "dev-only URLs in sources:"; echo "$U" | head3; }
  E=$(git grep -InE '\{\s*\}\s*//\s*(todo|no-?op|noop|empty)|actual (fun|class|val).*(TODO|= *Unit *$)' -- '*.kt' ':!*/test/*' 2>/dev/null | head -5)
  [ -z "$E" ] && pass "no empty/no-op actuals or handlers flagged by pattern" || { warn "possible empty implementations:"; echo "$E" | head3; }
  # Disabled UI / dead buttons
  B=$(git grep -InE 'onClick *= *\{ *\}|onClick\s*=\s*\{\s*/\*|enabled *= *false *//|\.clickable *\{ *\}' -- '*.kt' ':!*/test/*' ':!*Preview*' 2>/dev/null | head -5)
  [ -z "$B" ] && pass "no empty onClick handlers" || { warn "buttons that do nothing:"; echo "$B" | head3; }
  I=$(git grep -InE '@Ignore|@Disabled|\.skip\(|@Test.*Ignore' -- '*.kt' 2>/dev/null | wc -l | tr -d ' ')
  [ "$I" -eq 0 ] && pass "no ignored/disabled tests" || warn "$I ignored/disabled test(s): fix or delete before release"
  # KMP: expect without actual on a target
  if [ $KMP -eq 1 ]; then
    EXP=$(git grep -hoE 'expect (fun|class|object|interface|val) +[A-Za-z0-9_<>.]+' -- '*/commonMain/*.kt' 2>/dev/null | sed -E 's/expect (fun|class|object|interface|val) +//; s/[<(].*//' | sort -u)
    MISS=""
    for n in $(echo "$EXP"); do
      for tgt in androidMain iosMain; do
        ls -d */src/$tgt >/dev/null 2>&1 || continue
        git grep -qE "actual .*\b$n\b" -- "*/$tgt/*.kt" 2>/dev/null || MISS="$MISS $n@$tgt"
      done
    done
    [ -z "$MISS" ] && pass "every expect has an actual on android and ios (by name)" || warn "expect with no matching actual by name (may be typealias or interface-injected; verify):$MISS"
    # Android-only or iOS-only code leaking into commonMain
    L=$(git grep -InE '^import (android\.|androidx\.(activity|fragment|appcompat)|java\.(io|util\.concurrent)\.|platform\.(UIKit|Foundation))' -- '*/commonMain/*.kt' 2>/dev/null | head -5)
    [ -z "$L" ] && pass "commonMain has no platform imports" || { warn "platform imports in commonMain (will fail the other target or force JVM-only types):"; echo "$L" | head3; }
  fi
fi

echo; echo "== 4. Android manifest and build hygiene =="
MAN="$MODULE/src/main/AndroidManifest.xml"
if [ -f "$MAN" ]; then
  grep -q 'usesCleartextTraffic="true"' "$MAN" && warn "usesCleartextTraffic=true" || pass "no cleartext flag"
  grep -q 'allowBackup="false"' "$MAN" && pass "allowBackup=false" || warn "allowBackup not false"
  grep -q 'android:debuggable' "$MAN" && warn "manifest sets android:debuggable explicitly; remove it"
  info "$(grep -c 'android:exported="true"' "$MAN") exported component(s): launcher expected, review the rest and require permissions"
  grep -oE 'android\.permission\.[A-Z_]+' "$MAN" | sort -u | tr '\n' ' ' | sed 's/^/INFO  declared permissions: /'; echo
  grep -qE 'permission\.(READ_SMS|RECEIVE_SMS|READ_CALL_LOG|SYSTEM_ALERT_WINDOW|MANAGE_EXTERNAL_STORAGE|QUERY_ALL_PACKAGES|ACCESS_BACKGROUND_LOCATION)' "$MAN" && warn "Play-restricted permission declared: needs a declaration form"
fi
V=$(grep -hE 'versionCode|versionName' "$G" 2>/dev/null | head -2 | tr -s ' ' | tr '\n' ';'); [ -n "$V" ] && info "version: $V (versionCode must exceed Play's highest)"
grep -rqE 'targetSdk *= *[0-9]+' "$G" 2>/dev/null && info "$(grep -hoE 'targetSdk *= *[0-9]+' "$G" | head -1) (Play requires the current API level for new releases)"

if [ $IOS -eq 1 ]; then
  echo; echo "== 5. iOS release hygiene =="
  PLIST=$(echo "$FILES" | grep -E '(^|/)Info\.plist$' | grep -viE 'test|pods' | head -1)
  PM=$(echo "$FILES" | grep -E 'PrivacyInfo\.xcprivacy$' | head -1)
  [ -n "$PM" ] && pass "privacy manifest present ($PM)" || fail "no PrivacyInfo.xcprivacy (App Store requires it; list required-reason APIs and collected data)"
  if [ -n "$PLIST" ]; then
    grep -q 'NSAllowsArbitraryLoads' "$PLIST" && warn "App Transport Security disabled (NSAllowsArbitraryLoads); justify in review notes"
    for k in NSCameraUsageDescription NSMicrophoneUsageDescription NSLocationWhenInUseUsageDescription NSPhotoLibraryUsageDescription NSMotionUsageDescription NSUserTrackingUsageDescription; do
      grep -q "$k" "$PLIST" && ! grep -A1 "$k" "$PLIST" | grep -qE '<string>[^<]{8,}' && warn "$k present but empty/short purpose string"
    done
    info "plist: $PLIST (confirm CFBundleShortVersionString / CFBundleVersion bumped)"
  fi
  U=$(echo "$FILES" | grep -E '\.entitlements$' | head -3 | xargs grep -lE 'aps-environment.*development' 2>/dev/null)
  [ -n "$U" ] && warn "aps-environment is 'development' in $U (release signing normally flips it; verify the archive)"
  [ -d "$(echo "$FILES" | grep -E '\.xcodeproj/' | head -1 | cut -d/ -f1-2)" ] && info "iOS: archive with Release config, check no -Onone, no debug symbols stripped from dSYM upload"
  GS=$(echo "$FILES" | grep -E 'GoogleService-Info\.plist$' | head -1); [ -n "$GS" ] && info "$GS tracked: public client config is fine; confirm it is the PRODUCTION Firebase project, not a dev one"
fi

echo; echo "== 6. Dependencies =="
if [ -f gradle/libs.versions.toml ]; then
  S=$(grep -nE '^[A-Za-z0-9_.-]+ *= *"[^"]*(SNAPSHOT|alpha|beta|-rc|-dev|eap)[^"]*"' gradle/libs.versions.toml | head -8)
  [ -z "$S" ] && pass "no pre-release dependency versions" || { warn "pre-release dependency versions (accept consciously for release):"; echo "$S" | head3 "" 8; }
fi
GP=$(git grep -nE 'mavenLocal\(\)|jcenter\(\)|http://' -- '*.gradle' '*.gradle.kts' 2>/dev/null | head -3)
[ -z "$GP" ] && pass "no mavenLocal/jcenter/http repositories" || { warn "risky repositories:"; echo "$GP" | head3; }

echo; echo "== Summary =="
echo "$FAILS FAIL, $WARNS WARN"
echo "Mechanical scan only. Still required: run the MINIFIED release build, android docs checks, skill discovery, and the review pass (see SKILL.md)."
[ $FAILS -eq 0 ] || exit 1
