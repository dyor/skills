#!/bin/zsh
# Archive the iOS app and upload it to App Store Connect (TestFlight).
#
#   ios_upload.sh <appDir> <bundleId> <xcodeproj> <scheme> <keyId> <issuerId> <keyPath> <notesFile> [recordId]
#
# recordId: the app's key in Publisher's releases.json (its Android package when it has
# one), so the last build Publisher uploaded counts even when App Store Connect can't be read.
#
# Signs and uploads with xcodebuild itself, using the Apple ID signed in to Xcode:
# creating the "iOS Distribution" certificate through cloud signing needs an Admin
# role, which Xcode's account has and an App Manager API key does not ("Cloud signing
# permission error"). The API key is still what reads App Store Connect, sets TestFlight
# notes and submits for review. Picks a build number App Store Connect
# will accept, writing it back into the Xcode project, as android_upload.sh does for
# versionCode. DRY_RUN=1 archives and exports but does not upload.
#
# Release naming (see build-publisher "Release naming"):
#   first attempt  MAJOR.MINOR (BUILD)         e.g. 1.2 (6)
#   any retry      MAJOR.MINOR.BUILD (BUILD)   e.g. 1.2.7 (7)
# PUBLISHER_VERSION=1.2.7 sets MARKETING_VERSION for this run. App Store Connect refuses a
# new build for a version it has already approved, so this script stops before the archive
# when the version is approved and says which MAJOR.MINOR.<build> to retry as.
set -euo pipefail

# Ruby reads the App Store Connect snapshot as the locale's encoding; with LANG unset it is
# US-ASCII and a name like "Buen Día" fails to parse. Force UTF-8 for every child process.
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

APP_DIR=$1; BUNDLE_ID=$2; PROJECT=$3; SCHEME=$4; KEY_ID=$5; ISSUER=$6; KEY_PATH=$7; NOTES_FILE=${8:-}; RECORD_ID=${9:-$2}
cd "$APP_DIR"
SCRIPTS=${0:A:h}

# Same lock as android_upload.sh: one publish per project, whoever starts it.
LOCK="$APP_DIR/.publisher.lock"
if [ "${PUBLISHER_LOCK_OWNED:-0}" != "1" ]; then
  if [ -f "$LOCK" ]; then
    PID=$(grep -oE 'pid=[0-9]+' "$LOCK" | cut -d= -f2)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
      echo "Another publish is already running (pid $PID). Lock: $LOCK"; exit 1
    fi
    rm -f "$LOCK"
  fi
  printf 'pid=%s\naction=ios_upload.sh\nstarted=%s\n' "$$" "$(date -u +%FT%TZ)" > "$LOCK"
  trap 'rm -f "$LOCK"' EXIT
fi

PBXPROJ="$PROJECT/project.pbxproj"
CURRENT=$(grep -oE 'CURRENT_PROJECT_VERSION = [0-9]+' "$PBXPROJ" | head -1 | grep -oE '[0-9]+$')
echo "build number in source: $CURRENT"

