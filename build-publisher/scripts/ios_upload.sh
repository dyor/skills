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
set -euo pipefail

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
HIGHEST=$(print -r -- "$SNAPSHOT" | ruby -rjson -e '
  d = (JSON.parse(STDIN.read) rescue nil)
  abort("not JSON") unless d.is_a?(Hash)
  abort(d["error"]) if d["error"]
  puts((d["builds"] || []).map { |b| b["buildNumber"].to_i }.max || 0)' 2>/dev/null) || HIGHEST=""

# The last build Publisher itself uploaded for this app. A failed App Store Connect
# read once fell back to 0 here, kept the source number, and the upload was rejected
# as a duplicate after a full archive — so a failed read now falls back to this.
RECORDED=$(ruby -rjson -e '
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

echo "--- archiving $SCHEME (Release)"
xcodebuild archive -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" "${AUTH[@]}" | tail -n 25

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

echo "uploaded build $NEXT to TestFlight"
