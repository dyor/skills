#!/usr/bin/env bash
# Run the app's backend tests, then deploy its Firebase functions. Runner sets:
#   APP_DIR           repo folder
#   BASE_PACKAGE      optional app id (packageName) for Publisher's shared test marker
#   FIREBASE_PROJECT  project id
#   FIREBASE_ONLY     what to deploy (--only), e.g. functions
#   FIREBASE_TEST     optional test command; a failure stops the deploy
set -euo pipefail
cd "$APP_DIR"

HEAD_SHA="$(git rev-parse HEAD 2>/dev/null || true)"

if [ -n "${FIREBASE_TEST:-}" ]; then
  echo "==> Tests: $FIREBASE_TEST"
  bash -c "$FIREBASE_TEST"
  APP_ID="${BASE_PACKAGE:-${PACKAGE:-}}"
  if [ -n "$APP_ID" ] && [ -n "$HEAD_SHA" ] && git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
    MARKERS="$HOME/Library/Application Support/Publisher/tests"
    mkdir -p "$MARKERS"
    touch "$MARKERS/${APP_ID}-${HEAD_SHA}"
  fi
fi

echo "==> firebase deploy --only $FIREBASE_ONLY --project $FIREBASE_PROJECT"
firebase deploy --only "$FIREBASE_ONLY" --project "$FIREBASE_PROJECT" --non-interactive
