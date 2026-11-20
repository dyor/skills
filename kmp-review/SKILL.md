---
name: kmp-review
description: Pre-release review for Kotlin Multiplatform (Compose Multiplatform + Android + iOS) apps. Say "/kmp-review for release" to run everything - R8/minified-build verification, secrets and API-key scan (tracked files and git history), unfinished-code scan (stubs, TODOs, empty actuals, dead buttons, dev URLs), iOS release hygiene (privacy manifest, ATS, permissions), skill discovery (local dyor skills plus android/skills), Android docs lookup through the android CLI, and a KMP-aware code review (commonMain purity, expect/actual, Kotlin/Native threading, cinterop). Ends with a ship / ship-after-fixes / block verdict.
version: 1.1.0
---

# KMP Review (`kmp-review`)

One command for "are we ready to release?" on a KMP app. The user says
`/kmp-review for release` (or `/kmp-review <scope>` for a narrower review of a diff or
feature). You run every step below, in order, and finish with a verdict.

Sibling skills:
- `android-review` is the Android-only version (same checks, no iOS/commonMain section).
- `play-prepublish-check` is Publisher's script gate for the Play upload; this skill is a
  superset for the code and repo, and includes the Android review methodology.
- `google-play-publishing`, `adapty-store-payments`, `implement-native-firebase-kmp`,
  `app-store-assets`, `febak-site-pages` are the reference skills to invoke when the
  change touches their area (Step 2).

## Modes
- **release** (default when the user says "for release"): all steps, whole app, diff
  since the last release tag/`chore(release)` commit is the review scope, the rest of the
  repo gets the mechanical scans only.
- **diff**: Steps 2-5 on `git diff <base>..HEAD`, skip the release gate.

## Step 0: Orient (2 minutes)
1. Find the shape: `settings.gradle.kts` modules, `shared/` (or `composeApp/`) with
   `commonMain`/`androidMain`/`iosMain`, `androidApp/` (or `composeApp`), `iosApp/`.
2. Find the release base: `git describe --tags --abbrev=0`, else the last commit whose
   message starts `chore(release)`, else ask. Record `git diff --stat <base>..HEAD`.
3. Read `distribution/` notes, `SPECS/`, and the repo's CLAUDE.md for app-specific
   release facts (package id, Firebase project, payments, flags to flip).

## Step 1: Run the mechanical scan
```bash
~/.claude/skills/kmp-review/scripts/release_scan.sh <appDir> [androidModule] [baseRef]
```
Exit 1 means at least one FAIL. It covers, with FAIL/WARN/INFO levels:
- **R8 (Android):** `isMinifyEnabled`, `isShrinkResources`, optimizing default rules,
  keep-rules file present and not a blanket `-keep class **`, `mapping.txt` exists.
- **Secrets / API keys:** provider-format keys (AWS, GitHub, Stripe live, Slack, SendGrid,
  Anthropic/OpenAI `sk-`, private keys), `AIza` Google keys outside Firebase config files,
  hard-coded `apiKey/secret/token/password = "..."`, tracked keystores / `.p8` / `.pem` /
  `.env` / service-account JSON / `local.properties`, and secret-type files deleted from
  git history (still leaked).
- **Unfinished code:** `TODO()`, `NotImplementedError`, `TODO/FIXME/HACK`, "coming soon" /
  "not yet implemented" / "stub" / "mock data" wording, debug logging, localhost / 10.0.2.2
  / ngrok URLs, empty `onClick = {}`, `@Ignore`d tests, `expect` declarations with no
  `actual` on a target, platform imports leaking into `commonMain`.
- **Manifest / iOS hygiene:** cleartext, backup, exported components, restricted
  permissions, privacy manifest, ATS, empty usage-description strings, APNs environment,
  dev-vs-prod Firebase plist.
- **Dependencies:** SNAPSHOT/alpha/beta/rc versions, `mavenLocal()`, `http://` repos.

Also run `~/.claude/skills/play-prepublish-check/scripts/prepublish_check.sh <appDir>
[module] [aab]` when a built AAB exists (checks AD_ID, debug signing, AAB permissions).

**Triage every WARN and FAIL by hand**; the script is a pattern match. Typical benign
cases: public Firebase client keys, deliberate "Coming soon" UI, a `.env` that is
actually a committed template. Typical real ones: a server key in `.env`, a TODO stub that
throws on the iOS path, an `expect` with no iOS `actual`. For each, write the verdict and
why. Never dismiss an item as benign without opening the file.

