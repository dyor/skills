#!/bin/zsh
# Build a release AAB and upload it to a Play track.
#
#   android_upload.sh <appDir> <packageName> <serviceAccountKey> <metadataPath> <track> <notesFile> [module]
#
# <module> is the Gradle module that builds the app (default androidApp; composeApp for a
# KMP project at the repo root). Its build file, task and AAB path are all derived from it.
#
# Picks a version code that Play will accept, writes the release notes where supply
# expects them, then builds and uploads. Safe to read and edit — the app just runs it.
set -euo pipefail

APP_DIR=$1; PKG=$2; KEY=$3; META=$4; TRACK=$5; NOTES_FILE=$6; MODULE=${7:-androidApp}
cd "$APP_DIR"

# Publisher.app takes the lock before invoking this script and sets PUBLISHER_LOCK_OWNED.
# Run straight from a terminal, honour the lock ourselves so a manual run cannot race
# a publish already in flight from the app.
LOCK="$APP_DIR/.publisher.lock"
if [ "${PUBLISHER_LOCK_OWNED:-0}" != "1" ]; then
  if [ -f "$LOCK" ]; then
    PID=$(grep -oE 'pid=[0-9]+' "$LOCK" | cut -d= -f2)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
      echo "Another publish is already running (pid $PID). Lock: $LOCK"; exit 1
    fi
    rm -f "$LOCK"
  fi
  printf 'pid=%s\naction=android_upload.sh\nstarted=%s\n' "$$" "$(date -u +%FT%TZ)" > "$LOCK"
  trap 'rm -f "$LOCK"' EXIT
fi

# Pre-publish gate: the play-prepublish-check skill (github.com/dyor/skills). It lives in
# the agents' skills folder, ~/.agents/skills/play-prepublish-check (override the folder
# with PUBLISHER_SKILLS_DIR). If it is not there, fetch it from GitHub and put it there.
# Mechanical FAILs stop the upload before the slow build. PUBLISHER_SKIP_PREPUBLISH=1
# skips the gate for one run.
SKILLS_DIR=${PUBLISHER_SKILLS_DIR:-$HOME/.agents/skills}
SKILL=$SKILLS_DIR/play-prepublish-check
if [ "${PUBLISHER_SKIP_PREPUBLISH:-0}" != "1" ]; then
  if [ ! -x "$SKILL/scripts/prepublish_check.sh" ]; then
    echo "play-prepublish-check not found in $SKILLS_DIR; downloading from github.com/dyor/skills"
    TMP=$(mktemp -d)
    if git clone --quiet --depth 1 --filter=blob:none --sparse https://github.com/dyor/skills.git "$TMP/skills" \
       && git -C "$TMP/skills" sparse-checkout set play-prepublish-check android-review \
       && [ -d "$TMP/skills/play-prepublish-check" ]; then
      mkdir -p "$SKILLS_DIR"
      for d in play-prepublish-check android-review; do
        [ -d "$TMP/skills/$d" ] && [ ! -e "$SKILLS_DIR/$d" ] && cp -R "$TMP/skills/$d" "$SKILLS_DIR/$d"
      done
    else
      echo "WARNING: could not download the pre-publish skill; continuing without the gate."
    fi
    rm -rf "$TMP"
  fi
  if [ -x "$SKILL/scripts/prepublish_check.sh" ]; then
    echo "== Pre-publish check =="
    "$SKILL/scripts/prepublish_check.sh" "$APP_DIR" "$MODULE" || {
      echo "Pre-publish check failed. Fix the FAIL lines above, or rerun with PUBLISHER_SKIP_PREPUBLISH=1."
      exit 1
    }
  fi
fi

GRADLE_FILE=$MODULE/build.gradle.kts
CURRENT=$(grep -oE 'versionCode *= *[0-9]+' "$GRADLE_FILE" | head -1 | grep -oE '[0-9]+')
echo "versionCode in source: $CURRENT"