# Highest build number App Store Connect already has for this app, so a stale checkout
# or another machine cannot collide ("The bundle version must be higher…").
SNAPSHOT=$(bundle exec ruby "$SCRIPTS/appstore_snapshot.rb" "$BUNDLE_ID" "$KEY_ID" "$ISSUER" "$KEY_PATH" 2>&1 | tail -1) || true
HIGHEST=$(print -r -- "$SNAPSHOT" | ruby -Eutf-8 -rjson -e '
  d = (JSON.parse(STDIN.read) rescue nil)
  abort("not JSON") unless d.is_a?(Hash)
  abort(d["error"]) if d["error"]
  puts((d["builds"] || []).map { |b| b["buildNumber"].to_i }.max || 0)' 2>/dev/null) || HIGHEST=""

# The last build Publisher itself uploaded for this app. A failed App Store Connect
# read once fell back to 0 here, kept the source number, and the upload was rejected
# as a duplicate after a full archive — so a failed read now falls back to this.
RECORDED=$(ruby -Eutf-8 -rjson -e '
  f = File.join(Dir.home, "Library/Application Support/Publisher/releases.json")
  r = (JSON.parse(File.read(f)) rescue [])
  puts r.select { |e| e["packageName"] == ARGV[0] && e["platform"] == "ios" }.map { |e| e["versionCode"].to_i }.max || 0' "$RECORD_ID")

if [ -z "$HIGHEST" ]; then
  echo "WARNING: could not read builds from App Store Connect: $SNAPSHOT"
  if [ "$RECORDED" -eq 0 ]; then
    echo "No build is recorded for $RECORD_ID either, so the next build number is a guess. Not uploading:"
    echo "fix the App Store Connect read (above), or check the build numbers in App Store Connect and retry."
    exit 1
  fi
  echo "using the last build Publisher uploaded: $RECORDED"
  HIGHEST=$RECORDED
fi
[ "$RECORDED" -gt "$HIGHEST" ] && HIGHEST=$RECORDED
echo "highest build on App Store Connect / last uploaded: $HIGHEST"

if [ "$CURRENT" -le "$HIGHEST" ]; then
  NEXT=$((HIGHEST + 1))
  echo "bumping build number $CURRENT -> $NEXT"
  /usr/bin/sed -i '' "s/CURRENT_PROJECT_VERSION = $CURRENT;/CURRENT_PROJECT_VERSION = $NEXT;/g" "$PBXPROJ"
  # XcodeGen projects (Buen Dia): project.yml is the source of truth, and the next
  # `xcodegen generate` would otherwise reset the number the project file now has.
  SPEC="${PROJECT:h}/project.yml"
  if [ -f "$SPEC" ]; then
    /usr/bin/sed -i '' -E "s/(CURRENT_PROJECT_VERSION: *\"?)$CURRENT(\"?)/\1$NEXT\2/" "$SPEC"
    echo "also bumped $SPEC"
  fi
else
  NEXT=$CURRENT
  echo "keeping build number $NEXT"
fi

# Publish to both stores: one build number for the release on both stores.
MIN_BUILD=${PUBLISHER_MIN_BUILD:-0}
if [ "$MIN_BUILD" -gt "$NEXT" ]; then
  /usr/bin/sed -i '' "s/CURRENT_PROJECT_VERSION = $NEXT;/CURRENT_PROJECT_VERSION = $MIN_BUILD;/g" "$PBXPROJ"
  SPEC="${PROJECT:h}/project.yml"
  [ -f "$SPEC" ] && /usr/bin/sed -i '' -E "s/(CURRENT_PROJECT_VERSION: *\"?)$NEXT(\"?)/\1$MIN_BUILD\2/" "$SPEC"
  echo "raising build number $NEXT -> $MIN_BUILD to match the release's build number"
  NEXT=$MIN_BUILD
fi

# Version string for this attempt (PUBLISHER_VERSION, else whatever the project has).
SPEC="${PROJECT:h}/project.yml"
CUR_VERSION=$(grep -oE 'MARKETING_VERSION = [^;]+' "$PBXPROJ" | head -1 | sed -E 's/MARKETING_VERSION = //; s/"//g; s/ //g')
VERSION=${PUBLISHER_VERSION:-$CUR_VERSION}
if ! print -r -- "$VERSION" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
  echo "Version '$VERSION' is not MAJOR.MINOR or MAJOR.MINOR.BUILD"; exit 1
fi
THIRD=$(print -r -- "$VERSION" | awk -F. 'NF==3 {print $3}')
BASE=$(print -r -- "$VERSION" | awk -F. '{print $1"."$2}')
if [ -n "$THIRD" ] && [ "$THIRD" != "$NEXT" ]; then
  echo "Retry version $VERSION must end in the build number ($NEXT): use $BASE.$NEXT"; exit 1
fi

# Apple closes a version once it approves it; a new build for it is refused (ITMS-90186 /
# ITMS-90062) only after a full archive and upload. Check now instead.
APPROVED=$(print -r -- "$SNAPSHOT" | ruby -Eutf-8 -rjson -e '
  d = (JSON.parse(STDIN.read) rescue {})
  closed = %w[PENDING_APPLE_RELEASE PENDING_DEVELOPER_RELEASE PROCESSING_FOR_APP_STORE
              READY_FOR_SALE READY_FOR_DISTRIBUTION REPLACED_WITH_NEW_VERSION
              REMOVED_FROM_SALE DEVELOPER_REMOVED_FROM_SALE]
  puts (d["versions"] || []).select { |v| closed.include?(v["state"]) }.map { |v| v["version"] }' 2>/dev/null) || APPROVED=""
if print -r -- "$APPROVED" | grep -qxF -- "$VERSION"; then
  echo "App Store Connect has already approved version $VERSION, so it will not accept another build of it."
  echo "Retry as $BASE.$NEXT (build $NEXT):  PUBLISHER_VERSION=$BASE.$NEXT"
  exit 1
fi

if [ "$VERSION" != "$CUR_VERSION" ]; then
  /usr/bin/sed -i '' -E "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = $VERSION;/g" "$PBXPROJ"
  [ -f "$SPEC" ] && /usr/bin/sed -i '' -E "s/(MARKETING_VERSION: *)\"?[0-9.]+\"?/\1\"$VERSION\"/" "$SPEC"
  echo "MARKETING_VERSION $CUR_VERSION -> $VERSION"
fi

OUT="$APP_DIR/distribution/ios/build"
ARCHIVE="$OUT/$SCHEME.xcarchive"
mkdir -p "$OUT"
rm -rf "$ARCHIVE" "$OUT/export"

# Xcode's signed-in account signs. To sign with an Admin-role API key instead, set
# SIGN_WITH_API_KEY=1.
AUTH=(-allowProvisioningUpdates)
if [ "${SIGN_WITH_API_KEY:-0}" = "1" ]; then
  AUTH+=(-authenticationKeyPath "$KEY_PATH" -authenticationKeyID "$KEY_ID" -authenticationKeyIssuerID "$ISSUER")
fi

# The Gradle daemon (4 GB) plus the Kotlin daemon (3 GB) don't fit beside leftovers on an
# 8 GB Mac. Stop any idle daemons first so the archive starts with the memory to itself.
if [ -x ./gradlew ]; then ./gradlew --stop >/dev/null 2>&1 || true; fi

LOG="$OUT/archive.log"
run_archive() {
  xcodebuild archive -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
    -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" "${AUTH[@]}" > "$LOG" 2>&1
}
echo "--- archiving $SCHEME (Release)"
if ! run_archive; then
  # macOS killing the Gradle daemon is transient and its progress is cached: stop what is
  # left and retry once instead of failing after 10 minutes.
  if grep -q "daemon disappeared unexpectedly" "$LOG"; then
    echo "Gradle daemon was killed (low memory). Stopping daemons and retrying once…"
    pkill -f GradleDaemon 2>/dev/null || true; pkill -f KotlinCompileDaemon 2>/dev/null || true
    sleep 5
    run_archive || true
  fi
fi
if [ ! -d "$ARCHIVE" ]; then
  echo "ARCHIVE FAILED. The real errors (full log: $LOG):"
  grep -E "error:|^e: |What went wrong|daemon disappeared|Execution failed|Provisioning|requires a provisioning|No profiles" -A2 "$LOG" | head -40
  exit 65
fi
tail -n 5 "$LOG"

# destination=upload makes -exportArchive send the build to App Store Connect itself.
DESTINATION=upload
[ "${DRY_RUN:-0}" = "1" ] && DESTINATION=export
cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>$DESTINATION</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PLIST

# Said again here: the activity history keeps only the end of a run's log.
echo "--- exporting ($DESTINATION) build $NEXT (source had $CURRENT, highest known $HIGHEST)"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$OUT/export" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" "${AUTH[@]}" | tail -n 25

if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "DRY RUN: exported $(ls "$OUT/export"/*.ipa 2>/dev/null) — nothing uploaded"
  exit 0
fi

# "What to Test" is attached once App Store Connect has processed the build.
if [ -n "$NOTES_FILE" ] && [ -s "$NOTES_FILE" ]; then
  bundle exec ruby "$SCRIPTS/appstore_notes.rb" "$BUNDLE_ID" "$KEY_ID" "$ISSUER" "$KEY_PATH" "$NEXT" "$NOTES_FILE" || \
    echo "WARNING: build uploaded, but its TestFlight notes could not be set (add them in App Store Connect)."
fi

echo "uploaded $VERSION ($NEXT) to TestFlight"