### R8 is not done until the minified build RUNS
1. `./gradlew :androidApp:bundleRelease` (or `assembleRelease` for a local APK). Confirm
   `mapping.txt` is produced and the build log has no new `Missing class` warnings; read
   `build/outputs/mapping/release/missing_rules.txt` if present and add the suggested
   `-dontwarn`/`-keep` lines only where the code path is real.
2. Install the minified build (`android run` or `adb install`) and exercise: sign-in,
   purchases/credits, every JSON decode path (kotlinx.serialization), Koin/DI-injected
   screens, Firebase/Firestore reads, camera/media, deep links, any reflection.
   `adb logcat -b crash` stays empty.
3. Compare size with the previous release (INFO). Large growth means a rules file turned
   shrinking off in practice (blanket keeps).
4. If the `r8-analyzer` skill is installed (Step 2), run it: it finds redundant or
   overly broad keep rules.
5. Upload `mapping.txt` (Play console does it from the AAB; Crashlytics needs the plugin).

## Step 2: Skill discovery (what should be invoked?)
Match the diff and the repo to skills, load the ones that apply, and list them in the
report under "Skills applied" and "Skills recommended".

**Local dyor skills to invoke when the area is touched** (check they exist with
`ls ~/.claude/skills`):
| Change touches | Invoke |
|---|---|
| In-app purchases, credits, Adapty, StoreKit/Play Billing | `adapty-store-payments` |
| Play upload, tracks, AD_ID, tester access | `google-play-publishing`, `play-prepublish-check` |
| Firebase Auth/Firestore/Functions/Remote Config in KMP | `implement-native-firebase-kmp` |
| Store screenshots, listing text | `app-store-assets` |
| Privacy policy / terms / support page / site copy | `febak-site-pages` |
| Compose migration patterns (Room, Koin, Maps) | `compose-migration-hints` |
| Visual regression of a screen | `agentic-test-driven-development`, `execute-and-report-journey` |
| Need an overview of the whole library | `dyor-knowledge-base` |

