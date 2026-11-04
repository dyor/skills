---
name: play-prepublish-check
description: Pre-publication system check to run before every Google Play release (internal, closed or production) of an Android or KMP app. Verifies R8/resource shrinking is on, the AAB is signed and declares no stray permissions, scans for security problems (secrets, exported components, cleartext, backup) and Play policy problems (declarations vs permissions), and runs android-review on the changes since the last release. Use before pushing a build to Play, when Publisher reports a failed pre-publish check, or when asked for a "release readiness" or "system check".
version: 1.0.0
---

# Play pre-publish check (`play-prepublish-check`)

Kept separate from `google-play-publishing` on purpose: that skill is reference (how Play
behaves); this one is a checklist to *run* on every release, so it stays short.

Publisher runs `scripts/prepublish_check.sh` before every Android upload. Run the agent
steps below yourself when asked for a full check, or before a production release.

## 1. Mechanical checks (`scripts/prepublish_check.sh <appDir> [module] [aabPath]`)
Exit code 1 means at least one FAIL; Publisher stops the upload. WARN never blocks.

| Check | Level | Why |
|---|---|---|
| Release build has `isMinifyEnabled = true` | FAIL | Without R8 the dex ships whole (Golf Sparks: 30 MB, 20 MB with R8) |
| `isShrinkResources = true` | WARN | Drops unused resources |
| Signing properties present, release not on debug key | FAIL | Play rejects debug-signed bundles |
| `proguard-rules.pro` referenced by the release build | WARN | R8 needs keep rules for serialization and reflection |
| Built AAB manifest has no `AD_ID` unless declared | FAIL | See `google-play-publishing` §5 |
| `debuggable` true in release | FAIL | |
| `usesCleartextTraffic="true"` | WARN | |
| `allowBackup` not set to false | WARN | Backups can leak private data |
| Exported components without a permission | WARN | Review each by hand |
| Secrets in tracked files (private keys, `AIza`, `sk-`, `AKIA`) | FAIL | |
| Keystore / service-account JSON tracked by git | FAIL | |
| AAB size | INFO | Compare with the previous release |

R8 is only half the job: a minified build must be **run** (purchases, sign-in, JSON
decode, any reflection) before it ships. A rules file that compiles is not a rules file
that works.

## 2. Agent steps (not scriptable)
1. **Code review.** Run `android-review` on `git diff <last-release-tag>..HEAD`
   (Golf Sparks: the last `chore(release)` commit). Fix MAJOR findings before publishing.
2. **Security pass.** Read `SPECS/security-audit-report.md` if the repo has one; confirm
   no open item is marked pre-launch. Check new endpoints for auth and rate limits.
3. **Policy pass.** Compare the manifest permissions with the Play declarations and the
   privacy policy: location (prominent disclosure, foreground service), activity
   recognition (health declaration), camera/mic, data deletion URL, Data safety form,
   ads/AD_ID. Anything new since the last release needs its declaration updated first.
4. **Sign-in works in the Play build.** If the app uses Google Sign-In, confirm the Play
   app signing SHA-1, the upload SHA-1 and the debug SHA-1 are registered for each package
   (`firebase apps:android:sha:list <appId>`). A missing one shows as "No credentials
   available" in a Play-installed build. How to find and add them: `google-play-publishing` §5.
5. **Release facts.** versionCode above Play's highest, release notes ≤ 500 characters,
   backend flags that must flip with this build (e.g. purchases switch), functions
   deployed before the app that needs them. For apps with a `firebase` block in Publisher's
   or Runner's `config.json`, both show whether functions are behind the code (they share
   `~/Library/Application Support/Publisher/firebase_deploys.json`); deploy from either
   before releasing if it says so.

## 3. Report
Write `SPECS/prepublish-<date>.md` (or paste in chat): one line per check with
PASS/WARN/FAIL, the android-review summary, and a verdict: ship / ship after fixes / block.