# Ask Play for the highest version code it already knows about, so a build from a
# stale checkout (or another machine) can't collide.
HIGHEST=$(KEY="$KEY" PKG="$PKG" bundle exec ruby -e '
require "googleauth"; require "net/http"; require "json"
key, pkg = ENV["KEY"], ENV["PKG"]
auth = Google::Auth::ServiceAccountCredentials.make_creds(
  json_key_io: File.open(key), scope: "https://www.googleapis.com/auth/androidpublisher")
tok = auth.fetch_access_token!["access_token"]
base = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/#{pkg}"
uri = URI("#{base}/edits"); h = Net::HTTP.new(uri.host, 443); h.use_ssl = true
edit = JSON.parse(h.post(uri.path, "", {"Authorization" => "Bearer #{tok}"}).body)
abort("0") unless edit["id"]
r = Net::HTTP.get_response(URI("#{base}/edits/#{edit["id"]}/bundles"),
                           {"Authorization" => "Bearer #{tok}"})
codes = (JSON.parse(r.body)["bundles"] || []).map { |b| b["versionCode"].to_i }
# Delete the query edit. Leaving it open makes Play reject the edit supply opens later
# with "This edit has expired", especially when a long build sits in between.
del = Net::HTTP::Delete.new(URI("#{base}/edits/#{edit["id"]}"),
                            {"Authorization" => "Bearer #{tok}"})
h.request(del) rescue nil
print codes.max || 0
' 2>/dev/null) || HIGHEST=""
if [ -z "$HIGHEST" ]; then
  echo "WARNING: could not read version codes from Play (auth or network?)."
  echo "         Falling back to the version code in source; if Play already has it,"
  echo "         the upload will be rejected rather than silently overwriting anything."
  HIGHEST=0
fi
echo "highest versionCode on Play: $HIGHEST"

if [ "$CURRENT" -le "$HIGHEST" ]; then
  NEXT=$((HIGHEST + 1))
  echo "bumping versionCode $CURRENT -> $NEXT (Play already has $HIGHEST)"
  /usr/bin/sed -i '' "s/versionCode = $CURRENT/versionCode = $NEXT/" "$GRADLE_FILE"
else
  NEXT=$CURRENT
  echo "keeping versionCode $NEXT"
fi

# supply reads release notes from <metadata>/<lang>/changelogs/<versionCode>.txt
CHANGELOG_DIR="$META/en-US/changelogs"
mkdir -p "$CHANGELOG_DIR"
if [ -s "$NOTES_FILE" ]; then
  cp "$NOTES_FILE" "$CHANGELOG_DIR/$NEXT.txt"
  echo "release notes -> $CHANGELOG_DIR/$NEXT.txt"
elif [ ! -f "$CHANGELOG_DIR/$NEXT.txt" ]; then
  echo "Bug fixes and improvements." > "$CHANGELOG_DIR/$NEXT.txt"
  echo "no notes supplied; wrote a placeholder to $CHANGELOG_DIR/$NEXT.txt"
fi

# Play rejects a release whose notes run past 500 characters (counted in UTF-16 units, so an
# emoji is 2). Keep whole lines while they fit; a single over-long line is cut with an ellipsis.
python3 - "$CHANGELOG_DIR/$NEXT.txt" <<'PY'
import sys
LIMIT = 500
n = lambda t: len(t.encode("utf-16-le")) // 2
path = sys.argv[1]
text = open(path, encoding="utf-8").read().strip()
if n(text) > LIMIT:
    kept = []
    for line in text.splitlines():
        if n("\n".join(kept + [line])) > LIMIT:
            break
        kept.append(line)
    out = "\n".join(kept)
    if not out:
        out = text
        while n(out + "…") > LIMIT:
            out = out[:-1]
        out = out.rstrip() + "…"
    open(path, "w", encoding="utf-8").write(out + "\n")
    print(f"release notes were {n(text)} characters; trimmed to {n(out)} (Play's limit is {LIMIT})")
PY
echo "--- release notes for $NEXT ---"; cat "$CHANGELOG_DIR/$NEXT.txt"; echo "---"

./gradlew ":$MODULE:bundleRelease"

# AGP names the bundle after the Gradle project (:composeApp -> composeApp-release.aab).
# If a build overrides that, take the single AAB in the output dir rather than guess.
AAB_DIR=$MODULE/build/outputs/bundle/release
AAB=$AAB_DIR/$MODULE-release.aab
if [ ! -f "$AAB" ]; then
  AABS=("$AAB_DIR"/*.aab(N))
  [ ${#AABS[@]} -eq 1 ] || { echo "Expected one AAB in $AAB_DIR, found ${#AABS[@]}"; exit 1; }
  AAB=${AABS[1]}
fi
echo "AAB: $AAB"

if [ "${PUBLISHER_USE_SUPPLY:-0}" = "1" ]; then
  # The original single-track upload through fastlane supply.
  bundle exec fastlane run upload_to_play_store \
    package_name:"$PKG" \
    json_key:"$KEY" \
    aab:"$AAB" \
    track:"$TRACK" \
    release_status:completed \
    metadata_path:"$META" \
    skip_upload_metadata:true \
    skip_upload_images:true \
    skip_upload_screenshots:true \
    skip_upload_changelogs:false \
    changes_not_sent_for_review:true \
    timeout:900
  echo "uploaded versionCode $NEXT to $TRACK"
else
  # One Play edit sets the new build on the target track AND on every other non-production
  # track that already holds a release (see scripts/play_release.rb for why).
  VERSION_NAME=$(grep -oE 'versionName = "[^"]+"' "$GRADLE_FILE" | head -1 | cut -d'"' -f2)
  KEY="$KEY" PKG="$PKG" AAB="$AAB" NOTES_FILE="$CHANGELOG_DIR/$NEXT.txt" TRACK="$TRACK" \
    VERSION_NAME="$VERSION_NAME" bundle exec ruby "${0:A:h}/play_release.rb"
fi

# The upload edited two tracked files: the versionCode bump and this version's release notes.
# Commit just those and push, so nothing is left hanging in the tree (a dirty tree blocks the
# next publish). Best effort: the build is already live, so a failure here only warns.
RELEASE_FILES=("$GRADLE_FILE" "$CHANGELOG_DIR/$NEXT.txt")
if git -C "$APP_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  BEFORE=$(git rev-parse HEAD)
  git add -- "${RELEASE_FILES[@]}" 2>/dev/null || true
  if ! git diff --cached --quiet -- "${RELEASE_FILES[@]}" 2>/dev/null; then
    if git commit -q -m "chore(release): versionCode $NEXT to $TRACK" -- "${RELEASE_FILES[@]}"; then
      echo "release commit $(git rev-parse HEAD) after $BEFORE"
      git push -q || echo "WARNING: committed the release files but could not push; push when you can."
    else
      echo "WARNING: could not commit the release files; commit $GRADLE_FILE and the new changelog by hand."
    fi
  fi
fi