**Android/Google skills** (these are the only ones that exist for the Android half; KMP
itself has no official skill set, so for shared/iOS code rely on Step 4 and the web docs
below). Installed ones: `android skills list`. Discoverable ones:
`android skills find <keyword>`, then `android skills add <id>`. Keywords to try per
touched area: `r8`, `edge-to-edge`, `camerax`, `media3`, `navigation`, `permissions`,
`play-policy`, `agp` (AGP upgrade), `profiler`, `credential`, `appfunctions`. Firebase:
`npx -y skills add firebase/agent-skills --agent android_studio --skill <name>`
(`firebase-auth-basics`, `firebase-firestore`, `firebase-crashlytics`,
`firebase-app-check`, `firebase-remote-config`). Recommend, do not auto-install; give
the exact command. If nothing relevant exists, say so in one line ("no installed or
discoverable skill for <area>").

## Step 3: Authoritative docs
**Android half, via the android CLI** (not memory):
```bash
android docs search "R8 keep rules full mode"     # then:
android docs fetch kb://<id-from-search>
```
Search once per distinct API or policy in the diff, e.g. `"foreground service types
android 15"`, `"photo picker permissions"`, `"target SDK requirements Play"`, `"CameraX
QualitySelector"`, `"Compose DisposableEffect"`, `"credential manager restore"`. Cite
API levels, deprecations and documented threading in findings. If `android` is not on
PATH, install it per the `android-cli` skill. If a search returns nothing useful, say so
rather than guessing.

**KMP / iOS half** (the android CLI does not cover these): use WebFetch/WebSearch on
kotlinlang.org (KMP, Kotlin/Native memory model, cinterop), jetbrains.com/help/kotlin-multiplatform-dev,
the Compose Multiplatform docs, and developer.apple.com for AVFoundation, privacy
manifest, App Review Guidelines. Prefer the official page over blog posts.

## Step 4: Code review of the release diff
Apply the full `android-review` methodology (Phase 1-4 there: boundary analysis,
systematic audit, standard findings and fix-ticket format; for a Google Play release also its
Phase 2.5 live Vitals check and constrained-emulator screenshot pass). Do not skip it: whole-file
reads, thread/ownership tracing, no artificial cap on findings. Add this KMP-specific pass:

1. **commonMain purity.** No `android.*`, `java.*`, `platform.*` imports; no `Dispatchers.IO`
   assumptions on native (use `Dispatchers.Default` or an injected dispatcher), no
   `System.currentTimeMillis`, `String.format`, `Locale`, `Thread`, `synchronized`; use
   `kotlinx-datetime`, `Mutex`, `atomicfu`.
2. **expect/actual completeness and parity.** Every `expect` has a real `actual` on
   Android and iOS (a body of `TODO()`, `= Unit`, or a returned fake value is a finding),
   with equivalent behavior: permissions, errors surfaced, cancellation, return on denied.
   Compare the Android and iOS actuals side by side for behavior drift, not just
   existence. Feature present on one platform only must be hidden or labeled on the other.
3. **Kotlin/Native threading.** Mutable state touched from multiple dispatchers
   (`mutableMapOf`, `var` caches) needs a `Mutex`/`atomic`/single-thread confinement.
   Callbacks from Objective-C/Swift into Kotlin on arbitrary threads. `StateFlow` collected
   from Swift: lifecycle and cancellation handled.
4. **iOS interop crashes.** `runCatching` does not catch `NSException`. AVAudioSession/
   AVAudioEngine/AVCapture calls, `removeTapOnBus`, `KVC` on missing keys, force-unwrapped
   `NSError**` out-params, `memScoped` pointers escaping their scope, `CPointer` not
   released, `ByteArray.toNSData()` copies on big payloads.
5. **Lifecycle on both sides.** Android: `DisposableEffect`, `repeatOnLifecycle`, camera and
   sensor release. iOS: Compose `UIViewController` dispose, observers removed, timers and
   `NSNotificationCenter` tokens cancelled; background/foreground transitions.
6. **Resources and strings.** Compose Resources present for both targets, no
   Android-only `R.string` in commonMain, localized strings exist for all shipped locales,
   usage-description strings (iOS) and permission rationale (Android) written for the
   feature that needs them.
7. **State survival.** Process death on Android (`rememberSaveable`/`SavedStateHandle`);
   iOS scene discard; navigation back stack restored.
8. **Release flags and config.** Debug menus, test accounts, "give credits away" switches
   (`adapty-store-payments`), staging endpoints and dev Firebase plists are off/prod for
   the release build. Feature flags that must flip with this build are listed.
9. **Policy vs. code.** New permissions, SDKs, data collection since the last release are
   in the Play Data safety form, the iOS privacy manifest/nutrition labels, and the
   privacy policy (`febak-site-pages`). Account deletion path exists if accounts exist.
10. **Unfinished features.** For every `ComingSoon`/disabled/hidden screen, confirm it is
    deliberately labeled to the user, not a dead end. For every WARN from Step 1 under
    "unfinished", state: ship as-is (why), finish, or hide.

## Step 5: Report and verdict
Write `SPECS/kmp-review-<yyyy-mm-dd>.md` (create `SPECS/` if absent) and paste a short
summary in chat. Structure:

```markdown
# KMP release review: <app> <version> (<date>)
**Verdict:** SHIP | SHIP AFTER FIXES | BLOCK   (one-sentence reason)
## Scope
<base>..<HEAD>, N files, modules touched
## Mechanical scan
Table: check | level | result | triage note (benign / real / fixed)
## R8 and minified-build run
What was run, what was exercised, what broke, size before/after
## Skills
Applied: ... | Recommended (not installed, with install command): ... | None found for: ...
## Docs consulted
Title (kb:// or URL): what it settled
## Findings
Ordered MAJOR > MODERATE > MINOR, each in android-review's finding format with a diff
and a 5-section fix ticket for MAJOR/MODERATE.
## Not verified
Anything you could not check (no device, no AAB, no iOS archive), stated plainly.
## Release facts
versionCode/Build number vs stores, release notes length, backend deploys, flags to flip
```

Verdict rules: any FAIL left open, any MAJOR finding, or an unrun minified build ->
**BLOCK**. Only MODERATE/WARN items with owner decisions -> **SHIP AFTER FIXES**. Else
**SHIP**. If a secret was ever committed, the verdict is BLOCK until it is rotated, even
if deleted from HEAD.

## Guardrails
- Report outcomes faithfully: say what you ran and what you did not.
- Read-only by default: fix findings only when asked. Never `git rm`, rotate keys, edit
  history, publish or upload on your own; list the commands for the user.
- Never print a full secret in the report; show the file, line and first 4 characters.
- Keep scoped: no drive-by refactors in fix tickets.
- Updating this skill: when a release teaches a new failure mode, add it to the script or
  Step 4, bump `version`, and mirror shared scan changes into `android-review/scripts/`.
