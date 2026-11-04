#!/usr/bin/env bash
# Run the app's backend tests, then deploy its Firebase functions. Runner sets:
#   APP_DIR           repo folder
#   FIREBASE_PROJECT  project id
#   FIREBASE_ONLY     what to deploy (--only), e.g. functions
#   FIREBASE_TEST     optional test command; a failure stops the deploy
set -euo pipefail
cd "$APP_DIR"

if [ -n "${FIREBASE_TEST:-}" ]; then
  echo "==> Tests: $FIREBASE_TEST"
  bash -c "$FIREBASE_TEST"
fi

echo "==> firebase deploy --only $FIREBASE_ONLY --project $FIREBASE_PROJECT"
firebase deploy --only "$FIREBASE_ONLY" --project "$FIREBASE_PROJECT" --non-interactive
